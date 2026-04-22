# Phase 6: Analysis And Hardening - Discussion Log

> **Audit trail only.** Do not use as primary implementation input.  
> Final phase decisions are captured in `06-CONTEXT.md`.

**Date:** 2026-04-22  
**Phase:** 06-analysis-and-hardening

---

## Confirmed User Choices

### 1. Case Organization

**Chosen:** 方法并列版

固定至少支持：

- `full`
- `interrupted`
- `recovered_cs_1d`
- `recovered_cs_2d`

理由：

- 第一版就能直接比较不同恢复方法
- 后续扩 `recovered_*` 时不必重构整体结果骨架

---

### 2. Real / Sim Evaluation Logic

**Chosen:** 同结构，分指标

约束：

- sim 做绝对对比
- real 做相对对比
- 不适用指标显式标成 `skipped` 或 `not_available`

理由：

- 保持结果结构统一
- 又不强迫 real 使用无意义的 ground-truth 逻辑

---

### 3. Output Form

**Chosen:** 平衡版

第一版要求同时支持：

- 结构化结果
- 对比总览图
- 简短 summary

并且每类输出单独开关控制。

---

### 4. Metric Strategy

**Chosen:** 完整主指标

优先指标：

- sim: `PSNR`、`relativeL2Error`、`normalizedCorrelation`
- real: `PSLR`、`ISLR`、`IRW`、`peak shift`

约束：

- summary 从完整指标中挑重点写
- 最终验收以成像结果是否更好为主

---

## Additional Constraints Confirmed Later

- 恢复评估必须是独立模块
- 直接删除该模块后，不影响主链 `load/generate -> degradation -> recovery -> bp_imaging`
- 主流程只能通过显式开关接入
- 模块内部可以复用现有分析函数，但不能反向污染 recovery 或 BP 主契约

---

## Structure Refinement Notes

### Early Candidate

曾讨论过较重的平铺结构，把很多 recovery-evaluation 专用文件直接放在 `src/analysis/` 根目录下。  
结论：不推荐。根目录暴露面过大，不利于长期维护。

### Over-Split Candidate

曾讨论过进一步细拆：

- `compute_sim_recovery_metrics.m`
- `compute_real_recovery_metrics.m`
- `build_case_result.m`
- `build_comparison_result.m`
- `resolve_recovery_eval_outputs.m`

全部作为顶层平铺文件。  
结论：方向对，但层级过散。

### Accepted Refinement

最终接受的结构原则：

- `src/analysis/` 根目录只暴露 `run_recovery_evaluation.m`
- 内部细节收进 `recovery_evaluation/`
- `metrics/`、`builders/`、`outputs/` 三类子目录保留
- `compare_recovery_cases.m` 与 `evaluate_recovery_cases.m` 二选一时，更倾向后者

最终采用 `evaluate_recovery_cases.m` 的原因：

- 主流程更自然：`prepare -> build_cases -> evaluate -> summarize -> emit`
- 它不仅做 comparison，还负责逐个 case 的评估和标准结果生成

---

## External Review Suggestions Digested

外部 review 中被采纳的高价值建议：

- 明确 `build_recovery_evaluation_cases.m` 和 `build_case_result.m` 的职责边界
- 明确 `summary` 只能消费已有 `cases` 与 `comparisons`，不能重算指标
- 先把 `case / caseResult / comparisonResult / summary` 的字段契约定死
- 在 `prepare_recovery_evaluation_config.m` 中统一标准化 `evaluationMode`
- 用 `anti-patterns` 和 `done definition` 作为 Phase 6 的审查基线

未原样照搬的点：

- 过重的 YAML 式契约描述
- 过早为任意数量方法做插件化 registry
- 过度限制所有内部临时 struct 的组织方式

---

## Deferred Ideas

- 非 CS 方法加入后的统一 benchmark
- 更细粒度的输出开关，例如 `saveProfiles`、`saveCaseImages`
- 更复杂的多方法自动排序与推荐规则
- 表格导出、报告导出等更重的 reporting 层

---

## Final Recommendation Snapshot

Phase 6 推荐实现为：

- 单入口：`run_recovery_evaluation.m`
- 单内部子系统：`recovery_evaluation/`
- 稳定结果骨架：`cases / comparisons / summary`
- 分类输出开关：`outputs.*`
- 结构先清晰，再扩功能

---

*Audit trail only - final decisions live in `06-CONTEXT.md`.*
