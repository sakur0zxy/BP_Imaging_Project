function provenance = build_pipeline_provenance(context)
%BUILD_PIPELINE_PROVENANCE 汇总本次运行的轻量追踪信息。

if nargin < 1 || isempty(context)
    context = struct();
end

config = localGet(context, 'config', struct());
sourceData = localGet(context, 'sourceData', struct());
degradationInfo = localGet(context, 'degradationInfo', struct());
recoveryResult = localGet(context, 'recoveryResult', struct());
imageResult = localGet(context, 'imageResult', struct());
analysisResult = localGet(context, 'analysisResult', struct());
recoveryEvaluation = localGet(context, 'recoveryEvaluation', struct());
referenceCacheInfo = localGet(context, 'referenceCacheInfo', struct());
backend = localGet(context, 'backend', struct());
runInfo = localGet(context, 'runInfo', struct());

provenance = struct();
provenance.generatedAt = datestr(now, 'yyyy-mm-dd HH:MM:SS');
provenance.pipeline = localBuildPipelineSection(context, config);
provenance.source = localBuildSourceSection(sourceData);
provenance.degradation = localBuildDegradationSection(degradationInfo);
provenance.recovery = localBuildRecoverySection(recoveryResult);
provenance.imaging = localBuildImagingSection(imageResult, config);
provenance.analysis = localBuildAnalysisSection(analysisResult);
provenance.recoveryEvaluation = localBuildRecoveryEvaluationSection(recoveryEvaluation);
provenance.cache = localBuildCacheSection(referenceCacheInfo);
provenance.runtime = localBuildRuntimeSection(backend, runInfo);
end

function section = localBuildPipelineSection(context, config)
section = struct();
section.mode = localString(localGet(context, 'mode', localNested(config, {'project', 'mode'}, '')));
section.runLabel = localString(localGet(context, 'runLabel', ''));
end

function section = localBuildSourceSection(sourceData)
section = struct();
section.kind = localString(localNested(sourceData, {'meta', 'kind'}, ''));
section.provider = localString(localNested(sourceData, {'meta', 'provider'}, ''));
section.dataRoot = localString(localNested(sourceData, {'meta', 'dataRoot'}, ''));
section.echoSize = localSize(localGet(sourceData, 'echo', []));

track = localGet(sourceData, 'track', struct());
section.numAzimuthSamples = numel(localGet(track, 'x', []));
section.numRangeSamples = size(localGet(sourceData, 'echo', []), 1);

mask = localGet(sourceData, 'mask', []);
section.validAzimuthCount = localCountTrue(mask);
section.missingAzimuthCount = numel(mask) - section.validAzimuthCount;
end

function section = localBuildDegradationSection(info)
section = struct();
section.mode = localString(localGet(info, 'mode', ''));
section.missingRatio = localGet(info, 'missingRatio', []);
section.totalMissing = localGet(info, 'totalMissing', []);
section.totalSamples = localGet(info, 'totalSamples', []);
section.randomSeedUsed = localGet(info, 'randomSeedUsed', []);
end

function section = localBuildRecoverySection(result)
section = struct();
section.status = localString(localGet(result, 'status', ''));
section.reason = localString(localGet(result, 'reason', ''));
section.method = localString(localGet(result, 'method', ''));
section.iterations = localNested(result, {'recoveryInfo', 'iterations'}, []);
section.runtimeSec = localNested(result, {'recoveryInfo', 'runtimeSec'}, []);
section.missingRelErr = localNested(result, {'metrics', 'missingRelErr'}, []);
end

function section = localBuildImagingSection(imageResult, config)
section = struct();
section.grid = struct();
section.grid.numPixels = localNested(imageResult, {'grid', 'numPixels'}, ...
    localNested(config, {'imaging', 'grid', 'numPixels'}, []));
section.grid.xLimits = localNested(imageResult, {'grid', 'xLimits'}, ...
    localNested(config, {'imaging', 'grid', 'xLimits'}, []));
section.grid.yLimits = localNested(imageResult, {'grid', 'yLimits'}, ...
    localNested(config, {'imaging', 'grid', 'yLimits'}, []));
section.usedAzimuthCount = localNested(imageResult, {'meta', 'usedAzimuthCount'}, []);
section.totalAzimuthCount = localNested(imageResult, {'meta', 'totalAzimuthCount'}, []);
section.elapsedSeconds = localNested(imageResult, {'meta', 'elapsedSeconds'}, []);
section.peakValue = localNested(imageResult, {'peak', 'value'}, []);
end

function section = localBuildAnalysisSection(result)
section = struct();
section.status = localString(localGet(result, 'status', ''));
section.pointTargetStatus = localNested(result, {'pointTarget', 'status'}, '');
section.imageQualityStatus = localNested(result, {'imageQuality', 'status'}, '');
end

function section = localBuildRecoveryEvaluationSection(result)
section = struct();
section.enabled = logical(localGet(result, 'enabled', false));
section.status = localString(localGet(result, 'status', ''));
section.bestMethodIfAny = localNested(result, {'summary', 'bestMethodIfAny'}, '');
end

function section = localBuildCacheSection(info)
section = struct();
section.cacheHit = logical(localGet(info, 'cacheHit', false));
section.folderName = localString(localGet(info, 'folderName', ''));
section.key = localString(localGet(info, 'key', ''));
end

function section = localBuildRuntimeSection(backend, runInfo)
section = struct();
section.backendName = localString(localGet(backend, 'name', ''));
section.runDir = localString(localGet(runInfo, 'runDir', ''));
section.outputEnabled = logical(localGet(runInfo, 'enabled', false));
end

function value = localGet(parent, fieldName, defaultValue)
if isstruct(parent) && isfield(parent, fieldName)
    value = parent.(fieldName);
else
    value = defaultValue;
end
end

function value = localNested(parent, fields, defaultValue)
value = parent;
for idx = 1:numel(fields)
    if ~isstruct(value) || ~isfield(value, fields{idx})
        value = defaultValue;
        return;
    end
    value = value.(fields{idx});
end
end

function textValue = localString(value)
if isempty(value)
    textValue = '';
else
    textValue = char(string(value));
end
end

function value = localSize(data)
if isempty(data)
    value = [];
else
    value = size(data);
end
end

function count = localCountTrue(mask)
if isempty(mask)
    count = 0;
else
    count = nnz(logical(mask));
end
end
