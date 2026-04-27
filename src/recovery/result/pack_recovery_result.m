function result = pack_recovery_result(status, reason, methodName, sourceData, problem, echoData, recoveryInfo, metrics)
%PACK_RECOVERY_RESULT 统一封装 recoveryResult 输出结构。
if nargin < 8 || isempty(metrics)
    metrics = struct();
end
if nargin < 7 || isempty(recoveryInfo)
    recoveryInfo = struct();
end

result = struct();
result.status = status;
result.reason = reason;
result.method = methodName;
result.problem = problem;
result.echo = echoData;
result.recoveryInfo = recoveryInfo;
result.metrics = metrics;
result.sourceData = sourceData;

if strcmp(status, 'completed')
    result.sourceData.echo = echoData;
    result.sourceData.mask = true(1, size(echoData, 2));
    result.sourceData.meta.recovery = struct( ...
        'method', methodName, ...
        'status', status, ...
        'iterations', localGetInfoField(recoveryInfo, 'iterations', 0), ...
        'runtimeSec', localGetInfoField(recoveryInfo, 'runtimeSec', 0));
end
end

function value = localGetInfoField(info, fieldName, defaultValue)
value = defaultValue;
if isstruct(info) && isfield(info, fieldName)
    value = info.(fieldName);
end
end
