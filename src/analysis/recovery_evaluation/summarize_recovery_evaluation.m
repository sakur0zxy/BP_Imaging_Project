function summary = summarize_recovery_evaluation(caseResults, comparisonResults, evalConfig)
%SUMMARIZE_RECOVERY_EVALUATION 基于已有结果生成结构化结论。
summary = struct();
summary.highLevelFindings = {};
summary.perCaseFindings = struct();
summary.bestMethodIfAny = '';
summary.riskOrLimitations = {};
summary.modeSpecificNotes = {};
summary.meta = struct('evaluationMode', evalConfig.evaluationMode);

if strcmp(evalConfig.evaluationMode, 'simulation')
    summary = localSummarizeSimulation(summary, comparisonResults);
else
    summary = localSummarizeReal(summary, comparisonResults);
end

summary.riskOrLimitations = [summary.riskOrLimitations, localCollectStatusRisks(caseResults, comparisonResults)]; %#ok<AGROW>
summary.meta.caseNames = fieldnames(caseResults);
summary.meta.comparisonNames = fieldnames(comparisonResults);
end

function summary = localSummarizeSimulation(summary, comparisonResults)
interruptedGap = localGetMetricValue(comparisonResults, 'full_vs_interrupted', 'relativeL2Error', NaN);
psnrInterrupted = localGetMetricValue(comparisonResults, 'full_vs_interrupted', 'psnr', NaN);

methodNames = {'cs_1d', 'cs_2d'};
scores = nan(1, numel(methodNames));
for idx = 1:numel(methodNames)
    methodName = methodNames{idx};
    comparisonName = ['full_vs_recovered_', methodName];
    relL2 = localGetMetricValue(comparisonResults, comparisonName, 'relativeL2Error', NaN);
    psnrValue = localGetMetricValue(comparisonResults, comparisonName, 'psnr', NaN);
    corrValue = localGetMetricValue(comparisonResults, comparisonName, 'normalizedCorrelation', NaN);

    improved = isfinite(interruptedGap) && isfinite(relL2) && relL2 < interruptedGap;
    summary.perCaseFindings.(['recovered_', methodName]) = struct( ...
        'closerToFullThanInterrupted', improved, ...
        'relativeL2Error', relL2, ...
        'psnr', psnrValue, ...
        'normalizedCorrelation', corrValue);

    if improved
        summary.highLevelFindings{end + 1} = sprintf('%s 相比 interrupted 更接近 full。', upper(methodName)); %#ok<AGROW>
    else
        summary.highLevelFindings{end + 1} = sprintf('%s 没有明显优于 interrupted。', upper(methodName)); %#ok<AGROW>
    end

    if isfinite(relL2) && isfinite(corrValue)
        scores(idx) = -relL2 + corrValue;
        if isfinite(psnrValue)
            scores(idx) = scores(idx) + psnrValue / 100;
        end
    end
end

if all(isnan(scores))
    summary.bestMethodIfAny = '';
else
    [~, bestIdx] = max(scores);
    summary.bestMethodIfAny = methodNames{bestIdx};
end

if ~isempty(summary.bestMethodIfAny)
    summary.highLevelFindings{end + 1} = sprintf('仿真口径下更优的方法是 %s。', upper(summary.bestMethodIfAny));
end

summary.modeSpecificNotes = { ...
    'simulation 模式下优先看 PSNR、relativeL2Error 和 normalizedCorrelation。', ...
    sprintf('interrupted 相对 full 的 PSNR=%.4g，relativeL2Error=%.4g。', ...
        psnrInterrupted, interruptedGap)};
end

function summary = localSummarizeReal(summary, comparisonResults)
interruptedCloseness = localGetMetricValue(comparisonResults, 'full_vs_interrupted', 'closenessScore', NaN);

methodNames = {'cs_1d', 'cs_2d'};
closenessScores = nan(1, numel(methodNames));
improvementVotes = nan(1, numel(methodNames));

for idx = 1:numel(methodNames)
    methodName = methodNames{idx};
    fullComparison = ['full_vs_recovered_', methodName];
    interruptedComparison = ['interrupted_vs_recovered_', methodName];

    closenessScores(idx) = localGetMetricValue(comparisonResults, fullComparison, 'closenessScore', NaN);
    improvementVotes(idx) = localGetMetricValue(comparisonResults, interruptedComparison, 'improvementVotes', NaN);
    peakShiftPixels = localGetMetricValue(comparisonResults, fullComparison, 'peakShiftPixels', NaN);

    improved = isfinite(improvementVotes(idx)) && improvementVotes(idx) > 0;
    closerThanInterrupted = isfinite(interruptedCloseness) && isfinite(closenessScores(idx)) ...
        && closenessScores(idx) < interruptedCloseness;

    summary.perCaseFindings.(['recovered_', methodName]) = struct( ...
        'improvementVotes', improvementVotes(idx), ...
        'closenessToFull', closenessScores(idx), ...
        'closerToFullThanInterrupted', closerThanInterrupted, ...
        'peakShiftPixels', peakShiftPixels);

    if improved || closerThanInterrupted
        summary.highLevelFindings{end + 1} = sprintf('%s 在实测口径下优于 interrupted。', upper(methodName)); %#ok<AGROW>
    else
        summary.highLevelFindings{end + 1} = sprintf('%s 在实测口径下没有明显优于 interrupted。', upper(methodName)); %#ok<AGROW>
    end
end

if all(isnan(closenessScores))
    summary.bestMethodIfAny = '';
else
    scoreVector = -closenessScores + improvementVotes / 10;
    [~, bestIdx] = max(scoreVector);
    summary.bestMethodIfAny = methodNames{bestIdx};
end

if ~isempty(summary.bestMethodIfAny)
    summary.highLevelFindings{end + 1} = sprintf('实测口径下更优的方法是 %s。', upper(summary.bestMethodIfAny));
end

summary.modeSpecificNotes = { ...
    'real 模式下优先看 PSLR、ISLR、IRW 和 peak shift。', ...
    sprintf('interrupted 相对 full 的 closenessScore=%.4g。', interruptedCloseness)};
end

function risks = localCollectStatusRisks(caseResults, comparisonResults)
risks = {};

caseNames = fieldnames(caseResults);
for idx = 1:numel(caseNames)
    caseStatus = localGetField(caseResults.(caseNames{idx}), 'status', 'completed');
    if ~strcmp(caseStatus, 'completed')
        risks{end + 1} = sprintf('Case %s status=%s。', caseNames{idx}, caseStatus); %#ok<AGROW>
    end
end

comparisonNames = fieldnames(comparisonResults);
for idx = 1:numel(comparisonNames)
    comparisonStatus = localGetField(comparisonResults.(comparisonNames{idx}), 'status', 'completed');
    if ~strcmp(comparisonStatus, 'completed')
        risks{end + 1} = sprintf('Comparison %s status=%s。', comparisonNames{idx}, comparisonStatus); %#ok<AGROW>
    end
end
end

function value = localGetMetricValue(comparisonResults, comparisonName, metricName, defaultValue)
value = defaultValue;
if ~isfield(comparisonResults, comparisonName)
    return;
end

metrics = comparisonResults.(comparisonName).metrics;
if isstruct(metrics) && isfield(metrics, 'metricValues') ...
        && isstruct(metrics.metricValues) && isfield(metrics.metricValues, metricName)
    value = metrics.metricValues.(metricName);
end
end

function value = localGetField(data, fieldName, defaultValue)
value = defaultValue;
if isstruct(data) && isfield(data, fieldName)
    value = data.(fieldName);
end
end
