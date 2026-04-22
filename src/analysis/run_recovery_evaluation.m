function result = run_recovery_evaluation(config, context)
%RUN_RECOVERY_EVALUATION 恢复效果评估唯一入口。
if nargin < 2 || isempty(context)
    context = struct();
end

moduleConfig = localGetRecoveryEvaluationConfig(config);
evalConfig = prepare_recovery_evaluation_config(moduleConfig, localGetProjectMode(config));

result = struct();
result.enabled = evalConfig.enable;
result.status = 'disabled';
result.config = evalConfig;
result.cases = struct();
result.comparisons = struct();
result.summary = struct();
result.files = struct('matFile', '', 'summaryFile', '', 'panelFile', '', 'panelShown', false);
result.messages = {};

if ~evalConfig.enable
    result.reason = 'recovery-evaluation-disabled';
    return;
end

casesToEvaluate = build_recovery_evaluation_cases(evalConfig, context);
[caseResults, comparisonResults] = evaluate_recovery_cases(casesToEvaluate, evalConfig, config, context);
summaryResult = summarize_recovery_evaluation(caseResults, comparisonResults, evalConfig);

result.status = localResolveOverallStatus(caseResults, comparisonResults);
result.reason = '';
result.cases = caseResults;
result.comparisons = comparisonResults;
result.summary = summaryResult;
result.messages = localCollectMessages(caseResults, comparisonResults);
result.files = emit_recovery_evaluation_outputs(result, localGetRunInfo(context), config, evalConfig);
end

function moduleConfig = localGetRecoveryEvaluationConfig(config)
moduleConfig = struct();
if isfield(config, 'analysis') && isstruct(config.analysis) ...
        && isfield(config.analysis, 'recoveryEvaluation')
    moduleConfig = config.analysis.recoveryEvaluation;
end
end

function projectMode = localGetProjectMode(config)
projectMode = '';
if isfield(config, 'project') && isstruct(config.project) && isfield(config.project, 'mode')
    projectMode = config.project.mode;
end
end

function runInfo = localGetRunInfo(context)
runInfo = struct( ...
    'enabled', false, ...
    'runDir', '', ...
    'imagesDir', '', ...
    'matsDir', '', ...
    'logsDir', '', ...
    'checkpointDir', '', ...
    'logFile', '', ...
    'checkpointFile', '', ...
    'effectiveConfigFile', '', ...
    'summaryFile', '');

if isstruct(context) && isfield(context, 'runInfo') && isstruct(context.runInfo)
    runInfo = merge_structs(runInfo, context.runInfo);
end
end

function status = localResolveOverallStatus(caseResults, comparisonResults)
status = 'completed';

caseNames = fieldnames(caseResults);
for idx = 1:numel(caseNames)
    caseStatus = localGetField(caseResults.(caseNames{idx}), 'status', 'completed');
    if strcmp(caseStatus, 'failed')
        status = 'failed';
        return;
    elseif strcmp(caseStatus, 'skipped')
        status = 'partial';
    end
end

comparisonNames = fieldnames(comparisonResults);
for idx = 1:numel(comparisonNames)
    comparisonStatus = localGetField(comparisonResults.(comparisonNames{idx}), 'status', 'completed');
    if strcmp(comparisonStatus, 'failed')
        status = 'failed';
        return;
    elseif strcmp(comparisonStatus, 'skipped')
        status = 'partial';
    end
end
end

function messages = localCollectMessages(caseResults, comparisonResults)
messages = {};

caseNames = fieldnames(caseResults);
for idx = 1:numel(caseNames)
    caseMessages = localGetField(caseResults.(caseNames{idx}), 'messages', {});
    messages = [messages, localToCellstr(caseMessages)]; %#ok<AGROW>
end

comparisonNames = fieldnames(comparisonResults);
for idx = 1:numel(comparisonNames)
    comparisonMessages = localGetField(comparisonResults.(comparisonNames{idx}), 'messages', {});
    messages = [messages, localToCellstr(comparisonMessages)]; %#ok<AGROW>
end
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end

function values = localToCellstr(value)
if isempty(value)
    values = {};
elseif ischar(value)
    values = {value};
elseif isstring(value)
    values = cellstr(value(:).');
elseif iscell(value)
    values = value;
else
    values = {char(string(value))};
end
end
