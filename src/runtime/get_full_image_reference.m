function [imageResult, cacheInfo] = get_full_image_reference(sourceData, config)
%GET_FULL_IMAGE_REFERENCE Read or generate the full-data reference image.
sourceData = validate_source_data(sourceData);

cacheInfo = struct( ...
    'enabled', false, ...
    'cacheHit', false, ...
    'key', '', ...
    'shortKey', '', ...
    'folderName', '', ...
    'folderPath', '', ...
    'filePath', '', ...
    'infoFilePath', '', ...
    'infoFilePathCn', '', ...
    'namespace', 'baseline', ...
    'reason', 'cache-disabled');

if ~localIsCacheEnabled(config)
    imageResult = bp_imaging(sourceData, config);
    return;
end

cacheInfo.enabled = true;
cacheInfo.reason = '';
cacheInfo.namespace = localGetCacheField(config, 'fullImageNamespace', 'baseline');
cacheInfo.key = localBuildCacheKey(sourceData, config);
cacheInfo.shortKey = cacheInfo.key(1:min(7, numel(cacheInfo.key)));
cacheInfo.folderName = localBuildCacheFolderName(sourceData, cacheInfo.namespace, cacheInfo.shortKey);

cache = cache_manager(config);
cacheInfo.folderPath = cache.build_dir(cacheInfo.folderName);
cacheInfo.filePath = cache.build_path(cacheInfo.folderName);
cacheInfo.infoFilePath = cache.build_info_path(cacheInfo.folderName);
cacheInfo.infoFilePathCn = cache.build_info_cn_path(cacheInfo.folderName);
if cache.exists(cacheInfo.folderName)
    payload = cache.load(cacheInfo.folderName);
    imageResult = payload.imageResult;
    cacheInfo.cacheHit = true;
    return;
end

imageResult = bp_imaging(sourceData, config);
payload = struct();
payload.imageResult = imageResult;
payload.signature = localBuildCacheSignature(sourceData, config);

descriptionText = localBuildCacheDescription(sourceData, config, cacheInfo, payload.signature);
descriptionTextCn = localBuildCacheDescriptionCn(sourceData, config, cacheInfo);
cache.save(cacheInfo.folderName, payload, descriptionText, descriptionTextCn);
end

function enabled = localIsCacheEnabled(config)
enabled = false;
if isfield(config, 'cache') && isstruct(config.cache) ...
        && isfield(config.cache, 'enableFullImageCache')
    enabled = logical(config.cache.enableFullImageCache);
end
end

function value = localGetCacheField(config, fieldName, defaultValue)
value = defaultValue;
if isfield(config, 'cache') && isstruct(config.cache) && isfield(config.cache, fieldName)
    value = config.cache.(fieldName);
end
end

function key = localBuildCacheKey(sourceData, config)
signature = localBuildCacheSignature(sourceData, config);
key = hash_struct(signature);
end

function signature = localBuildCacheSignature(sourceData, config)
signature = struct();
signature.projectMode = localGetField(config.project, 'mode', '');
signature.sourceKind = localGetField(sourceData.meta, 'kind', '');
signature.provider = localGetField(sourceData.meta, 'provider', '');
signature.dataRoot = localGetField(sourceData.meta, 'dataRoot', '');
signature.scene = localGetField(sourceData.meta, 'scene', struct());
signature.track = sourceData.track;
signature.radar = sourceData.radar;
signature.imaging = config.imaging;
signature.echoSummary = localBuildEchoSummary(sourceData.echo);
end

function summary = localBuildEchoSummary(echoData)
summary = struct();
summary.size = size(echoData);
summary.l2Norm = norm(double(echoData(:)));
summary.maxAbs = max(abs(double(echoData(:))));

