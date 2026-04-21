function result = recover_1d(model, config)
%RECOVER_1D 使用方位向 FFT 稀疏先验恢复缺失回波。
localValidateInputs(model, config);

lambda = config.lambda1D;
[echoRec, info] = localRunFista(model.observedEcho, model.observedMatrixMask, lambda, ...
    @localProxAzimuth, @localTransformAzimuth, config, '1d-azimuth-fft');

result = struct();
result.echo = echoRec;
result.info = info;
result.metrics = localBuildMetrics(echoRec, model);
end

function localValidateInputs(model, config)
assert(isstruct(model) && isscalar(model), 'model 必须是标量结构体。');
assert(isfield(model, 'observedEcho') && isnumeric(model.observedEcho), ...
    'model.observedEcho 缺失或类型错误。');
assert(isfield(model, 'observedMatrixMask') && islogical(model.observedMatrixMask), ...
    'model.observedMatrixMask 缺失或类型错误。');
assert(isequal(size(model.observedEcho), size(model.observedMatrixMask)), ...
    'model.observedEcho 与 model.observedMatrixMask 尺寸不一致。');
assert(isstruct(config) && isscalar(config), 'config 必须是标量结构体。');
assert(isfield(config, 'lambda1D') && config.lambda1D >= 0, ...
    'config.lambda1D 必须大于等于 0。');
end

function dataOut = localProxAzimuth(dataIn, thresh)
spec = localTransformAzimuth(dataIn);
spec = localComplexSoft(spec, thresh);
dataOut = localInverseTransformAzimuth(spec);
end

function spec = localTransformAzimuth(dataIn)
numAz = size(dataIn, 2);
spec = fft(dataIn, [], 2) / sqrt(numAz);
end

function dataOut = localInverseTransformAzimuth(spec)
numAz = size(spec, 2);
dataOut = ifft(spec, [], 2) * sqrt(numAz);
end

function [echoRec, info] = localRunFista(echoCut, maskObs, lambda, proxFcn, transformFcn, config, methodName)
dataClass = class(echoCut);
maskObs = logical(maskObs);

[dataNorm, scaleValue] = localNormalizeEcho(echoCut, config.normalizeInput);
obsData = dataNorm;
xPrev = obsData;
yPrev = xPrev;
tPrev = 1;
relHistory = zeros(config.maxIter, 1);
objHistory = zeros(config.maxIter, 1);

timeStart = tic;
for iter = 1:config.maxIter
    gradValue = maskObs .* (yPrev - obsData);
    xNow = yPrev - gradValue;
    xNow = proxFcn(xNow, lambda);
    xNow(maskObs) = obsData(maskObs);

    relChange = norm(double(xNow(:) - xPrev(:))) / (norm(double(xPrev(:))) + eps);
    relHistory(iter) = relChange;
    objHistory(iter) = localObjective(xNow, obsData, maskObs, lambda, transformFcn);

    if config.useFista
        tNow = (1 + sqrt(1 + 4 * tPrev^2)) / 2;
        yNow = xNow + ((tPrev - 1) / tNow) * (xNow - xPrev);
        yNow(maskObs) = obsData(maskObs);
        tPrev = tNow;
        yPrev = yNow;
    else
        yPrev = xNow;
    end

    xPrev = xNow;

    if config.verbose && (iter == 1 || mod(iter, 20) == 0 || iter == config.maxIter)
        fprintf('  [%s] iter %d/%d, relChange = %.3e\n', ...
            methodName, iter, config.maxIter, relChange);
    end

    if relChange <= config.tol
        relHistory = relHistory(1:iter);
        objHistory = objHistory(1:iter);
        break;
    end
end
timeUsed = toc(timeStart);

echoRec = xPrev * scaleValue;
echoRec(maskObs) = echoCut(maskObs);
echoRec = cast(echoRec, dataClass);

obsDiff = echoRec(maskObs) - echoCut(maskObs);
info = struct();
info.method = methodName;
info.iterations = numel(relHistory);
info.converged = relHistory(end) <= config.tol;
info.lambda = lambda;
info.relChangeHistory = relHistory;
info.objectiveHistory = objHistory;
info.scaleValue = scaleValue;
info.runtimeSec = timeUsed;
info.observedConsistencyErr = localRelativeError(echoRec(maskObs), echoCut(maskObs));
info.maxObservedAbsErr = localMaxAbsError(obsDiff);
end

function [dataNorm, scaleValue] = localNormalizeEcho(dataIn, doNormalize)
if doNormalize
    scaleValue = max(abs(dataIn(:)));
else
    scaleValue = 1;
end

if isempty(scaleValue) || ~isfinite(scaleValue) || scaleValue <= 0
    scaleValue = 1;
end
dataNorm = dataIn / scaleValue;
end

function objValue = localObjective(xNow, obsData, maskObs, lambda, transformFcn)
fitValue = maskObs .* (xNow - obsData);
specValue = transformFcn(xNow);
objValue = 0.5 * sum(abs(fitValue(:)).^2) + lambda * sum(abs(specValue(:)));
end

function valueOut = localComplexSoft(valueIn, thresh)
amp = abs(valueIn);
scale = max(amp - thresh, 0) ./ (amp + eps);
valueOut = scale .* valueIn;
end

function metrics = localBuildMetrics(echoRec, model)
metrics = struct();
metrics.observedConsistencyErr = localRelativeError( ...
    echoRec(model.observedMatrixMask), ...
    model.observedEcho(model.observedMatrixMask));
metrics.maxObservedAbsErr = localMaxAbsError( ...
    echoRec(model.observedMatrixMask) - model.observedEcho(model.observedMatrixMask));
metrics.observedFraction = model.observedFraction;
metrics.missingFraction = model.missingFraction;

if model.hasReference
    metrics.wholeRelErr = localRelativeError(echoRec, model.referenceEcho);
    if any(model.missingMatrixMask(:))
        metrics.missingRelErr = localRelativeError( ...
            echoRec(model.missingMatrixMask), ...
            model.referenceEcho(model.missingMatrixMask));
    else
        metrics.missingRelErr = 0;
    end
else
    metrics.wholeRelErr = NaN;
    metrics.missingRelErr = NaN;
end
end

function relErr = localRelativeError(valueNow, valueRef)
den = norm(double(valueRef(:)));
if den <= eps
    relErr = norm(double(valueNow(:) - valueRef(:)));
else
    relErr = norm(double(valueNow(:) - valueRef(:))) / den;
end
end

function maxErr = localMaxAbsError(diffValue)
if isempty(diffValue)
    maxErr = 0;
else
    maxErr = max(abs(diffValue(:)));
end
end
