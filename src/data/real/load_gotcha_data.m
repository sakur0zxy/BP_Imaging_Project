function sourceData = load_gotcha_data(config)
%LOAD_GOTCHA_DATA 读取并整理 Gotcha 数据到统一内部格式。

dataRoot = localResolveDataRoot(config);
numFiles = config.source.numFiles;

xCells = cell(1, numFiles);
yCells = cell(1, numFiles);
zCells = cell(1, numFiles);
echoCells = cell(1, numFiles);
freqRef = [];

for fileIdx = 1:numFiles
    filePath = fullfile(dataRoot, sprintf(config.source.filePattern, fileIdx));
    if exist(filePath, 'file') ~= 2
        error('load_gotcha_data:MissingDataFile', '找不到数据文件：%s', filePath);
    end

    sample = localLoadSingleFile(filePath, config.source);
    if isempty(freqRef)
        freqRef = sample.freq;
    else
        localValidateFrequency(sample.freq, freqRef, filePath);
    end

    xCells{fileIdx} = sample.x;
    yCells{fileIdx} = sample.y;
    zCells{fileIdx} = sample.z;
    echoCells{fileIdx} = sample.echo;
end

rawData = struct();
rawData.track = struct( ...
    'x', [xCells{:}], ...
    'y', [yCells{:}], ...
    'z', [zCells{:}]);
rawData.echo = [echoCells{:}];
rawData.radar = localBuildRadar(config, size(rawData.echo, 1), freqRef);

meta = struct();
meta.kind = 'real';
meta.provider = 'gotcha';
meta.dataRoot = dataRoot;

sourceData = normalize_source_data(rawData, meta);
end

function dataRoot = localResolveDataRoot(config)
if isfield(config.path, 'realDataRoot') && ~isempty(config.path.realDataRoot)
    dataRoot = localResolvePath(config.path.projectRoot, config.path.realDataRoot);
    return;
end

dataRoot = '';
for idx = 1:numel(config.path.realDataCandidates)
    candidate = localResolvePath(config.path.projectRoot, config.path.realDataCandidates{idx});
    if exist(candidate, 'dir') == 7
        dataRoot = candidate;
        break;
    end
end

if isempty(dataRoot)
    error('load_gotcha_data:DataRootNotFound', ...
        '未找到实测数据目录，请在 local_env_config.m 中设置 path.realDataRoot。');
end
end

function pathText = localResolvePath(projectRoot, rawPath)
if startsWith(rawPath, '\') || startsWith(rawPath, '/') ...
        || ~isempty(regexp(rawPath, '^[A-Za-z]:[\\/]', 'once'))
    pathText = rawPath;
else
    pathText = fullfile(projectRoot, rawPath);
end
end

function sample = localLoadSingleFile(filePath, sourceConfig)
loaded = load(filePath);
varName = sourceConfig.variableName;
if ~isfield(loaded, varName)
    error('load_gotcha_data:MissingTopVariable', ...
        '文件 %s 缺少顶层变量 %s。', filePath, varName);
end

dataStruct = loaded.(varName);
map = sourceConfig.fieldMap;
required = {'x', 'y', 'z', 'echo', 'freq'};
for idx = 1:numel(required)
    key = required{idx};
    if ~isfield(map, key) || ~isfield(dataStruct, map.(key))
        error('load_gotcha_data:MissingField', ...
            '文件 %s 缺少字段映射 %s。', filePath, key);
    end
end

sample = struct();
xValue = dataStruct.(map.x);
yValue = dataStruct.(map.y);
zValue = dataStruct.(map.z);
echoValue = dataStruct.(map.echo);
freqValue = dataStruct.(map.freq);

sample.x = xValue(:).';
sample.y = yValue(:).';
sample.z = zValue(:).';
sample.echo = echoValue;
sample.freq = freqValue(:).';

assert(size(sample.echo, 2) == numel(sample.x), ...
    '文件 %s 的 echo 列数与轨迹长度不一致。', filePath);
assert(size(sample.echo, 1) == numel(sample.freq), ...
    '文件 %s 的 echo 行数与频率长度不一致。', filePath);
end

function localValidateFrequency(freqNow, freqRef, filePath)
if numel(freqNow) ~= numel(freqRef)
    error('load_gotcha_data:FrequencyMismatch', ...
        '文件 %s 的频率长度不一致。', filePath);
end

if max(abs(double(freqNow(:)) - double(freqRef(:)))) > 1e-9
    error('load_gotcha_data:FrequencyMismatch', ...
        '文件 %s 的频率向量与首个文件不一致。', filePath);
end
end

function radar = localBuildRadar(config, numRangeSamples, freqHz)
c = config.radar.c;
centerOmega = config.radar.centerOmega;
pulseWidth = config.radar.pulseWidth;
upsampleFactor = config.radar.rangeUpsampleFactor;

ts = pulseWidth / numRangeSamples;
numRangeSamplesUp = upsampleFactor * numRangeSamples;
firstFreq = freqHz(1);
y0 = (centerOmega - firstFreq * 2 * pi) / pulseWidth * 2;
rangeStep = c * pi / (y0 * ts * numRangeSamplesUp);

radar = struct();
radar.c = c;
radar.centerOmega = centerOmega;
radar.pulseWidth = pulseWidth;
radar.ts = ts;
radar.y0 = y0;
radar.firstFreqHz = firstFreq;
radar.freqHz = freqHz;
radar.bandwidthHz = abs(freqHz(end) - freqHz(1));
radar.numRangeSamples = numRangeSamples;
radar.numRangeSamplesUp = numRangeSamplesUp;
radar.rangeStep = rangeStep;
end