headCount = min(8, numel(echoData));
headValues = echoData(1:headCount);
summary.headReal = real(double(headValues(:).'));
summary.headImag = imag(double(headValues(:).'));
end

function folderName = localBuildCacheFolderName(sourceData, namespace, shortKey)
sourceTag = localBuildSourceTag(sourceData.meta);
namespace = localSanitizeToken(namespace);
if isempty(namespace)
    namespace = 'baseline';
end

folderName = sprintf('%s_%s_%s', sourceTag, namespace, shortKey);
end

function sourceTag = localBuildSourceTag(meta)
kind = lower(localSanitizeToken(localGetField(meta, 'kind', '')));
provider = lower(localSanitizeToken(localGetField(meta, 'provider', '')));
dataRootName = lower(localSanitizeToken(localGetLastPathToken(localGetField(meta, 'dataRoot', ''))));

if strcmp(kind, 'real') && ~isempty(dataRootName)
    sourceTag = dataRootName;
elseif strcmp(kind, 'real') && ~isempty(provider)
    sourceTag = provider;
elseif ~isempty(kind)
    sourceTag = kind;
elseif ~isempty(provider)
    sourceTag = provider;
elseif ~isempty(dataRootName)
    sourceTag = dataRootName;
else
    sourceTag = 'source';
end
end

function token = localSanitizeToken(value)
token = lower(char(string(value)));
token = regexprep(token, '[^a-z0-9]+', '_');
token = regexprep(token, '^_+|_+$', '');
end

function token = localGetLastPathToken(pathText)
token = '';
if isempty(pathText)
    return;
end

normalized = strrep(char(pathText), '/', filesep);
normalized = strrep(normalized, '\', filesep);
while ~isempty(normalized) && (normalized(end) == filesep)
    normalized(end) = [];
end

if isempty(normalized)
    return;
end

[~, token] = fileparts(normalized);
end

function descriptionText = localBuildCacheDescription(sourceData, config, cacheInfo, signature)
lines = {};
lines{end + 1} = 'Full Image Reference Cache';
lines{end + 1} = sprintf('Created At: %s', timestamp_str('yyyy-MM-dd HH:mm:ss'));
lines{end + 1} = sprintf('Folder Name: %s', cacheInfo.folderName);
lines{end + 1} = sprintf('Cache Key: %s', cacheInfo.key);
lines{end + 1} = sprintf('Short Key: %s', cacheInfo.shortKey);
lines{end + 1} = sprintf('Cache Folder: %s', cacheInfo.folderPath);
lines{end + 1} = sprintf('Image File: %s', cacheInfo.filePath);
lines{end + 1} = sprintf('Info File: %s', cacheInfo.infoFilePath);
lines{end + 1} = '';

lines{end + 1} = '[Data]';
lines{end + 1} = sprintf('Source Kind: %s', localGetField(sourceData.meta, 'kind', ''));
lines{end + 1} = sprintf('Source Name: %s', localInferSourceName(sourceData.meta));
lines{end + 1} = sprintf('Provider: %s', localGetField(sourceData.meta, 'provider', ''));
lines{end + 1} = sprintf('Data Root: %s', localGetField(sourceData.meta, 'dataRoot', ''));
lines{end + 1} = sprintf('Echo Size: %s', mat2str(size(sourceData.echo)));
lines{end + 1} = sprintf('Track Sample Count: %d', numel(sourceData.track.x));
lines{end + 1} = sprintf('Range Sample Count: %d', size(sourceData.echo, 1));
lines{end + 1} = '';

lines{end + 1} = '[Imaging Parameters]';
lines = [lines, localFlattenStruct('imaging', config.imaging)]; %#ok<AGROW>
lines{end + 1} = '';

lines{end + 1} = '[Track Summary]';
lines{end + 1} = sprintf('xRange: %s', mat2str([min(sourceData.track.x), max(sourceData.track.x)], 12));
lines{end + 1} = sprintf('yRange: %s', mat2str([min(sourceData.track.y), max(sourceData.track.y)], 12));
lines{end + 1} = sprintf('zRange: %s', mat2str([min(sourceData.track.z), max(sourceData.track.z)], 12));
lines{end + 1} = '';

lines{end + 1} = '[Radar Summary]';
lines = [lines, localFlattenStruct('radar', localSelectRadarSummary(sourceData.radar))]; %#ok<AGROW>
lines{end + 1} = '';

lines{end + 1} = '[Cache Signature]';
lines = [lines, localFlattenStruct('signature', signature)]; %#ok<AGROW>

descriptionText = strjoin(lines, newline);
end

function descriptionText = localBuildCacheDescriptionCn(sourceData, config, cacheInfo)
centerFreqHz = localGetCenterFreqHz(sourceData.radar);
trackCount = numel(sourceData.track.x);
rangeCount = size(sourceData.echo, 1);
xRange = [min(sourceData.track.x), max(sourceData.track.x)];
yRange = [min(sourceData.track.y), max(sourceData.track.y)];
zRange = [min(sourceData.track.z), max(sourceData.track.z)];

lines = {};
lines{end + 1} = '=========================================';
lines{end + 1} = sprintf(' 缓存生成时间 (Timestamp): %s', timestamp_str('yyyy-MM-dd HH:mm:ss'));
lines{end + 1} = sprintf(' 缓存唯一标识 (Hash): %s', cacheInfo.shortKey);
lines{end + 1} = sprintf(' 缓存目录 (Folder): %s', cacheInfo.folderName);
lines{end + 1} = sprintf(' 缓存类型 (Type): %s', localBuildCacheTypeCn(sourceData.meta));
lines{end + 1} = '=========================================';
lines{end + 1} = '';

lines{end + 1} = '【数据来源】';
lines{end + 1} = sprintf('- 数据类型 (source_kind): %s', localGetField(sourceData.meta, 'kind', ''));
lines{end + 1} = sprintf('- 数据名称 (source_name): %s', localInferSourceName(sourceData.meta));
lines{end + 1} = sprintf('- 数据提供方式 (provider): %s', localGetField(sourceData.meta, 'provider', ''));
lines{end + 1} = sprintf('- 数据根目录 (data_root): %s', localGetField(sourceData.meta, 'dataRoot', ''));
lines{end + 1} = '';

lines{end + 1} = '【雷达核心参数】';
lines{end + 1} = sprintf('- 中心频率 (center_freq): %.12g Hz', centerFreqHz);
lines{end + 1} = sprintf('- 发射带宽 (bandwidth): %.12g Hz', localGetField(sourceData.radar, 'bandwidthHz', NaN));
lines{end + 1} = sprintf('- 脉冲宽度 (pulse_width): %.12g s', localGetField(sourceData.radar, 'pulseWidth', NaN));
lines{end + 1} = sprintf('- 距离采样数 (num_range_samples): %d', rangeCount);
lines{end + 1} = sprintf('- 插值后距离采样数 (num_range_samples_up): %d', ...
    round(localGetField(sourceData.radar, 'numRangeSamplesUp', rangeCount)));
lines{end + 1} = '';

lines{end + 1} = '【成像网格参数】';
lines{end + 1} = sprintf('- 网格大小 (num_pixels): %d x %d', ...
    config.imaging.grid.numPixels, config.imaging.grid.numPixels);
lines{end + 1} = sprintf('- X范围 (x_limits): %s', mat2str(config.imaging.grid.xLimits, 12));
lines{end + 1} = sprintf('- Y范围 (y_limits): %s', mat2str(config.imaging.grid.yLimits, 12));
lines{end + 1} = sprintf('- 单精度计算 (use_single_precision): %s', ...
    localLogicalToText(localGetField(config.imaging, 'useSinglePrecision', false)));
lines{end + 1} = sprintf('- 迭代块长度 (iteration_length): %d', ...
    round(localGetField(config.imaging, 'iterationLength', 0)));
lines{end + 1} = '';

lines{end + 1} = '【轨迹参数】';
lines{end + 1} = sprintf('- 方位采样数 (num_azimuth_samples): %d', trackCount);
lines{end + 1} = sprintf('- x范围 (track_x_range): %s', mat2str(xRange, 12));
lines{end + 1} = sprintf('- y范围 (track_y_range): %s', mat2str(yRange, 12));
lines{end + 1} = sprintf('- z范围 (track_z_range): %s', mat2str(zRange, 12));
lines{end + 1} = '';

lines{end + 1} = '【完整参数索引】';
lines = [lines, localFlattenStructCn('imaging', config.imaging)]; %#ok<AGROW>
lines = [lines, localFlattenStructCn('radar', localSelectRadarSummary(sourceData.radar))]; %#ok<AGROW>
lines{end + 1} = '=========================================';

descriptionText = strjoin(lines, newline);
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end

function sourceName = localInferSourceName(meta)
sourceName = localGetField(meta, 'dataName', '');
if ~isempty(sourceName)
    return;
end

dataRoot = localGetField(meta, 'dataRoot', '');
if ~isempty(dataRoot)
    [~, sourceName] = fileparts(dataRoot);
    if ~isempty(sourceName)
        return;
    end
end

provider = localGetField(meta, 'provider', '');
kind = localGetField(meta, 'kind', '');
if ~isempty(provider) && ~isempty(kind)
    sourceName = sprintf('%s_%s', kind, provider);
elseif ~isempty(provider)
    sourceName = provider;
else
    sourceName = kind;
end
end

function typeText = localBuildCacheTypeCn(meta)
kind = localGetField(meta, 'kind', '');
provider = localGetField(meta, 'provider', '');
if strcmp(kind, 'sim')
    typeText = '仿真完整参考图';
elseif strcmp(kind, 'real') && strcmp(provider, 'gotcha')
    typeText = 'Gotcha 实测完整参考图';
elseif strcmp(kind, 'real')
    typeText = '实测完整参考图';
else
    typeText = '完整参考图';
end
end

function radarSummary = localSelectRadarSummary(radar)
fieldNames = {'centerOmega', 'bandwidthHz', 'pulseWidth', 'numRangeSamples', ...
    'numRangeSamplesUp', 'rangeStep', 'firstFreqHz', 'ts', 'y0'};

radarSummary = struct();
for idx = 1:numel(fieldNames)
    fieldName = fieldNames{idx};
    if isfield(radar, fieldName)
        radarSummary.(fieldName) = radar.(fieldName);
    end
end
end

function lines = localFlattenStruct(prefix, value)
lines = {};

if isstruct(value)
    fieldNames = fieldnames(value);
    for idx = 1:numel(fieldNames)
        fieldName = fieldNames{idx};
        childPrefix = sprintf('%s.%s', prefix, fieldName);
        lines = [lines, localFlattenStruct(childPrefix, value.(fieldName))]; %#ok<AGROW>
    end
    return;
end

lines{end + 1} = sprintf('%s = %s', prefix, localValueToText(value));
end

function lines = localFlattenStructCn(prefix, value)
lines = {};

if isstruct(value)
    fieldNames = fieldnames(value);
    for idx = 1:numel(fieldNames)
        fieldName = fieldNames{idx};
        childPrefix = sprintf('%s.%s', prefix, fieldName);
        lines = [lines, localFlattenStructCn(childPrefix, value.(fieldName))]; %#ok<AGROW>
    end
    return;
end

lines{end + 1} = sprintf('- %s: %s', prefix, localValueToText(value));
end

function textValue = localValueToText(value)
if islogical(value) && isscalar(value)
    textValue = char(string(value));
    return;
end

if isnumeric(value)
    if isscalar(value)
        textValue = num2str(value, '%.12g');
    else
        textValue = mat2str(value, 12);
    end
    return;
end

if ischar(value)
    textValue = value;
    return;
end

if isstring(value)
    textValue = char(join(value(:).', ', '));
    return;
end

if iscell(value)
    cellText = cellfun(@localValueToText, value, 'UniformOutput', false);
    textValue = ['{', strjoin(cellText, ', '), '}'];
    return;
end

textValue = '<unsupported-value>';
end

function textValue = localLogicalToText(value)
if logical(value)
    textValue = 'true';
else
    textValue = 'false';
end
end

function centerFreqHz = localGetCenterFreqHz(radar)
centerOmega = localGetField(radar, 'centerOmega', NaN);
if isnan(centerOmega)
    centerFreqHz = NaN;
else
    centerFreqHz = centerOmega / (2 * pi);
end
end
