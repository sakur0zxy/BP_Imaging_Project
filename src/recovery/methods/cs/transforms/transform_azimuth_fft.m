function spec = transform_azimuth_fft(dataIn)
%TRANSFORM_AZIMUTH_FFT 方位向 FFT 变换。
numAz = size(dataIn, 2);
spec = fft(dataIn, [], 2) / sqrt(numAz);
end
