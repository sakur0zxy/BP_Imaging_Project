function config = local_env_config()
%LOCAL_ENV_CONFIG 本机私有配置模板。
% 这里只放“机器相关”的内容，不放项目公共默认值。

config = struct();

%% 数据路径
config.path.realDataRoot = ''; % 实测数据根目录，例如 gotcha_BP 所在目录
config.path.simDataRoot = ''; % 仿真输入数据目录

%% 本机运行时偏好
config.runtime.preferGpu = false; % 本机是否优先尝试 GPU
config.runtime.useParallel = false; % 本机是否默认开并行池
config.runtime.maxWorkers = []; % 本机并行 worker 数；空表示自动决定
end

