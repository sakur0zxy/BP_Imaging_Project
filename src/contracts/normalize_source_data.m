function sourceData = normalize_source_data(rawData, meta)
%NORMALIZE_SOURCE_DATA 把原始输入整理成统一内部结构。

if nargin < 2 || isempty(meta)
    meta = struct();
end

track = localNormalizeTrack(rawData);
echoData = localNormalizeEcho(rawData);
radar = localNormalizeRadar(rawData, echoData);

sourceData = struct();
sourceData.track = track;
sourceData.echo = echoData;
sourceData.radar = radar;
sourceData.mask = true(1, size(echoData, 2));
sourceData.meta = meta;

sourceData = validate_source_data(sourceData);
end

function track = localNormalizeTrack(rawData)
track = struct();

if isfield(rawData, 'track')
    rawTrack = rawData.track;
else
    rawTrack = rawData;
end

track.x = localPickTrackField(rawTrack, {'x', 'X'});
track.y = localPickTrackField(rawTrack, {'y', 'Y'});
track.z = localPickTrackField(rawTrack, {'z', 'Z'});

track.x = track.x(:).';
track.y = track.y(:).';
track.z = track.z(:).';
end

function value = localPickTrackField(rawTrack, names)
for idx = 1:numel(names)
    if isfield(rawTrack, names{idx})
        value = rawTrack.(names{idx});
        return;
    end
end
error('normalize_source_data:MissingTrackField', ...
    '缺少轨迹字段：%s', strjoin(names, '/'));
end

function echoData = localNormalizeEcho(rawData)
names = {'echo', 'echoData', 'fp'};
for idx = 1:numel(names)
    if isfield(rawData, names{idx})
        echoData = rawData.(names{idx});
        return;
    end
end
error('normalize_source_data:MissingEcho', '缺少回波字段。');
end

function radar = localNormalizeRadar(rawData, echoData)
if isfield(rawData, 'radar')
    radar = rawData.radar;
else
    radar = struct();
end

if ~isfield(radar, 'numRangeSamples')
    radar.numRangeSamples = size(echoData, 1);
end
if ~isfield(radar, 'numRangeSamplesUp')
    radar.numRangeSamplesUp = radar.numRangeSamples;
end
if ~isfield(radar, 'c')
    radar.c = 3e8;
end
if ~isfield(radar, 'centerOmega')
    radar.centerOmega = 2 * pi * 9.6e9;
end
if ~isfield(radar, 'rangeStep')
    radar.rangeStep = 1;
end
end

