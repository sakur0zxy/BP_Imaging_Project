%RUN_REAL_MINIMAL 实测最小示例。
% 先在 config/local/local_env_config.m 里填 realDataRoot。

cfg = load_real_config();
cfg.output.enableSave = false;
cfg.analysis.enablePointAnalysis = false;
result = main_real_data(cfg); %#ok<NASGU>

