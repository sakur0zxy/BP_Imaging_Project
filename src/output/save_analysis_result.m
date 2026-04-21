function filePath = save_analysis_result(resultData, runInfo, config, baseName)
%SAVE_ANALYSIS_RESULT 保存分析结果。

if nargin < 4 || isempty(baseName)
    baseName = 'analysis_result';
end

filePath = '';
if ~runInfo.enabled || ~config.output.saveAnalysisMat || isempty(resultData)
    return;
end

filePath = fullfile(runInfo.matsDir, [baseName, '.mat']);
safe_save(filePath, resultData, 'analysisResult');
end

