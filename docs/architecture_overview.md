# Architecture Overview

## 目标

新仓库不再围绕旧脚本堆叠，而是按职责拆成稳定层次：

- `config/`：配置默认值、本地环境覆盖、加载器
- `src/pipelines/`：实测与仿真主流程编排
- `src/data/`：数据入口和缺失控制
- `src/contracts/`：内部数据契约、配置别名兼容、校验
- `src/bp_core/`：BP 成像核心
- `src/cs_recovery/`：压缩感知恢复
- `src/analysis/`：分析层
- `src/output/`：结果输出
- `src/runtime/`：日志、缓存、checkpoint、硬件环境
- `src/utils/`：纯工具函数

## 当前阶段

Phase 1 先稳定基础层和实测主链路骨架。仿真、恢复、深入分析会在后续阶段补齐。

