# Config Contract

## 顶层分区

- `project`：流程模式
- `path`：项目根目录、数据目录、缓存目录
- `source`：实测原始文件命名和字段映射
- `scene`：仿真场景参数
- `radar`：物理参数
- `imaging`：网格、精度、显示相关参数
- `degradation`：缺失控制参数
- `recovery`：缺失回波恢复参数
- `analysis`：点目标分析和图像质量评估开关
- `output`：输出目录和保存开关
- `runtime`：GPU、并行和 worker 设置

## Recovery

- `recovery.enable`
  控制是否在 `degradation` 之后、`bp_imaging` 之前执行恢复。
- `recovery.method`
  目前支持 `1d` 和 `2d`。
- `recovery.lambda1D`
  1D 方位向 FFT 稀疏正则强度。
- `recovery.lambda2D`
  2D FFT 稀疏正则强度。
- `recovery.maxIter`
  最大迭代次数。
- `recovery.tol`
  相邻迭代相对变化阈值。
- `recovery.useFista`
  `true` 用 FISTA，`false` 用 ISTA。
- `recovery.normalizeInput`
  是否先按幅值归一化后再恢复。
- `recovery.verbose`
  是否打印恢复迭代日志。
- `recovery.skipWhenNoMissing`
  没有缺失时是否自动跳过恢复。

## Analysis

- `analysis.enablePointAnalysis`
  是否执行点目标分析。
- `analysis.enableImageQuality`
  是否执行图像质量评估。
- `analysis.pointTarget.cutoutHeight`
  峰值邻域裁剪高度，必须是偶数。
- `analysis.pointTarget.cutoutWidth`
  峰值邻域裁剪宽度，必须是偶数。
- `analysis.pointTarget.upsampleFactor`
  局部切片 FFT 升采样倍数。
- `analysis.pointTarget.enableTiltCorrection`
  是否做局部倾斜校正。
- `analysis.pointTarget.tiltThresholdDeg`
  倾角低于该值时不旋转。
- `analysis.pointTarget.tiltEdgeFraction`
  估计倾角时使用的左右边缘列比例。
- `analysis.imageQuality.compareMode`
  图像质量对比方式，支持 `amplitude` 和 `complex`。

## 兼容旧配置

当前已兼容以下旧字段别名：
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
