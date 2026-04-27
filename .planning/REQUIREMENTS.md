# Requirements: BP Imaging Project

**Defined:** 2026-04-21
**Core Value:** 把旧 BP 成像项目重建成一个结构清楚、变量易懂、注释简洁、可以长期演进的 MATLAB 工程

## v1 Requirements

### Architecture

- [ ] **ARCH-01**: 仓库目录必须与用户给出的新架构保持一致
- [ ] **ARCH-02**: 实测与仿真流程必须通过不同主入口和不同配置加载器启动
- [ ] **ARCH-03**: 核心源码必须按 pipelines/data/contracts/bp_core/recovery/analysis/output/runtime/utils 分层

### Configuration

- [ ] **CONF-01**: 实测流程支持默认配置、本地配置、用户覆盖三层合并
- [ ] **CONF-02**: 仿真流程支持默认配置、本地配置、用户覆盖三层合并
- [ ] **CONF-03**: 新仓库需兼容旧项目常见配置别名，避免迁移初期频繁改脚本

### Real Pipeline

- [ ] **REAL-01**: 可以读取 GOTCHA 类 `.mat` 数据并转成统一内部结构
- [ ] **REAL-02**: 可以对实测数据应用固定间断或随机间断
- [ ] **REAL-03**: 可以在统一 BP 核心入口下完成实测成像

### Runtime And Output

- [ ] **RUN-01**: 每次运行可以创建独立结果目录并保存生效配置
- [ ] **RUN-02**: 支持终端加文件双写日志
- [ ] **RUN-03**: 支持基础 checkpoint 文件输出

### Documentation And Tests

- [ ] **DOC-01**: 提供数据结构、配置字段、主流程和架构概览文档
- [ ] **TEST-01**: 提供基础契约、间断和流程冒烟测试

## v2 Requirements

### Simulation

- **SIM-01**: 生成点目标仿真数据并走统一内部契约
- **SIM-02**: 仿真数据可以直接复用缺失控制与 BP 核心

### Recovery

- **CS-01**: 提供压缩感知恢复统一入口
- **CS-02**: 支持一维与二维恢复实现

### Analysis

- **ANL-01**: 提供点目标分析统一入口
- **ANL-02**: 提供图像质量通用指标

## Out of Scope

| Feature | Reason |
|---------|--------|
| GUI | 当前优先级是算法工程重建 |
| Python 重写 | 用户明确排除 |
| 云端服务化 | 当前项目是本地 MATLAB 科研工程 |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| ARCH-01 | Phase 1 | In Progress |
| ARCH-02 | Phase 1 | In Progress |
| ARCH-03 | Phase 1 | In Progress |
| CONF-01 | Phase 1 | In Progress |
| CONF-02 | Phase 1 | In Progress |
| CONF-03 | Phase 1 | In Progress |
| REAL-01 | Phase 2 | Pending |
| REAL-02 | Phase 2 | Pending |
| REAL-03 | Phase 3 | Pending |
| RUN-01 | Phase 1 | In Progress |
| RUN-02 | Phase 1 | In Progress |
| RUN-03 | Phase 1 | In Progress |
| DOC-01 | Phase 1 | In Progress |
| TEST-01 | Phase 1 | In Progress |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 13
- Unmapped: 0

---
*Requirements defined: 2026-04-21*
*Last updated: 2026-04-21 after Phase 1 scaffold start*
