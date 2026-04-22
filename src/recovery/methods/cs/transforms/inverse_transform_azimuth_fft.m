function dataOut = inverse_transform_azimuth_fft(spec)
%INVERSE_TRANSFORM_AZIMUTH_FFT 方位向 FFT 逆变换。
numAz = size(spec, 2);
dataOut = ifft(spec, [], 2) * sqrt(numAz);
end
