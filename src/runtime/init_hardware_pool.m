function poolInfo = init_hardware_pool(config)
%INIT_HARDWARE_POOL 初始化并行环境。

poolInfo = struct('enabled', false, 'workers', 0);

if ~isfield(config.runtime, 'useParallel') || ~config.runtime.useParallel
    return;
end

try
    pool = gcp('nocreate');
    if isempty(pool)
        if isempty(config.runtime.maxWorkers)
            pool = parpool();
        else
            pool = parpool(config.runtime.maxWorkers);
        end
    end
    poolInfo.enabled = true;
    poolInfo.workers = pool.NumWorkers;
catch
    poolInfo.enabled = false;
    poolInfo.workers = 0;
end
end

