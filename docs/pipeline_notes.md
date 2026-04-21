# Pipeline Notes

## 实测主流程

`main_real_data -> load_real_config -> run_real_data_pipeline`

当前主流程分为：

1. 加载并校验配置
2. 准备运行目录与日志
3. 读取 GOTCHA 数据并归一化到内部契约
4. 应用缺失控制
5. 可选执行回波恢复
6. 执行 BP 成像
7. 可选执行点目标分析
8. 保存图像、分析结果、汇总和 checkpoint

## 仿真主流程

`main_sim_data -> load_sim_config -> run_sim_data_pipeline`

当前主流程分为：

1. 加载并校验配置
2. 生成点目标仿真数据
3. 应用缺失控制
4. 可选执行回波恢复
5. 执行 BP 成像
6. 若启用图像质量评估，则额外生成完整回波参考图
7. 执行点目标分析和图像质量评估
8. 保存图像、分析结果、汇总和 checkpoint

## 当前分析输出

- 点目标分析输出局部切片、升采样结果、倾斜校正信息
- `xProfile / yProfile` 都会给出 `PSLR / ISLR / IRW`
- 仿真链路在提供参考图时，会额外输出 `MSE / RMSE / MAE / PSNR / relativeL2Error / normalizedCorrelation`
