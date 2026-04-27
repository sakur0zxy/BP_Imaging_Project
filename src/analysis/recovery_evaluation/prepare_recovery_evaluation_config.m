function evalConfig = prepare_recovery_evaluation_config(evalConfig, projectMode)
%PREPARE_RECOVERY_EVALUATION_CONFIG 规范化并校验恢复效果评估配置。
if nargin < 1 || isempty(evalConfig)
    evalConfig = struct();
end
if nargin < 2
    projectMode = '';
end

assert(isstruct(evalConfig) && isscalar(evalConfig), ...
    'analysis.recoveryEvaluation 必须是标量结构体。');

defaults = localBuildDefaults(projectMode);
evalConfig = merge_structs(defaults, evalConfig);

assert(isfield(evalConfig, 'enable') && islogical(evalConfig.enable) && isscalar(evalConfig.enable), ...
    'analysis.recoveryEvaluation.enable 必须是逻辑标量。');

requestedMode = localNormalizeRequestedMode(localGetField(evalConfig, 'evaluationMode', 'auto'));
projectModeText = localNormalizeMode(projectMode);
[modeText, modeSource] = localResolveEvaluationMode(requestedMode, projectModeText);

caseNames = localNormalizeCaseNames(localGetField(evalConfig, 'caseNames', defaults.caseNames));
supportedCaseNames = defaults.caseNames;
assert(numel(caseNames) == numel(supportedCaseNames) && all(strcmp(caseNames, supportedCaseNames)), ...
    'analysis.recoveryEvaluation.caseNames 当前必须固定为 full / interrupted / recovered_cs_1d / recovered_cs_2d。');

referenceCase = char(string(localGetField(evalConfig, 'referenceCase', 'full')));
assert(any(strcmp(referenceCase, caseNames)), ...
    'analysis.recoveryEvaluation.referenceCase 必须出现在 caseNames 中。');

outputs = localValidateOutputOptions(localGetField(evalConfig, 'outputs', defaults.outputs));
metricOptions = localValidateMetricOptions(localGetField(evalConfig, 'metricOptions', defaults.metricOptions));
thresholds = localValidateThresholds(localGetField(evalConfig, 'thresholds', defaults.thresholds));

comparisonPlan = localBuildComparisonPlan(caseNames, modeText);
if isfield(evalConfig, 'comparisonPlan') && ~isempty(evalConfig.comparisonPlan)
    comparisonPlan = localValidateComparisonPlan(evalConfig.comparisonPlan, caseNames, modeText);
end

meta = localGetField(evalConfig, 'meta', struct());
if ~isstruct(meta) || ~isscalar(meta)
    error('analysis.recoveryEvaluation.meta 必须是标量结构体。');
end
meta.createdBy = 'prepare_recovery_evaluation_config';
meta.caseNames = caseNames;
meta.projectMode = projectModeText;
meta.requestedEvaluationMode = requestedMode;
meta.resolvedEvaluationMode = modeText;
meta.evaluationModeSource = modeSource;

evalConfig.mode = modeText;
evalConfig.evaluationMode = modeText;
evalConfig.caseNames = caseNames;
evalConfig.referenceCase = referenceCase;
evalConfig.comparisonPlan = comparisonPlan;
evalConfig.outputs = outputs;
evalConfig.outputOptions = outputs;
evalConfig.metricOptions = metricOptions;
evalConfig.thresholds = thresholds;
evalConfig.meta = meta;
end

function defaults = localBuildDefaults(projectMode)
modeText = localNormalizeMode(projectMode);
if isempty(modeText)
    modeText = 'simulation';
end

defaults = struct();
defaults.enable = false;
defaults.evaluationMode = 'auto';
defaults.caseNames = {'full', 'interrupted', 'recovered_cs_1d', 'recovered_cs_2d'};
defaults.referenceCase = 'full';
defaults.outputs = struct( ...
    'enable', true, ...
    'saveMat', false, ...
    'saveSummary', false, ...
    'savePanel', false, ...
    'showPanel', true, ...
    'savePointTargetPanel', false, ...
    'showPointTargetPanel', true);
defaults.metricOptions = struct( ...
    'enablePointAnalysis', strcmp(modeText, 'real'), ...
    'enableImageQuality', strcmp(modeText, 'simulation'), ...
    'compareMode', 'amplitude');

if strcmp(modeText, 'real')
    defaults.thresholds = struct('warningPeakShiftPixels', 2);
else
    defaults.thresholds = struct('warningRelativeL2Error', 0.25);
end

defaults.comparisonPlan = localBuildComparisonPlan(defaults.caseNames, modeText);
defaults.meta = struct();
end

function outputs = localValidateOutputOptions(outputs)
assert(isstruct(outputs) && isscalar(outputs), ...
    'analysis.recoveryEvaluation.outputs 必须是标量结构体。');
requiredFields = {'enable', 'saveMat', 'saveSummary', 'savePanel', 'showPanel', ...
    'savePointTargetPanel', 'showPointTargetPanel'};
for idx = 1:numel(requiredFields)
    fieldName = requiredFields{idx};
    assert(isfield(outputs, fieldName) && islogical(outputs.(fieldName)) ...
        && isscalar(outputs.(fieldName)), ...
        'analysis.recoveryEvaluation.outputs.%s 必须是逻辑标量。', fieldName);
end
end

function metricOptions = localValidateMetricOptions(metricOptions)
assert(isstruct(metricOptions) && isscalar(metricOptions), ...
    'analysis.recoveryEvaluation.metricOptions 必须是标量结构体。');
