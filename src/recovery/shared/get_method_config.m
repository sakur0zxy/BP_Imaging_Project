function methodConfig = get_method_config(recoveryConfig, methodName)
%GET_METHOD_CONFIG 读取当前方法对应的参数块。
methodName = lower(char(string(methodName)));
assert(isfield(recoveryConfig, 'methods') && isstruct(recoveryConfig.methods), ...
    'recovery.methods 缺失或类型错误。');
assert(isfield(recoveryConfig.methods, methodName), ...
    'recovery.methods.%s 缺失。', methodName);

methodConfig = recoveryConfig.methods.(methodName);
assert(isstruct(methodConfig) && isscalar(methodConfig), ...
    'recovery.methods.%s 必须是标量结构体。', methodName);
end
