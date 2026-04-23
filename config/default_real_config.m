function config = default_real_config()
%DEFAULT_REAL_CONFIG 实测流程默认配置。
% 单位约定：距离 [m]，时间 [s]，频率 [Hz]，圆频率 [rad/s]，角度 [deg]

config = struct();

%% 1. 流程与路径
config.project.mode = 'real';                  % 流程模式

config.path.projectRoot = '';                  % 项目根目录；由 startup / load_* 补齐
config.path.realDataRoot = '';                 % 实测数据根目录；为空时自动搜索候选目录
config.path.realDataCandidates = {'data/real_data'}; % 实测数据候选目录
config.path.cacheRoot = 'cache';               % 相对 projectRoot 的缓存根目录

%% 2. 缓存
config.cache.enableFullImageCache = true;      % [bool] 是否缓存完整参考图
config.cache.fullImageNamespace = 'baseline';  % 完整参考图缓存命名空间

%% 3. 实测数据读取
config.source.numFiles = 9;                    % [count] 读取的方位块文件数
config.source.filePattern = 'data_3dsar_pass1_az%03d_VV.mat'; % 文件名模板
config.source.variableName = 'data';           % MAT 文件顶层变量名
config.source.fieldMap = struct( ...
    'x', 'x', ...                              % [m] 平台 x 坐标字段
    'y', 'y', ...                              % [m] 平台 y 坐标字段
    'z', 'z', ...                              % [m] 平台 z 坐标字段
    'echo', 'fp', ...                          % 回波矩阵字段
    'freq', 'freq');                           % [Hz] 频率向量字段

%% 4. 雷达参数
% 实测流程里，频率向量来自原始数据；下面参数主要用于内部推导和统一契约。
config.radar.c = 3e8;                          % [m/s] 光速
config.radar.centerOmega = 2 * pi * 9.6e9;    % [rad/s] 中心圆频率
config.radar.pulseWidth = 1e-5;                % [s] 脉冲宽度
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
config.degradation.enable = false;             % [bool] 实测默认不做缺失控制
config.degradation.mode = 'none';              % 缺失模式；默认保留完整实测回波
config.degradation.missingRatio = 0;           % [ratio] 默认缺失比例
config.degradation.numSegments = 5;            % [count] 缺失分段数
config.degradation.gapMinMeters = 0;           % [m] 随机缺失最小物理长度
config.degradation.gapMaxMeters = 100;         % [m] 随机缺失最大物理长度
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
    'enable', true, ...                       % [bool] 是否启用恢复效果评估
    'evaluationMode', 'auto', ...              % 'auto' 默认跟随 real/sim 流程；也可手动写 'real' | 'simulation'
    'caseNames', {{'full', 'interrupted', 'recovered_cs_1d', 'recovered_cs_2d'}}, ...
    'referenceCase', 'full', ...               % 对比参考 case
    'outputs', struct( ...
        'enable', true, ...                    % [bool] 评估输出总开关；false 时不保存/显示任何评估输出
        'saveMat', false, ...                  % [bool] 是否保存结构化评估结果
        'saveSummary', false, ...              % [bool] 是否保存简短 summary 文本
        'savePanel', false, ...                % [bool] 是否保存总览对比图文件
        'showPanel', true), ...                % [bool] 是否直接显示总览对比图
    'metricOptions', struct( ...
        'enablePointAnalysis', true, ...       % [bool] 评估内部是否强制做点目标分析
        'enableImageQuality', true, ...       % [bool] 评估内部是否强制做图像质量评估
        'compareMode', 'amplitude'), ...       % 图像质量对比模式
    'thresholds', struct( ...
        'warningPeakShiftPixels', 2));         % [pixel] 峰值漂移告警阈值

%% 9. 调试显示
config.debug.showImageFigure = true;           % [bool] 是否弹出主成像图
config.debug.showPointTargetFigures = true;   % [bool] 是否弹出点目标分析图

%% 10. 输出
config.output.enableSave = false;              % [bool] 是否保存结果
config.output.runRoot = fullfile('results', 'real_runs'); % 结果根目录
config.output.saveImagePng = false;            % [bool] 是否保存可视化 PNG
config.output.saveImageMat = true;             % [bool] 是否保存图像矩阵 MAT
config.output.saveSummaryMat = true;           % [bool] 是否保存 summary.mat
config.output.saveAnalysisMat = true;          % [bool] 是否保存 analysis.mat
config.output.imageScaleMode = 'linear';       % 'log' | 'linear'
config.output.imageDynamicRangeDb = 40;        % [dB] 图像显示动态范围

%% 11. 运行时
config.runtime.preferGpu = false;              % [bool] 是否优先使用 GPU
config.runtime.useParallel = true;            % [bool] 是否启用并行池
config.runtime.maxWorkers = [];                % [count] 最大 worker 数
end
