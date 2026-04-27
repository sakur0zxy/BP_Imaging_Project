# Pipeline Notes

## 实测主流程

`main_real_data -> load_real_config -> run_real_data_pipeline`

当前主流程顺序：

1. 加载并校验配置
2. 准备运行目录、日志与 checkpoint
3. 读取 GOTCHA 数据并归一化到统一内部结构
4. 为完整数据生成或读取 baseline 参考图
5. 应用缺失控制
6. 可选执行 `run_recovery`
7. 执行 `bp_imaging`
8. 执行主结果分析 `point_target_analysis`
9. 可选执行 `run_recovery_evaluation`
10. 保存图像、分析结果、汇总和 checkpoint

其中 `run_recovery_evaluation` 是独立模块：

- 只在 `analysis.recoveryEvaluation.enable = true` 时接入
- 关闭或删除该模块不影响主链
- 评估对象固定为 `full / interrupted / recovered_cs_1d / recovered_cs_2d`

## 仿真主流程

`main_sim_data -> load_sim_config -> run_sim_data_pipeline`

当前主流程顺序：

1. 加载并校验配置
2. 生成点目标仿真数据
3. 应用缺失控制
4. 可选执行 `run_recovery`
5. 执行 `bp_imaging`
6. 若启用主分析图像质量评估，则额外准备完整回波参考图
7. 执行主结果分析 `point_target_analysis`
8. 可选执行 `run_recovery_evaluation`
9. 保存图像、分析结果、汇总和 checkpoint

## Recovery Evaluation 主链

`run_recovery_evaluation` 内部顺序固定为：

1. `prepare_recovery_evaluation_config`
2. `build_recovery_evaluation_cases`
3. `evaluate_recovery_cases`
4. `summarize_recovery_evaluation`
5. `emit_recovery_evaluation_outputs`

模块内部职责约束：

- `prepare_*` 只做配置规范化与校验
- `build_*cases*` 只组织 case，不做结果封装
- `evaluate_*` 负责逐个 case 评估并生成 comparisons
- `summarize_*` 只基于已有 comparison 结果产出结论
- `outputs/*` 只负责保存与显示，不反向影响评估逻辑

## 当前分析输出

主分析输出：

- 局部 cutout
- 升采样结果
- `xProfile / yProfile`
- `PSLR / ISLR / IRW`
- 若提供参考图，则附加 `MSE / RMSE / MAE / PSNR / relativeL2Error / normalizedCorrelation`

恢复评估输出：

- `cases.*`
- `comparisons.*`
- `summary.*`
- 可选 `recovery_evaluation.mat`
- 可选 `recovery_evaluation_summary.txt`
- 可选 `recovery_evaluation_panel.png`：完整图总览 + 每个 case 的点目标指标摘要
- 可选 `recovery_evaluation_point_target_panel.png`：点目标局部图 + X/Y 剖面叠加对比

两类恢复评估图的职责不同：

- `recovery_evaluation_panel.png` 用来看整体成像结果是否合理，以及每个 case 的核心指标状态。
- `recovery_evaluation_point_target_panel.png` 用来看点目标主瓣、旁瓣、拖尾和剖面恢复变化。

## Pipeline Provenance

Phase 7 开始引入轻量运行追踪信息。目标是记录“这张图怎么来的”，但不复制大矩阵。

`build_pipeline_provenance(context)` 负责汇总：

- pipeline 模式：`real` 或 `sim`
- 数据来源：`sourceData.meta.kind/provider/dataRoot`
- 数据规模：`echo` 尺寸、方位采样数、有效/缺失方位数
- 缺失控制：模式、缺失比例、缺失数量、随机种子
- 恢复状态：状态、方法、迭代次数、耗时、缺失处相对误差
- 成像信息：网格大小、范围、使用方位数、峰值、耗时
- 分析状态：点目标分析、图像质量分析
- 恢复评估状态：是否启用、状态、最佳方法
- 缓存信息：是否命中、目录名、缓存 key
- 运行环境：后端名称、run 目录、是否保存输出

约束：

- provenance 只保存标量、短文本、小向量和状态信息。
- provenance 不保存 `echo`、`image`、`imageAbs` 等大矩阵。
- Phase 7.1 先提供构建工具；后续计划再接入统一 pipeline 输出。

## Run Manifest

`save_run_manifest(result, runInfo, config)` 负责保存本次运行说明文件：

- 默认文件名：`run_manifest.txt`
- 默认位置：本次 `run_*` 目录根部
- 生效条件：`runInfo.enabled = true` 且 `config.output.enableSave = true`
- 内容来源：优先读取 `result.provenance`，缺失时从现有 `result` 字段临时汇总

记录内容包括：

- pipeline 模式和 run 标签
- sourceData 来源和尺寸
- baseline cache 命中情况
- degradation / recovery / imaging / analysis / recoveryEvaluation 状态
- backend 和 run 目录

约束：

- manifest 是运行说明，不是结果数据文件。
- manifest 不保存图像矩阵、回波矩阵或大型中间变量。
- Phase 7.1 只新增保存工具；后续计划再由公共 pipeline 统一调用。
