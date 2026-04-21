function config = load_real_config(userOverrides)
%LOAD_REAL_CONFIG 加载实测配置。
% 合并顺序：默认值 -> 本机私有配置 -> 调用时覆盖值。

if nargin < 1
    userOverrides = struct();
end

config = default_real_config();
config.path.projectRoot = localProjectRoot(); % 让后续模块都能拿到项目根目录
config = merge_structs(config, localLoadEnvConfig()); % 本机路径、硬件偏好放这里
config = merge_structs(config, userOverrides); % 单次实验临时覆盖
config = normalize_legacy_config_aliases(config, 'real'); % 兼容旧项目字段名
config = validate_real_config(config); % 最后统一校验
end

function envConfig = localLoadEnvConfig()
envConfig = struct();
localConfigFile = fullfile(fileparts(mfilename('fullpath')), 'local', 'local_env_config.m');
if exist(localConfigFile, 'file') == 2
    localDir = fileparts(localConfigFile);
    addpath(localDir);
    cleanup = onCleanup(@() rmpath(localDir)); %#ok<NASGU>
    envConfig = local_env_config();
end
end

function projectRoot = localProjectRoot()
projectRoot = fileparts(fileparts(mfilename('fullpath')));
end

