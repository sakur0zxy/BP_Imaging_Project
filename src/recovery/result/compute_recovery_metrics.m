function metrics = compute_recovery_metrics(echoRec, problem)
%COMPUTE_RECOVERY_METRICS 统一计算恢复指标。
metrics = struct();
metrics.observedConsistencyErr = localRelativeError( ...
    echoRec(problem.observedMatrixMask), ...
    problem.observedEcho(problem.observedMatrixMask));
metrics.maxObservedAbsErr = localMaxAbsError( ...
    echoRec(problem.observedMatrixMask) - problem.observedEcho(problem.observedMatrixMask));
metrics.observedFraction = problem.observedFraction;
metrics.missingFraction = problem.missingFraction;

if problem.hasReference
    metrics.wholeRelErr = localRelativeError(echoRec, problem.referenceEcho);
    if any(problem.missingMatrixMask(:))
        metrics.missingRelErr = localRelativeError( ...
            echoRec(problem.missingMatrixMask), ...
            problem.referenceEcho(problem.missingMatrixMask));
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
