clear; clc

%% Load files
path = fileparts(which('Assemble_input_audio.m'));
files  = dir([path, '\*.wav']); 

% Calibration 
path = 'C:\Users\rdavi\Desktop\artigo Fred\MEMS mics frequency response\';
[calib_filt, fs_calib] = audioread([path 'Mic_calibration.wav']);

%% car speakers
car = [];
for k=1:4
    [x, fs] = audioread([files(k).folder, '\' files(k).name]);
    if size(x,2)>1
        x = sum(x, 2);
    end
    car = cat(2, car, x);
end

%% Pading for the "passenger speaker" 
pa  = zeros(length(car),1);

%% Binaural recordins
bin_rec = zeros(length(car) + length(calib_filt) - 1, 2);
% bin_rec = zeros(length(car),2);
cont= 0;
for k=5:size(files,1)
    [x, fs] = audioread([files(k).folder, '\' files(k).name]);
    xf = fast_conv(x, calib_filt); % calibration
    bin_rec = bin_rec + xf;
    cont = cont+1;
end
bin_rec = bin_rec./cont;

% Output
y = [car, pa, bin_rec(1:length(car),:)];
y = y./max(abs(y(:)))*0.97;

filename = ['audio_comp_', num2str(size(y,2)), 'ch.wav'];
audiowrite(filename, y, fs);






%% Fast conv
function y = fast_conv(x1, x2)
    nfft = length(x1) + length(x2) - 1;
    y = real(ifft(fft(x1, nfft).*fft(x2, nfft)));
end