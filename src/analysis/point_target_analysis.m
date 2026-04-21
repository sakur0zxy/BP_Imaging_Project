function result = point_target_analysis(imageResult, config, analysisContext)
%POINT_TARGET_ANALYSIS 点目标分析与图像质量评估统一入口。
if nargin < 3 || isempty(analysisContext)
    analysisContext = struct();
end

runPointAnalysis = localGetAnalysisFlag(config, 'enablePointAnalysis', false);
runImageQuality = localGetAnalysisFlag(config, 'enableImageQuality', false);
if ~runPointAnalysis && ~runImageQuality
    result = struct('enabled', false, 'status', 'disabled');
    return;
end

result = struct();
result.enabled = true;
result.status = 'completed';
result.messages = {};
result.pointTarget = struct('enabled', false, 'status', 'disabled');
result.imageQuality = struct('enabled', false, 'status', 'disabled');
result.reference = struct( ...
    'available', false, ...
    'label', localGetContextField(analysisContext, 'referenceLabel', ''), ...
    'info', localGetContextField(analysisContext, 'referenceInfo', struct()));

if runPointAnalysis
    result.pointTarget = localRunPointTargetAnalysis(imageResult, config);
end

referenceImage = localGetContextField(analysisContext, 'referenceImage', []);
if ~isempty(referenceImage)
    result.reference.available = true;
end

if runImageQuality
    if result.reference.available
        qualityOptions = localGetImageQualityOptions(config);
        metrics = evaluate_image_quality(referenceImage, imageResult.image, qualityOptions);
        result.imageQuality = struct( ...
            'enabled', true, ...
            'status', 'completed', ...
            'metrics', metrics);
    else
        result.status = 'partial';
        result.messages{end + 1} = '未提供参考图像，跳过图像质量评估。';
        result.imageQuality = struct( ...
            'enabled', true, ...
            'status', 'skipped', ...
            'reason', 'missing-reference-image');
    end
end
end

function pointResult = localRunPointTargetAnalysis(imageResult, config)
analysisConfig = localGetPointTargetConfig(config);
imageData = imageResult.image;
imageAbs = abs(imageData);
peakInfo = imageResult.peak;

cutData = localExtractPatch(imageData, peakInfo.row, peakInfo.col, ...
    analysisConfig.cutoutHeight, analysisConfig.cutoutWidth);
upsampledData = localUpsampleFft(cutData, analysisConfig.upsampleFactor);

rotationInfo = localRotateIfNeeded(upsampledData, analysisConfig);
peakUp = localFindPeak(rotationInfo.image);
[xProfile, yProfile] = localBuildProfiles(rotationInfo.image, peakUp);

xSpacing = localAxisSpacing(imageResult.grid.xAxis);
ySpacing = localAxisSpacing(imageResult.grid.yAxis);

pointResult = struct();
pointResult.enabled = true;
pointResult.status = 'completed';
pointResult.peak = peakInfo;
pointResult.cutout = struct( ...
    'image', cutData, ...
    'size', size(cutData));
pointResult.upsampled = struct( ...
    'image', rotationInfo.image, ...
    'rawImage', upsampledData, ...
    'factor', analysisConfig.upsampleFactor, ...
    'peakRow', peakUp(1), ...
    'peakCol', peakUp(2));
pointResult.rotation = rotationInfo.meta;
pointResult.xProfile = localPackProfile(xProfile, analysisConfig.upsampleFactor, xSpacing);
pointResult.yProfile = localPackProfile(yProfile, analysisConfig.upsampleFactor, ySpacing);

if localShouldShowPointTargetFigures(config, analysisConfig)
    localShowPointTargetFigures(pointResult, imageAbs, analysisConfig);
end
end

function packed = localPackProfile(profile, upsampleFactor, spacing)
metrics = localProfileMetrics(profile, upsampleFactor, spacing);
packed = struct();
packed.profileLinear = profile(:);
packed.profileDb = 20 * log10(abs(profile(:)) + eps);
packed.metrics = metrics;
end

function metrics = localProfileMetrics(profile, upsampleFactor, spacing)
metrics = struct();
metrics.pslrDb = localComputePslr(profile);
metrics.islrDb = localComputeIslr(profile);
metrics.irwSamples = localComputeIrw(profile, upsampleFactor, 1);
metrics.irwPhysical = localComputeIrw(profile, upsampleFactor, spacing);
metrics.peakValue = max(abs(profile(:)));
end

