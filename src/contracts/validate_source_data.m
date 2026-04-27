function sourceData = validate_source_data(sourceData)
%VALIDATE_SOURCE_DATA 校验统一内部数据结构。

localRequireStruct(sourceData, 'track', 'sourceData.track');
localRequireStruct(sourceData, 'radar', 'sourceData.radar');
localRequireStruct(sourceData, 'meta', 'sourceData.meta');

localRequireField(sourceData.track, 'x', 'sourceData.track.x');
localRequireField(sourceData.track, 'y', 'sourceData.track.y');
localRequireField(sourceData.track, 'z', 'sourceData.track.z');
localRequireField(sourceData, 'echo', 'sourceData.echo');

sourceData.track.x = localValidateVector(sourceData.track.x, 'sourceData.track.x');
sourceData.track.y = localValidateVector(sourceData.track.y, 'sourceData.track.y');
sourceData.track.z = localValidateVector(sourceData.track.z, 'sourceData.track.z');

if ~isnumeric(sourceData.echo) || ndims(sourceData.echo) ~= 2 || isempty(sourceData.echo)
    error('validate_source_data:InvalidEcho', ...
        'sourceData.echo 必须是非空二维数值矩阵。');
end
if ~all(isfinite(sourceData.echo(:)))
    error('validate_source_data:InvalidEchoValue', ...
        'sourceData.echo 不能包含 NaN 或 Inf。');
end

numAzimuthSamples = numel(sourceData.track.x);
if numAzimuthSamples == 0
    error('validate_source_data:EmptyTrack', ...
        'sourceData.track.x/y/z 不能为空。');
end
if numel(sourceData.track.y) ~= numAzimuthSamples
    error('validate_source_data:TrackLengthMismatch', ...
        'sourceData.track.y 长度必须与 sourceData.track.x 一致。');
end
if numel(sourceData.track.z) ~= numAzimuthSamples
    error('validate_source_data:TrackLengthMismatch', ...
        'sourceData.track.z 长度必须与 sourceData.track.x 一致。');
end
if size(sourceData.echo, 2) ~= numAzimuthSamples
    error('validate_source_data:EchoAzimuthMismatch', ...
        'sourceData.echo 的列数必须与轨迹长度一致。');
end

if ~isfield(sourceData, 'mask') || isempty(sourceData.mask)
    sourceData.mask = true(1, numAzimuthSamples);
end
sourceData.mask = localValidateMask(sourceData.mask, numAzimuthSamples);

if ~isfield(sourceData.radar, 'numRangeSamples')
    sourceData.radar.numRangeSamples = size(sourceData.echo, 1);
end
if ~isfield(sourceData.radar, 'numRangeSamplesUp')
    sourceData.radar.numRangeSamplesUp = sourceData.radar.numRangeSamples;
end

localValidatePositiveScalar(sourceData.radar, 'c', 'sourceData.radar.c');
localValidateFiniteScalar(sourceData.radar, 'centerOmega', 'sourceData.radar.centerOmega');
localValidatePositiveScalar(sourceData.radar, 'numRangeSamples', 'sourceData.radar.numRangeSamples');
localValidatePositiveScalar(sourceData.radar, 'numRangeSamplesUp', 'sourceData.radar.numRangeSamplesUp');
localValidatePositiveScalar(sourceData.radar, 'rangeStep', 'sourceData.radar.rangeStep');

if sourceData.radar.numRangeSamples ~= size(sourceData.echo, 1)
    error('validate_source_data:RangeSampleMismatch', ...
        'sourceData.radar.numRangeSamples 必须与 sourceData.echo 行数一致。');
end
if sourceData.radar.numRangeSamplesUp < sourceData.radar.numRangeSamples
    error('validate_source_data:UpsampleRangeMismatch', ...
        'sourceData.radar.numRangeSamplesUp 不能小于 numRangeSamples。');
end
end

function localRequireStruct(parent, fieldName, pathText)
if ~isfield(parent, fieldName) || ~isstruct(parent.(fieldName))
    error('validate_source_data:MissingStruct', '%s 缺失或类型错误。', pathText);
end
end

function localRequireField(parent, fieldName, pathText)
if ~isfield(parent, fieldName)
    error('validate_source_data:MissingField', '%s 缺失。', pathText);
end
end

function value = localValidateVector(value, pathText)
if ~isnumeric(value) || isempty(value) || ~isvector(value) || ~all(isfinite(value(:)))
    error('validate_source_data:InvalidVector', ...
        '%s 必须是非空有限数值向量。', pathText);
end
value = value(:).';
end

function mask = localValidateMask(mask, numAzimuthSamples)
if ~isvector(mask) || numel(mask) ~= numAzimuthSamples
    error('validate_source_data:InvalidMask', ...
        'sourceData.mask 长度必须与轨迹长度一致。');
end
if islogical(mask)
    mask = mask(:).';
    return;
end
if isnumeric(mask) && all(mask(:) == 0 | mask(:) == 1)
    mask = logical(mask(:).');
    return;
end
error('validate_source_data:InvalidMask', ...
    'sourceData.mask 必须是逻辑向量，或只包含 0/1 的数值向量。');
end

function localValidateFiniteScalar(parent, fieldName, pathText)
localRequireField(parent, fieldName, pathText);
value = parent.(fieldName);
if ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
    error('validate_source_data:InvalidScalar', '%s 必须是有限数值标量。', pathText);
end
end

function localValidatePositiveScalar(parent, fieldName, pathText)
localValidateFiniteScalar(parent, fieldName, pathText);
if parent.(fieldName) <= 0
    error('validate_source_data:InvalidPositiveScalar', '%s 必须大于 0。', pathText);
end
end
