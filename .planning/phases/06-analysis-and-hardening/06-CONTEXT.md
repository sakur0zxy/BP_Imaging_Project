# Phase 6: Analysis And Hardening - Context

**Gathered:** 2026-04-22  
**Revised:** 2026-04-22  
**Status:** Ready for planning  
**Source:** In-thread phase discussion + live codebase audit + external review digestion

<domain>
## Phase Boundary

本 phase 聚焦在当前稳定的 `src/recovery/` 主契约之上，补齐“恢复效果评估”这一层，
目标是回答：

- 缺失后直接成像比完整参考差多少
- 恢复后是否优于 `interrupted`
- 恢复后是否接近 `full`
- `cs_1d` 和 `cs_2d` 谁更好

本 phase 应覆盖：

- 恢复效果评估模块
- `full / interrupted / recovered_cs_1d / recovered_cs_2d` 四组案例组织
- 仿真与实测共用结果结构、分离指标口径
- 平衡版输出：结构化结果 + 总览对比图 + 简短 summary
- 分类输出开关控制
- 模块必须可插拔，删除后不影响主成像链路

本 phase 不覆盖：

- 再次修改 `src/recovery/` 主契约
- 新增非 CS 恢复算法
- 重做 BP 成像核心
- 把恢复评估做成主流程硬依赖
</domain>

<structure>
## Recommended Module Structure

```text
src/analysis/
├── run_recovery_evaluation.m                          % 恢复评估唯一入口；pipeline 只调它
│
└── recovery_evaluation/
    ├── prepare_recovery_evaluation_config.m           % 规范化配置；确定 evaluationMode；整理 outputs 开关
    ├── build_recovery_evaluation_cases.m              % 只组织待评估案例，不做结果封装
    ├── evaluate_recovery_cases.m                      % 逐个 case 评估并生成 comparisons
    ├── summarize_recovery_evaluation.m                % 只基于已有结果生成结论，不重复算指标
    │
    ├── metrics/
    │   ├── compute_sim_recovery_metrics.m             % 仿真口径绝对指标
    │   └── compute_real_recovery_metrics.m            % 实测口径相对指标
    │
    ├── builders/
    │   ├── build_case_result.m                        % 封装单个 caseResult 标准结构
    │   └── build_comparison_result.m                  % 封装单个 comparisonResult 标准结构
    │
    └── outputs/
        ├── emit_recovery_evaluation_outputs.m         % 统一处理保存/显示开关
        └── plot_recovery_evaluation_panel.m           % 生成总览对比图
```

结构约束：

- `run_recovery_evaluation.m` 是唯一公开入口
- `recovery_evaluation/` 是内部子系统，删掉后不影响主链
- `metrics/` 只算指标
- `builders/` 只封装统一结果结构
- `outputs/` 只负责保存与显示，不反向影响评估逻辑
</structure>

<decisions>
## Implementation Decisions

### Cases
- **D-01:** 第一版固定四组案例：`full`、`interrupted`、`recovered_cs_1d`、`recovered_cs_2d`
- **D-02:** 结构上允许未来继续扩 `recovered_*`，但当前不为任意数量方法做过重抽象

### Real / Sim Metric Modes
- **D-03:** 实测和仿真共用同一套结果骨架：`cases / comparisons / summary`
- **D-04:** 仿真使用绝对指标，实测使用相对指标
- **D-05:** 不适用的指标必须显式标成 `skipped` 或 `not_available`
- **D-06:** 在 `prepare_recovery_evaluation_config.m` 内统一标准化 `evaluationMode`

### Output Mode
- **D-07:** 输出采用平衡版：结构化结果 + 总览对比图 + 简短 summary
- **D-08:** 输出分类开关放在 `config.analysis.recoveryEvaluation.outputs.*`
- **D-09:** 第一版至少支持：
  - `saveMat`
  - `saveSummary`
  - `savePanel`
  - `showPanel`

### Module Boundary
- **D-10:** 恢复评估必须是独立模块，关闭或删除后主链 `load/generate -> degradation -> recovery -> bp_imaging` 不受影响
- **D-11:** 主流程只能通过显式开关接入该模块
- **D-12:** 可以复用 `point_target_analysis`、`evaluate_image_quality`、`get_full_image_reference`，但不能反向要求 recovery 或 BP 修改主契约

