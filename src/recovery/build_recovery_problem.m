function problem = build_recovery_problem(sourceData, referenceSourceData)
%BUILD_RECOVERY_PROBLEM 将缺失回波整理成恢复算法统一输入。
if nargin < 2
    referenceSourceData = [];
end

sourceData = validate_source_data(sourceData);
if ~isempty(referenceSourceData)
    referenceSourceData = validate_source_data(referenceSourceData);
    assert(isequal(size(referenceSourceData.echo), size(sourceData.echo)), ...
        'referenceSourceData.echo 尺寸必须与 sourceData.echo 一致。');
end

[observedAzimuthMask, observedMatrixMask] = resolve_observation_mask(sourceData);
missingMatrixMask = ~observedMatrixMask;
missingAzimuthMask = ~observedAzimuthMask;

assert(any(observedMatrixMask(:)), ...
    '观测掩码全为 false，无法执行恢复。');

problem = struct();
problem.sourceData = sourceData;
problem.referenceSourceData = referenceSourceData;
problem.observedEcho = sourceData.echo;
problem.referenceEcho = [];
problem.track = sourceData.track;
problem.radar = sourceData.radar;
problem.meta = sourceData.meta;
problem.observedAzimuthMask = observedAzimuthMask;
problem.observedMatrixMask = observedMatrixMask;
problem.missingAzimuthMask = missingAzimuthMask;
problem.missingMatrixMask = missingMatrixMask;
problem.numRangeSamples = size(sourceData.echo, 1);
problem.numAzimuthSamples = size(sourceData.echo, 2);
problem.observedFraction = nnz(observedMatrixMask) / numel(observedMatrixMask);
problem.missingFraction = 1 - problem.observedFraction;
problem.totalObservedSamples = nnz(observedMatrixMask);
problem.totalMissingSamples = nnz(missingMatrixMask);
problem.hasReference = false;

if ~isempty(referenceSourceData)
    problem.referenceEcho = referenceSourceData.echo;
    problem.hasReference = true;
end
end
