clear; clc

%% LOad SOFA
path_sofa = 'C:\Users\rdavi\Desktop\artigo Fred\BRIR_ms\';
Obj = SOFAload([path_sofa 'car_BRIRs.sofa']);

fs = Obj.Data.SamplingRate;
sz = size(Obj.Data.IR);
dimorder = length(sz):-1:1;
IR = permute(Obj.Data.IR, dimorder);
N_ir = size(IR,1);
size(IR)
TRmax = 1.5;
N_out = fs*TRmax;
%% SOFA files windowing
IR_win = zeros(size(IR));
thr = 10;
for k = 1:size(IR, 2)
    for m = 1:size(IR, 4)
       A = IR(:,k,1,m); % L
       B = IR(:,k,2,m); % R    
       % Get onset 
       OnSetL = IR_start(A, thr);
       OnSetR = IR_start(B, thr); 
       [winL, a, w_endL]  = create_window(TRmax, N_ir, OnSetL, fs);
       [winR, b, w_endR]  = create_window(TRmax, N_ir, OnSetR, fs);
       IR_win(:,k,1,m) = squeeze(IR(:,k,1,m)).*winL;
       IR_win(:,k,2,m) = squeeze(IR(:,k,2,m)).*winR;
    end
end
IR_win = permute(IR_win, dimorder);
IR_win = IR_win./max(abs(IR_win(:)));


%% View output 
Obj_win = Obj;
Obj_win.Data.IR = IR_win(:,:,:,3000:15000);
plot_mag_phase(Obj, Obj_win, 'Calibration (bruel)')

SOFAsave('Obj_car_windowed.sofa',Obj_win);% only calibration







%% Internal function ------------------------------------------------------
function [win, w_begin, w_end] = create_window(TRmax, N_ir, OnSet, fs)
%% criar janela
% TRmax = 1.5;   % Max expected TR
% N_ir = 26000;  % BRIR length
% OnSet          % IR start
N_TRmax = ceil(TRmax*fs);

lin_size = 300;
idx_start = OnSet-lin_size;

win_decay = tukeywin(2*length(idx_start:N_TRmax/2+1), 0.5);
win_decay = win_decay(length(win_decay)/2:end-1);

win_mid = ones(idx_start+lin_size, 1);

win_begin = zeros(idx_start-lin_size,1);

win_end = zeros(N_ir -(length(win_begin)+ length(win_mid)+length(win_decay)),1);
win = [win_begin; win_mid; win_decay; win_end];
% win = [win, win];
% plot(win)


w_begin = length(win_begin);
w_end = length(win_begin)+ length(win_mid)+length(win_decay);
end




function sampleStart = IR_start(IR,threshold)
    % 20210207 - Davi Carvalho, adapted from ita_start_IR.m from https://git.rwth-aachen.de/ita/toolbox/-/blob/master/kernel/DSP/ita_start_IR.m
    threshold = -abs(threshold);
    IR_square = IR.^2; 
    % Max value on IR 
    [pk_val, idx_max] = max(IR_square(:));   
    abs_dat = 10.*log10(IR_square(1:idx_max)) - 10.*log10(pk_val);    
    
    lastBelowThreshold  = find(abs_dat < threshold,1,'last');
    if ~isempty(lastBelowThreshold)
        sampleStart = lastBelowThreshold;
    else
        sampleStart = 1;
    end
    % Check if oscillations exist before the last value below threshold
    % If so, these are part of the RIR and need to be considered.
    idx6dBaboveThreshold = find(abs_dat(1:sampleStart) > threshold + 6);
    if ~isempty(idx6dBaboveThreshold)
         tmp = find(abs_dat(1:idx6dBaboveThreshold(1)) < threshold, 1 ,'last');
         if isempty(tmp) % without this if, the function would generate an error, if the oscillation persists until the first sample
            sampleStart = 1;
        else
            sampleStart = tmp;
         end
    end
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