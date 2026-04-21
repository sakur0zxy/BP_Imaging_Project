function config = default_sim_config()
%DEFAULT_SIM_CONFIG 仿真流程默认配置。
% 单位约定：
% 距离 [m]，时间 [s]，频率 [Hz]，圆频率 [rad/s]，角度 [deg]

config = struct();

%% 1. 流程与路径
config.project.mode = 'sim';                    % 流程模式

config.path.projectRoot = '';                   % 项目根目录；由 startup / load_* 补齐
config.path.simDataRoot = '';                   % 仿真输入数据根目录；留空时自动搜索候选目录
config.path.simDataCandidates = {'data/sim_data'}; % 仿真输入候选目录
config.path.cacheRoot = 'cache';                % 缓存根目录，相对 projectRoot

%% 2. 缓存
config.cache.enableFullImageCache = true;       % [bool] 是否缓存完整参考图
config.cache.fullImageNamespace = 'baseline';   % 缓存目录名中的中间标签

%% 3. 场景与目标
config.scene.referencePoint = [0, 0, 0];        % [m] (1x3) 参考点 [x, y, z]
config.scene.targetPositions = [0, 0, 0];       % [m] (Nx3) 目标坐标
config.scene.targetAmplitudes = 1;              % [linear] (Nx1) 目标幅度
config.scene.targetPhasesDeg = 0;               % [deg] (Nx1) 目标初始相位

% 若为 true，仿真直接继承实测轨迹。
% 这时下面的 scene.track* 和 scene.track.* 手动参数只作为默认占位，不参与实际轨迹生成。
config.scene.inheritRealTrack = true;           % [bool] 是否继承实测轨迹

config.scene.numAzimuthSamples = 1055;          % [count] 方位向采样点数
config.scene.numRangeSamples = 424;             % [count] 距离向采样点数

% 旧字段兼容区：
% build_platform_track 会优先读取 scene.track，再用这些旧字段覆盖其中的
% numSamples / xLimits / yValue / zValue，保证旧脚本仍可运行。
config.scene.trackXLimits = [7000.98388672, 7089.26464844]; % [m] 旧字段：线性轨迹 x 起止
config.scene.trackYValue = 555.469604492;                  % [m] 旧字段：线性轨迹 y 常值
config.scene.trackZValue = 7275.87744141;                  % [m] 旧字段：平台高度

% 轨迹模式仅支持：'linear' | 'arc' | 'sinusoidal'
config.scene.track = struct( ...
    'mode', 'linear', ...                      % 轨迹模式
    'numSamples', 1055, ...                    % [count] 轨迹点数
    ...
    'xLimits', [7000.98388672, 7089.26464844], ... % [m] linear / sinusoidal 使用
    'yValue', 555.469604492, ...                   % [m] linear 使用
    'zValue', 7275.87744141, ...                   % [m] linear / arc / sinusoidal 使用
    ...
    'centerXY', [7045.12426758, 555.469604492], ... % [m] arc 使用，圆心 [x, y]
    'radius', 44.14038086, ...                      % [m] arc 使用，半径
    'angleLimitsDeg', [180, 0], ...                 % [deg] arc 使用，起止角
    ...
    'yCenter', 555.469604492, ...                % [m] sinusoidal 使用，摆动中心线
    'yAmplitude', 30, ...                        % [m] sinusoidal 使用，摆动幅度
    'yCycles', 1.5);                             % [cycle] sinusoidal 使用，摆动周期数

%% 4. 雷达参数
% 若为 true，仿真直接继承实测雷达参数。
% 这时下面的 centerOmega / bandwidthHz / pulseWidth 等手动设置不会参与实际回波生成。
config.radar.inheritRealRadar = true;           % [bool] 是否继承实测雷达参数

config.radar.c = 3e8;                           % [m/s] 光速
config.radar.centerOmega = 2 * pi * 9599261696; % [rad/s] 中心圆频率
config.radar.pulseWidth = 1e-5;                 % [s] 脉冲宽度
config.radar.bandwidthHz = 622360576;           % [Hz] 发射带宽
config.radar.rangeUpsampleFactor = 8;           % [ratio] 距离向升采样倍数

