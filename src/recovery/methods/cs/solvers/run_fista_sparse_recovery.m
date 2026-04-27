function [echoRec, info] = run_fista_sparse_recovery(observedEcho, observedMask, solverConfig, transformFcn, inverseTransformFcn, methodName)
%RUN_FISTA_SPARSE_RECOVERY 通用 FISTA/ISTA 稀疏恢复求解器。
dataClass = class(observedEcho);
observedMask = logical(observedMask);

[dataNorm, scaleValue] = localNormalizeEcho(observedEcho, solverConfig.normalizeInput);
obsData = dataNorm;
xPrev = obsData;
yPrev = xPrev;
tPrev = 1;
relHistory = zeros(solverConfig.maxIter, 1);
objHistory = zeros(solverConfig.maxIter, 1);

timeStart = tic;
for iter = 1:solverConfig.maxIter
    gradValue = observedMask .* (yPrev - obsData);
    xNow = yPrev - gradValue;
    xNow = localApplySoftThreshold(xNow, solverConfig.lambda, transformFcn, inverseTransformFcn);
    xNow(observedMask) = obsData(observedMask);

    relChange = norm(double(xNow(:) - xPrev(:))) / (norm(double(xPrev(:))) + eps);
    relHistory(iter) = relChange;
    objHistory(iter) = localObjective(xNow, obsData, observedMask, solverConfig.lambda, transformFcn);

    if solverConfig.useFista
        tNow = (1 + sqrt(1 + 4 * tPrev^2)) / 2;
        yNow = xNow + ((tPrev - 1) / tNow) * (xNow - xPrev);
        yNow(observedMask) = obsData(observedMask);
        tPrev = tNow;
        yPrev = yNow;
    else
        yPrev = xNow;
    end

    xPrev = xNow;

    if solverConfig.verbose && (iter == 1 || mod(iter, 20) == 0 || iter == solverConfig.maxIter)
        fprintf('  [%s] iter %d/%d, relChange = %.3e\n', ...
            methodName, iter, solverConfig.maxIter, relChange);
    end

    if relChange <= solverConfig.tol
        relHistory = relHistory(1:iter);
        objHistory = objHistory(1:iter);
        break;
    end
end
timeUsed = toc(timeStart);

echoRec = xPrev * scaleValue;
echoRec(observedMask) = observedEcho(observedMask);
echoRec = cast(echoRec, dataClass);

obsDiff = echoRec(observedMask) - observedEcho(observedMask);
info = struct();
info.method = methodName;
info.iterations = numel(relHistory);
info.converged = relHistory(end) <= solverConfig.tol;
info.lambda = solverConfig.lambda;
info.useFista = solverConfig.useFista;
info.relChangeHistory = relHistory;
info.objectiveHistory = objHistory;
info.scaleValue = scaleValue;
info.runtimeSec = timeUsed;
info.observedConsistencyErr = localRelativeError(echoRec(observedMask), observedEcho(observedMask));
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

function dataOut = localApplySoftThreshold(dataIn, thresh, transformFcn, inverseTransformFcn)
spec = transformFcn(dataIn);
spec = localComplexSoft(spec, thresh);
dataOut = inverseTransformFcn(spec);
end

function objValue = localObjective(xNow, obsData, observedMask, lambda, transformFcn)
fitValue = observedMask .* (xNow - obsData);
specValue = transformFcn(xNow);
objValue = 0.5 * sum(abs(fitValue(:)).^2) + lambda * sum(abs(specValue(:)));
end

function valueOut = localComplexSoft(valueIn, thresh)
amp = abs(valueIn);
scale = max(amp - thresh, 0) ./ (amp + eps);
valueOut = scale .* valueIn;
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