function rotationInfo = localRotateIfNeeded(imageData, analysisConfig)
estimatedTiltDeg = localEstimateTilt(imageData, analysisConfig.tiltEdgeFraction);
appliedRotationDeg = 0;
rotatedImage = imageData;

if analysisConfig.enableTiltCorrection ...
        && abs(estimatedTiltDeg) >= analysisConfig.tiltThresholdDeg
    appliedRotationDeg = -estimatedTiltDeg;
    rotatedImage = localRotateComplex(imageData, appliedRotationDeg);
end

rotationInfo = struct();
rotationInfo.image = rotatedImage;
rotationInfo.meta = struct( ...
    'estimatedTiltDeg', estimatedTiltDeg, ...
    'appliedRotationDeg', appliedRotationDeg, ...
    'enabled', analysisConfig.enableTiltCorrection);
end

function [xProfile, yProfile] = localBuildProfiles(imageData, peakPosition)
xProfile = localNormalizeProfile(imageData(:, peakPosition(2)));
yProfile = localNormalizeProfile(imageData(peakPosition(1), :).');
end

function normalized = localNormalizeProfile(profile)
profile = profile(:);
scaleValue = max(abs(profile));
if scaleValue > 0
    normalized = profile / scaleValue;
else
    normalized = profile;
end
end

function patch = localExtractPatch(imageData, peakRow, peakCol, patchHeight, patchWidth)
patch = complex(zeros(patchHeight, patchWidth, class(imageData)));
rowStart = peakRow - patchHeight / 2;
colStart = peakCol - patchWidth / 2;
rowEnd = rowStart + patchHeight - 1;
colEnd = colStart + patchWidth - 1;

srcRowStart = max(1, rowStart);
srcColStart = max(1, colStart);
srcRowEnd = min(size(imageData, 1), rowEnd);
srcColEnd = min(size(imageData, 2), colEnd);

dstRowStart = srcRowStart - rowStart + 1;
dstColStart = srcColStart - colStart + 1;
dstRowEnd = dstRowStart + (srcRowEnd - srcRowStart);
dstColEnd = dstColStart + (srcColEnd - srcColStart);

patch(dstRowStart:dstRowEnd, dstColStart:dstColEnd) = ...
    imageData(srcRowStart:srcRowEnd, srcColStart:srcColEnd);
end

function upsampled = localUpsampleFft(imageData, upsampleFactor)
[height, width] = size(imageData);
heightUp = height * upsampleFactor;
widthUp = width * upsampleFactor;

spectrum = fftshift(fft2(fftshift(imageData)));
spectrumUp = complex(zeros(heightUp, widthUp, class(spectrum)));

rowStart = floor(heightUp / 2) - floor(height / 2) + 1;
colStart = floor(widthUp / 2) - floor(width / 2) + 1;
rowEnd = rowStart + height - 1;
colEnd = colStart + width - 1;

spectrumUp(rowStart:rowEnd, colStart:colEnd) = spectrum;
upsampled = fftshift(ifft2(fftshift(spectrumUp)));
end

function peakPosition = localFindPeak(imageData)
[~, peakIndex] = max(abs(imageData(:)));
[peakRow, peakCol] = ind2sub(size(imageData), peakIndex);
peakPosition = [peakRow, peakCol];
end

function spacing = localAxisSpacing(axisValues)
if numel(axisValues) < 2
    spacing = 1;
else
    spacing = abs(axisValues(2) - axisValues(1));
end
end

function pslrDb = localComputePslr(profile)
signal = abs(profile(:));
if isempty(signal) || max(signal) <= 0
    pslrDb = NaN;
    return;
end

peakIndices = localFindLocalPeaks(signal);
if isempty(peakIndices)
    pslrDb = NaN;
    return;
end

peakValues = sort(signal(peakIndices), 'descend');
if numel(peakValues) < 2
    pslrDb = -Inf;
else
    pslrDb = 20 * log10(peakValues(2) / peakValues(1));
end
end

function islrDb = localComputeIslr(profile)
signal = abs(profile(:));
if isempty(signal) || max(signal) <= 0
    islrDb = NaN;
    return;
end

[~, peakIndex] = max(signal);
[leftIndex, rightIndex] = localFindMainlobeBounds(signal, peakIndex);
mainPower = sum(signal(leftIndex:rightIndex).^2);
allPower = sum(signal.^2);

if mainPower <= 0 || allPower <= mainPower
    islrDb = -Inf;
else
    islrDb = 10 * log10((allPower - mainPower) / mainPower);
end
end

function irwValue = localComputeIrw(profile, upsampleFactor, spacing)
signal = abs(profile(:));
if isempty(signal)
    irwValue = NaN;
    return;
end

[peakValue, peakIndex] = max(signal);
if peakValue <= 0
    irwValue = NaN;
    return;
end

threshold = peakValue * 10^(-3 / 20);

leftIndex = peakIndex;
while leftIndex > 1 && signal(leftIndex) > threshold
    leftIndex = leftIndex - 1;
end
if leftIndex == 1 && signal(leftIndex) > threshold
    irwValue = NaN;
    return;
end

rightIndex = peakIndex;
while rightIndex < numel(signal) && signal(rightIndex) > threshold
    rightIndex = rightIndex + 1;
end
if rightIndex == numel(signal) && signal(rightIndex) > threshold
    irwValue = NaN;
    return;
end

leftCross = localInterpolateCross(leftIndex, signal(leftIndex), leftIndex + 1, signal(leftIndex + 1), threshold);
rightCross = localInterpolateCross(rightIndex - 1, signal(rightIndex - 1), rightIndex, signal(rightIndex), threshold);
irwValue = (rightCross - leftCross) / upsampleFactor * spacing;
end

function peakIndices = localFindLocalPeaks(signal)
numPoints = numel(signal);
if numPoints < 3
    peakIndices = (1:numPoints).';
    return;
end

peakIndices = find(signal(2:numPoints-1) >= signal(1:numPoints-2) ...
    & signal(2:numPoints-1) > signal(3:numPoints)) + 1;
if signal(1) > signal(2)
    peakIndices = [1; peakIndices(:)];
end
if signal(end) > signal(end - 1)
    peakIndices = [peakIndices(:); numPoints];
end
peakIndices = unique(peakIndices(:));
end

function [leftIndex, rightIndex] = localFindMainlobeBounds(signal, peakIndex)
valleyIndices = find(signal(2:end-1) <= signal(1:end-2) ...
    & signal(2:end-1) < signal(3:end)) + 1;
leftCandidates = valleyIndices(valleyIndices < peakIndex);
rightCandidates = valleyIndices(valleyIndices > peakIndex);

if isempty(leftCandidates)
    leftIndex = max(1, peakIndex - 1);
else
    leftIndex = leftCandidates(end);
end

if isempty(rightCandidates)
    rightIndex = min(numel(signal), peakIndex + 1);
else
    rightIndex = rightCandidates(1);
end
end

function xValue = localInterpolateCross(x1, y1, x2, y2, targetY)
if abs(y2 - y1) < eps
    xValue = (x1 + x2) / 2;
else
    xValue = x1 + (targetY - y1) * (x2 - x1) / (y2 - y1);
end
end

function tiltDeg = localEstimateTilt(imageData, edgeFraction)
amplitude = abs(imageData);
if isempty(amplitude) || max(amplitude(:)) <= 0
    tiltDeg = 0;
    return;
end

[~, peakRows] = max(amplitude, [], 1);
numCols = size(imageData, 2);
edgeCount = ceil(numCols * edgeFraction);
edgeCount = max(edgeCount, 1);
edgeCount = min(edgeCount, floor(numCols / 2));
if edgeCount < 1
    tiltDeg = 0;
    return;
end

usedCols = [1:edgeCount, (numCols - edgeCount + 1):numCols];
usedCols = unique(usedCols(:));
if numel(usedCols) < 2
    tiltDeg = 0;
    return;
end

xValues = usedCols - (numCols + 1) / 2;
yValues = peakRows(usedCols) - (size(imageData, 1) + 1) / 2;
fitCoefficients = polyfit(xValues(:), yValues(:), 1);
tiltDeg = localNormalizeAngle(atan2d(fitCoefficients(1), 1));
if tiltDeg > 45
    tiltDeg = tiltDeg - 90;
elseif tiltDeg <= -45
    tiltDeg = tiltDeg + 90;
end
end

function angleOut = localNormalizeAngle(angleIn)
angleOut = mod(angleIn + 90, 180) - 90;
end

function rotatedImage = localRotateComplex(imageData, angleDeg)
if abs(angleDeg) < eps
    rotatedImage = imageData;
    return;
end

[height, width] = size(imageData);
[gridY, gridX] = ndgrid(1:height, 1:width);
centerX = (width + 1) / 2;
centerY = (height + 1) / 2;

xValue = gridX - centerX;
yValue = gridY - centerY;
angleRad = deg2rad(angleDeg);

xInput = xValue * cos(angleRad) + yValue * sin(angleRad) + centerX;
yInput = -xValue * sin(angleRad) + yValue * cos(angleRad) + centerY;

realPart = interp2(real(imageData), xInput, yInput, 'linear', 0);
imagPart = interp2(imag(imageData), xInput, yInput, 'linear', 0);
rotatedImage = realPart + 1i * imagPart;
end

function analysisConfig = localGetPointTargetConfig(config)
analysisConfig = struct( ...
    'cutoutHeight', 32, ...
    'cutoutWidth', 32, ...
    'upsampleFactor', 16, ...
    'enableTiltCorrection', true, ...
    'tiltThresholdDeg', 0.0, ...
    'tiltEdgeFraction', 0.2);

if isfield(config, 'analysis') && isstruct(config.analysis) ...
        && isfield(config.analysis, 'pointTarget') ...
        && isstruct(config.analysis.pointTarget)
    analysisConfig = merge_structs(analysisConfig, config.analysis.pointTarget);
end
end

function options = localGetImageQualityOptions(config)
options = struct('compareMode', 'amplitude');
if isfield(config, 'analysis') && isstruct(config.analysis) ...
        && isfield(config.analysis, 'imageQuality') ...
        && isstruct(config.analysis.imageQuality)
    options = merge_structs(options, config.analysis.imageQuality);
end
end

function value = localGetAnalysisFlag(config, fieldName, defaultValue)
value = defaultValue;
if isfield(config, 'analysis') && isstruct(config.analysis) && isfield(config.analysis, fieldName)
    value = config.analysis.(fieldName);
end
end

function value = localGetContextField(context, fieldName, defaultValue)
value = defaultValue;
if isstruct(context) && isfield(context, fieldName)
    value = context.(fieldName);
end
end

function tf = localShouldShowPointTargetFigures(config, analysisConfig)
tf = false;
if isfield(config, 'debug') && isstruct(config.debug) ...
        && isfield(config.debug, 'showPointTargetFigures')
    tf = logical(config.debug.showPointTargetFigures);
    return;
end

if isfield(analysisConfig, 'showFigures')
    tf = logical(analysisConfig.showFigures);
end
end

function localShowPointTargetFigures(pointResult, imageAbs, analysisConfig)
figure('Name', 'Point Target Debug - Full Image', 'Color', 'w');
imagesc(imageAbs);
axis image;
colormap jet;
colorbar;
hold on;
plot(pointResult.peak.col, pointResult.peak.row, 'wx', 'LineWidth', 1.5, 'MarkerSize', 10);
hold off;
title('Point Target Debug: Full Image Peak');
xlabel('Y Index');
ylabel('X Index');

figure('Name', 'Point Target Debug - Cutout', 'Color', 'w');
imagesc(abs(pointResult.cutout.image));
axis image;
colormap jet;
colorbar;
title('Point Target Debug: Cutout');
xlabel('Cutout Y');
ylabel('Cutout X');

figure('Name', 'Point Target Debug - Upsampled', 'Color', 'w');
imagesc(abs(pointResult.upsampled.image));
axis image;
colormap jet;
colorbar;
hold on;
plot(pointResult.upsampled.peakCol, pointResult.upsampled.peakRow, 'wx', 'LineWidth', 1.5, 'MarkerSize', 10);
hold off;
title(sprintf('Upsampled Slice (x%d, rot %.2f deg)', ...
    analysisConfig.upsampleFactor, pointResult.rotation.appliedRotationDeg));
xlabel('Upsampled Y');
ylabel('Upsampled X');

figure('Name', 'Point Target Debug - Profiles', 'Color', 'w');
tiledlayout(1, 2);

nexttile;
plot(pointResult.xProfile.profileDb, 'b', 'LineWidth', 1.1);
grid on;
title(sprintf('X Profile | PSLR %.2f dB | ISLR %.2f dB', ...
    pointResult.xProfile.metrics.pslrDb, pointResult.xProfile.metrics.islrDb));
xlabel('Sample');
ylabel('Amplitude (dB)');

nexttile;
plot(pointResult.yProfile.profileDb, 'r', 'LineWidth', 1.1);
grid on;
title(sprintf('Y Profile | PSLR %.2f dB | ISLR %.2f dB', ...
    pointResult.yProfile.metrics.pslrDb, pointResult.yProfile.metrics.islrDb));
xlabel('Sample');
ylabel('Amplitude (dB)');
end
