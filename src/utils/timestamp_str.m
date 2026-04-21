function text = timestamp_str(formatText)
%TIMESTAMP_STR 生成时间戳字符串。

if nargin < 1 || isempty(formatText)
    formatText = 'yyyyMMdd_HHmmss';
end

text = char(datetime('now', 'Format', formatText));
end

