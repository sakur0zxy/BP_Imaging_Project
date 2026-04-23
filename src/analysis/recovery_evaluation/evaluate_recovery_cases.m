function [caseResults, comparisonResults] = evaluate_recovery_cases(caseItems, evalConfig, config, ~)
%EVALUATE_RECOVERY_CASES 逐个 case 评估并生成 comparisons。
caseResults = struct();
comparisonResults = struct();

fullImage = [];
for idx = 1:numel(evalConfig.caseNames)
    caseName = evalConfig.caseNames{idx};
    [caseResult, fullImage] = localEvaluateSingleCase(caseItems.(caseName), evalConfig, config, fullImage);
    caseResults.(caseName) = caseResult;
end

for idx = 1:numel(evalConfig.comparisonPlan)
    comparisonSpec = evalConfig.comparisonPlan(idx);
    referenceCase = caseResults.(comparisonSpec.referenceCase);
    targetCase = caseResults.(comparisonSpec.targetCase);

    if strcmp(evalConfig.evaluationMode, 'simulation')
        metrics = compute_sim_recovery_metrics(referenceCase, targetCase, comparisonSpec, evalConfig);
    else
        metrics = compute_real_recovery_metrics(referenceCase, targetCase, comparisonSpec, evalConfig);
    end

    comparisonStatus = localGetField(metrics, 'status', 'completed');
    comparisonMessages = localBuildComparisonMessages(metrics, comparisonSpec);
    comparisonResults.(comparisonSpec.comparisonName) = build_comparison_result( ...
        comparisonSpec.comparisonName, ...
        comparisonSpec.referenceCase, ...
        comparisonSpec.targetCase, ...
        evalConfig.evaluationMode, ...
        metrics, ...
        comparisonStatus, ...
        comparisonMessages, ...
        struct());
end
end

function [caseResult, fullImage] = localEvaluateSingleCase(caseItem, evalConfig, config, fullImage)
messages = {};
artifacts = struct( ...
    'imageResult', struct(), ...
    'analysisResult', struct(), ...
    'recoveryResult', struct(), ...
    'cacheInfo', struct());

switch caseItem.caseType
    case 'full'
        [imageResult, cacheInfo] = localResolveFullImage(caseItem, config);
        artifacts.imageResult = imageResult;
        artifacts.cacheInfo = cacheInfo;
        if isfield(imageResult, 'image')
            fullImage = imageResult.image;
        end
        recoveryResult = struct('status', 'not_applicable', 'reason', 'full-case');

    case 'interrupted'
        imageResult = bp_imaging(caseItem.payload.sourceData, config);
        artifacts.imageResult = imageResult;
        recoveryResult = struct('status', 'not_applicable', 'reason', 'interrupted-case');

    case 'recovered'
        recoveryConfig = localBuildRecoveryConfig(config, caseItem.payload.recoveryMethod);
        recoveryResult = run_recovery(caseItem.payload.sourceData, recoveryConfig, caseItem.payload.referenceSourceData);
        imageResult = bp_imaging(recoveryResult.sourceData, config);
        artifacts.imageResult = imageResult;
        messages{end + 1} = sprintf('Recovery case %s finished with status=%s.', ...
            caseItem.caseName, recoveryResult.status);

    otherwise
        error('evaluate_recovery_cases:UnsupportedCaseType', ...
            '不支持的 caseType: %s', caseItem.caseType);
end

artifacts.recoveryResult = recoveryResult;
analysisResult = localRunCaseAnalysis(imageResult, fullImage, config, evalConfig);
artifacts.analysisResult = analysisResult;

caseMetrics = localBuildCaseMetrics(imageResult, analysisResult, recoveryResult, artifacts.cacheInfo);
caseStatus = localResolveCaseStatus(caseItem, recoveryResult, analysisResult);
caseMessages = messages;
if isfield(analysisResult, 'status') && strcmp(analysisResult.status, 'partial')
    caseMessages{end + 1} = sprintf('Case %s analysis status=partial.', caseItem.caseName);
end

caseResult = build_case_result( ...
    caseItem, ...
    caseMetrics, ...
    artifacts, ...
    caseStatus, ...
    caseMessages, ...
    struct('displayName', localGetField(caseItem.meta, 'displayName', caseItem.caseName)));
end

function caseStatus = localResolveCaseStatus(caseItem, recoveryResult, analysisResult)
caseStatus = 'completed';

if strcmp(caseItem.caseType, 'recovered')
    recoveryStatus = localGetField(recoveryResult, 'status', 'completed');
    if ~strcmp(recoveryStatus, 'completed')
        caseStatus = recoveryStatus;
        return;
    end
end

if isfield(analysisResult, 'status') && strcmp(analysisResult.status, 'partial')
    caseStatus = 'partial';
end
end

function [imageResult, cacheInfo] = localResolveFullImage(caseItem, config)
cacheInfo = struct( ...
    'enabled', false, ...
    'cacheHit', false, ...
    'folderName', '', ...
    'reason', '');

