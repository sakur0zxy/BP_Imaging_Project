---
phase: "06-analysis-and-hardening"
plan: "04"
status: completed
completed_at: "2026-04-27"
---

# 06-04 Recovery Evaluation Visualization Panels

## Summary

完成恢复效果评估可视化增强：

- `recovery_evaluation_panel.png` 保留为总览图：第一行完整成像图，第二行改为点目标指标卡片。
- 新增 `recovery_evaluation_point_target_panel.png`：上方显示点目标局部图，下方显示 X/Y profile 叠加对比。
- 新增 `savePointTargetPanel` / `showPointTargetPanel`，与已有 `savePanel` / `showPanel` 分别控制。
- 输出结构新增 `pointTargetPanelFile` / `pointTargetPanelShown`。
- 可选模块可用性检查、disabled result 和缺模块测试同步更新。
- 文档补充两类 panel 的职责差异。

## Files Changed

- `.planning/STATE.md`
- `.planning/phases/06-analysis-and-hardening/06-04-PLAN.md`
- `config/default_real_config.m`
- `config/default_sim_config.m`
- `docs/config_contract.md`
- `docs/pipeline_notes.md`
- `src/analysis/is_recovery_evaluation_available.m`
- `src/analysis/run_optional_recovery_evaluation.m`
- `src/analysis/run_recovery_evaluation.m`
- `src/analysis/recovery_evaluation/outputs/emit_recovery_evaluation_outputs.m`
- `src/analysis/recovery_evaluation/outputs/plot_recovery_evaluation_panel.m`
- `src/analysis/recovery_evaluation/outputs/plot_recovery_evaluation_point_target_panel.m`
- `src/analysis/recovery_evaluation/prepare_recovery_evaluation_config.m`
- `src/contracts/prepare_optional_recovery_evaluation_config.m`
- `tests/test_real_pipeline.m`
- `tests/test_recovery_evaluation_smoke.m`

## Verification

- PASS: `matlab -batch "startup; results = runtests('tests/test_recovery_evaluation_smoke.m'); assertSuccess(results);"`
- PASS: `matlab -batch "startup; results = runtests('tests'); assertSuccess(results);"`
- PASS: `savePointTargetPanel=true` smoke test generates `recovery_evaluation_point_target_panel.png`.
- PASS: `outputs.enable=false` smoke test suppresses all recovery evaluation files and panel display flags.
- PASS: recovery evaluation module absence tests still pass when disabled.

## Deviations from Plan

None - plan executed as written. Supporting files `run_recovery_evaluation.m`, `run_optional_recovery_evaluation.m`, and `is_recovery_evaluation_available.m` were updated to carry the new output fields and module completeness check.

## Next Phase Readiness

Ready for review or commit. The next useful step is a visual run with real or sim data and `analysis.recoveryEvaluation.enable=true` to inspect the actual generated figures.
