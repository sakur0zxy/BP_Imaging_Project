function config = normalize_legacy_config_aliases(config, modeName)
%NORMALIZE_LEGACY_CONFIG_ALIASES 兼容旧仓库常见配置字段名。

if nargin < 2
    modeName = '';
end

if isfield(config, 'path')
    if isfield(config.path, 'dataRoot')
        if strcmp(modeName, 'sim')
            config.path.simDataRoot = config.path.dataRoot;
        else
            config.path.realDataRoot = config.path.dataRoot;
        end
    end
    if isfield(config.path, 'dataRootCandidates')
        config.path.realDataCandidates = config.path.dataRootCandidates;
    end
end

if isfield(config, 'general')
    if isfield(config.general, 'numDataFiles')
        config.source.numFiles = config.general.numDataFiles;
    end
    if isfield(config.general, 'dataFilePattern')
        config.source.filePattern = config.general.dataFilePattern;
    end
    if isfield(config.general, 'dataVariableName')
        config.source.variableName = config.general.dataVariableName;
    end
    if isfield(config.general, 'dataFieldMap')
        config.source.fieldMap = config.general.dataFieldMap;
    end
end

if isfield(config, 'interruption')
    config.degradation = merge_structs(config.degradation, config.interruption);
end

if isfield(config, 'image')
    if isfield(config.image, 'numPixels')
        config.imaging.grid.numPixels = config.image.numPixels;
    end
    if isfield(config.image, 'xLimits')
        config.imaging.grid.xLimits = config.image.xLimits;
    end
    if isfield(config.image, 'yLimits')
        config.imaging.grid.yLimits = config.image.yLimits;
    end
end

if isfield(config, 'iteration') && isfield(config.iteration, 'J')
    config.imaging.iterationLength = config.iteration.J;
end

if isfield(config, 'output') && isfield(config.output, 'enableOutput')
    config.output.enableSave = config.output.enableOutput;
end
end

