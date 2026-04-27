function files = emit_recovery_evaluation_outputs(recoveryEvaluation, runInfo, ~, evalConfig)
%EMIT_RECOVERY_EVALUATION_OUTPUTS 统一处理保存与显示开关。
files = struct( ...
    'matFile', '', ...
    'summaryFile', '', ...
    'panelFile', '', ...
    'panelShown', false, ...
    'pointTargetPanelFile', '', ...
    'pointTargetPanelShown', false);
outputOptions = evalConfig.outputOptions;

if isfield(outputOptions, 'enable') && ~outputOptions.enable
    return;
end

if outputOptions.saveMat && runInfo.enabled
    files.matFile = fullfile(runInfo.matsDir, 'recovery_evaluation.mat');
    safe_save(files.matFile, recoveryEvaluation, 'recoveryEvaluation');
end

if outputOptions.saveSummary && runInfo.enabled
    files.summaryFile = fullfile(runInfo.logsDir, 'recovery_evaluation_summary.txt');
    localWriteSummaryFile(files.summaryFile, recoveryEvaluation);
end

shouldSavePanel = outputOptions.savePanel && runInfo.enabled;
shouldShowPanel = outputOptions.showPanel;
shouldSavePointTargetPanel = outputOptions.savePointTargetPanel && runInfo.enabled;
shouldShowPointTargetPanel = outputOptions.showPointTargetPanel;

if shouldSavePanel
    files.panelFile = fullfile(runInfo.imagesDir, 'recovery_evaluation_panel.png');
end

if shouldSavePanel || shouldShowPanel
    files.panelFile = plot_recovery_evaluation_panel( ...
        recoveryEvaluation, files.panelFile, shouldShowPanel);
    files.panelShown = shouldShowPanel;
end

if shouldSavePointTargetPanel
    files.pointTargetPanelFile = fullfile(runInfo.imagesDir, 'recovery_evaluation_point_target_panel.png');
end

if shouldSavePointTargetPanel || shouldShowPointTargetPanel
    files.pointTargetPanelFile = plot_recovery_evaluation_point_target_panel( ...
        recoveryEvaluation, files.pointTargetPanelFile, shouldShowPointTargetPanel);
    files.pointTargetPanelShown = shouldShowPointTargetPanel;
end
end

function localWriteSummaryFile(filePath, recoveryEvaluation)
fid = fopen(filePath, 'w');
assert(fid > 0, '无法写入 recovery evaluation summary 文件：%s', filePath);
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Recovery Evaluation Summary\n');
fprintf(fid, 'Status: %s\n', recoveryEvaluation.status);
fprintf(fid, 'Mode: %s\n', recoveryEvaluation.config.evaluationMode);
fprintf(fid, 'Best Method: %s\n', localStringOrEmpty(recoveryEvaluation.summary.bestMethodIfAny));
fprintf(fid, '\n[High Level Findings]\n');

findings = localToCellstr(recoveryEvaluation.summary.highLevelFindings);
for idx = 1:numel(findings)
    fprintf(fid, '- %s\n', findings{idx});
end

fprintf(fid, '\n[Risk Or Limitations]\n');
risks = localToCellstr(recoveryEvaluation.summary.riskOrLimitations);
for idx = 1:numel(risks)
    fprintf(fid, '- %s\n', risks{idx});
end
end

function textValue = localStringOrEmpty(value)
if isempty(value)
    textValue = '';
else
    textValue = char(string(value));
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
