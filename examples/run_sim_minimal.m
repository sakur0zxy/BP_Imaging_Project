%RUN_SIM_MINIMAL 仿真最小示例。

cfg = load_sim_config();
cfg.output.enableSave = false;
cfg.analysis.enablePointAnalysis = false;
cfg.degradation.enable = false;
cfg.degradation.mode = 'none';
cfg.scene.inheritRealTrack = false;
cfg.radar.inheritRealRadar = false;
cfg.scene.targetPositions = [0, 0, 0; 10, 6, 0];
cfg.scene.targetAmplitudes = [1; 0.7];
cfg.scene.targetPhasesDeg = [0; 30];
cfg.scene.numAzimuthSamples = 96;
cfg.scene.numRangeSamples = 192;
cfg.scene.trackXLimits = [-50, 50];
cfg.scene.trackYValue = -120;
cfg.scene.trackZValue = 80;
cfg.radar.bandwidthHz = 2e8;
result = main_sim_data(cfg); %#ok<NASGU>
