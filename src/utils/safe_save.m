function safe_save(filePath, data, varName)
%SAFE_SAVE 确保目录存在后保存 MAT 文件。

if nargin < 3 || isempty(varName)
    varName = 'payload';
end

ensure_dir(fileparts(filePath));
tmp = struct();
tmp.(varName) = data;
save(filePath, '-struct', 'tmp', '-v7.3');
end

