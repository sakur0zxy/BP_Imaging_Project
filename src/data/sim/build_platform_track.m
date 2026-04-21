function track = build_platform_track(sceneConfig)
%BUILD_PLATFORM_TRACK 根据配置生成平台轨迹。
% 输出始终是三个等长行向量：track.x / track.y / track.z。

trackConfig = localResolveTrackConfig(sceneConfig);
localValidateCommon(trackConfig);

switch lower(string(trackConfig.mode))
    case "linear"
        track = localBuildLinearTrack(trackConfig);
    case "arc"
        track = localBuildArcTrack(trackConfig);
    case "sinusoidal"
        track = localBuildSinusoidalTrack(trackConfig);
    otherwise
        error('build_platform_track:UnsupportedMode', ...
            ['不支持的轨迹模式：%s。' newline ...
             '支持的模式有：linear、arc、sinusoidal。'], ...
            char(string(trackConfig.mode)));
end

track = localValidateOutput(track, trackConfig);
end

function trackConfig = localResolveTrackConfig(sceneConfig)
if isfield(sceneConfig, 'track') && isstruct(sceneConfig.track) && ~isempty(sceneConfig.track)
    trackConfig = sceneConfig.track;
else
    trackConfig = struct();
    trackConfig.mode = 'linear';
end

if isfield(sceneConfig, 'numAzimuthSamples') && ~isempty(sceneConfig.numAzimuthSamples)
    trackConfig.numSamples = sceneConfig.numAzimuthSamples;
end

if isfield(sceneConfig, 'trackXLimits') && ~isempty(sceneConfig.trackXLimits)
    trackConfig.xLimits = sceneConfig.trackXLimits;
end

if isfield(sceneConfig, 'trackYValue') && ~isempty(sceneConfig.trackYValue)
    trackConfig.yValue = sceneConfig.trackYValue;
end

if isfield(sceneConfig, 'trackZValue') && ~isempty(sceneConfig.trackZValue)
    trackConfig.zValue = sceneConfig.trackZValue;
end
end

function localValidateCommon(trackConfig)
assert(isfield(trackConfig, 'numSamples') && isnumeric(trackConfig.numSamples) ...
    && isscalar(trackConfig.numSamples) && isfinite(trackConfig.numSamples) ...
    && trackConfig.numSamples >= 8 && mod(trackConfig.numSamples, 1) == 0, ...
    ['轨迹参数错误：numSamples 必须是不小于 8 的整数。' newline ...
     '建议检查 scene.track.numSamples 或 scene.numAzimuthSamples。']);

assert(isfield(trackConfig, 'mode') && ~isempty(trackConfig.mode), ...
    '轨迹参数错误：缺少 scene.track.mode。');
end

function track = localBuildLinearTrack(trackConfig)
localRequireField(trackConfig, 'xLimits', ...
    'linear 模式需要 scene.track.xLimits = [xStart, xEnd]。');
localRequireField(trackConfig, 'yValue', ...
    'linear 模式需要 scene.track.yValue。');
localRequireField(trackConfig, 'zValue', ...
    'linear 模式需要 scene.track.zValue。');

assert(numel(trackConfig.xLimits) == 2 && all(isfinite(trackConfig.xLimits)), ...
    ['轨迹参数错误：linear 模式下 xLimits 必须是两个有限数。' newline ...
     '例如：scene.track.xLimits = [7000, 7090]。']);

if trackConfig.xLimits(1) == trackConfig.xLimits(2)
    error('build_platform_track:LinearZeroSpan', ...
        ['轨迹参数错误：linear 模式下 xLimits 的起点和终点不能相同。' newline ...
         '否则平台没有沿轨迹运动。']);
end

track = struct();
track.x = linspace(trackConfig.xLimits(1), trackConfig.xLimits(2), trackConfig.numSamples);
track.y = trackConfig.yValue * ones(1, trackConfig.numSamples);
track.z = trackConfig.zValue * ones(1, trackConfig.numSamples);
end

function track = localBuildArcTrack(trackConfig)
localRequireField(trackConfig, 'centerXY', ...
    'arc 模式需要 scene.track.centerXY = [xCenter, yCenter]。');
localRequireField(trackConfig, 'radius', ...
    'arc 模式需要 scene.track.radius。');
localRequireField(trackConfig, 'angleLimitsDeg', ...
    'arc 模式需要 scene.track.angleLimitsDeg = [startDeg, endDeg]。');
localRequireField(trackConfig, 'zValue', ...
    'arc 模式需要 scene.track.zValue。');

assert(numel(trackConfig.centerXY) == 2 && all(isfinite(trackConfig.centerXY)), ...
    ['轨迹参数错误：arc 模式下 centerXY 必须是两个有限数。' newline ...
     '例如：scene.track.centerXY = [7050, 550]。']);
