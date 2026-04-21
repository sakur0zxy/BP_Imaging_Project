function result = run_cs_recovery(sourceData, recoveryConfig, referenceSourceData)
%RUN_CS_RECOVERY 恢复流程入口。
if nargin < 2
    error('run_cs_recovery:NotEnoughInputs', ...
        '至少需要 sourceData 和 recoveryConfig。');
end
if nargin < 3
    referenceSourceData = [];
end

sourceData = validate_source_data(sourceData);
if ~isempty(referenceSourceData)
    referenceSourceData = validate_source_data(referenceSourceData);
end

result = struct();
result.status = 'skipped';
result.reason = 'recovery-disabled';
result.method = '';
result.model = struct();
result.sourceData = sourceData;
result.echo = sourceData.echo;
result.recoveryInfo = struct();
result.metrics = struct();

if ~recoveryConfig.enable
    return;
end

model = build_measurement_model(sourceData, referenceSourceData);
result.model = model;
result.method = lower(char(string(recoveryConfig.method)));

if recoveryConfig.skipWhenNoMissing && ~any(model.missingMatrixMask(:))
    result.reason = 'no-missing-samples';
    return;
end

switch result.method
    case '1d'
        recoveryResult = recover_1d(model, recoveryConfig);
    case '2d'
        recoveryResult = recover_2d(model, recoveryConfig);
    otherwise
        error('run_cs_recovery:UnsupportedMethod', ...
            '不支持的 recovery.method: %s', result.method);
end

result.status = 'completed';
result.reason = '';
result.echo = recoveryResult.echo;
result.recoveryInfo = recoveryResult.info;
result.metrics = recoveryResult.metrics;
result.sourceData = sourceData;
result.sourceData.echo = recoveryResult.echo;
result.sourceData.mask = true(1, size(recoveryResult.echo, 2));
result.sourceData.meta.recovery = struct( ...
    'method', result.method, ...
    'status', result.status, ...
    'iterations', recoveryResult.info.iterations, ...
    'runtimeSec', recoveryResult.info.runtimeSec);
end
