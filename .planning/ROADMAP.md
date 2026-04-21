# Roadmap: BP Imaging Project

## Phase 1 - Foundation Reset

目标：按新架构搭起仓库地基，把配置、契约、运行时、输出、主入口、文档和基础测试先落稳。
- 建立目录骨架和 `.gitignore`
- 建立 `startup.m`、`main_real_data.m`、`main_sim_data.m`
- 建立 real/sim 默认配置、加载器和本地配置模板
- 建立统一数据契约、旧字段别名兼容和基础校验工具
- 建立日志、缓存、checkpoint 和输出目录准备逻辑
- 建立基础文档和测试骨架

## Phase 2 - Real Data Ingest And Degradation

目标：把旧仓库中的实测数据读取和缺失控制拆成新模块。
- 实现 `load_gotcha_data.m`
- 实现 `apply_degradation.m`
- 实现固定间断、随机间断、掩码生成和缺失摘要
- 让实测主流程在新架构中跑通到 BP 输入前

## Phase 3 - BP Core Migration

目标：把旧 BP 成像主链路迁移到 `bp_core/`，统一入口和命名。
- 实现 `bp_precompute.m`
- 实现 `bp_backprojection.m`
- 实现 `bp_imaging.m`
- 打通 `run_real_data_pipeline.m`

## Phase 4 - Simulation Pipeline

目标：把仿真数据入口接入统一内部结构。
- 实现 `generate_point_target_data.m`
- 独立 `build_platform_track.m`，支持多种轨迹模式
- 实现 `run_sim_data_pipeline.m`
- 让仿真流程复用同一套 degradation / bp_core / output

## Phase 5 - Recovery Integration

目标：重建压缩感知恢复层并接入主流程。
- 实现观测模型构建
- 实现 1D 与 2D 恢复入口
- 在 real/sim 主流程中插入 `degradation -> recovery -> bp_imaging`
- 补齐恢复冒烟测试和实测小规模验证

## Phase 6 - Analysis And Hardening

目标：补齐分析、测试和文档，形成可长期迭代的工程基线。
- 实现点目标分析
- 完善图像质量评估
- 补齐实测 / 仿真 / 恢复测试
- 文档收口到稳定版本

## Next Up

**Phase 6** 应该继续执行：围绕恢复结果补齐分析、评估、测试和文档收口。  
推荐下一步：`$gsd-plan-phase 6`
