function cache = cache_manager(config)
%CACHE_MANAGER Control cache read/write under the project cache root.
rootDir = fullfile(config.path.projectRoot, config.path.cacheRoot);

cache.root = rootDir;
cache.build_dir = @(folderName) fullfile(rootDir, folderName);
cache.build_path = @(folderName) fullfile(cache.build_dir(folderName), 'image_data.mat');
cache.build_info_path = @(folderName) fullfile(cache.build_dir(folderName), 'parameters_info.txt');
cache.build_info_cn_path = @(folderName) fullfile(cache.build_dir(folderName), '缓存说明.txt');
cache.exists = @(folderName) exist(cache.build_path(folderName), 'file') == 2;
cache.save = @localSave;
cache.load = @localLoad;

    function localSave(folderName, payload, descriptionText, descriptionTextCn)
        if nargin < 3
            descriptionText = '';
        end
        if nargin < 4
            descriptionTextCn = '';
        end

        folderPath = cache.build_dir(folderName);
        filePath = cache.build_path(folderName);
        infoPath = cache.build_info_path(folderName);
        infoCnPath = cache.build_info_cn_path(folderName);

        ensure_dir(folderPath);
        safe_save(filePath, payload, 'payload');
        localWriteTextFile(infoPath, descriptionText);
        localWriteTextFile(infoCnPath, descriptionTextCn);
    end

    function payload = localLoad(folderName)
        filePath = cache.build_path(folderName);
        loaded = load(filePath, 'payload');
        payload = loaded.payload;
    end

    function localWriteTextFile(filePath, textData)
        if nargin < 2 || isempty(textData)
            textData = sprintf('Cache folder generated at %s.\n', ...
                timestamp_str('yyyy-MM-dd HH:mm:ss'));
        end

        ensure_dir(fileparts(filePath));
        fileId = fopen(filePath, 'w');
        if fileId < 0
            error('cache_manager:OpenInfoFileFailed', ...
                'Unable to write cache info file: %s', filePath);
        end

        cleanup = onCleanup(@() fclose(fileId)); %#ok<NASGU>
        fprintf(fileId, '%s', textData);
        if isempty(textData) || textData(end) ~= newline
            fprintf(fileId, '\n');
        end
    end
end
