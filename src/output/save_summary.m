function filePath = save_summary(summary, runInfo, config)
%SAVE_SUMMARY 保存运行汇总。

filePath = '';
if ~runInfo.enabled || ~config.output.saveSummaryMat
    return;
end

filePath = runInfo.summaryFile;
safe_save(filePath, summary, 'summary');
end

