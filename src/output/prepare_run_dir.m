function runInfo = prepare_run_dir(config)
%PREPARE_RUN_DIR 创建本次运行目录。

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

if ~config.output.enableSave
    return;
end

runRoot = fullfile(config.path.projectRoot, config.output.runRoot);
runName = ['run_', timestamp_str()];
runDir = fullfile(runRoot, runName);

runInfo.enabled = true;
runInfo.runDir = runDir;
runInfo.imagesDir = fullfile(runDir, 'images');
runInfo.matsDir = fullfile(runDir, 'mats');
runInfo.logsDir = fullfile(runDir, 'logs');
runInfo.checkpointDir = fullfile(runDir, 'checkpoint');
runInfo.logFile = fullfile(runInfo.logsDir, 'session_log.txt');
runInfo.checkpointFile = fullfile(runInfo.checkpointDir, 'checkpoint_status.json');
runInfo.effectiveConfigFile = fullfile(runDir, 'effective_config.mat');
runInfo.summaryFile = fullfile(runDir, 'summary.mat');

ensure_dir(runInfo.imagesDir);
ensure_dir(runInfo.matsDir);
ensure_dir(runInfo.logsDir);
ensure_dir(runInfo.checkpointDir);
end

