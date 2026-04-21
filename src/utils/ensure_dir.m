function ensure_dir(folderPath)
%ENSURE_DIR 安全创建目录。

if isempty(folderPath)
    return;
end

if exist(folderPath, 'dir') ~= 7
    mkdir(folderPath);
end
end

