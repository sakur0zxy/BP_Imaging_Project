function save_checkpoint(runInfo, status)
%SAVE_CHECKPOINT 保存当前运行 checkpoint。

if ~runInfo.enabled
    return;
end

manager = checkpoint_manager(runInfo.checkpointFile);
manager.save(status);
end

