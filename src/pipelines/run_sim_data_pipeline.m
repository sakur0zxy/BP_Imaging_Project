function result = run_sim_data_pipeline(config)
%RUN_SIM_DATA_PIPELINE 串起仿真生成、缺失控制、BP 成像和输出。

pipelineTimer = tic;

config = validate_sim_config(config);
runInfo = prepare_run_dir(config);
log = logger(runInfo.logFile);
cleanup = onCleanup(@() log.close()); %#ok<NASGU>

log.info('Start simulation pipeline.');
backend = resolve_backend(config);
poolInfo = init_hardware_pool(config);
log.info('Backend: %s', backend.name);
log.info('Parallel pool enabled: %d, workers: %d', poolInfo.enabled, poolInfo.workers);

if runInfo.enabled
    safe_save(runInfo.effectiveConfigFile, config, 'config');
end

save_checkpoint(runInfo, struct('stage', 'config_loaded'));

sourceData = generate_point_target_data(config);
sourceReference = sourceData;
log.info('Generated simulation data: range=%d, azimuth=%d', ...
    size(sourceData.echo, 1), size(sourceData.echo, 2));
save_checkpoint(runInfo, struct('stage', 'data_generated'));

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

imageResult = bp_imaging(sourceData, config);
log.info('Imaging finished: used azimuth=%d/%d, peak=%.6g, elapsed=%.3fs', ...
    imageResult.meta.usedAzimuthCount, imageResult.meta.totalAzimuthCount, ...
    imageResult.peak.value, imageResult.meta.elapsedSeconds);
save_checkpoint(runInfo, struct('stage', 'imaging_done'));

analysisContext = struct( ...
    'referenceImage', [], ...
    'referenceLabel', '', ...
    'referenceInfo', struct());
referenceCacheInfo = struct();
if config.analysis.enableImageQuality
    [referenceImageResult, referenceCacheInfo] = get_full_image_reference(sourceReference, config);
    analysisContext.referenceImage = referenceImageResult.image;
    analysisContext.referenceLabel = 'full-echo-reference';
    analysisContext.referenceInfo = referenceCacheInfo;
    log.info('Reference imaging ready for analysis: cacheHit=%d, peak=%.6g, elapsed=%.3fs', ...
        referenceCacheInfo.cacheHit, referenceImageResult.peak.value, ...
        referenceImageResult.meta.elapsedSeconds);
end

analysisResult = point_target_analysis(imageResult, config, analysisContext);
recoveryEvaluation = run_optional_recovery_evaluation(config, struct( ...
    'runInfo', runInfo, ...
    'sourceReference', sourceReference, ...
    'degradedSourceData', degradedSourceData));
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
    'recoveryEvaluation', recoveryEvaluation.files, ...
    'manifest', '');
result.summary = struct( ...
    'pipelineElapsedSeconds', toc(pipelineTimer), ...
    'usedAzimuthCount', imageResult.meta.usedAzimuthCount, ...
    'totalAzimuthCount', imageResult.meta.totalAzimuthCount, ...
    'peakAmplitude', imageResult.peak.value, ...
    'recoveryStatus', recoveryResult.status, ...
    'recoveryEvaluationStatus', recoveryEvaluation.status, ...
    'runDir', runInfo.runDir, ...
    'targetCount', size(config.scene.targetPositions, 1));

if isfield(recoveryResult, 'method') && ~isempty(recoveryResult.method)
    result.summary.recoveryMethod = recoveryResult.method;
end
if isfield(recoveryResult, 'recoveryInfo') && isstruct(recoveryResult.recoveryInfo) ...
        && isfield(recoveryResult.recoveryInfo, 'iterations')
    result.summary.recoveryIterations = recoveryResult.recoveryInfo.iterations;
end
if config.analysis.enableImageQuality
    result.summary.referenceCacheHit = analysisContext.referenceInfo.cacheHit;
end
if isfield(recoveryEvaluation, 'summary') && isstruct(recoveryEvaluation.summary) ...
        && isfield(recoveryEvaluation.summary, 'bestMethodIfAny') ...
        && ~isempty(recoveryEvaluation.summary.bestMethodIfAny)
    result.summary.recoveryEvaluationBestMethod = recoveryEvaluation.summary.bestMethodIfAny;
end

result.provenance = build_pipeline_provenance(struct( ...
    'mode', 'sim', ...
    'config', config, ...
    'sourceData', sourceData, ...
    'degradationInfo', degradationInfo, ...
    'recoveryResult', recoveryResult, ...
    'imageResult', imageResult, ...
    'analysisResult', analysisResult, ...
    'recoveryEvaluation', recoveryEvaluation, ...
    'referenceCacheInfo', referenceCacheInfo, ...
    'backend', backend, ...
    'runInfo', runInfo));
result.files.manifest = save_run_manifest(result, runInfo, config);

save_summary(result, runInfo, config);
save_checkpoint(runInfo, struct('stage', 'completed'));
log.info('Simulation pipeline finished in %.3fs.', result.summary.pipelineElapsedSeconds);
end

function textValue = localStringOrEmpty(value)
if isempty(value)
    textValue = '';
else
    textValue = char(string(value));
end
end
