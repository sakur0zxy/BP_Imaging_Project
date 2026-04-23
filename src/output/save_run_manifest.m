function filePath = save_run_manifest(result, runInfo, config)
%SAVE_RUN_MANIFEST 保存本次运行的人类可读追踪说明。

filePath = '';
if nargin < 3 || ~isstruct(runInfo) || ~localGet(runInfo, 'enabled', false)
    return;
end
if ~localNested(config, {'output', 'enableSave'}, false)
    return;
end

if isfield(result, 'provenance') && isstruct(result.provenance)
    provenance = result.provenance;
else
    provenance = build_pipeline_provenance(localResultToContext(result, config, runInfo));
end

filePath = fullfile(runInfo.runDir, 'run_manifest.txt');
ensure_dir(runInfo.runDir);

fid = fopen(filePath, 'w');
if fid < 0
    error('save_run_manifest:OpenFailed', '无法写入运行说明文件：%s', filePath);
end
cleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, '=========================================\n');
fprintf(fid, ' Run Manifest\n');
fprintf(fid, ' Generated At: %s\n', localText(localGet(provenance, 'generatedAt', '')));
fprintf(fid, '=========================================\n\n');

localWriteSection(fid, 'Pipeline');
localWriteField(fid, 'mode', localNested(provenance, {'pipeline', 'mode'}, ''));
localWriteField(fid, 'runLabel', localNested(provenance, {'pipeline', 'runLabel'}, ''));

localWriteSection(fid, 'Source Data');
localWriteField(fid, 'kind', localNested(provenance, {'source', 'kind'}, ''));
localWriteField(fid, 'provider', localNested(provenance, {'source', 'provider'}, ''));
localWriteField(fid, 'dataRoot', localNested(provenance, {'source', 'dataRoot'}, ''));
localWriteField(fid, 'echoSize', localNested(provenance, {'source', 'echoSize'}, []));
localWriteField(fid, 'numAzimuthSamples', localNested(provenance, {'source', 'numAzimuthSamples'}, []));
localWriteField(fid, 'validAzimuthCount', localNested(provenance, {'source', 'validAzimuthCount'}, []));
localWriteField(fid, 'missingAzimuthCount', localNested(provenance, {'source', 'missingAzimuthCount'}, []));

localWriteSection(fid, 'Reference Cache');
localWriteField(fid, 'cacheHit', localNested(provenance, {'cache', 'cacheHit'}, false));
localWriteField(fid, 'folderName', localNested(provenance, {'cache', 'folderName'}, ''));
localWriteField(fid, 'key', localNested(provenance, {'cache', 'key'}, ''));

localWriteSection(fid, 'Degradation');
localWriteField(fid, 'mode', localNested(provenance, {'degradation', 'mode'}, ''));
localWriteField(fid, 'missingRatio', localNested(provenance, {'degradation', 'missingRatio'}, []));
localWriteField(fid, 'totalMissing', localNested(provenance, {'degradation', 'totalMissing'}, []));
localWriteField(fid, 'randomSeedUsed', localNested(provenance, {'degradation', 'randomSeedUsed'}, []));

localWriteSection(fid, 'Recovery');
localWriteField(fid, 'status', localNested(provenance, {'recovery', 'status'}, ''));
localWriteField(fid, 'method', localNested(provenance, {'recovery', 'method'}, ''));
localWriteField(fid, 'iterations', localNested(provenance, {'recovery', 'iterations'}, []));
localWriteField(fid, 'runtimeSec', localNested(provenance, {'recovery', 'runtimeSec'}, []));

localWriteSection(fid, 'Imaging');
localWriteField(fid, 'grid.numPixels', localNested(provenance, {'imaging', 'grid', 'numPixels'}, []));
localWriteField(fid, 'grid.xLimits', localNested(provenance, {'imaging', 'grid', 'xLimits'}, []));
localWriteField(fid, 'grid.yLimits', localNested(provenance, {'imaging', 'grid', 'yLimits'}, []));
localWriteField(fid, 'usedAzimuthCount', localNested(provenance, {'imaging', 'usedAzimuthCount'}, []));
localWriteField(fid, 'peakValue', localNested(provenance, {'imaging', 'peakValue'}, []));

localWriteSection(fid, 'Analysis');
localWriteField(fid, 'status', localNested(provenance, {'analysis', 'status'}, ''));
localWriteField(fid, 'pointTargetStatus', localNested(provenance, {'analysis', 'pointTargetStatus'}, ''));
localWriteField(fid, 'imageQualityStatus', localNested(provenance, {'analysis', 'imageQualityStatus'}, ''));

localWriteSection(fid, 'Recovery Evaluation');
localWriteField(fid, 'enabled', localNested(provenance, {'recoveryEvaluation', 'enabled'}, false));
localWriteField(fid, 'status', localNested(provenance, {'recoveryEvaluation', 'status'}, ''));
localWriteField(fid, 'bestMethodIfAny', localNested(provenance, {'recoveryEvaluation', 'bestMethodIfAny'}, ''));

localWriteSection(fid, 'Runtime');
localWriteField(fid, 'backendName', localNested(provenance, {'runtime', 'backendName'}, ''));
localWriteField(fid, 'runDir', localNested(provenance, {'runtime', 'runDir'}, ''));
localWriteField(fid, 'outputEnabled', localNested(provenance, {'runtime', 'outputEnabled'}, false));
end

function context = localResultToContext(result, config, runInfo)
context = struct();
context.config = config;
context.runInfo = runInfo;
context.sourceData = localGet(result, 'source', struct());
context.degradationInfo = localGet(result, 'degradation', struct());
context.recoveryResult = localGet(result, 'recovery', struct());
context.imageResult = localGet(result, 'image', struct());
context.analysisResult = localGet(result, 'analysis', struct());
context.recoveryEvaluation = localGet(result, 'recoveryEvaluation', struct());
context.backend = localGet(result, 'backend', struct());
end

function localWriteSection(fid, titleText)
fprintf(fid, '\n[%s]\n', titleText);
end

function localWriteField(fid, name, value)
fprintf(fid, '- %s: %s\n', name, localText(value));
end

function textValue = localText(value)
if isempty(value)
    textValue = '';
elseif islogical(value)
    textValue = char(string(value));
elseif isnumeric(value)
    if isscalar(value)
        textValue = num2str(value, '%.12g');
    else
        textValue = mat2str(value);
    end
else
    textValue = char(string(value));
end
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
