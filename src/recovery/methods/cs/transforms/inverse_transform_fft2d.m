function dataOut = inverse_transform_fft2d(spec)
%INVERSE_TRANSFORM_FFT2D 二维 FFT 逆变换。
scaleValue = sqrt(numel(spec));
dataOut = ifft2(spec) * scaleValue;
end
