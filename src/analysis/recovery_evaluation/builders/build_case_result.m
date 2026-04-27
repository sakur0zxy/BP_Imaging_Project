function caseResult = build_case_result(caseItem, metrics, artifacts, status, messages, meta)
%BUILD_CASE_RESULT 封装单个 case 的标准结果结构。
if nargin < 6 || isempty(meta)
    meta = struct();
end
if nargin < 5 || isempty(messages)
    messages = {};
end
if nargin < 4 || isempty(status)
    status = 'completed';
end
if nargin < 3 || isempty(artifacts)
    artifacts = struct();
end
if nargin < 2 || isempty(metrics)
    metrics = struct();
end

caseResult = struct();
caseResult.caseName = caseItem.caseName;
caseResult.mode = caseItem.mode;
caseResult.status = status;
caseResult.metrics = metrics;
caseResult.artifacts = artifacts;
caseResult.messages = localToCellstr(messages);
caseResult.meta = merge_structs(caseItem.meta, meta);
caseResult.displayName = localGetField(caseResult.meta, 'displayName', caseItem.caseName);
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end

function values = localToCellstr(value)
if isempty(value)
    values = {};
elseif ischar(value)
    values = {value};
elseif isstring(value)
    values = cellstr(value(:).');
elseif iscell(value)
    values = value;
else
    values = {char(string(value))};
end
end
