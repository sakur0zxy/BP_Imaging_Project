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

## 约束

- `track.x/y/z`：等长行向量
- `echo`：`numRangeSamples x numAzimuthSamples` 复数矩阵
- `radar.numRangeSamples`：与 `size(echo, 1)` 一致
- `track` 长度：与 `size(echo, 2)` 一致
- `mask`：长度等于方位向样本数的逻辑向量

