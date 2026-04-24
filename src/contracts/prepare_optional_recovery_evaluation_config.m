function evalConfig = prepare_optional_recovery_evaluation_config(evalConfig, projectMode)
%PREPARE_OPTIONAL_RECOVERY_EVALUATION_CONFIG 处理可选恢复评估配置。

if nargin < 1 || isempty(evalConfig)
    evalConfig = struct();
end
if nargin < 2
    projectMode = '';
end

assert(isstruct(evalConfig) && isscalar(evalConfig), ...
    'analysis.recoveryEvaluation 必须是标量结构体。');

if exist('prepare_recovery_evaluation_config', 'file') == 2
    evalConfig = prepare_recovery_evaluation_config(evalConfig, projectMode);
    return;
end

defaults = localBuildDisabledDefaults(projectMode);
evalConfig = merge_structs(defaults, evalConfig);

assert(isfield(evalConfig, 'enable') && islogical(evalConfig.enable) && isscalar(evalConfig.enable), ...
    'analysis.recoveryEvaluation.enable 必须是逻辑标量。');
if evalConfig.enable
    error('prepare_optional_recovery_evaluation_config:ModuleMissing', ...
        ['analysis.recoveryEvaluation.enable=true，但恢复评估模块不可用。', ...
        '请恢复 src/analysis/recovery_evaluation，或将 analysis.recoveryEvaluation.enable 设为 false。']);
end

requestedMode = localNormalizeRequestedMode(localGetField(evalConfig, 'evaluationMode', 'auto'));
projectModeText = localNormalizeMode(projectMode);
[modeText, modeSource] = localResolveEvaluationMode(requestedMode, projectModeText);

meta = localGetField(evalConfig, 'meta', struct());
if ~isstruct(meta) || ~isscalar(meta)
    meta = struct();
end
meta.createdBy = 'prepare_optional_recovery_evaluation_config';
meta.projectMode = projectModeText;
meta.requestedEvaluationMode = requestedMode;
meta.resolvedEvaluationMode = modeText;
meta.evaluationModeSource = modeSource;
meta.moduleAvailable = false;

evalConfig.mode = modeText;
evalConfig.evaluationMode = modeText;
evalConfig.meta = meta;
end

function defaults = localBuildDisabledDefaults(projectMode)
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
    'enable', false, ...
    'saveMat', false, ...
    'saveSummary', false, ...
    'savePanel', false, ...
    'showPanel', false);
defaults.metricOptions = struct( ...
    'enablePointAnalysis', strcmp(modeText, 'real'), ...
    'enableImageQuality', strcmp(modeText, 'simulation'), ...
    'compareMode', 'amplitude');
if strcmp(modeText, 'real')
    defaults.thresholds = struct('warningPeakShiftPixels', 2);
else
    defaults.thresholds = struct('warningRelativeL2Error', 0.25);
end
defaults.meta = struct();
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
    error(['analysis.recoveryEvaluation.evaluationMode=%s 与 project.mode=%s 不匹配。', ...
        '默认建议使用 auto，或手动选择匹配当前数据流程的模式。'], ...
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
