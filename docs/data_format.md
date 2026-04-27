# Data Format

## 统一内部数据结构

实测和仿真都会被整理成同一个 `sourceData` 结构：

```matlab
sourceData.track.x
sourceData.track.y
sourceData.track.z
sourceData.echo
sourceData.radar
sourceData.mask
sourceData.meta
```

## 字段契约

- `sourceData.track.x/y/z`：`1 x numAzimuthSamples` 数值向量，单位 `[m]`。表示每个方位采样对应的平台位置。
- `sourceData.echo`：`numRangeSamples x numAzimuthSamples` 数值矩阵，通常为复数。行是距离/频率采样，列是方位采样。
- `sourceData.radar.c`：数值标量，单位 `[m/s]`。电磁波传播速度。
- `sourceData.radar.centerOmega`：数值标量，单位 `[rad/s]`。中心圆频率。
- `sourceData.radar.numRangeSamples`：正整数标量，必须等于 `size(sourceData.echo, 1)`。
- `sourceData.radar.numRangeSamplesUp`：正整数标量，不能小于 `numRangeSamples`。
- `sourceData.radar.rangeStep`：正数标量，单位 `[m]`。BP 插值使用的距离采样间隔。
- `sourceData.mask`：`1 x numAzimuthSamples` 逻辑向量。`true` 表示该方位采样有效，`false` 表示缺失。
- `sourceData.meta`：结构体。记录数据来源、生成方式、继承信息或本地数据路径等元信息。

## 必填与可选

必填字段：

- `track.x`
- `track.y`
- `track.z`
- `echo`
- `radar`
- `mask`
- `meta`

`normalize_source_data` 会补齐部分默认值：

- 缺少 `mask` 时，默认全部方位采样有效。
- 缺少 `radar.c` 时，默认 `3e8`。
- 缺少 `radar.centerOmega` 时，默认 `2 * pi * 9.6e9`。
- 缺少 `radar.numRangeSamples` 时，使用 `size(echo, 1)`。
- 缺少 `radar.numRangeSamplesUp` 时，使用 `numRangeSamples`。
- 缺少 `radar.rangeStep` 时，默认 `1`。

## 校验规则

- `track.x/y/z` 必须是非空、有限、等长数值向量。
- `echo` 必须是非空二维数值矩阵，不能包含 `NaN` 或 `Inf`。
- `size(echo, 2)` 必须等于轨迹长度。
- `mask` 必须与轨迹长度一致。逻辑向量直接使用，`0/1` 数值向量会转成逻辑向量。
- `radar.numRangeSamples` 必须等于 `size(echo, 1)`。
- `radar.numRangeSamplesUp` 必须大于等于 `numRangeSamples`。
- `radar.c`、`centerOmega`、`rangeStep` 等 BP 依赖字段必须存在且有限。

## real / sim 对齐原则

real 和 sim 可以有不同 `meta`，但进入 `degradation / recovery / bp_imaging / analysis` 前，以下字段必须完全对齐：

- `track`
- `echo`
- `radar`
- `mask`
- `meta`

下游模块不应该再依赖 Gotcha 原始字段名或仿真内部字段名。
