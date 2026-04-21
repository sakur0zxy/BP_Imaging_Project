function [sourceData, info] = apply_degradation(sourceData, config)
%APPLY_DEGRADATION 缺失控制统一入口。

if ~config.enable || strcmp(config.mode, 'none')
    info = summarize_degradation(true(1, size(sourceData.echo, 2)), [], config, sourceData, []);
    return;
end

[mask, gapRanges, seedUsed] = build_gap_mask(sourceData, config);
sourceData.echo(:, ~mask) = 0;
sourceData.mask = mask;
info = summarize_degradation(mask, gapRanges, config, sourceData, seedUsed);
sourceData.meta.degradation = info;
end

