function model = build_measurement_model(sourceData, referenceSourceData)
%BUILD_MEASUREMENT_MODEL 将缺失回波整理成恢复算法统一输入。
if nargin < 2
    referenceSourceData = [];
end

sourceData = validate_source_data(sourceData);
if ~isempty(referenceSourceData)
    referenceSourceData = validate_source_data(referenceSourceData);
    assert(isequal(size(referenceSourceData.echo), size(sourceData.echo)), ...
        'referenceSourceData.echo 尺寸必须与 sourceData.echo 一致。');
end

[observedAzimuthMask, observedMatrixMask] = localResolveObservedMask(sourceData);
missingMatrixMask = ~observedMatrixMask;
missingAzimuthMask = ~observedAzimuthMask;

assert(any(observedMatrixMask(:)), ...
    '观测掩码全为 false，无法执行恢复。');

model = struct();
model.observedEcho = sourceData.echo;
model.referenceEcho = [];
model.track = sourceData.track;
model.radar = sourceData.radar;
model.meta = sourceData.meta;
model.observedAzimuthMask = observedAzimuthMask;
model.observedMatrixMask = observedMatrixMask;
model.missingAzimuthMask = missingAzimuthMask;
model.missingMatrixMask = missingMatrixMask;
model.numRangeSamples = size(sourceData.echo, 1);
model.numAzimuthSamples = size(sourceData.echo, 2);
model.observedFraction = nnz(observedMatrixMask) / numel(observedMatrixMask);
model.missingFraction = 1 - model.observedFraction;
model.totalObservedSamples = nnz(observedMatrixMask);
model.totalMissingSamples = nnz(missingMatrixMask);
model.hasReference = false;

if ~isempty(referenceSourceData)
    model.referenceEcho = referenceSourceData.echo;
    model.hasReference = true;
end
end

function [observedAzimuthMask, observedMatrixMask] = localResolveObservedMask(sourceData)
rawMask = sourceData.mask;
echoSize = size(sourceData.echo);

if isequal(size(rawMask), echoSize)
    observedMatrixMask = logical(rawMask);
    observedAzimuthMask = all(observedMatrixMask, 1);
    return;
end

rawMask = logical(rawMask(:).');
assert(numel(rawMask) == echoSize(2), ...
    'sourceData.mask 长度必须与方位向样本数一致。');

observedAzimuthMask = rawMask;
observedMatrixMask = repmat(observedAzimuthMask, echoSize(1), 1);
end
