function metrics = evaluate_image_quality(referenceImage, targetImage, options)
%EVALUATE_IMAGE_QUALITY 计算基础图像质量指标。
if nargin < 3 || isempty(options)
    options = struct();
end

compareMode = localGetOption(options, 'compareMode', 'amplitude');
[referenceData, targetData] = localResolveCompareData(referenceImage, targetImage, compareMode);

assert(isequal(size(referenceData), size(targetData)), ...
    'referenceImage 与 targetImage 尺寸必须一致。');

errorImage = targetData - referenceData;
mseValue = mean(errorImage(:).^2);
rmseValue = sqrt(mseValue);
maeValue = mean(abs(errorImage(:)));
maxAbsError = max(abs(errorImage(:)));
referenceNorm = norm(referenceData(:));
targetNorm = norm(targetData(:));

metrics = struct();
metrics.compareMode = char(string(compareMode));
metrics.mse = mseValue;
metrics.rmse = rmseValue;
metrics.mae = maeValue;
metrics.maxAbsError = maxAbsError;
metrics.relativeL2Error = localRelativeError(targetData, referenceData);
metrics.referenceEnergy = sum(referenceData(:).^2);
metrics.targetEnergy = sum(targetData(:).^2);

if mseValue == 0
    metrics.psnr = inf;
else
    peakValue = max(abs(referenceData(:)));
    if peakValue <= 0
        metrics.psnr = NaN;
    else
        metrics.psnr = 10 * log10((peakValue^2) / mseValue);
    end
end

if referenceNorm <= eps || targetNorm <= eps
    metrics.normalizedCorrelation = NaN;
else
    metrics.normalizedCorrelation = sum(referenceData(:) .* targetData(:)) ...
        / (referenceNorm * targetNorm);
end
end

function [referenceData, targetData] = localResolveCompareData(referenceImage, targetImage, compareMode)
switch lower(string(compareMode))
    case "complex"
        referenceData = double(referenceImage);
        targetData = double(targetImage);
    otherwise
        referenceData = abs(double(referenceImage));
        targetData = abs(double(targetImage));
end
end

function value = localGetOption(options, fieldName, defaultValue)
value = defaultValue;
if isstruct(options) && isfield(options, fieldName)
    value = options.(fieldName);
end
end

function relErr = localRelativeError(valueNow, valueRef)
denominator = norm(valueRef(:));
if denominator <= eps
    relErr = norm(valueNow(:) - valueRef(:));
else
    relErr = norm(valueNow(:) - valueRef(:)) / denominator;
end
end
