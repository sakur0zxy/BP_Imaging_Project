function [mask, gapRanges] = apply_fixed_gap(numAzimuthSamples, config)
%APPLY_FIXED_GAP 生成固定间断掩码。

mask = true(1, numAzimuthSamples);

if ~isempty(config.fixedGapRanges)
    gapRanges = round(config.fixedGapRanges);
else
    gapLength = max(1, round(numAzimuthSamples * config.missingRatio));
    startIndex = max(1, floor((numAzimuthSamples - gapLength) / 2) + 1);
    endIndex = min(numAzimuthSamples, startIndex + gapLength - 1);
    gapRanges = [startIndex, endIndex];
end

for idx = 1:size(gapRanges, 1)
    gapStart = max(1, gapRanges(idx, 1));
    gapEnd = min(numAzimuthSamples, gapRanges(idx, 2));
    if gapStart <= gapEnd
        mask(gapStart:gapEnd) = false;
    end
end
end

