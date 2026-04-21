function config = default_real_config()
%DEFAULT_REAL_CONFIG 实测流程默认配置。
% 单位约定：
% 距离 [m]，时间 [s]，频率 [Hz]，圆频率 [rad/s]，角度 [deg]

config = struct();

%% 1. 流程与路径
config.project.mode = 'real';                  % 流程模式

config.path.projectRoot = '';                  % 项目根目录；由 startup / load_* 补齐
config.path.realDataRoot = '';                 % 实测数据根目录；留空时自动搜索候选目录
config.path.realDataCandidates = {'data/real_data'}; % 实测数据候选目录
config.path.cacheRoot = 'cache';               % 缓存根目录，相对 projectRoot

%% 2. 缓存
config.cache.enableFullImageCache = true;      % [bool] 是否缓存完整参考图
config.cache.fullImageNamespace = 'baseline';  % 缓存目录名中的中间标签

%% 3. 实测数据读取
config.source.numFiles = 9;                    % [count] 读取的方位块文件数
config.source.filePattern = 'data_3dsar_pass1_az%03d_VV.mat'; % 文件名模板
config.source.variableName = 'data';           % MAT 文件顶层变量名
config.source.fieldMap = struct( ...
    'x', 'x', ...                              % [m] 平台 x 坐标字段
    'y', 'y', ...                              % [m] 平台 y 坐标字段
    'z', 'z', ...                              % [m] 平台 z 坐标字段
    'echo', 'fp', ...                          % 复回波矩阵字段
    'freq', 'freq');                           % [Hz] 频率向量字段

%% 4. 雷达参数
% 实测流程中，频率向量来自数据文件本身；下面这些参数主要用于推导内部雷达量。
config.radar.c = 3e8;                          % [m/s] 光速
config.radar.centerOmega = 2 * pi * 9.6e9;    % [rad/s] 中心圆频率
config.radar.pulseWidth = 1e-5;                % [s] 脉冲宽度
config.radar.rangeUpsampleFactor = 8;          % [ratio] 距离向升采样倍数

%% 5. BP 成像参数
config.imaging.grid.numPixels = 512;           % [pixel] 成像网格边长，最终图像为 numPixels x numPixels
config.imaging.grid.xLimits = [-50, 50];       % [m] 成像网格 x 范围
config.imaging.grid.yLimits = [-50, 50];       % [m] 成像网格 y 范围
config.imaging.iterationLength = 468;          % [count] BP 单次处理脉冲数
config.imaging.useSinglePrecision = true;      % [bool] 是否使用单精度
config.imaging.showProgress = false;           % [bool] 是否打印 BP 进度
config.imaging.progressStep = 20;              % [%] 进度打印步长
config.imaging.progressScale = 6;              % 保留参数；当前用于进度显示缩放
config.imaging.outputScale = 7;                % 保留参数；当前传入成像流程

%% 6. 缺失控制
% mode 仅支持：'none' | 'fixed_gap' | 'random_gap'
config.degradation.enable = true;              % [bool] 是否启用缺失控制
config.degradation.mode = 'none';              % 缺失模式；实测默认不做缺失
config.degradation.missingRatio = 0.5;         % [ratio] 缺失比例，0.5 表示缺失 50%
config.degradation.numSegments = 5;            % [count] 固定/随机缺失时的分段数
config.degradation.gapMinMeters = 0;           % [m] 随机缺失最小物理长度
config.degradation.gapMaxMeters = 100;         % [m] 随机缺失最大物理长度
config.degradation.fixedGapRanges = [];        % [index] 固定缺失区间；为空时按其他参数自动生成
config.degradation.randomSeed = [];            % [int] 随机种子；留空时每次重新采样

%% 7. 压缩感知恢复
config.recovery.enable = false;                % [bool] 是否启用恢复
config.recovery.method = '1d';                 % 恢复模式：'1d' | '2d'
config.recovery.lambda1D = 0.02;               % 1D 正则化系数
config.recovery.lambda2D = 0.01;               % 2D 正则化系数
config.recovery.maxIter = 80;                  % [count] 最大迭代次数
config.recovery.tol = 1e-4;                    % 收敛阈值
config.recovery.useFista = true;               % [bool] 是否启用 FISTA
config.recovery.normalizeInput = true;         % [bool] 是否对输入归一化
config.recovery.verbose = false;               % [bool] 是否打印迭代信息
config.recovery.skipWhenNoMissing = true;      % [bool] 无缺失时是否自动跳过恢复

%% 8. 分析与调试显示
config.analysis.enablePointAnalysis = false;   % [bool] 是否计算点目标分析指标
config.analysis.enableImageQuality = false;    % [bool] 是否计算图像质量指标

config.analysis.pointTarget = struct( ...
    'cutoutHeight', 32, ...                    % [pixel] 点目标分析窗口高度
    'cutoutWidth', 32, ...                     % [pixel] 点目标分析窗口宽度
    'upsampleFactor', 16, ...                  % [ratio] 分析前局部升采样倍数
    'enableTiltCorrection', true, ...          % [bool] 是否做主瓣倾斜校正
    'tiltThresholdDeg', 0.0, ...               % [deg] 倾斜校正触发阈值
    'tiltEdgeFraction', 0.2);                  % [ratio] 倾斜估计时使用的边缘比例

config.analysis.imageQuality = struct( ...
    'compareMode', 'amplitude');               % 对比模式：'amplitude' | 'complex'

config.debug.showImageFigure = false;          % [bool] 是否弹出主成像图
config.debug.showPointTargetFigures = false;   % [bool] 是否弹出点目标分析图

%% 9. 输出
config.output.enableSave = true;               % [bool] 是否保存结果
config.output.runRoot = fullfile('results', 'real_runs'); % 输出根目录
config.output.saveImagePng = true;             % [bool] 是否保存可视化 PNG
config.output.saveImageMat = true;             % [bool] 是否保存图像矩阵 MAT
config.output.saveSummaryMat = true;           % [bool] 是否保存 summary.mat
config.output.saveAnalysisMat = true;          % [bool] 是否保存 analysis.mat
config.output.imageScaleMode = 'linear';       % 图像显示模式：'log' | 'linear'
config.output.imageDynamicRangeDb = 40;        % [dB] 图像显示动态范围

%% 10. 运行时
config.runtime.preferGpu = false;              % [bool] 是否优先使用 GPU
config.runtime.useParallel = false;            % [bool] 是否启用并行池
config.runtime.maxWorkers = [];                % [count] 最大并行 worker 数；留空时自动决定
end
