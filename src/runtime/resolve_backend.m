function backend = resolve_backend(config)
%RESOLVE_BACKEND 选择 CPU 或 GPU 后端。

backend = struct();
backend.name = 'cpu';
backend.useGpu = false;

preferGpu = isfield(config.runtime, 'preferGpu') && config.runtime.preferGpu;
if ~preferGpu
    return;
end

try
    hasGpu = gpuDeviceCount("available") > 0;
catch
    try
        hasGpu = gpuDeviceCount > 0;
    catch
        hasGpu = false;
    end
end

if hasGpu
    backend.name = 'gpu';
    backend.useGpu = true;
end
end

