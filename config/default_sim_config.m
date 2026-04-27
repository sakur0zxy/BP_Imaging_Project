function config = default_sim_config()
%DEFAULT_SIM_CONFIG 仿真流程默认配置。
% 单位约定：距离 [m]，时间 [s]，频率 [Hz]，圆频率 [rad/s]，角度 [deg]

config = struct();

%% 1. 流程与路径
config.project.mode = 'sim';                   % 流程模式

config.path.projectRoot = '';                  % 项目根目录；由 startup / load_* 补齐
config.path.simDataRoot = '';                  % 仿真输入数据根目录；为空时自动搜索候选目录
config.path.simDataCandidates = {'data/sim_data'}; % 仿真输入候选目录
config.path.cacheRoot = 'cache';               % 相对 projectRoot 的缓存根目录

%% 2. 缓存
config.cache.enableFullImageCache = true;      % [bool] 是否缓存完整参考图
config.cache.fullImageNamespace = 'baseline';  % 完整参考图缓存命名空间

%% 3. 场景与目标
config.scene.referencePoint = [0, 0, 0];       % [m] (1x3) 参考点 [x, y, z]
config.scene.targetPositions = [0, 0, 0];      % [m] (Nx3) 目标坐标
config.scene.targetAmplitudes = 1;             % [linear] (Nx1) 目标幅度
config.scene.targetPhasesDeg = 0;              % [deg] (Nx1) 目标初始相位

% 若为 true，仿真直接继承实测轨迹。
% 此时下面的 scene.trackXLimits 和 scene.track.* 只作为默认占位，不参与实际轨迹生成。
config.scene.inheritRealTrack = true;          % [bool] 是否继承实测轨迹

config.scene.numAzimuthSamples = 1055;         % [count] 方位向采样点数
config.scene.numRangeSamples = 424;            % [count] 距离向采样点数

% 旧字段兼容区：
% build_platform_track 会优先读取 scene.track，再用这些旧字段覆盖其中的
% numSamples / xLimits / yValue / zValue，保证旧脚本仍可运行。
config.scene.trackXLimits = [7000.98388672, 7089.26464844]; % [m] 旧字段：线性轨迹 x 起止
config.scene.trackYValue = 555.469604492;                  % [m] 旧字段：线性轨迹 y 常值
config.scene.trackZValue = 7275.87744141;                  % [m] 旧字段：平台高度

% 轨迹模式仅支持：'linear' | 'arc' | 'sinusoidal'
config.scene.track = struct( ...
    'mode', 'linear', ...                       % 轨迹模式
    'numSamples', 1055, ...                     % [count] 轨迹点数
    ...
    'xLimits', [7000.98388672, 7089.26464844], ... % [m] linear / sinusoidal 使用
    'yValue', 555.469604492, ...                % [m] linear 使用
    'zValue', 7275.87744141, ...                % [m] linear / arc / sinusoidal 使用
    ...
    'centerXY', [7045.12426758, 555.469604492], ... % [m] arc 使用，圆心 [x, y]
    'radius', 44.14038086, ...                  % [m] arc 使用，半径
    'angleLimitsDeg', [180, 0], ...             % [deg] arc 使用，起止角
    ...
    'yCenter', 555.469604492, ...               % [m] sinusoidal 使用，摆动中心线
    'yAmplitude', 30, ...                       % [m] sinusoidal 使用，摆动幅度
    'yCycles', 1.5);                            % [cycle] sinusoidal 使用，周期数

%% 4. 雷达参数
% 若为 true，仿真直接继承实测雷达参数。
% 此时下面的中心频率、带宽、脉宽等手动设置不参与实际回波生成。
config.radar.inheritRealRadar = true;          % [bool] 是否继承实测雷达参数

config.radar.c = 3e8;                          % [m/s] 光速
config.radar.centerOmega = 2 * pi * 9599261696; % [rad/s] 中心圆频率
config.radar.pulseWidth = 1e-5;                % [s] 脉冲宽度
config.radar.bandwidthHz = 622360576;          % [Hz] 发射带宽
config.radar.rangeUpsampleFactor = 8;          % [ratio] 距离向升采样倍数

%% 5. BP 成像参数
config.imaging.grid.numPixels = 512;           % [pixel] 输出图像边长
config.imaging.grid.xLimits = [-50, 50];       % [m] 成像网格 x 范围
config.imaging.grid.yLimits = [-50, 50];       % [m] 成像网格 y 范围
config.imaging.iterationLength = 468;          % [count] BP 单次处理脉冲数
config.imaging.useSinglePrecision = true;      % [bool] 是否使用单精度
config.imaging.showProgress = false;           % [bool] 是否打印 BP 进度
config.imaging.progressStep = 20;              % [%] 进度打印步长
config.imaging.progressScale = 6;              % 保留参数
config.imaging.outputScale = 7;                % 保留参数