requiredLogicalFields = {'enablePointAnalysis', 'enableImageQuality'};
for idx = 1:numel(requiredLogicalFields)
    fieldName = requiredLogicalFields{idx};
    assert(isfield(metricOptions, fieldName) && islogical(metricOptions.(fieldName)) ...
        && isscalar(metricOptions.(fieldName)), ...
        'analysis.recoveryEvaluation.metricOptions.%s 必须是逻辑标量。', fieldName);
end
assert(isfield(metricOptions, 'compareMode') ...
    && any(strcmpi(string(metricOptions.compareMode), ["amplitude", "complex"])), ...
    'analysis.recoveryEvaluation.metricOptions.compareMode 只支持 amplitude 或 complex。');
metricOptions.compareMode = char(string(metricOptions.compareMode));
end

function thresholds = localValidateThresholds(thresholds)
assert(isstruct(thresholds) && isscalar(thresholds), ...
    'analysis.recoveryEvaluation.thresholds 必须是标量结构体。');
fieldNames = fieldnames(thresholds);
for idx = 1:numel(fieldNames)
    fieldName = fieldNames{idx};
    fieldValue = thresholds.(fieldName);
    assert(isnumeric(fieldValue) && isscalar(fieldValue), ...
        'analysis.recoveryEvaluation.thresholds.%s 必须是数值标量。', fieldName);
end
end

function comparisonPlan = localBuildComparisonPlan(caseNames, modeText)
comparisonPairs = { ...
    'full_vs_interrupted', 'full', 'interrupted'; ...
    'full_vs_recovered_cs_1d', 'full', 'recovered_cs_1d'; ...
    'full_vs_recovered_cs_2d', 'full', 'recovered_cs_2d'; ...
    'interrupted_vs_recovered_cs_1d', 'interrupted', 'recovered_cs_1d'; ...
    'interrupted_vs_recovered_cs_2d', 'interrupted', 'recovered_cs_2d'};

comparisonPlan = struct('comparisonName', {}, 'referenceCase', {}, 'targetCase', {}, 'mode', {});
for idx = 1:size(comparisonPairs, 1)
    referenceCase = comparisonPairs{idx, 2};
    targetCase = comparisonPairs{idx, 3};
    if any(strcmp(referenceCase, caseNames)) && any(strcmp(targetCase, caseNames))
        comparisonPlan(end + 1) = struct( ... %#ok<AGROW>
            'comparisonName', comparisonPairs{idx, 1}, ...
            'referenceCase', referenceCase, ...
            'targetCase', targetCase, ...
            'mode', modeText);
    end
end
end

function comparisonPlan = localValidateComparisonPlan(comparisonPlan, caseNames, modeText)
assert(isstruct(comparisonPlan), ...
    'analysis.recoveryEvaluation.comparisonPlan 必须是结构体数组。');
requiredFields = {'comparisonName', 'referenceCase', 'targetCase'};
for idx = 1:numel(comparisonPlan)
    for fieldIdx = 1:numel(requiredFields)
        fieldName = requiredFields{fieldIdx};
        assert(isfield(comparisonPlan(idx), fieldName), ...
            'analysis.recoveryEvaluation.comparisonPlan 缺少 %s。', fieldName);
    end
    assert(any(strcmp(comparisonPlan(idx).referenceCase, caseNames)), ...
        'comparisonPlan.referenceCase 不在 caseNames 中。');
    assert(any(strcmp(comparisonPlan(idx).targetCase, caseNames)), ...
        'comparisonPlan.targetCase 不在 caseNames 中。');
    comparisonPlan(idx).mode = modeText;
end
end

function caseNames = localNormalizeCaseNames(caseNames)
if ischar(caseNames) || isstring(caseNames)
    caseNames = cellstr(string(caseNames));
elseif iscell(caseNames)
    caseNames = cellfun(@(value) char(string(value)), caseNames, 'UniformOutput', false);
else
    error('analysis.recoveryEvaluation.caseNames 必须是字符串或 cellstr。');
end

caseNames = reshape(caseNames, 1, []);
end

function modeText = localNormalizeMode(modeText)
modeText = lower(char(string(modeText)));
switch modeText
    case {'sim', 'simulation'}
        modeText = 'simulation';
    case {'real'}
        modeText = 'real';
    otherwise
        modeText = '';
end
end

function requestedMode = localNormalizeRequestedMode(requestedMode)
requestedMode = lower(char(string(requestedMode)));
switch requestedMode
    case {'auto', ''}
        requestedMode = 'auto';
    case {'sim', 'simulation'}
        requestedMode = 'simulation';
    case {'real'}
        requestedMode = 'real';
    otherwise
        error('analysis.recoveryEvaluation.evaluationMode 只支持 auto、real 或 simulation。');
end
end

function [modeText, modeSource] = localResolveEvaluationMode(requestedMode, projectModeText)
if strcmp(requestedMode, 'auto')
    if isempty(projectModeText)
        modeText = 'simulation';
        modeSource = 'auto-default-simulation';
    else
        modeText = projectModeText;
        modeSource = 'auto-project-mode';
    end
    return;
end

if ~isempty(projectModeText) && ~strcmp(requestedMode, projectModeText)
    error('analysis.recoveryEvaluation.evaluationMode=%s 与 project.mode=%s 不匹配。默认建议使用 auto，或手动选择匹配当前数据流程的模式。', ...
        requestedMode, projectModeText);
end

modeText = requestedMode;
modeSource = 'manual';
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end
