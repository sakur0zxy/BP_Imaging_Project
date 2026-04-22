function [observedAzimuthMask, observedMatrixMask] = resolve_observation_mask(sourceData)
%RESOLVE_OBSERVATION_MASK 将 sourceData.mask 统一成恢复模块内部格式。
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
