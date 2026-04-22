function merged = merge_structs(baseStruct, overrideStruct)
%MERGE_STRUCTS 递归合并结构体。

if isempty(baseStruct)
    merged = overrideStruct;
    return;
end

if isempty(overrideStruct)
    merged = baseStruct;
    return;
end

if ~isstruct(baseStruct) || ~isstruct(overrideStruct)
    merged = overrideStruct;
    return;
end

if ~isscalar(baseStruct) || ~isscalar(overrideStruct)
    merged = overrideStruct;
    return;
end

merged = baseStruct;
fields = fieldnames(overrideStruct);
for idx = 1:numel(fields)
    name = fields{idx};
    value = overrideStruct.(name);
    if isfield(merged, name)
        existingValue = merged.(name);
    else
        existingValue = [];
    end

    if isstruct(existingValue) && isscalar(existingValue) ...
            && isstruct(value) && isscalar(value)
        merged.(name) = merge_structs(existingValue, value);
    else
        merged.(name) = value;
    end
end
end
