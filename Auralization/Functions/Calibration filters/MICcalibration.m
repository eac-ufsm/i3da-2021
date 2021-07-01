function Obj = MICcalibration(Obj)
% fs = Obj.Data.SamplingRate;
sz = size(Obj.Data.IR);
dimorder = length(sz):-1:1;
IR = permute(Obj.Data.IR, dimorder);

load('calib_filter', 'sosMatrixL', 'sosMatrixR', 'scaleValuesL', 'scaleValuesR')

% Zero-phase distortion
IR(:,:,1,:) = filtfilt(sosMatrixL, scaleValuesL, squeeze(IR(:,:,1,:)));  %% high pass
IR(:,:,2,:) = filtfilt(sosMatrixR, scaleValuesR, squeeze(IR(:,:,2,:)));  %% low passs

%% Output
Obj.Data.IR = permute(IR, dimorder);

end

