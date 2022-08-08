clear; clc

%% LOad SOFA
path_sofa = '';
Obj = SOFAload([path_sofa 'raw_BRIRs.sofa'], 'nochecks');
Obj = truncate_IR(Obj);
fs = Obj.Data.SamplingRate;
sz = size(Obj.Data.IR);
dimorder = length(sz):-1:1;
IR = permute(Obj.Data.IR, dimorder);
N_ir = size(IR,1);
TRmax = 0.22;
N_out = fs*TRmax;

%% SOFA files windowing
% IR_win = zeros(size(IR));
clear IR_win
thr = 10;
for k = 1:size(IR, 2)
    for m = 1:size(IR, 4)
       A = IR(5000:end-1,k,1,m); % L
       B = IR(5000:end-1,k,2,m); % R  
       N_ir = size(A,1);
       % Get onset 
       OnSetL = IR_start(A, thr);
       OnSetR = IR_start(B, thr); 
       winL  = create_window(TRmax, N_ir, OnSetL, fs);
       winR  = create_window(TRmax, N_ir, OnSetR, fs);
       IR_win(:,k,1,m) = A.*winL;
       IR_win(:,k,2,m) = B.*winR;
       if k == 1 && m == 1 
           win_save = winL;
       end
    end
end
IR_win = permute(IR_win, dimorder);
IR_win = IR_win./max(abs(IR_win(:)));


%% View output 
Obj_win = Obj;
Obj_win.Data.IR = IR_win; %(:,:,:,5150:22000-1);
plot_mag_phase(Obj, Obj_win, 'Calibration (bruel)')
size(Obj_win.Data.IR)


SOFAsave('windowed_BRIRs.sofa', Obj_win);% only calibration

save('window_for_plot', 'win_save')

%%

% figure()
% for k = 1:5
%     for m= 1:2
%     plot(squeeze(Obj_win.Data.IR(:,m,k,:)).'); hold on 
%     end
% end
% size(Obj_win.Data.IR)


%% Internal function ------------------------------------------------------
function win = create_window(TRmax, N_ir, OnSet, fs)
%% criar janela
% TRmax = 1.5;   % Max expected TR
% N_ir = 26000;  % BRIR length
% OnSet          % IR start
N_TRmax = ceil(TRmax*fs);

lin_size = 50;
idx_start = OnSet-lin_size;
idx_end = ceil(N_TRmax);
win_decay = tukeywin(2*(idx_end-idx_start), 0.4);
win_decay = win_decay(length(win_decay)/2:end-1);

% win_mid = ones(idx_start, 1);

win_begin = zeros(idx_start-lin_size,1);

win_end = zeros(N_ir -(length(win_begin)+length(win_decay)),1);
% win = [win_begin; win_decay; win_end];
win = [win_begin; ones(abs(length(win_begin) - N_ir),1)];
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
IR1 = shiftdim(Obj.Data.IR, 3);
IR2 = shiftdim(Obj2.Data.IR, 3);

ir1 = IR1(5000:end,1,1,1);       
ir2 = IR2(1:end,1,1,1);

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
subplot(311)

plot(tx1, ir1); hold on 
plot(tx2, ir2); 


xlim([0, tx1(end)])
% axis tight
xlabel('Time (s)')
ylabel('Amplitude')
legend('Original', 'Windowed', 'location', 'best')

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