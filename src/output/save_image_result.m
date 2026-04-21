function files = save_image_result(imageResult, runInfo, config, baseName)
%SAVE_IMAGE_RESULT 保存图像结果，并可选直接显示调试图。
if nargin < 4 || isempty(baseName)
    baseName = 'bp_image';
end

files = struct('matFile', '', 'pngFile', '');
imageData = localResolveImageData(imageResult);

if localShouldShowImageFigure(config)
    localShowImageFigure(imageData, config, baseName);
end

if ~runInfo.enabled
    return;
end

if config.output.saveImageMat
    files.matFile = fullfile(runInfo.matsDir, [baseName, '.mat']);
    safe_save(files.matFile, imageResult, 'imageResult');
end

if config.output.saveImagePng
    files.pngFile = fullfile(runInfo.imagesDir, [baseName, '.png']);
    previewImage = localBuildPreviewImage(imageData, config);
    imwrite(previewImage, files.pngFile);
end
end

function imageData = localResolveImageData(imageResult)
if isstruct(imageResult) && isfield(imageResult, 'image')
    imageData = imageResult.image;
else
    imageData = imageResult;
end
end

function previewImage = localBuildPreviewImage(imageData, config)
imageAmp = abs(imageData);
scaleMode = localGetOutputField(config, 'imageScaleMode', 'linear');

switch lower(string(scaleMode))
    case "log"
        dynamicRangeDb = localGetOutputField(config, 'imageDynamicRangeDb', 40);
        maxValue = max(imageAmp(:));
        if maxValue <= 0
            previewImage = zeros(size(imageAmp), 'double');
            return;
        end
        imageDb = 20 * log10(imageAmp / maxValue + eps);
        imageDb = max(imageDb, -abs(dynamicRangeDb));
        previewImage = (imageDb + abs(dynamicRangeDb)) / abs(dynamicRangeDb);

    otherwise
        scale = mean(imageAmp(:));
        if scale > 0
            previewImage = imageAmp / (scale * max(config.imaging.outputScale, 1));
        else
            previewImage = imageAmp;
        end
        previewImage = min(max(previewImage, 0), 1);
end
end

function value = localGetOutputField(config, fieldName, defaultValue)
value = defaultValue;
if isfield(config, 'output') && isstruct(config.output) && isfield(config.output, fieldName)
    value = config.output.(fieldName);
end
end

function tf = localShouldShowImageFigure(config)
tf = false;
if isfield(config, 'debug') && isstruct(config.debug) && isfield(config.debug, 'showImageFigure')
    tf = logical(config.debug.showImageFigure);
    return;
end

if isfield(config, 'output') && isstruct(config.output) && isfield(config.output, 'showImageFigure')
    tf = logical(config.output.showImageFigure);
end
end

function localShowImageFigure(imageData, config, baseName)
previewImage = localBuildPreviewImage(imageData, config);
figure('Name', sprintf('Image Debug - %s', baseName), 'Color', 'w');
imagesc(previewImage);
axis image;
colormap jet;
colorbar;
xlabel('Y Index');
ylabel('X Index');
title(sprintf('Image Debug: %s', strrep(baseName, '_', '\_')));
end
