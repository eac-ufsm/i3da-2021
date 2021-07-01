clear all; clc; close all; 
% BRIR auralization with head tracker
%% Config options
add_binaural_ch = true; % if true consideres the last 2 channels as binaural signals already
use_live_ht = false; % if true load the head tracker for real time head orientation 
load_ht_data = true; % it true specify the path for the head tracker measurement
save_output = true;  % whether to record the playback audio or not

%% Define input paths
% SOFA
path = 'C:\Users\rdavi\Desktop\artigo Fred\';
% path_sofa = [path 'BRIR_ms\car_BRIRs.sofa'];
% path_sofa = [path 'BRIR_ms\Obj_car_windowed.sofa'];
% path_sofa = [path 'BRIR_ms\Obj_band_filtered.sofa'];
path_sofa = [path 'BRIR_ms\Obj_band_filtered_calib.sofa'];

% AUDIO 
% path_audio = [path 'Musica\cena1\audio_comp_7ch.wav'];
path_audio = [path 'Musica\cena2\audio_comp_7ch.wav'];

% HEAD TRACKER 
path_tracker = 'C:\Users\rdavi\Desktop\artigo Fred\Musica\Gravações Biauriculares-20210626T195523Z-001\Gravações Biauriculares\';
% path_ht_data = [path 'Musica\cena1\conversa_pai_e_filho_resampled.mat'];
path_ht_data = [path_tracker 'taxi_pt1_resampled.mat'];

% Output file name
file = ['car_cena1_' 'Obj_band_filtered_calib.wav'];
% file = ['car_cena2_' 'Obj_band_filtered_calib.wav'];
% file = 'teste.wav';

%% Start Head Tracker from binaries
if use_live_ht
    addpath('D:\Documentos\1 - Work\internoise2021-headtracker\src\output'); %#ok<*UNRCH>
    open('HeadTracker.exe') 
    % Connect to UDP port
    try
        release(udpr)
    catch
    end
    udpr = dsp.UDPReceiver('RemoteIPAddress', '127.0.0.1',...
                           'LocalIPPort',50050, ...
                           'ReceiveBufferSize', 18);
end
% Initialize head orientation
pitch = 0;  % head tracker
yaw = 0;    % head tracker

%% Load HT data
if load_ht_data
    load(path_ht_data, 'resampled_HT')
    yaw=resampled_HT(1,1);
end


%% Load BRIR
Obj = SOFAload(path_sofa, 'nochecks');
Fs = Obj.Data.SamplingRate;
listener_posi = Obj.ListenerView;
BRIRs = permute(Obj.Data.IR, [2,4,3,1]);
BRIRs = BRIRs./max(abs(BRIRs(:)))*.5; % cena1=.10, cena2=.10
n_ch_brir = size(Obj.Data.IR,3);
% Change from spherical to navigational coordinates 
listener_posi = -sph2nav(listener_posi);


%% Load audio
[audio, fs_audio] = audioread(path_audio);
n_ch_audio = size(audio,2)-3; %#ok<NASGU>

if fs_audio ~= Fs
    audio = resample(audio,Fs,fs_audio);
end
audio = audio./max(abs(audio(:)))*.7;


% if add_binaural_ch 
%     bin_audio = audio(:, end-1:end);
%     audio(:, end-2:end) = []; % -2 removes also the brir in the passenger seat 
% end



%% Audio to DSP object
samples_per_frame = 2048;
sigsrc = dsp.SignalSource(audio, samples_per_frame);

% if add_binaural_ch 
%     sig_bin = dsp.SignalSource(bin_audio,samples_per_frame);
% end

deviceWriter = audioDeviceWriter('SampleRate', Fs, "BitDepth","16-bit integer");
setup(deviceWriter, zeros(samples_per_frame, 2))
        
%% Configs
% Set the source positions
sourcePositions = Obj.EmitterPosition;
% Find corresponding hrtf index
idx_hato = dsearchn(listener_posi(:,1), yaw);
IR = BRIRs(:,:,:,idx_hato);    

    
%% START AURALIZATION
% Define FIR filters
% for k =1:n_ch_audio*2
%     FIR{k} = dsp.FIRFilter('NumeratorSource','Input port');
% end
PartitionSize = 4096;
for k =1:n_ch_audio
        fdfOA1{k} =  dsp.FrequencyDomainFIRFilter('Method', 'overlap-add',...
                                                   'PartitionForReducedLatency', true,...
                                                    'PartitionLength',PartitionSize);
        fdfOA2{k} =  dsp.FrequencyDomainFIRFilter('Method', 'overlap-add',...
                                                'PartitionForReducedLatency', true,...
                                                    'PartitionLength',PartitionSize);
end


release(deviceWriter) % just to make sure matlab isn't already using the device
release(sigsrc)
% release(sig_bin)

out_l = zeros(samples_per_frame,n_ch_audio);
out_r = zeros(samples_per_frame,n_ch_audio);
out = zeros(samples_per_frame,2);
pos = listener_posi(:,1);
saveout = zeros(length(audio)+samples_per_frame,2);

cont_start = 1;
cont_end = cont_start+samples_per_frame-1;

idx_changer = inf;
while ~isDone(sigsrc) 
    
    %%%% Read audio file   
    audioIn = sigsrc();   
    
    %%%% HEAD TRACKER 
    if use_live_ht % Real time tracking
%         drawnow limitrate
        py_output = udpr();
        if ~isempty(py_output)            
            data = str2num(convertCharsToStrings(char(py_output))); %#ok<*ST2NM>
            idx_hato = dsearchn(pos, data(1));
            % Obtain a pair of HRTFs at the desired position.
            IR = BRIRs(:,:,:,idx_hato);
        end
                
    end
    if load_ht_data % Recorded tracking
        if cont_end < length(resampled_HT)
            yaw = resampled_HT(cont_start,1);
            idx_hato = dsearchn(pos, yaw);
            % Obtain a pair of BRIRs at the desired position.
            IR = BRIRs(:,:,:,idx_hato);    
        end            
    end    
       
    %%%% Apply BRIRs
    for n=1:4
        if idx_changer ~= idx_hato
            fdfOA1{n}.Numerator = IR(1,:,n);
            fdfOA2{n}.Numerator = IR(2,:,n);           
        end
        out_l(:,n) = fdfOA1{n}(audioIn(:,n));
        out_r(:,n) = fdfOA2{n}(audioIn(:,n));
    end
    idx_changer = idx_hato;
    
    %%%% Fetch output
    if add_binaural_ch
        out = [mean([out_l, audioIn(:,6)],2),...
               mean([out_r, audioIn(:,7)],2)];
    else % no binaural channels
        out = [mean(out_l,2),...
               mean(out_r,2)];
    end
    
    deviceWriter(out);
    
    %%%Save audio output 
    if save_output
        saveout(cont_start:cont_end,:) = out; %#ok<AGROW>
    end   
    cont_start = cont_end+1;
    cont_end = cont_start+samples_per_frame-1;
end
release(sigsrc)
release(deviceWriter)


%% Save auralization 
saveout = saveout./max(abs(saveout(:)))*0.96;
filename = file;
audiowrite(filename, saveout, fs_audio)


%% Fast conv
function y = fast_conv(x1, x2)
    nfft = length(x1) + length(x2) - 1;
    y = real(ifft(fft(x1, nfft).*fft(x2, nfft)));
end
