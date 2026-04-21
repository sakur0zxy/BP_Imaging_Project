function [imageData, meta] = bp_backprojection(sourceData, pre, config)
%BP_BACKPROJECTION 执行 BP 反投影主循环。

computeTimer = tic;

trackX = cast(sourceData.track.x, pre.numType);
trackY = cast(sourceData.track.y, pre.numType);
trackZ = cast(sourceData.track.z, pre.numType);
echoData = cast(sourceData.echo, pre.numType);

imageSize = pre.imageSize;
imageData = complex(zeros(imageSize, imageSize, pre.numType));
history1 = imageData;
history2 = imageData;
history3 = imageData;

showProgress = config.imaging.showProgress;
progressStep = config.imaging.progressStep;
progressScale = config.imaging.progressScale;
handleImage = [];

if showProgress
    figure('Name', 'BP Imaging Progress', 'Color', 'w');
    handleImage = imagesc(abs(imageData));
    title('BP Imaging Progress');
    xlabel('Range Axis');
    ylabel('Azimuth Axis');
    axis image;
    colormap jet;
end

usedCount = 0;
for idx = 1:numel(pre.activeIndices)
    azimuthIndex = pre.activeIndices(idx);
    usedCount = usedCount + 1;

    xPos = trackX(azimuthIndex);
    yPos = trackY(azimuthIndex);
    zPos = trackZ(azimuthIndex);

    onePulse = echoData(:, azimuthIndex) * pre.windows.azimuth(idx);
    onePulse = fftshift(fft(onePulse .* pre.windows.range, sourceData.radar.numRangeSamplesUp));

    refRange = sqrt(xPos.^2 + yPos.^2 + zPos.^2);
    rangeOffset = sqrt((xPos - pre.grid.gridX).^2 + (yPos - pre.grid.gridY).^2 + zPos.^2) - refRange;

    sampleIndex = round(-double(rangeOffset) / double(pre.range.step)) + pre.range.halfIndex;
    sampleIndex(sampleIndex < 1) = 1;
    sampleIndex(sampleIndex > sourceData.radar.numRangeSamplesUp) = sourceData.radar.numRangeSamplesUp;
    validMask = sampleIndex > 1 & sampleIndex < sourceData.radar.numRangeSamplesUp;

    currentImage = onePulse(sampleIndex) .* cast(validMask, pre.numType) ...
        .* exp(pre.constants.phaseScale * rangeOffset);
    imageData = currentImage ...
        + pre.iterWeights(1) * history1 ...
        + pre.iterWeights(2) * history2 ...
        + pre.iterWeights(3) * history3;

    history3 = history2;
    history2 = history1;
    history1 = imageData;

    if showProgress && (idx == 1 || mod(idx, progressStep) == 0 || idx == numel(pre.activeIndices))
        scale = mean(abs(imageData(:)));
        if scale > 0
            set(handleImage, 'CData', abs(imageData) / (scale * progressScale));
        else
            set(handleImage, 'CData', abs(imageData));
        end
        drawnow limitrate;
    end
end

meta = struct();
meta.numericClass = pre.numType;
meta.usedAzimuthCount = usedCount;
meta.totalAzimuthCount = size(sourceData.echo, 2);
meta.activeAzimuthIndices = pre.activeIndices;
meta.imageSize = imageSize;
meta.numRangeSamples = sourceData.radar.numRangeSamples;
meta.numRangeSamplesUp = sourceData.radar.numRangeSamplesUp;
meta.rangeStep = sourceData.radar.rangeStep;
meta.elapsedSeconds = toc(computeTimer);
meta.peakAmplitude = max(abs(imageData(:)));
meta.meanAmplitude = mean(abs(imageData(:)));
end

