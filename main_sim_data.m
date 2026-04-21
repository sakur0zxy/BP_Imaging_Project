function result = main_sim_data(userConfig)
%MAIN_SIM_DATA 仿真数据主入口。

if nargin < 1
    userConfig = struct();
end

startup();
config = load_sim_config(userConfig);
result = run_sim_data_pipeline(config);
end