%% 6. 缺失控制
% mode 仅支持：'none' | 'fixed_gap' | 'random_gap'
config.degradation.enable = true;              % [bool] 是否启用缺失控制
config.degradation.mode = 'fixed_gap';         % 缺失模式
config.degradation.missingRatio = 0.3;         % [ratio] 目标缺失比例
config.degradation.numSegments = 5;            % [count] 缺失分段数
config.degradation.gapMinMeters = 0;           % [m] 随机缺失最小物理长度
config.degradation.gapMaxMeters = 150;         % [m] 随机缺失最大物理长度
config.degradation.fixedGapRanges = [];        % [index] 固定缺失区间
config.degradation.randomSeed = [];            % [int] 随机种子

%% 7. 恢复
% recovery.method 正式支持：'cs_1d' | 'cs_2d'
config.recovery.enable = true;                % [bool] 是否启用恢复
config.recovery.method = 'cs_1d';              % 恢复方法名
config.recovery.common = struct( ...
    'maxIter', 80, ...                         % [count] 最大迭代次数
    'tol', 1e-4, ...                           % 收敛阈值
    'useFista', true, ...                      % [bool] true=FISTA, false=ISTA
    'normalizeInput', true, ...                % [bool] 恢复前是否归一化输入
    'verbose', false, ...                      % [bool] 是否打印恢复日志
    'skipWhenNoMissing', true);                % [bool] 无缺失时是否自动跳过

config.recovery.methods = struct();
config.recovery.methods.cs_1d = struct( ...
    'lambda', 0.02);                           % cs_1d 稀疏正则系数
config.recovery.methods.cs_2d = struct( ...
    'lambda', 0.01);                           % cs_2d 稀疏正则系数

%% 8. 分析
config.analysis.enablePointAnalysis = true;   % [bool] 是否执行点目标分析
config.analysis.enableImageQuality = true;    % [bool] 是否执行图像质量评估

config.analysis.pointTarget = struct( ...
    'cutoutHeight', 32, ...                    % [pixel] 点目标分析窗高
    'cutoutWidth', 32, ...                     % [pixel] 点目标分析窗宽
    'upsampleFactor', 16, ...                  % [ratio] 分析前局部升采样倍数
    'enableTiltCorrection', true, ...          % [bool] 是否做主瓣倾斜校正
    'tiltThresholdDeg', 0.0, ...               % [deg] 触发倾斜校正的阈值
    'tiltEdgeFraction', 0.2);                  % [ratio] 倾角估计使用的边缘比例
config.analysis.imageQuality = struct( ...
    'compareMode', 'amplitude');               % 'amplitude' | 'complex'

config.analysis.recoveryEvaluation = struct( ...
    'enable', false, ...                      % [bool] 默认关闭恢复效果评估；需要评估时再手动开启
    'evaluationMode', 'auto', ...              % 'auto' 默认跟随 real/sim 流程；也可手动写 'real' | 'simulation'
    'caseNames', {{'full', 'interrupted', 'recovered_cs_1d', 'recovered_cs_2d'}}, ...
    'referenceCase', 'full', ...               % 对比参考 case
    'outputs', struct( ...
        'enable', true, ...                    % [bool] 评估输出总开关；false 时不保存/显示任何评估输出
        'saveMat', false, ...                  % [bool] 是否保存结构化评估结果
        'saveSummary', false, ...              % [bool] 是否保存简短 summary 文本
        'savePanel', false, ...                % [bool] 是否保存总览对比图文件
        'showPanel', true, ...                 % [bool] 是否直接显示总览对比图
        'savePointTargetPanel', false, ...     % [bool] 是否保存点目标细节对比图
        'showPointTargetPanel', true), ...     % [bool] 是否直接显示点目标细节对比图
    'metricOptions', struct( ...
        'enablePointAnalysis', true, ...      % [bool] 评估内部是否强制做点目标分析
        'enableImageQuality', true, ...        % [bool] 评估内部是否强制做图像质量评估
        'compareMode', 'amplitude'), ...       % 图像质量对比模式
    'thresholds', struct( ...
        'warningRelativeL2Error', 0.25));      % 相对误差告警阈值

%% 9. 调试显示
config.debug.showImageFigure = true;           % [bool] 是否弹出主成像图
config.debug.showPointTargetFigures = true;   % [bool] 是否弹出点目标分析图

%% 10. 输出
config.output.enableSave = false;              % [bool] 是否保存结果
config.output.runRoot = fullfile('results', 'sim_runs'); % 结果根目录
config.output.saveImagePng = false;            % [bool] 是否保存可视化 PNG
config.output.saveImageMat = true;             % [bool] 是否保存图像矩阵 MAT
config.output.saveSummaryMat = true;           % [bool] 是否保存 summary.mat
config.output.saveAnalysisMat = true;          % [bool] 是否保存 analysis.mat
config.output.imageScaleMode = 'log';          % 'log' | 'linear'
config.output.imageDynamicRangeDb = 40;        % [dB] 图像显示动态范围

%% 11. 运行时
config.runtime.preferGpu = false;              % [bool] 是否优先使用 GPU
config.runtime.useParallel = false;            % [bool] 是否启用并行池
config.runtime.maxWorkers = [];                % [count] 最大 worker 数
end
