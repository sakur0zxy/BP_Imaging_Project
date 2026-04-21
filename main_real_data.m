function result = main_real_data(userConfig)
%MAIN_REAL_DATA 实测数据主入口。

if nargin < 1
    userConfig = struct();
end

startup();
config = load_real_config(userConfig);
result = run_real_data_pipeline(config);
end

