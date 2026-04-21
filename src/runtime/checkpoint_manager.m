function manager = checkpoint_manager(checkpointFile)
%CHECKPOINT_MANAGER 管理 checkpoint 状态文件。

manager.file = checkpointFile;
manager.exists = @() ~isempty(checkpointFile) && exist(checkpointFile, 'file') == 2;
manager.save = @localSave;
manager.load = @localLoad;
manager.clear = @localClear;

    function localSave(status)
        if isempty(checkpointFile)
            return;
        end
        ensure_dir(fileparts(checkpointFile));
        jsonText = jsonencode(status, 'PrettyPrint', true);
        fid = fopen(checkpointFile, 'w');
        assert(fid > 0, '无法写入 checkpoint 文件：%s', checkpointFile);
        cleaner = onCleanup(@() fclose(fid)); %#ok<NASGU>
        fwrite(fid, jsonText, 'char');
    end

    function status = localLoad()
        if ~manager.exists()
            status = struct();
            return;
        end
        jsonText = fileread(checkpointFile);
        status = jsondecode(jsonText);
    end

    function localClear()
        if manager.exists()
            delete(checkpointFile);
        end
    end
end