%% 5. BP 成像参数
config.imaging.grid.numPixels = 512;            % [pixel] 成像网格边长，最终图像为 numPixels x numPixels
config.imaging.grid.xLimits = [-50, 50];        % [m] 成像网格 x 范围
config.imaging.grid.yLimits = [-50, 50];        % [m] 成像网格 y 范围
config.imaging.iterationLength = 468;           % [count] BP 单次处理脉冲数
config.imaging.useSinglePrecision = true;       % [bool] 是否使用单精度
config.imaging.showProgress = false;            % [bool] 是否打印 BP 进度
config.imaging.progressStep = 20;               % [%] 进度打印步长
config.imaging.progressScale = 6;               % 保留参数；当前用于进度显示缩放
config.imaging.outputScale = 7;                 % 保留参数；当前传入成像流程

%% 6. 缺失控制
% mode 仅支持：'none' | 'fixed_gap' | 'random_gap'
config.degradation.enable = true;               % [bool] 是否启用缺失控制
config.degradation.mode = 'fixed_gap';          % 缺失模式
config.degradation.missingRatio = 0.3;          % [ratio] 缺失比例，0.3 表示缺失 30%
config.degradation.numSegments = 5;             % [count] 固定/随机缺失时的分段数
config.degradation.gapMinMeters = 0;            % [m] 随机缺失最小物理长度
config.degradation.gapMaxMeters = 150;          % [m] 随机缺失最大物理长度
config.degradation.fixedGapRanges = [];         % [index] 固定缺失区间；为空时按其他参数自动生成
config.degradation.randomSeed = [];             % [int] 随机种子；留空时每次重新采样

%% 7. 压缩感知恢复
config.recovery.enable = false;                 % [bool] 是否启用恢复
config.recovery.method = '1d';                  % 恢复模式：'1d' | '2d'
config.recovery.lambda1D = 0.02;                % 1D 正则化系数
config.recovery.lambda2D = 0.01;                % 2D 正则化系数
config.recovery.maxIter = 80;                   % [count] 最大迭代次数
config.recovery.tol = 1e-4;                     % 收敛阈值
config.recovery.useFista = true;                % [bool] 是否启用 FISTA
config.recovery.normalizeInput = true;          % [bool] 是否对输入归一化
config.recovery.verbose = false;                % [bool] 是否打印迭代信息
config.recovery.skipWhenNoMissing = true;       % [bool] 无缺失时是否自动跳过恢复

%% 8. 分析与调试显示
config.analysis.enablePointAnalysis = false;    % [bool] 是否计算点目标分析指标
config.analysis.enableImageQuality = false;     % [bool] 是否计算图像质量指标

config.analysis.pointTarget = struct( ...
    'cutoutHeight', 32, ...                     % [pixel] 点目标分析窗口高度
    'cutoutWidth', 32, ...                      % [pixel] 点目标分析窗口宽度
    'upsampleFactor', 16, ...                   % [ratio] 分析前局部升采样倍数
    'enableTiltCorrection', true, ...           % [bool] 是否做主瓣倾斜校正
    'tiltThresholdDeg', 0.0, ...                % [deg] 倾斜校正触发阈值
    'tiltEdgeFraction', 0.2);                   % [ratio] 倾斜估计时使用的边缘比例

config.analysis.imageQuality = struct( ...
    'compareMode', 'amplitude');                % 对比模式：'amplitude' | 'complex'

config.debug.showImageFigure = false;           % [bool] 是否弹出主成像图
config.debug.showPointTargetFigures = false;    % [bool] 是否弹出点目标分析图

%% 9. 输出
config.output.enableSave = true;                % [bool] 是否保存结果
config.output.runRoot = fullfile('results', 'sim_runs'); % 输出根目录
config.output.saveImagePng = true;              % [bool] 是否保存可视化 PNG
config.output.saveImageMat = true;              % [bool] 是否保存图像矩阵 MAT
config.output.saveSummaryMat = true;            % [bool] 是否保存 summary.mat
config.output.saveAnalysisMat = true;           % [bool] 是否保存 analysis.mat
config.output.imageScaleMode = 'log';           % 图像显示模式：'log' | 'linear'
config.output.imageDynamicRangeDb = 40;         % [dB] 图像显示动态范围

%% 10. 运行时
config.runtime.preferGpu = false;               % [bool] 是否优先使用 GPU
config.runtime.useParallel = false;             % [bool] 是否启用并行池
config.runtime.maxWorkers = [];                 % [count] 最大并行 worker 数；留空时自动决定
end
