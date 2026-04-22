# Roadmap: BP Imaging Project

## Phase 1 - Foundation Reset

目标：按新架构搭起仓库地基，把配置、契约、运行时、输出、主入口、文档和基础测试先落稳。

- 建立目录骨架和 `.gitignore`
- 建立 `startup.m`、`main_real_data.m`、`main_sim_data.m`
- 建立 real/sim 默认配置、加载器和本地配置模板
- 建立统一数据契约、旧字段兼容和基础校验工具
- 建立日志、缓存、checkpoint 和输出目录准备逻辑
- 建立基础文档和测试骨架

状态：已完成

## Phase 2 - Real Data Ingest And Degradation

目标：把旧仓库中的实测数据读取和缺失控制拆成新模块。

- 实现 `load_gotcha_data.m`
- 实现 `apply_degradation.m`
- 实现固定间断、随机间断、掩码生成和缺失摘要
- 让实测主流程在新架构中跑通到 BP 输入前

状态：已完成

## Phase 3 - BP Core Migration

目标：把旧 BP 成像主链路迁移到 `bp_core/`，统一入口和命名。

- 实现 `bp_precompute.m`
- 实现 `bp_backprojection.m`
- 实现 `bp_imaging.m`
- 打通 `run_real_data_pipeline.m`

状态：已完成

## Phase 4 - Simulation Pipeline

目标：把仿真数据入口接入统一内部结构。

- 实现 `generate_point_target_data.m`
- 独立 `build_platform_track.m`，支持多种轨迹模式
- 实现 `run_sim_data_pipeline.m`
- 让仿真流程复用同一套 `degradation / bp_core / output`

状态：已完成

## Phase 5 - Recovery Integration

目标：把恢复能力接入 real/sim 主流程，形成最小可用链路。

- 实现观测模型构建
- 实现 1D / 2D 恢复入口
- 在 real/sim 主流程中接入 `degradation -> recovery -> bp_imaging`
- 补齐恢复冒烟测试和小规模验证

状态：已完成

## Phase 5.1 - Recovery Modularization

目标：把当前偏 CS 专用的恢复层重构成长期可扩展的 `recovery/` 模块，不保留旧接口兼容。

- 将 `src/cs_recovery/` 重构为 `src/recovery/`
- 统一官方入口为 `run_recovery(...)`
- 将方法名切换为 `cs_1d`、`cs_2d`
- 将恢复配置改为 `recovery.common.*` 与 `recovery.methods.<method>.*`
- 将 CS 家族内部的求解器和变换下沉到 `methods/cs/`
- 同步 real/sim pipeline、测试和文档，并移除旧 `run_cs_recovery` 与旧扁平 recovery 字段

状态：已完成（2026-04-22）

## Phase 6 - Analysis And Hardening

目标：补齐恢复效果评估、对比输出、测试和文档，形成可长期迭代的分析基线。

- 实现可插拔的 recovery evaluation 模块
- 提供 `full / interrupted / recovered_cs_1d / recovered_cs_2d` 四组对比
- 实现 `cases / comparisons / summary` 结果骨架
- 完善分类输出：`saveMat / saveSummary / savePanel / showPanel`
- 接入 real/sim pipeline
- 补齐实测 / 仿真 recovery evaluation 测试
- 同步架构、配置和 pipeline 文档

状态：已完成（2026-04-22）

## Next Up

推荐下一步：运行 milestone audit，确认当前 milestone 是否可以归档；如果继续扩展分析层，优先做批量 comparison 导出和多恢复方法横向比较。
