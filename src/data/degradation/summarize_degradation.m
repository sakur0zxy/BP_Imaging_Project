function info = summarize_degradation(mask, gapRanges, config, sourceData, seedUsed)
%SUMMARIZE_DEGRADATION 汇总缺失信息。

numAzimuthSamples = size(sourceData.echo, 2);
activeIndex = find(mask);

info = struct();
info.mode = config.mode;
info.numAzimuthSamples = numAzimuthSamples;
info.activeIndices = activeIndex;
info.mask = mask;
info.gapRanges = gapRanges;
info.totalMissing = sum(~mask);
info.totalValid = sum(mask);
info.missingRatio = sum(~mask) / max(numAzimuthSamples, 1);
info.randomSeed = seedUsed;
end