assert(isnumeric(trackConfig.radius) && isscalar(trackConfig.radius) ...
    && isfinite(trackConfig.radius) && trackConfig.radius > 0, ...
    ['轨迹参数错误：arc 模式下 radius 必须大于 0。' newline ...
     '例如：scene.track.radius = 80。']);
assert(numel(trackConfig.angleLimitsDeg) == 2 && all(isfinite(trackConfig.angleLimitsDeg)), ...
    ['轨迹参数错误：arc 模式下 angleLimitsDeg 必须是两个有限角度。' newline ...
     '例如：scene.track.angleLimitsDeg = [-20, 20]。']);

if trackConfig.angleLimitsDeg(1) == trackConfig.angleLimitsDeg(2)
    error('build_platform_track:ArcZeroAngleSpan', ...
        ['轨迹参数错误：arc 模式下 angleLimitsDeg 的起点和终点不能相同。' newline ...
         '否则平台没有沿圆弧运动。']);
end

anglesRad = deg2rad(linspace(trackConfig.angleLimitsDeg(1), ...
    trackConfig.angleLimitsDeg(2), trackConfig.numSamples));

track = struct();
track.x = trackConfig.centerXY(1) + trackConfig.radius * cos(anglesRad);
track.y = trackConfig.centerXY(2) + trackConfig.radius * sin(anglesRad);
track.z = trackConfig.zValue * ones(1, trackConfig.numSamples);
end

function track = localBuildSinusoidalTrack(trackConfig)
localRequireField(trackConfig, 'xLimits', ...
    'sinusoidal 模式需要 scene.track.xLimits = [xStart, xEnd]。');
localRequireField(trackConfig, 'yCenter', ...
    'sinusoidal 模式需要 scene.track.yCenter。');
localRequireField(trackConfig, 'yAmplitude', ...
    'sinusoidal 模式需要 scene.track.yAmplitude。');
localRequireField(trackConfig, 'yCycles', ...
    'sinusoidal 模式需要 scene.track.yCycles。');
localRequireField(trackConfig, 'zValue', ...
    'sinusoidal 模式需要 scene.track.zValue。');

assert(numel(trackConfig.xLimits) == 2 && all(isfinite(trackConfig.xLimits)), ...
    ['轨迹参数错误：sinusoidal 模式下 xLimits 必须是两个有限数。' newline ...
     '例如：scene.track.xLimits = [7000, 7090]。']);
assert(isnumeric(trackConfig.yAmplitude) && isscalar(trackConfig.yAmplitude) ...
    && isfinite(trackConfig.yAmplitude) && trackConfig.yAmplitude >= 0, ...
    ['轨迹参数错误：sinusoidal 模式下 yAmplitude 必须是非负数。' newline ...
     '例如：scene.track.yAmplitude = 30。']);
assert(isnumeric(trackConfig.yCycles) && isscalar(trackConfig.yCycles) ...
    && isfinite(trackConfig.yCycles) && trackConfig.yCycles > 0, ...
    ['轨迹参数错误：sinusoidal 模式下 yCycles 必须大于 0。' newline ...
     '例如：scene.track.yCycles = 2。']);

if trackConfig.xLimits(1) == trackConfig.xLimits(2)
    error('build_platform_track:SinusoidalZeroSpan', ...
        ['轨迹参数错误：sinusoidal 模式下 xLimits 的起点和终点不能相同。' newline ...
         '否则正弦轨迹无法展开。']);
end

track = struct();
track.x = linspace(trackConfig.xLimits(1), trackConfig.xLimits(2), trackConfig.numSamples);
phase = linspace(0, 2 * pi * trackConfig.yCycles, trackConfig.numSamples);
track.y = trackConfig.yCenter + trackConfig.yAmplitude * sin(phase);
track.z = trackConfig.zValue * ones(1, trackConfig.numSamples);
end

function track = localValidateOutput(track, trackConfig)
fields = {'x', 'y', 'z'};
for idx = 1:numel(fields)
    name = fields{idx};
    assert(isfield(track, name) && isnumeric(track.(name)) && isvector(track.(name)), ...
        '轨迹生成失败：输出缺少合法的 track.%s。', name);
    track.(name) = track.(name)(:).';
end

numSamples = trackConfig.numSamples;
assert(numel(track.x) == numSamples && numel(track.y) == numSamples && numel(track.z) == numSamples, ...
    ['轨迹生成失败：输出轨迹长度与 numSamples 不一致。' newline ...
     '请检查当前轨迹模式的参数设置。']);

if any(~isfinite(track.x)) || any(~isfinite(track.y)) || any(~isfinite(track.z))
    error('build_platform_track:NonFiniteOutput', ...
        ['轨迹生成失败：输出轨迹里出现了 NaN 或 Inf。' newline ...
         '请检查半径、角度范围、振幅和样本数等参数。']);
end
end

function localRequireField(trackConfig, fieldName, messageText)
if ~isfield(trackConfig, fieldName) || isempty(trackConfig.(fieldName))
    error('build_platform_track:MissingField', '%s', messageText);
end
end
