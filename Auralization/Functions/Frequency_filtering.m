% Filter BRIRs 
clear; clc; close all;

%% Load files
path_sofa = 'C:\Users\rdavi\Desktop\artigo Fred\BRIR_ms\';
% BRIRs
Obj_ori = SOFAload([path_sofa 'car_BRIRs.sofa']);
Obj = SOFAload([path_sofa 'Obj_car_windowed.sofa']);
% Calibration
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

if rem(size(IR_calib,1),2) ~= 0
    IR_calib(end,:,:,:) = [];
end
IR_cal = permute(IR_calib, dimorder);
Obj_calib = Obj;

Obj_calib.Data.IR = IR_cal;
% plot_mag_phase(Obj, Obj_calib, 'Calibration (bruel)')

%% Frequency range filtering
fmin = 200;
fmax = 2e4;
Obj_band_filtered = sofaIRfilter(Obj, fmin, fmax);
Obj_band_filtered_calib = sofaIRfilter(Obj_calib, fmin, fmax);

plot_mag_phase(Obj_ori, Obj_band_filtered_calib, 'Calibration + Band filter (FL BRIR, HATO: 40°)')
% hFigure = figure(1);
% filename = [pwd, '\BRIRcalib.pdf' ];
% exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')

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

IR1 = shiftdim(Obj.Data.IR, 3);
IR2 = shiftdim(Obj2.Data.IR, 3);

ir1 = IR1(5000:end,1,1,1);       
ir2 = IR2(:,1,1,1);

ir1 = ir1./(max(abs(ir1(:))));
ir2 = ir2./(max(abs(ir2(:))));

N1 = size(ir1, 1);
fs1 = Obj.Data.SamplingRate;
f1 = linspace(0, fs1-fs1/N1, N1);

N2 = size(ir2, 1);
fs2 = Obj2.Data.SamplingRate;
f2 = linspace(0, fs2-fs2/N2, N2);


tx1 = (0:N1-1)/fs1; 
tx2 = (0:N2-1)/fs2; 

%%% PLOT -------------------------------------------------------------------
figure('outerposition', [100 100 1200 675]);
% Time
subplot(211)

plot(tx1, ir1); hold on 
plot(tx2, ir2); 


xlim([0, 0.2])
% axis tight
xlabel('Time (s)')
ylabel('Amplitude')
legend('Original', 'Window + Calibration + Band filter', 'location', 'southeast')
xtickformat('%,1.2f')
set(gca, 'Fontsize', 20)


%%% Frequency ------------------------------
subplot(212)
f1_1000hz = dsearchn(f1', 1000); %posicao da sample em 1000Hz
f2_1000hz = dsearchn(f2', 1000); %posicao da sample em 1000Hz

g_1 = fft(ir1, N1); 
g_1 = g_1./g_1(f1_1000hz); %normalizar em 1000Hz
g_1 = db(abs(g_1));

g_2 = fft(ir2, N2); 
g_2 = g_2./g_2(f2_1000hz); %normalizar em 1000Hz
g_2 = db(abs(g_2));

semilogx(f1, g_1); hold on
semilogx(f2, g_2);
legend('Original', 'Window + Calibration + Band filter', ...
                                'location', 'south')
xlabel('Frequency (Hz)')
ylabel('Magnitude (dB)')

xlim([20, 2e4])
ax = gca;
xticks(sort(unique([ ax.XTick, 20, 2e4])))
for k= 1:length(ax.XTick)
    labe{k,:} = num2str(ax.XTick(k));
end
xticklabels(labe)

% Phase
% subplot(313)
% semilogx(f1, angle(fft(ir1, N1))/pi); hold on
% semilogx(f2, angle(fft(ir2, N2))/pi);
% xlim([20, 2e4])
% legend('Original', 'Filtered', 'location', 'best')
% xlabel('Frequency (Hz)')
% ylabel('Phase / \pi')
% xticklabels(labe)
hold off
sgtitle(gtitle, 'Fontsize', 20, 'FontWeight', 'bold'); 
set(gca, 'Fontsize', 20)

end