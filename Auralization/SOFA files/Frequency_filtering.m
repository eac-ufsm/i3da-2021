% Filter BRIRs 
clear; clc; close all;

%% Load files
path_sofa = 'C:\Users\rdavi\Desktop\artigo Fred\BRIR_ms\';
% Obj = SOFAload([path_sofa 'car_BRIRs.sofa']);
Obj = SOFAload([path_sofa 'Obj_car_windowed.sofa']);


path_calib = 'C:\Users\rdavi\Desktop\artigo Fred\MEMS mics frequency response\';
[calib_filter, fs_calib] = audioread([path_calib 'Mic_calibration.wav']);


%% Apply calibration
sz = size(Obj.Data.IR);
dimorder = length(sz):-1:1;
IR = permute(Obj.Data.IR, dimorder);
for k = 1:size(IR,2)
    for m = 1:size(IR,4)
        IR_calib(:,k,:,m) = fast_conv(squeeze(IR(:,k,:,m)), calib_filter);
    end
end

IR_cal = permute(IR_calib, dimorder);
Obj_calib = Obj;
Obj_calib.Data.IR = IR_cal;


plot_mag_phase(Obj, Obj_calib, 'Calibration (bruel)')


%% Frequency range filtering
fmin = 10;
fmax = 2e4;
Obj_band_filtered = sofaIRfilter(Obj, fmin, fmax);
plot_mag_phase(Obj, Obj_band_filtered, 'Band filter')


Obj_band_filtered_calib = sofaIRfilter(Obj_calib, fmin, fmax);
plot_mag_phase(Obj, Obj_band_filtered_calib, 'Calibration (bruel) + Band filter')



%% SAVE SOFA FILES
SOFAsave('Obj_band_filtered_calib.sofa', Obj_band_filtered_calib);% Both calibration and band fiiltered
SOFAsave('Obj_band_filtered.sofa',Obj_band_filtered);%only band filtered
SOFAsave('Obj_calib.sofa',Obj_calib);% only calibration



%% INTERNAL FUNCTIONS  ----------------------------------------------------
%% Fast conv
function y = fast_conv(x1, x2)
    nfft = length(x1) + length(x2) - 1;
    y = real(ifft(fft(x1, nfft).*fft(x2, nfft)));
end


%% Plot
function plot_mag_phase(Obj, Obj2, gtitle)
if nargin<3
    gtitle = '';
end
N1 = size(Obj.Data.IR, 4);
fs1 = Obj.Data.SamplingRate;
f1 = linspace(0, fs1-fs1/N1, N1);

N2 = size(Obj2.Data.IR, 4);
fs2 = Obj2.Data.SamplingRate;
f2 = linspace(0, fs2-fs2/N2, N2);

IR1 = shiftdim(Obj.Data.IR, 3);
IR2 = shiftdim(Obj2.Data.IR, 3);

%%% PLOT -------------------------------------------------------------------
figure;
% Time
subplot(311)
tx1 = (0:N1-1)/fs1; 
tx2 = (0:N2-1)/fs2; 

ir1 = IR1(:,1,1,1);       
ir2 = IR2(:,1,1,1);
plot(tx1, ir1); hold on 
plot(tx2, ir2);  
axis tight
legend('Original', 'Filtered', 'location', 'best')
xlabel('Time (s)')

% Frequency
subplot(312)
semilogx(f1, db(abs(fft(ir1, N1)))); hold on
semilogx(f2, db(abs(fft(ir2, N2))));
xlim([20, 2e4])
legend('Original', 'Filtered', 'location', 'best')
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')
ax = gca;
for k= 1:length(ax.XTick)
    labe{k,:} = num2str(ax.XTick(k));
end
xticklabels(labe)

% Phase
subplot(313)
semilogx(f1, angle(fft(ir1, N1))/pi); hold on
semilogx(f2, angle(fft(ir2, N2))/pi);
xlim([20, 2e4])
legend('Original', 'Filtered', 'location', 'best')
xlabel('Frequency (Hz)')
ylabel('Phase / \pi')
xticklabels(labe)
hold off

sgtitle(gtitle); 
end