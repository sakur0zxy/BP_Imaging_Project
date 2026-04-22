function spec = transform_fft2d(dataIn)
%TRANSFORM_FFT2D 二维 FFT 变换。
scaleValue = sqrt(numel(dataIn));
spec = fft2(dataIn) / scaleValue;
end
