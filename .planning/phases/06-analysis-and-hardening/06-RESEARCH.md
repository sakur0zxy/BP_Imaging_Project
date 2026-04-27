# Phase 6: Analysis And Hardening - Research

## Research Goal

回答本 phase 的核心问题：

- 恢复效果评估模块最稳的边界应该切在哪里
- 如何在不污染主链的前提下，组织 `full / interrupted / recovered_*` 对比
- 如何让 sim / real 共结构、分口径
- 如何让结果既适合人工看图，也适合后续表格化与批量对比

## Live Code Findings

### 1. 当前 recovery 主契约已经稳定，Phase 6 不适合再反向改 recovery

- `src/recovery/run_recovery.m` 已经成为统一恢复入口
- real / sim pipeline 已经切到新 recovery 契约
- 继续在 Phase 6 里反向修改 recovery，会把恢复评估和恢复模块边界重新混掉

结论：

- Phase 6 必须建立在当前稳定 `run_recovery + recoveryResult` 契约之上
- 恢复评估只能消费已有结果，不能主导 recovery 结构

### 2. 当前 analysis 层已有可复用资产，但还缺恢复评估主链

已有资产：

- `src/analysis/point_target_analysis.m`
- `src/analysis/evaluate_image_quality.m`
- `src/runtime/get_full_image_reference.m`
- `src/output/save_analysis_result.m`

缺口：

- 缺少统一的 `run_recovery_evaluation.m`
- 缺少四组 case 的标准化组织逻辑
- 缺少标准 comparison 结果结构
- 缺少 summary 结构和输出开关

### 3. 恢复评估的真正复杂度不在目录，而在数据契约

真正需要定死的是：

- `standardizedConfig`
- `caseItem`
- `caseResult`
- `comparisonResult`
- `summary`

如果这些结构不先定死，即使目录漂亮，后面字段名也会漂。

### 4. 输出层必须独立，但不值得提前做过重 reporting 系统

用户已经明确：

- 要平衡版输出
- 每类输出都要有独立开关
- 模块必须可删、可关

这意味着：

- 需要 `outputs/` 子目录
- 需要 `emit_*` 统一收口保存/显示开关
- 但当前不需要提前做 CSV / PDF / 报告页系统

### 5. sim / real 最稳的做法是共结构、分口径

当前讨论已经稳定：

- sim：绝对指标
- real：相对指标
- 不适用的指标显式标 `skipped` 或 `not_available`

最稳的实现方式是：

- 在 `prepare_recovery_evaluation_config.m` 中统一标准化 `evaluationMode`
- 后面所有内部函数只读这个 mode，不自己猜

## Recommended Target Structure

```text
src/analysis/
├── run_recovery_evaluation.m
│
└── recovery_evaluation/
    ├── prepare_recovery_evaluation_config.m
    ├── build_recovery_evaluation_cases.m
    ├── evaluate_recovery_cases.m
    ├── summarize_recovery_evaluation.m
    │
    ├── metrics/
    │   ├── compute_sim_recovery_metrics.m
    │   └── compute_real_recovery_metrics.m
    │
    ├── builders/
    │   ├── build_case_result.m
    │   └── build_comparison_result.m
    │
    └── outputs/
        ├── emit_recovery_evaluation_outputs.m
        └── plot_recovery_evaluation_panel.m
```

## Locked Architectural Conclusions

- 恢复评估必须是独立分析模块，不是 recovery 子模块
- `run_recovery_evaluation.m` 是唯一公开入口
- 模块内部主链固定为：
  `prepare -> build_cases -> evaluate -> summarize -> emit`
- `build_recovery_evaluation_cases.m` 只组织 case，不封装结果
- `build_case_result.m` 只封装结果，不参与 case 编排
- `summarize_recovery_evaluation.m` 只消费已有结果，不重算指标
- `outputs/` 只负责输出行为，不反向影响评估逻辑

## Recommended Planning Split

### Wave 1

- 冻结 recoveryEvaluation 配置契约
- 新增输出开关和标准化 mode
- 同步 validators 和 config/docs

### Wave 2

- 建立恢复评估主链
- 实现四组 case 的标准化组织
- 实现 sim / real 指标分支
- 输出统一 `cases / comparisons / summary`

### Wave 3

- 接 outputs 层
- 接 real / sim pipeline
- 补恢复评估测试
- 同步文档和 phase 状态

## Why This Is The Best Sequence

- 先冻结契约，再做主链，最后再接输出和 pipeline，风险最低
- 可以避免一边写对比逻辑，一边反复改配置字段
- 能确保 module boundary 在接入 pipeline 前就已经稳定

---

*Research completed locally on 2026-04-22*  
*Scope: repo-internal recovery evaluation architecture, not external algorithm survey*
