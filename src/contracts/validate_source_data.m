function sourceData = validate_source_data(sourceData)
%VALIDATE_SOURCE_DATA 校验统一内部数据结构。

assert(isfield(sourceData, 'track') && isstruct(sourceData.track), ...
    'sourceData.track 缺失或类型错误。');
assert(isfield(sourceData.track, 'x') && isfield(sourceData.track, 'y') && isfield(sourceData.track, 'z'), ...
    'track 必须包含 x/y/z。');
assert(isfield(sourceData, 'echo') && isnumeric(sourceData.echo) && ndims(sourceData.echo) == 2, ...
    'sourceData.echo 必须是二维数值矩阵。');
assert(isfield(sourceData, 'radar') && isstruct(sourceData.radar), ...
    'sourceData.radar 缺失或类型错误。');

numAzimuthSamples = numel(sourceData.track.x);
assert(numel(sourceData.track.y) == numAzimuthSamples, 'track.y 长度不一致。');
assert(numel(sourceData.track.z) == numAzimuthSamples, 'track.z 长度不一致。');
assert(size(sourceData.echo, 2) == numAzimuthSamples, ...
    'echo 方位向长度必须与轨迹长度一致。');

if ~isfield(sourceData, 'mask') || isempty(sourceData.mask)
    sourceData.mask = true(1, numAzimuthSamples);
end
assert(numel(sourceData.mask) == numAzimuthSamples, 'mask 长度必须与轨迹长度一致。');

if ~isfield(sourceData.radar, 'numRangeSamples')
    sourceData.radar.numRangeSamples = size(sourceData.echo, 1);
end
assert(sourceData.radar.numRangeSamples == size(sourceData.echo, 1), ...
    'radar.numRangeSamples 与 echo 维度不一致。');

if ~isfield(sourceData.radar, 'numRangeSamplesUp')
    sourceData.radar.numRangeSamplesUp = sourceData.radar.numRangeSamples;
end
end