### Responsibility Boundaries
- **D-13:** `run_recovery_evaluation.m` 只做编排
- **D-14:** `build_recovery_evaluation_cases.m` 只组织 case，不封装 `caseResult`
- **D-15:** `build_case_result.m` 只封装单个 `caseResult`，不决定有哪些 case
- **D-16:** `evaluate_recovery_cases.m` 负责逐个 case 评估，并生成 `comparisons`
- **D-17:** `summarize_recovery_evaluation.m` 只基于已有 `cases` 与 `comparisons` 生成结论，不重复算指标
- **D-18:** `metrics/*` 不做流程控制，不输出业务结论
- **D-19:** `builders/*` 不做复杂业务逻辑和二次计算

### Acceptance Logic
- **D-20:** 恢复是否有效，以成像结果为主判断，而不是以恢复内部数值误差为最终验收标准
- **D-21:** summary 必须直接回答：
  - 恢复是否优于 `interrupted`
  - 是否接近 `full`
  - 不同恢复方法谁更好
  - 结论是否存在明显风险或限制
</decisions>

<contracts>
## Standard Contracts

### standardizedConfig

必须至少包含：

- `mode`
- `evaluationMode`
- `caseNames`
- `referenceCase`
- `comparisonPlan`
- `outputOptions`
- `metricOptions`
- `thresholds`
- `meta`

### caseItem

必须至少包含：

- `caseName`
- `caseType`
- `mode`
- `payload`
- `sourceTag`
- `status`
- `meta`

### caseResult

必须至少包含：

- `caseName`
- `mode`
- `status`
- `metrics`
- `artifacts`
- `messages`
- `meta`

### comparisonResult

必须至少包含：

- `comparisonName`
- `referenceCase`
- `targetCase`
- `mode`
- `metrics`
- `status`
- `messages`
- `meta`

### summary

必须至少包含：

- `highLevelFindings`
- `perCaseFindings`
- `bestMethodIfAny`
- `riskOrLimitations`
- `modeSpecificNotes`
- `meta`
</contracts>

<anti_patterns>
## Anti-Patterns To Avoid

- 在 `run_recovery_evaluation.m` 里堆满所有逻辑
- 在 `prepare_*` 里偷偷算指标
- `build_recovery_evaluation_cases.m` 和 `build_case_result.m` 职责混掉
- `evaluate_recovery_cases.m` 同时做 summary 文本
- `summarize_recovery_evaluation.m` 自己重算指标
- 混用 sim / real 指标逻辑
- 新增一个 `recovered_*` 方法要改十几个地方
- 字段名漂移，今天一个名字明天一个名字
- 输出裸矩阵或匿名 struct，缺少元信息
- 错误信息无法定位到模块和阶段
</anti_patterns>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Context
- `.planning/PROJECT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`

### Current Recovery And Pipelines
- `src/recovery/run_recovery.m`
- `src/pipelines/run_real_data_pipeline.m`
- `src/pipelines/run_sim_data_pipeline.m`
- `src/runtime/get_full_image_reference.m`

### Current Analysis And Output
- `src/analysis/point_target_analysis.m`
- `src/analysis/evaluate_image_quality.m`
- `src/output/save_analysis_result.m`
- `docs/pipeline_notes.md`
- `docs/config_contract.md`

### Preceding Phase
- `.planning/phases/05.1-recovery-modularization/05.1-CONTEXT.md`
</canonical_refs>

<done_definition>
## Done Definition

### Minimum Done
- 能从入口完整跑通 `prepare -> build_cases -> evaluate -> summarize -> emit`
- sim / real 两类模式逻辑均可运行
- 所有 case 输出统一结构
- 所有 comparison 输出统一结构
- summary 为结构化输出
- 模块可关、可删，不影响主链

### Good Done
- 新增一个 `recovered_*` 方法只需少量改动
- 新增一种 comparison 不需重写整体框架
- 非法配置能在 `prepare` 阶段被拦截
- summary 能区分“接近 full”和“优于 interrupted”两类结论

### Excellent Done
- 支持批量 case 评估
- 支持统一结果导出
- 支持后续表格/图形/报告层无痛接入
- 接口和字段在后续迭代中保持稳定
</done_definition>

---

*Phase: 06-analysis-and-hardening*  
*Context gathered: 2026-04-22*  
*Context revised: 2026-04-22*
