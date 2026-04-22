# Architecture Overview

## 目标

新仓库不再围绕旧脚本堆叠，而是按职责拆成稳定层次：

- `config/`：默认配置、本地环境覆盖、加载器
- `src/pipelines/`：实测与仿真主流程编排
- `src/data/`：数据入口与缺失控制
- `src/contracts/`：内部数据契约、旧字段兼容、配置校验
- `src/bp_core/`：BP 成像核心
- `src/recovery/`：可扩展恢复模块
- `src/analysis/`：主分析与恢复效果评估
- `src/output/`：结果输出
- `src/runtime/`：日志、缓存、checkpoint、硬件环境
- `src/utils/`：纯工具函数

## 当前阶段

当前已经完成：

- Phase 1：基础骨架、配置层、契约层、运行时、输出层、主入口
- Phase 2 / 3：实测数据读取、缺失控制、BP 成像主核
- Phase 4：仿真数据生成、轨迹模块、仿真成像链路
- Phase 5 / 5.1：恢复模块接入与 `src/recovery/` 长期架构重构
- Phase 6：恢复效果评估模块、pipeline 接线、测试与文档收口

## Recovery Evaluation 子系统

恢复效果评估作为 `src/analysis/` 下的独立子系统存在：

- 公开入口：`src/analysis/run_recovery_evaluation.m`
- 内部目录：`src/analysis/recovery_evaluation/`
- 子目录：
  - `metrics/`
  - `builders/`
  - `outputs/`

该子系统的设计原则：

- 可插拔
- 显式开关控制
- sim / real 指标逻辑分离
- `cases / comparisons / summary` 结构固定
- 删除后不影响 `load/generate -> degradation -> recovery -> bp_imaging` 主链

## 非 Git 路径

以下目录或文件应保持本地化，不进入 Git：

- `config/local/local_env_config.m`
- `data/real_data/`
- `data/sim_data/`
- `results/`
- `cache/`
