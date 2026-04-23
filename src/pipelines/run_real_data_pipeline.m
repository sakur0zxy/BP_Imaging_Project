function result = run_real_data_pipeline(config)
%RUN_REAL_DATA_PIPELINE 串起实测读取、缺失控制、BP 成像和输出。

pipelineTimer = tic;

config = validate_real_config(config);
runInfo = prepare_run_dir(config);
log = logger(runInfo.logFile);
cleanup = onCleanup(@() log.close()); %#ok<NASGU>

log.info('Start real-data pipeline.');
backend = resolve_backend(config);
poolInfo = init_hardware_pool(config);
log.info('Backend: %s', backend.name);
log.info('Parallel pool enabled: %d, workers: %d', poolInfo.enabled, poolInfo.workers);

if runInfo.enabled
    safe_save(runInfo.effectiveConfigFile, config, 'config');
end

save_checkpoint(runInfo, struct('stage', 'config_loaded'));

sourceData = load_gotcha_data(config);
sourceReference = sourceData;
analysisContext = struct( ...
    'referenceImage', [], ...
    'referenceLabel', '', ...
    'referenceInfo', struct());
log.info('Loaded real data: range=%d, azimuth=%d', ...
    size(sourceData.echo, 1), size(sourceData.echo, 2));
save_checkpoint(runInfo, struct('stage', 'data_loaded'));

[referenceImageResult, referenceCacheInfo] = get_full_image_reference(sourceReference, config);
analysisContext.referenceImage = referenceImageResult.image;
analysisContext.referenceLabel = 'full-echo-reference';
analysisContext.referenceInfo = referenceCacheInfo;
log.info('Reference imaging ready for real-data baseline: cacheHit=%d, folder=%s', ...
    referenceCacheInfo.cacheHit, referenceCacheInfo.folderName);

[sourceData, degradationInfo] = apply_degradation(sourceData, config.degradation);
degradedSourceData = sourceData;
log.info('Degradation mode: %s, missing ratio: %.6f', ...
    degradationInfo.mode, degradationInfo.missingRatio);
save_checkpoint(runInfo, struct('stage', 'degradation_done'));

recoveryResult = struct('status', 'disabled', 'reason', 'recovery-disabled');
recoveryFile = '';
if config.recovery.enable
    recoveryResult = run_recovery(sourceData, config.recovery, sourceReference);
    recoveryFile = save_analysis_result(recoveryResult, runInfo, config, 'recovery');
    if strcmp(recoveryResult.status, 'completed')
        sourceData = recoveryResult.sourceData;
        log.info('Recovery finished: method=%s, iterations=%d, missing rel err=%.6g, elapsed=%.3fs', ...
            recoveryResult.method, recoveryResult.recoveryInfo.iterations, ...
            recoveryResult.metrics.missingRelErr, recoveryResult.recoveryInfo.runtimeSec);
    else
        log.info('Recovery skipped: %s', recoveryResult.reason);
    end
    save_checkpoint(runInfo, struct('stage', 'recovery_done', 'status', recoveryResult.status));
end

if localCanReuseReferenceImage(config, degradationInfo, recoveryResult)
    imageResult = referenceImageResult;
else
    imageResult = bp_imaging(sourceData, config);
end
log.info('Imaging finished: used azimuth=%d/%d, peak=%.6g, elapsed=%.3fs', ...
    imageResult.meta.usedAzimuthCount, imageResult.meta.totalAzimuthCount, ...
    imageResult.peak.value, imageResult.meta.elapsedSeconds);
save_checkpoint(runInfo, struct('stage', 'imaging_done'));

analysisResult = point_target_analysis(imageResult, config, analysisContext);
recoveryEvaluation = run_recovery_evaluation(config, struct( ...
    'runInfo', runInfo, ...
    'sourceReference', sourceReference, ...
    'degradedSourceData', degradedSourceData, ...
    'fullImageResult', referenceImageResult));
if recoveryEvaluation.enabled
    log.info('Recovery evaluation finished: status=%s, bestMethod=%s', ...
        recoveryEvaluation.status, localStringOrEmpty(recoveryEvaluation.summary.bestMethodIfAny));
end
imageFiles = save_image_result(imageResult, runInfo, config, 'bp_image');
analysisFile = save_analysis_result(analysisResult, runInfo, config, 'analysis');

result = struct();
result.config = config;
result.backend = backend;
result.pool = poolInfo;
result.run = runInfo;
result.source = sourceData;
result.degradation = degradationInfo;
result.recovery = recoveryResult;
result.image = imageResult;
result.analysis = analysisResult;
result.recoveryEvaluation = recoveryEvaluation;
result.files = struct( ...
    'image', imageFiles, ...
    'analysis', analysisFile, ...
    'recovery', recoveryFile, ...
    'recoveryEvaluation', recoveryEvaluation.files);
result.summary = struct( ...
    'pipelineElapsedSeconds', toc(pipelineTimer), ...
    'usedAzimuthCount', imageResult.meta.usedAzimuthCount, ...
    'totalAzimuthCount', imageResult.meta.totalAzimuthCount, ...
    'peakAmplitude', imageResult.peak.value, ...
    'recoveryStatus', recoveryResult.status, ...
    'recoveryEvaluationStatus', recoveryEvaluation.status, ...
    'referenceCacheHit', referenceCacheInfo.cacheHit, ...
    'referenceCacheFolder', referenceCacheInfo.folderName, ...
    'runDir', runInfo.runDir);

if isfield(recoveryResult, 'method') && ~isempty(recoveryResult.method)
    result.summary.recoveryMethod = recoveryResult.method;
end
if isfield(recoveryResult, 'recoveryInfo') && isstruct(recoveryResult.recoveryInfo) ...
        && isfield(recoveryResult.recoveryInfo, 'iterations')
    result.summary.recoveryIterations = recoveryResult.recoveryInfo.iterations;
end
if isfield(recoveryEvaluation, 'summary') && isstruct(recoveryEvaluation.summary) ...
        && isfield(recoveryEvaluation.summary, 'bestMethodIfAny') ...
        && ~isempty(recoveryEvaluation.summary.bestMethodIfAny)
    result.summary.recoveryEvaluationBestMethod = recoveryEvaluation.summary.bestMethodIfAny;
end

save_summary(result, runInfo, config);
save_checkpoint(runInfo, struct('stage', 'completed'));
log.info('Real-data pipeline finished in %.3fs.', result.summary.pipelineElapsedSeconds);
end

function tf = localCanReuseReferenceImage(config, degradationInfo, recoveryResult)
sourceUnchangedByDegradation = ~config.degradation.enable ...
    || strcmpi(degradationInfo.mode, 'none') ...
    || degradationInfo.totalMissing == 0;
sourceUnchangedByRecovery = ~config.recovery.enable ...
    || any(strcmpi(recoveryResult.status, {'disabled', 'skipped'}));
tf = sourceUnchangedByDegradation && sourceUnchangedByRecovery;
end

function textValue = localStringOrEmpty(value)
if isempty(value)
    textValue = '';
else
    textValue = char(string(value));
end
end
