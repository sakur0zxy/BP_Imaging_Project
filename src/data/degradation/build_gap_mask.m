function [mask, gapRanges, seedUsed] = build_gap_mask(sourceData, config)
%BUILD_GAP_MASK 生成缺失掩码。

numAzimuthSamples = size(sourceData.echo, 2);
meanStepMeters = localMeanStep(sourceData.track);

switch string(config.mode)
    case "none"
        mask = true(1, numAzimuthSamples);
        gapRanges = zeros(0, 2);
        seedUsed = [];
    case "fixed_gap"
        [mask, gapRanges] = apply_fixed_gap(numAzimuthSamples, config);
        seedUsed = [];
    case "random_gap"
        [mask, gapRanges, seedUsed] = apply_random_gap(numAzimuthSamples, meanStepMeters, config);
    otherwise
        error('build_gap_mask:UnsupportedMode', '不支持的缺失模式：%s', config.mode);
end
end

function meanStep = localMeanStep(track)
dx = diff(track.x(:));
dy = diff(track.y(:));
dz = diff(track.z(:));
step = hypot(hypot(dx, dy), dz);
step = step(step > 0 & isfinite(step));
if isempty(step)
    meanStep = 1;
else
    meanStep = mean(step);
end
end

