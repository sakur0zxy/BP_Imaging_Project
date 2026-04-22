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
- 可选 `recovery_evaluation_panel.png`
