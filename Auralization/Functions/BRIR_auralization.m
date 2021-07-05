clear all; clc; 
% BRIR auralization with head tracker
% Davi R. Carvalho - Eng Acustica @ UFSM - JUL/2021

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Config options: %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_binaural_ch = true; % if true consideres the last 2 channels as binaural signals already
use_live_ht = true; % if true load the head tracker for real time head orientation 
load_ht_data = true; % it true specify the path for the head tracker measurement
save_output = true;  % whether to record the playback audio or not
scene = 1;           % Pick which scen you want to listen


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Define input paths %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SOFA
path_sofa0 = '../SOFA files/';
% path_sofa = [path_sofa0, 'Obj_car_windowed.sofa']; % Only time window was used
path_sofa = [path_sofa0, 'Obj_band_filtered_calib.sofa']; %  complete post processing

% Config scenes 
path_audio0 = '../Input audios/';
path_tracker0 = 'Processing recorded HT/';
if scene == 1
    path_audio = [path_audio0 'scene1.wav'];  
    path_ht_data = [path_tracker0 'conversa_pai_e_filho_resampled.mat']; % recorded HT
    use_live_ht = false;
    if save_output
        output_filename = ['car_cena1_' 'Obj_band_filtered_calib.wav'];   
    end
elseif scene ==2 
    path_audio = [path_audio0 'scene2.wav'];  
    path_ht_data = [path_tracker0 'taxi_pt1_resampled.mat']; % recorded HT
    use_live_ht = false;
    if save_output
        output_filename = ['car_cena2_' 'Obj_band_filtered_calib.wav'];   
    end
else % scene 3
    path_audio = [path_audio0 'scene3.wav'];  
    use_live_ht = true;
    load_ht_data = false;
    if save_output
        output_filename = ['car_cena3_' 'Obj_band_filtered_calib.wav']; 
    end
end


%% Start Head Tracker from binaries
if use_live_ht
    link = '<a href="https://github.com/eac-ufsm/internoise2021-headtracker/releases">here</a>';
    try
        addpath('D:\Documentos\1 - Work\internoise2021-headtracker\src\output'); 
        open('HeadTracker.exe') 
    catch 
        fprintf(['The Head tracker was not found at MATLAB path! \n' ...
              'Click ' link ' to download. \n'])
    end
    % Connect to UDP port
    udpr = dsp.UDPReceiver('RemoteIPAddress', '127.0.0.1',...
                           'LocalIPPort',50050, ...
                           'ReceiveBufferSize', 18);
end
% Initialize head orientation
yaw = 0;    % head tracker


%% Load HT data
if load_ht_data
    load(path_ht_data, 'resampled_HT')
    yaw=resampled_HT(1,1);
end


%% Load BRIR
Obj = SOFAload(path_sofa, 'nochecks');
Fs = Obj.Data.SamplingRate;
BRIRs = permute(Obj.Data.IR, [2,4,3,1]);
BRIRs = BRIRs./max(abs(BRIRs(:)))*.1; % cena1=.10, cena2=.10
n_samples = size(BRIRs,2);
n_ch_brir = size(Obj.Data.IR,3);
% Change from spherical to navigational coordinates 
listener_posi = Obj.ListenerView;
listener_posi = -sph2nav(listener_posi);
pos = listener_posi(:,1);
n_listener_pos = length(listener_posi);
% Initialize first hato for auralization loop
idx_hato = dsearchn(listener_posi(:,1), yaw);


%% Load audio
[audio, fs_audio] = audioread(path_audio);
n_ch_audio = size(audio,2)-3; 

if fs_audio ~= Fs
    audio = resample(audio,Fs,fs_audio);
end
audio = audio./max(abs(audio(:)))*.9;


%% Audio to DSP object
samples_per_frame = 2048; % In you experience underruns or glitches turn this up to solve it
% considering the head tracker recordings for scenes 1 and 2 was done with a
% buffer size of 2048, there's no benefits in using a lower buffer size for
% these scenes
sigsrc = dsp.SignalSource(audio, samples_per_frame);

deviceWriter = audioDeviceWriter('SampleRate', Fs, "BitDepth","16-bit integer");
setup(deviceWriter, zeros(samples_per_frame, 2))
        

%% Pre-config 
% Initialize  FIR filters
PartitionSize = 2^nextpow2(n_samples/2);
firBRIR_L = cell(1,n_ch_audio);
firBRIR_R = cell(1,n_ch_audio);
for s=1:n_ch_audio
    firBRIR_L{s} =  dsp.FrequencyDomainFIRFilter('Method', 'overlap-add',...
                                              'PartitionForReducedLatency', true,...
                                              'PartitionLength', PartitionSize );
        firBRIR_R{s} =  dsp.FrequencyDomainFIRFilter('Method', 'overlap-add',...
                                                  'PartitionForReducedLatency', true,...
                                                  'PartitionLength', PartitionSize);
end
% pre-allocate other variables
sz = size(firBRIR_L);
out_l = zeros(samples_per_frame,n_ch_audio);
out_r = zeros(samples_per_frame,n_ch_audio);
out = zeros(samples_per_frame,2);
saveout = zeros(length(audio)+samples_per_frame,2);
cont_start = 1;
cont_end = cont_start+samples_per_frame-1;
idx_changer =inf;


%% START AURALIZATION
release(deviceWriter) % just to make sure matlab isn't already using the device
release(sigsrc)
while ~isDone(sigsrc) 
    %%%% Read audio file   
    audioIn = step(sigsrc);   
    %%%% HEAD TRACKER 
    if use_live_ht % Real time tracking
        py_output = step(udpr);
        if ~isempty(py_output)            
            data = str2double(split(convertCharsToStrings(char(py_output)), ','));
            idx_hato = dsearchn(pos, data(1));
        end                
    end
    if load_ht_data % Recorded tracking
        if cont_start < length(resampled_HT)
            yaw = resampled_HT(cont_start,1);
            idx_hato = dsearchn(pos, yaw);   
        end            
    end           
    %%%% Apply BRIRs
    for n=1:4
        if idx_changer ~= idx_hato
            firBRIR_L{n}.Numerator = BRIRs(1,:,n,idx_hato);
            firBRIR_R{n}.Numerator = BRIRs(2,:,n,idx_hato);
        end
        out_l(:,n) = firBRIR_L{n}(audioIn(:,n));
        out_r(:,n) = firBRIR_R{n}(audioIn(:,n));   
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
    %%% Write audio to device
    deviceWriter(out);    
    %%% Save audio output 
    if save_output
        saveout(cont_start:cont_end,:) = out; 
    end   
    %%% Update counters
    cont_start = cont_end+1;
    cont_end = cont_start+samples_per_frame-1;
end
release(sigsrc)
release(deviceWriter)


%% Save auralization 
saveout = saveout./max(abs(saveout(:)))*0.96;
audiowrite(output_filename, saveout, fs_audio)