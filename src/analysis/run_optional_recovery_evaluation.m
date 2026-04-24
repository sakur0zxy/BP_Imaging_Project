function result = run_optional_recovery_evaluation(config, context)
%RUN_OPTIONAL_RECOVERY_EVALUATION 在模块可用且开启时运行恢复评估。

if nargin < 2 || isempty(context)
    context = struct();
end

if ~localIsRecoveryEvaluationEnabled(config)
    result = localDisabledResult(config, 'recovery-evaluation-disabled');
    return;
end

[isAvailable, missingFunctions] = is_recovery_evaluation_available();
if ~isAvailable
    error('run_optional_recovery_evaluation:ModuleMissing', ...
        ['analysis.recoveryEvaluation.enable=true，但恢复评估模块不完整。', ...
        '缺失函数：%s。请恢复 src/analysis/recovery_evaluation，或关闭 analysis.recoveryEvaluation.enable。'], ...
        strjoin(missingFunctions, ', '));
end

result = run_recovery_evaluation(config, context);
end

function tf = localIsRecoveryEvaluationEnabled(config)
tf = false;
if isstruct(config) && isfield(config, 'analysis') && isstruct(config.analysis) ...
        && isfield(config.analysis, 'recoveryEvaluation') ...
        && isstruct(config.analysis.recoveryEvaluation) ...
        && isfield(config.analysis.recoveryEvaluation, 'enable')
    tf = logical(config.analysis.recoveryEvaluation.enable);
end
end

function result = localDisabledResult(config, reason)
moduleConfig = struct();
if isstruct(config) && isfield(config, 'analysis') && isstruct(config.analysis) ...
        && isfield(config.analysis, 'recoveryEvaluation') ...
        && isstruct(config.analysis.recoveryEvaluation)
    moduleConfig = config.analysis.recoveryEvaluation;
end

result = struct();
result.enabled = false;
result.status = 'disabled';
result.config = moduleConfig;
result.cases = struct();
result.comparisons = struct();
result.summary = struct();
result.files = struct('matFile', '', 'summaryFile', '', 'panelFile', '', 'panelShown', false);
result.messages = {};
result.reason = reason;
end
