function sourceData = generate_point_target_data(config)
%GENERATE_POINT_TARGET_DATA 生成点目标仿真数据并整理成统一内部结构。

config = validate_sim_config(config);
[inheritData, inheritInfo] = localLoadRealDefaults(config);

if config.scene.inheritRealTrack && inheritInfo.available
    track = inheritData.track;
else
    track = build_platform_track(config.scene);
end

if config.radar.inheritRealRadar && inheritInfo.available
    radar = inheritData.radar;
else
    radar = localBuildRadar(config.radar, config.scene.numRangeSamples);
end

echoData = localBuildEcho(track, radar, config.scene);

rawData = struct();
rawData.track = track;
rawData.echo = echoData;
rawData.radar = radar;

meta = struct();
meta.kind = 'sim';
meta.provider = 'generate_point_target_data';
meta.scene = config.scene;
meta.inherit = inheritInfo;

sourceData = normalize_source_data(rawData, meta);
end

function [inheritData, inheritInfo] = localLoadRealDefaults(config)
inheritData = struct('track', [], 'radar', []);
inheritInfo = struct('available', false, 'reason', 'disabled');

if ~config.scene.inheritRealTrack && ~config.radar.inheritRealRadar
    return;
end

try
    realConfig = load_real_config(struct( ...
        'degradation', struct('enable', false, 'mode', 'none'), ...
        'analysis', struct('enablePointAnalysis', false), ...
        'output', struct('enableSave', false)));
    realData = load_gotcha_data(realConfig);
    inheritData.track = realData.track;
    inheritData.radar = realData.radar;
    inheritInfo.available = true;
    inheritInfo.reason = 'loaded-real-gotcha';
catch errorInfo
    inheritInfo.available = false;
    inheritInfo.reason = errorInfo.identifier;
end
end

function radar = localBuildRadar(radarConfig, numRangeSamples)
c = radarConfig.c;
centerOmega = radarConfig.centerOmega;
pulseWidth = radarConfig.pulseWidth;
bandwidthHz = radarConfig.bandwidthHz;
rangeUpsampleFactor = radarConfig.rangeUpsampleFactor;

centerFreqHz = centerOmega / (2 * pi);
freqHz = linspace(centerFreqHz - bandwidthHz / 2, centerFreqHz + bandwidthHz / 2, numRangeSamples);
ts = pulseWidth / numRangeSamples;
numRangeSamplesUp = rangeUpsampleFactor * numRangeSamples;
firstFreqHz = freqHz(1);
y0 = (centerOmega - firstFreqHz * 2 * pi) / pulseWidth * 2;
rangeStep = c * pi / (y0 * ts * numRangeSamplesUp);

radar = struct();
radar.c = c;
radar.centerOmega = centerOmega;
radar.pulseWidth = pulseWidth;
radar.bandwidthHz = bandwidthHz;
radar.freqHz = freqHz;
radar.firstFreqHz = firstFreqHz;
radar.ts = ts;
radar.y0 = y0;
radar.numRangeSamples = numRangeSamples;
radar.numRangeSamplesUp = numRangeSamplesUp;
radar.rangeStep = rangeStep;
end

function echoData = localBuildEcho(track, radar, sceneConfig)
targetPositions = double(sceneConfig.targetPositions);
targetAmplitudes = localExpandVector(sceneConfig.targetAmplitudes, size(targetPositions, 1));
targetPhases = deg2rad(localExpandVector(sceneConfig.targetPhasesDeg, size(targetPositions, 1)));
referencePoint = double(sceneConfig.referencePoint(:).');

freqHz = localRadarFrequencies(radar);
numRange = radar.numRangeSamples;
numAz = numel(track.x);
echoData = complex(zeros(numRange, numAz));

for azIdx = 1:numAz
    radarPos = [track.x(azIdx), track.y(azIdx), track.z(azIdx)];
    refRange = norm(radarPos - referencePoint);
    pulse = complex(zeros(numRange, 1));

    for targetIdx = 1:size(targetPositions, 1)
        targetPos = targetPositions(targetIdx, :);
        targetRange = norm(radarPos - targetPos);
        rangeDiff = targetRange - refRange;
        pulse = pulse + targetAmplitudes(targetIdx) ...
            .* exp(1i * targetPhases(targetIdx)) ...
            .* exp(-1i * 4 * pi * freqHz * rangeDiff / radar.c);
    end

    echoData(:, azIdx) = pulse;
end
end

function freqHz = localRadarFrequencies(radar)
if isfield(radar, 'freqHz') && ~isempty(radar.freqHz)
    freqHz = radar.freqHz(:);
elseif isfield(radar, 'freqVectorHz') && ~isempty(radar.freqVectorHz)
    freqHz = radar.freqVectorHz(:);
else
    error('generate_point_target_data:MissingFrequencyVector', ...
        '雷达参数中缺少频率向量。');
end
end

function out = localExpandVector(value, targetLength)
value = double(value(:));
if numel(value) == 1
    out = repmat(value, targetLength, 1);
else
    assert(numel(value) == targetLength, '向量长度与目标数量不一致。');
    out = value;
end
end
