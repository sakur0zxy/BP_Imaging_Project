# State

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-04-21)

**Core value:** 把旧 BP 成像项目重建成一个结构清楚、变量易懂、注释简洁、可长期迭代的 MATLAB 工程。  
**Current focus:** Phase 6 visualization enhancement complete; ready for review, commit, or milestone audit.

## Current Status

- Phase 1 已完成：基础骨架、配置层、契约层、运行时、输出层和主入口已落地
- Phase 2 / 3 已完成：实测 GOTCHA 数据读取、缺失控制和 BP 成像主核已迁入新结构并跑通
- Phase 4 已完成：仿真数据生成、轨迹模块和仿真成像链路已跑通
- Phase 5 已完成：恢复功能已接入 real/sim 主流程并通过基础测试
- Phase 5.1 已完成：recovery 已切到 `src/recovery/ + run_recovery + cs_1d/cs_2d + recovery.common/recovery.methods`
- Phase 6 已完成：recovery evaluation 模块、pipeline 接线、分类输出开关、测试和文档已收口
- Phase 6.4 已完成：recovery evaluation 总览图改为全图 + 指标卡片，并新增点目标局部 + X/Y 剖面对比图
- 当前全量 `tests/` 已通过，说明 recovery evaluation 的新增没有破坏现有链路

## Risks

- 当前 recovery evaluation 的 case 体系固定为 `full / interrupted / recovered_cs_1d / recovered_cs_2d`，后续若新增更多 recovered 方法，需要同步扩展 comparison plan 与 summary 规则
- real 场景下的评估仍然是相对口径，不应被误解为 ground truth 绝对误差
- summary 目前以结构化结论为主，后续如果要做批量实验表格化汇总，还需要再加导出层

## Next Action

- review 本次 06-04 可视化增强，确认两张恢复评估图的布局是否符合预期
- 运行 milestone audit，确认当前 milestone 是否可以归档
- 如果继续扩展分析层，优先考虑批量 comparison 导出和多恢复方法横向对比
