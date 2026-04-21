function pre = bp_precompute(sourceData, config)
%BP_PRECOMPUTE 为 BP 成像准备网格、窗函数和常用常量。
%
% 这里不做真正的反投影计算，只负责把成像阶段反复用到的量整理好，
% 避免主循环里混入配置解析和维度准备逻辑。

sourceData = validate_source_data(sourceData);

numType = 'double';
if config.imaging.useSinglePrecision
    numType = 'single';
end

imageSize = config.imaging.grid.numPixels;
xAxis = linspace(config.imaging.grid.xLimits(1), config.imaging.grid.xLimits(2), imageSize);
yAxis = linspace(config.imaging.grid.yLimits(1), config.imaging.grid.yLimits(2), imageSize);
[gridX, gridY] = ndgrid(xAxis, yAxis);

iterWeights = localIterationWeights(config.imaging.iterationLength, numType);
activeIndices = find(sourceData.mask);
if isempty(activeIndices)
    activeIndices = 1:size(sourceData.echo, 2);
end

pre = struct();
pre.numType = numType;
pre.imageSize = imageSize;
pre.xAxis = xAxis;
pre.yAxis = yAxis;
pre.grid = struct( ...
    'xAxis', xAxis, ...
    'yAxis', yAxis, ...
    'gridX', cast(gridX, numType), ...
    'gridY', cast(gridY, numType));
pre.activeIndices = activeIndices;
pre.windows = struct( ...
    'azimuth', cast(hamming(numel(activeIndices)).', numType), ...
    'range', cast(hamming(sourceData.radar.numRangeSamples), numType));
pre.iterWeights = iterWeights;
pre.range = struct( ...
    'numSamples', sourceData.radar.numRangeSamples, ...
    'numSamplesUp', sourceData.radar.numRangeSamplesUp, ...
    'halfIndex', sourceData.radar.numRangeSamplesUp / 2, ...
    'step', sourceData.radar.rangeStep);
pre.constants = struct( ...
    'phaseScale', cast(1i * 2, numType) * sourceData.radar.centerOmega / sourceData.radar.c);
pre.summary = struct( ...
    'numActiveAzimuth', numel(activeIndices), ...
    'numTotalAzimuth', size(sourceData.echo, 2), ...
    'numRangeSamples', sourceData.radar.numRangeSamples, ...
    'numRangeSamplesUp', sourceData.radar.numRangeSamplesUp);
end

function iterWeights = localIterationWeights(lengthValue, numType)
lambda = 1 - 2.8 / lengthValue;
mu = pi / (2 * lengthValue / 3);
gamma = 1 - 3 / lengthValue;

iterWeights = zeros(1, 3);
iterWeights(1) = -(-lambda * exp(-1i * mu) - lambda * exp(1i * mu) - gamma);
iterWeights(2) = -(lambda^2 + lambda * gamma * exp(-1i * mu) + lambda * gamma * exp(1i * mu));
iterWeights(3) = (lambda^2) * gamma;
iterWeights = cast(iterWeights, numType);
end