if isfield(caseItem.payload, 'fullImageResult') ...
        && isstruct(caseItem.payload.fullImageResult) ...
        && isfield(caseItem.payload.fullImageResult, 'image')
    imageResult = caseItem.payload.fullImageResult;
    cacheInfo.reason = 'reused-context-full-image';
else
    [imageResult, cacheInfo] = get_full_image_reference(caseItem.payload.sourceData, config);
end
end

function recoveryConfig = localBuildRecoveryConfig(config, methodName)
recoveryConfig = config.recovery;
recoveryConfig.enable = true;
recoveryConfig.method = methodName;
recoveryConfig = prepare_recovery_config(recoveryConfig);
end

function analysisResult = localRunCaseAnalysis(imageResult, fullImage, config, evalConfig)
analysisConfig = config;
analysisConfig.analysis.enablePointAnalysis = evalConfig.metricOptions.enablePointAnalysis;
analysisConfig.analysis.enableImageQuality = evalConfig.metricOptions.enableImageQuality && ~isempty(fullImage);
analysisConfig.analysis.imageQuality.compareMode = evalConfig.metricOptions.compareMode;
analysisConfig.debug.showPointTargetFigures = false;

analysisContext = struct( ...
    'referenceImage', fullImage, ...
    'referenceLabel', 'recovery-evaluation-full', ...
    'referenceInfo', struct('available', ~isempty(fullImage)));
analysisResult = point_target_analysis(imageResult, analysisConfig, analysisContext);
end

function metrics = localBuildCaseMetrics(imageResult, analysisResult, recoveryResult, cacheInfo)
metrics = struct();
metrics.pointTarget = localExtractPointTargetMetrics(analysisResult);
metrics.imageQuality = localExtractImageQualityMetrics(analysisResult);
metrics.peak = struct( ...
    'row', imageResult.peak.row, ...
    'col', imageResult.peak.col, ...
    'value', imageResult.peak.value);
metrics.recovery = struct( ...
    'status', localGetField(recoveryResult, 'status', 'not_applicable'), ...
    'method', localGetField(recoveryResult, 'method', ''), ...
    'iterations', localGetNestedField(recoveryResult, {'recoveryInfo', 'iterations'}, 0), ...
    'runtimeSec', localGetNestedField(recoveryResult, {'recoveryInfo', 'runtimeSec'}, 0));
metrics.cache = struct( ...
    'cacheHit', localGetField(cacheInfo, 'cacheHit', false), ...
    'folderName', localGetField(cacheInfo, 'folderName', ''));
end

function pointMetrics = localExtractPointTargetMetrics(analysisResult)
pointMetrics = struct('available', false);
if ~isfield(analysisResult, 'pointTarget') || ~strcmp(localGetField(analysisResult.pointTarget, 'status', ''), 'completed')
    return;
end

pointMetrics.available = true;
pointMetrics.avgPslrDb = localAverageValid([ ...
    analysisResult.pointTarget.xProfile.metrics.pslrDb, ...
    analysisResult.pointTarget.yProfile.metrics.pslrDb]);
pointMetrics.avgIslrDb = localAverageValid([ ...
    analysisResult.pointTarget.xProfile.metrics.islrDb, ...
    analysisResult.pointTarget.yProfile.metrics.islrDb]);
pointMetrics.avgIrwPhysical = localAverageValid([ ...
    analysisResult.pointTarget.xProfile.metrics.irwPhysical, ...
    analysisResult.pointTarget.yProfile.metrics.irwPhysical]);
pointMetrics.peakRow = analysisResult.pointTarget.peak.row;
pointMetrics.peakCol = analysisResult.pointTarget.peak.col;
pointMetrics.peakValue = analysisResult.pointTarget.peak.value;
pointMetrics.x = analysisResult.pointTarget.xProfile.metrics;
pointMetrics.y = analysisResult.pointTarget.yProfile.metrics;
end

function imageQualityMetrics = localExtractImageQualityMetrics(analysisResult)
imageQualityMetrics = struct('available', false);
if ~isfield(analysisResult, 'imageQuality') || ~strcmp(localGetField(analysisResult.imageQuality, 'status', ''), 'completed')
    return;
end

imageQualityMetrics.available = true;
imageQualityMetrics.compareMode = analysisResult.imageQuality.metrics.compareMode;
imageQualityMetrics.metrics = analysisResult.imageQuality.metrics;
end

function messages = localBuildComparisonMessages(metrics, comparisonSpec)
messages = {};
if isfield(metrics, 'status') && strcmp(metrics.status, 'skipped')
    reason = localGetNestedField(metrics, {'meta', 'reason'}, 'unknown');
    messages{end + 1} = sprintf('Comparison %s skipped: %s.', ...
        comparisonSpec.comparisonName, reason);
end
end

function value = localAverageValid(values)
values = values(isfinite(values));
if isempty(values)
    value = NaN;
else
    value = mean(values);
end
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end

function value = localGetNestedField(data, fieldPath, defaultValue)
value = defaultValue;
current = data;
for idx = 1:numel(fieldPath)
    fieldName = fieldPath{idx};
    if ~isstruct(current) || ~isfield(current, fieldName)
        return;
    end
    current = current.(fieldName);
end
value = current;
end
