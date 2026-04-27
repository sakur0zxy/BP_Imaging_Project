# 06-02 Summary

## Outcome

- 已新增 `src/analysis/run_recovery_evaluation.m`
- 已新增 `src/analysis/recovery_evaluation/` 子系统及 `metrics / builders / outputs` 结构
- 已实现 `prepare -> build_cases -> evaluate -> summarize -> emit` 主链
- recovery evaluation 固定支持 `full / interrupted / recovered_cs_1d / recovered_cs_2d`
- sim / real 指标逻辑已分离，summary 只消费 comparison 结果

## Verification

- `matlab -batch "cd('E:/博士文件/工作整理/2026/BP_Imaging_Project'); startup; results = runtests('tests'); disp(table(results)); assert(all([results.Passed]), 'Some tests failed.');"`
