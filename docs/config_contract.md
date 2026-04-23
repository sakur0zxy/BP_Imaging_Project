# Config Contract

## 顶层分区

- `project`：流程模式与工程元信息
- `path`：项目根目录、数据目录、缓存目录
- `source`：实测数据文件命名与字段映射
- `scene`：仿真场景、目标、轨迹参数
- `radar`：雷达物理参数
- `imaging`：BP 成像网格与执行参数
- `degradation`：缺失控制参数
- `recovery`：恢复模块参数
- `analysis`：分析与评估参数
- `debug`：调试图显示开关
- `output`：结果保存开关与输出目录
- `runtime`：GPU、并行与 worker 设置

## Recovery

- `recovery.enable`
  控制是否在 `degradation` 之后、`bp_imaging` 之前执行恢复。
- `recovery.method`
  当前正式支持 `cs_1d` 和 `cs_2d`。
- `recovery.common.maxIter`
  最大迭代次数。
- `recovery.common.tol`
  相邻迭代相对变化阈值。
- `recovery.common.useFista`
  `true` 用 FISTA，`false` 用 ISTA。
- `recovery.common.normalizeInput`
  是否先做输入归一化。
- `recovery.common.verbose`
  是否打印恢复迭代日志。
- `recovery.common.skipWhenNoMissing`
  没有缺失时是否自动跳过恢复。
- `recovery.methods.cs_1d.lambda`
  `cs_1d` 的方位向 FFT 稀疏正则系数。
- `recovery.methods.cs_1d.useFista`
  `cs_1d` 是否启用 FISTA。
- `recovery.methods.cs_2d.lambda`
  `cs_2d` 的 2D FFT 稀疏正则系数。
- `recovery.methods.cs_2d.useFista`
  `cs_2d` 是否启用 FISTA。

## Analysis

- `analysis.enablePointAnalysis`
  是否执行点目标分析。
- `analysis.enableImageQuality`
  是否执行图像质量评估。
- `analysis.pointTarget.cutoutHeight`
  峰值邻域裁剪高度，必须为偶数。
- `analysis.pointTarget.cutoutWidth`
  峰值邻域裁剪宽度，必须为偶数。
- `analysis.pointTarget.upsampleFactor`
  局部切片插值升采样倍数。
- `analysis.pointTarget.enableTiltCorrection`
  是否做局部倾斜校正。
- `analysis.pointTarget.tiltThresholdDeg`
  倾角低于该值时不旋转。
- `analysis.pointTarget.tiltEdgeFraction`
  估计倾角时使用的左右边缘列比例。
- `analysis.imageQuality.compareMode`
  图像质量对比方式，支持 `amplitude` 和 `complex`。

### Recovery Evaluation

- `analysis.recoveryEvaluation.enable`
  是否启用独立的恢复效果评估模块。
- `analysis.recoveryEvaluation.evaluationMode`
  评估口径，支持 `auto`、`real` 和 `simulation`。默认 `auto` 跟随 `project.mode`：real 流程解析为 `real`，sim 流程解析为 `simulation`。手动指定时必须与当前数据流程匹配。
- `analysis.recoveryEvaluation.caseNames`
  当前固定为 `full / interrupted / recovered_cs_1d / recovered_cs_2d`。
- `analysis.recoveryEvaluation.referenceCase`
  默认参考 case，当前固定为 `full`。
- `analysis.recoveryEvaluation.outputs.enable`
  评估输出总开关。设为 `false` 时，不保存 mat、不写 summary、不保存 panel，也不弹出 panel。
- `analysis.recoveryEvaluation.outputs.saveMat`
  是否保存完整 `recoveryEvaluation` 结构。
- `analysis.recoveryEvaluation.outputs.saveSummary`
  是否保存文本摘要。
- `analysis.recoveryEvaluation.outputs.savePanel`
  是否保存 `recovery_evaluation_panel.png` 总览图。
- `analysis.recoveryEvaluation.outputs.showPanel`
  是否直接弹出总览图。
- `analysis.recoveryEvaluation.metricOptions.enablePointAnalysis`
  recovery evaluation 内部是否对 case 执行点目标分析。
- `analysis.recoveryEvaluation.metricOptions.enableImageQuality`
  recovery evaluation 内部是否对 case 执行图像质量评估。
- `analysis.recoveryEvaluation.metricOptions.compareMode`
  recovery evaluation 内部图像质量对比方式，支持 `amplitude` 和 `complex`。
- `analysis.recoveryEvaluation.thresholds.*`
  不同口径的告警阈值。当前 real 默认用 `warningPeakShiftPixels`，simulation 默认用 `warningRelativeL2Error`。

Recovery evaluation 模块是可插拔的：关闭 `analysis.recoveryEvaluation.enable` 或删除其实现文件，不应影响 `load/generate -> degradation -> recovery -> bp_imaging` 主链。

## 兼容旧配置

当前仍兼容以下旧字段别名：

- `path.dataRoot` -> `path.realDataRoot` 或 `path.simDataRoot`
- `path.dataRootCandidates` -> `path.realDataCandidates`
- `general.numDataFiles` -> `source.numFiles`
- `general.dataFilePattern` -> `source.filePattern`
- `general.dataVariableName` -> `source.variableName`
- `general.dataFieldMap` -> `source.fieldMap`
- `interruption.*` -> `degradation.*`
- `image.numPixels/xLimits/yLimits` -> `imaging.grid.*`
- `iteration.J` -> `imaging.iterationLength`
- `output.enableOutput` -> `output.enableSave`

恢复模块不再兼容旧的 `1d / 2d` 方法名和 `lambda1D / lambda2D` 扁平配置写法。
