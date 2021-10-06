%   Code for the BRIRs measurements inside the car cabin. A webcam
%   headtracker (powered by Davi) is used to track the azimuth angles.
%
%	Part of the paper "Measurement of car cabin binaural impulse responses via convolution" 
%	presented at the I3DA conference, in Bologna (Italy).
%
%	William D'Andrea Fonseca, Felipe Ramos de Mello, Davi Rocha Carvalho, Paulo Henrique Mareze and Olavo Silva.
%
%% Cleaning Service

clear all; close all; clc;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Connect to UDP port - Headtracker
udpr = dsp.UDPReceiver('RemoteIPAddress', '127.0.0.1',...
                       'LocalIPPort',50050, ...
                       'ReceiveBufferSize', 18);
                   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Excitation signal

ms.fs = 44100; % Sampling rate
ms.fftDeg = 18; % Number of samples = 2.^fftDeg
ms.freqRange = [200, 20e3]; % Frequency range
ms.sweepITA = ita_generate_sweep('samplingRate', ms.fs, 'fftDegree', ms.fftDeg,...
    'freqRange', ms.freqRange, 'mode', 'exp');

ms.nSamples = ms.sweepITA.nSamples;
ms.audioLength = ms.sweepITA.nSamples/ms.fs;
ms.outputGain = 10.^(-3/20); % linear
ms.sweep = ms.outputGain.*ms.sweepITA.time; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Measurement setup

% Angle setup
ms.minAngle = -40;
ms.maxAngle = 40;
ms.angleRange = ms.maxAngle - ms.minAngle;
ms.angleResolution = 5;
ms.numOfMS = ms.angleRange/ms.angleResolution + 1;

% Audio setup
% asiosettings;
playRec = audioPlayerRecorder('SampleRate', ms.fs);
playRec.Device = 'ASIO4ALL v2';
playRec.BufferSize = 512*4;
playRec.PlayerChannelMapping = [1 2];
playRec.RecorderChannelMapping = [1 2];

% Structure for the results
results = cell(ms.numOfMS, 3); % angle, recording, headtracker data
recording = zeros(ms.nSamples, 2);
headtracking = zeros(128, 3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Dummy session para aquecer os motores

clc;

signal = zeros(ms.nSamples, 2);

% Contadores
lowerCounter = 1;
upperCounter = playRec.BufferSize;
headCounter = 1;

totalOR = 0;
totalUR = 0;

% Prompt para controle da medição
fprintf('Medição zero para aquecer os motores\n\n');
prompt = '    Aperte enter para começar\n';
input(prompt);


while upperCounter <= ms.nSamples
    
    [audioRecorded, nUnderruns, nOverruns] = playRec([ms.sweep(lowerCounter:upperCounter, 1), ms.sweep(lowerCounter:upperCounter, 1)]);
    recording(lowerCounter:upperCounter, :) = audioRecorded;
    
    totalUR = nUnderruns + totalUR;
    totalOR = nOverruns + totalOR;
    
    lowerCounter = upperCounter + 1;
    upperCounter = upperCounter + playRec.BufferSize;
    
    % Ler orientação atual do HeadTracker.
    py_output = step(udpr);
    
    if ~isempty(py_output)
        data = str2num(convertCharsToStrings(char(py_output))); %#ok<*ST2NM>
        headtracking(headCounter, 1) = data(1); % yaw
        headtracking(headCounter, 2) = data(2); % pitch
        headtracking(headCounter, 3) = data(3); % row
        
        headCounter = headCounter + 1;
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Medição

msCounter = 1;

while msCounter <= ms.numOfMS
   
    clc;
    
    % Contadores
    lowerCounter = 1;
    upperCounter = playRec.BufferSize;
    headCounter = 1;
    
    totalOR = 0;
    totalUR = 0;
    
    % Prompt para controle da medição
    fprintf('Medição número %d, ângulo (pitch) %.0f\n\n', msCounter, (msCounter*5 - 45));
    prompt = '    Aperte enter para começar\n';
    input(prompt);
    
    
    while upperCounter <= ms.nSamples
        
        [audioRecorded, nUnderruns, nOverruns] = playRec([ms.sweep(lowerCounter:upperCounter, 1), ms.sweep(lowerCounter:upperCounter, 1)]);
        recording(lowerCounter:upperCounter, :) = audioRecorded;
        
        totalUR = nUnderruns + totalUR;
        totalOR = nOverruns + totalOR;
        
        lowerCounter = upperCounter + 1;
        upperCounter = upperCounter + playRec.BufferSize;
        
        % Ler orientação atual do HeadTracker.
        py_output = step(udpr);
        
        if ~isempty(py_output)
            data = str2num(convertCharsToStrings(char(py_output))); %#ok<*ST2NM>
            headtracking(headCounter, 1) = data(1); % yaw
            headtracking(headCounter, 2) = data(2); % pitch
            headtracking(headCounter, 3) = data(3); % roll
            
            headCounter = headCounter + 1;
        end
    
    end
    
    results{msCounter, 1} = sprintf('Azimute: %.0f°', msCounter*5 - 45);
    results{msCounter, 2} = recording;
    results{msCounter, 3} = headtracking;
   
    release(playRec);
    
    if totalOR == 0 && totalUR == 0
         aa = itaAudio(results{msCounter, 2}, ms.fs, 'time');
         aa = aa/ms.sweepITA;
         aa.plot_freq; %aa.plot_time;
         
         prompt = 'Aceitar a medição? [y/n]\n';
         resp = input(prompt, 's');
         
         if resp=='y'
             disp('Medição realizada com sucesso!')
             msCounter = msCounter + 1;
         else
             prompt = 'Algo deu errado... Aperte enter para refazer:\n';
             input(prompt);
         end
         
    else
        prompt = 'Algo deu errado... Aperte enter para refazer:\n';
        input(prompt);
    end
    
end

clc;

prompt = 'Todas as medições foram realizadas com sucesso! Aperte enter para finalizar\n';
input(prompt);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Save data

% fileName = 'measurements/car_cabin_all_speakers_BRIR.mat'; info = 'Car sound system, all Speakers BRIR measurement';
% fileName = 'measurements/car_cabin_front_left_BRIR.mat'; info = 'Car sound system, front left BRIR measurement';
% fileName = 'measurements/car_cabin_front_right_BRIR.mat'; info = 'Car sound system, front right BRIR measurement';
% fileName = 'measurements/car_cabin_rear_left_BRIR.mat'; info = 'Car sound system, rear left BRIR measurement';
% fileName = 'measurements/car_cabin_rear_right_BRIR.mat'; info = 'Car sound system, rear right BRIR measurement';
fileName = 'measurements/passenger_loudspeaker_BRIR.mat'; info = 'Passenger loudspeaker BRIR measurement';

save(fileName, 'ms', 'results', 'info')

%% Backup 

save('backup/backup_ms6.mat');
