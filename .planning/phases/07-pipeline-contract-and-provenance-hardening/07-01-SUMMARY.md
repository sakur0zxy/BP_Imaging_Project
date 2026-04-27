# 07-01 Summary

## Outcome

- `validate_source_data` 已强化：检查 `track/echo/radar/mask/meta`、轨迹有限值、echo 有限值、mask 类型与长度、BP 依赖雷达字段。
- 新增 `build_pipeline_provenance`，用于生成轻量运行追踪结构，不复制 echo 或 image 大矩阵。
- 新增 `save_run_manifest`，可在输出开启时生成 `run_manifest.txt`，输出关闭时跳过。
- `docs/data_format.md` 和 `docs/pipeline_notes.md` 已补充 sourceData 契约、provenance 和 manifest 说明。
- 测试已覆盖异常 mask、缺失 meta、数值 mask 归一化、provenance 构建和 manifest 写入/跳过。

## Boundary

- 本计划只完成契约和 manifest 基础设施。
- 尚未抽取 `run_common_data_pipeline`。
- 尚未把 provenance/manifest 接入主 real/sim pipeline。
- 尚未新增 `result.stages` 或 `result.provenance`，这些留给 `07-02` 和 `07-03`。

## Verification

- `matlab -batch "cd('E:/博士文件/工作整理/2026/BP_Imaging_Project'); startup; results = runtests('tests/test_contract_normalization.m'); disp(table(results)); assert(all([results.Passed]));"`
- `matlab -batch "cd('E:/博士文件/工作整理/2026/BP_Imaging_Project'); startup; results = runtests('tests/test_sim_pipeline.m'); disp(table(results)); assert(all([results.Passed]));"`
- `git diff --check`
- `matlab -batch "cd('E:/博士文件/工作整理/2026/BP_Imaging_Project'); startup; results = runtests('tests'); disp(table(results)); assert(all([results.Passed]), 'Some tests failed.');"`

Result: full MATLAB test suite passed, 23/23.
