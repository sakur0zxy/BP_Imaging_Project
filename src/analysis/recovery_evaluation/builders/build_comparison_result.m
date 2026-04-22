function comparisonResult = build_comparison_result(comparisonName, referenceCase, targetCase, mode, metrics, status, messages, meta)
%BUILD_COMPARISON_RESULT 封装单个 comparison 的标准结果结构。
if nargin < 8 || isempty(meta)
    meta = struct();
end
if nargin < 7 || isempty(messages)
    messages = {};
end
if nargin < 6 || isempty(status)
    status = 'completed';
end
if nargin < 5 || isempty(metrics)
    metrics = struct();
end

comparisonResult = struct();
comparisonResult.comparisonName = comparisonName;
comparisonResult.referenceCase = referenceCase;
comparisonResult.targetCase = targetCase;
comparisonResult.mode = mode;
comparisonResult.metrics = metrics;
comparisonResult.status = status;
comparisonResult.messages = localToCellstr(messages);
comparisonResult.meta = meta;
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
