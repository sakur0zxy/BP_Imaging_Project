function [mask, gapRanges, seedUsed] = apply_random_gap(numAzimuthSamples, meanStepMeters, config)
%APPLY_RANDOM_GAP 生成随机间断掩码。

mask = true(1, numAzimuthSamples);
numSegments = config.numSegments;
numGaps = max(numSegments - 1, 1);
totalMissing = round(numAzimuthSamples * config.missingRatio);

minGap = ceil(config.gapMinMeters / max(meanStepMeters, eps));
maxGap = floor(config.gapMaxMeters / max(meanStepMeters, eps));
maxGap = max(maxGap, minGap);

if totalMissing < numGaps * minGap
    totalMissing = numGaps * minGap;
end

if totalMissing > numGaps * maxGap
    error('apply_random_gap:InvalidGapBudget', ...
        'missingRatio 与 gapMin/gapMax 约束不匹配。');
end

seedUsed = localResolveSeed(config.randomSeed);
state = rng;
cleanup = onCleanup(@() rng(state)); %#ok<NASGU>
rng(seedUsed, 'twister');

gapLengths = minGap * ones(1, numGaps);
remaining = totalMissing - sum(gapLengths);
capacity = (maxGap - minGap) * ones(1, numGaps);

while remaining > 0
    freeIndex = find(capacity > 0);
    pickCount = min(remaining, numel(freeIndex));
    chosen = freeIndex(randperm(numel(freeIndex), pickCount));
    gapLengths(chosen) = gapLengths(chosen) + 1;
    capacity(chosen) = capacity(chosen) - 1;
    remaining = remaining - pickCount;
end

validCount = numAzimuthSamples - sum(gapLengths);
segmentLengths = localBalancedLengths(validCount, numSegments);

gapRanges = zeros(numGaps, 2);
cursor = 1;
for idx = 1:numSegments
    cursor = cursor + segmentLengths(idx);
    if idx <= numGaps
        gapStart = cursor;
        gapEnd = cursor + gapLengths(idx) - 1;
        gapRanges(idx, :) = [gapStart, gapEnd];
        mask(gapStart:gapEnd) = false;
        cursor = gapEnd + 1;
    end
end
end

function seedUsed = localResolveSeed(seedValue)
if ~isempty(seedValue)
    seedUsed = double(seedValue);
    return;
end

seedUsed = mod(floor(posixtime(datetime('now')) * 1e6), 2^31 - 1);
if seedUsed <= 0
    seedUsed = 1;
end
end

function lengths = localBalancedLengths(totalCount, numParts)
baseLen = floor(totalCount / numParts);
extra = mod(totalCount, numParts);
lengths = baseLen * ones(1, numParts);
if extra > 0
    lengths(1:extra) = lengths(1:extra) + 1;
end
end

