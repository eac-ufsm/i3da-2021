% Example on how to generate an exponential sine sweep with controlable frequency
% response slope (in case a flat frequency response is needed, for example)
%
% The slope is adjusted multiplying the sine sweep by an adequate exponential function,
% which dependes on the signal duration and the relationship between the first and last
% frequencies. 
%
% Based on the article "Impulse response measurement with sine
% sweeps and amplitude modulation schemes" by Q. Meng, D. Sen, S. Wang e L.
% Hayes
%
% This kind of signal was used to measure the impulse response inside a car cabin,
% where the extra gain on low frequencies of the normal exponential sine sweep was
% causing distortion problems. To solve this problem and maintain the adequate SNR,
% a flat frequency response exponential sine sweep was used.
%
% Part of the paper "Measurement of car cabin binaural impulse responses and auralization via convolution"
% presented at the I3DA 2021 conference.
%
% William D'Andrea Fonseca, Felipe Ramos de Mello, Davi Rocha Carvalho, Paulo Henrique Mareze and Olavo Silva
%
% Last update: 06/10/21 

%% Cleaning service

clear all; clc;

%% Configurações

fs = 44100; % Sample rate
T = 20; % Duration of the signal in seconds
t = (0:1/fs:T)'; % Time vector

fftDeg = log2(length(t)); % Signal's fftDegree

f1 = 22; % First frequency
f2 = 22e3; % Last frequency

% Angelo Farina's exponential sweep equation constants
L = T/(log(f2/f1)); % cte 1
K = (T*2*pi*f1)/(log(f2/f1)); % cte 2

% Exponential function for the amplitude modulation
n = 1; % n = 1 -> +3dB/oct /// n = 2 -> 0dB/oct
m = exp(t./(n*L)); % exp. function

% Building the exponential sweep
s = sin(K.*(exp(t/L) - 1)); % "original" exponential sweep
s_mod = s.*m; % exponential sweep with amplitude modulation

% Normalization
s = s./max(abs(s));
s_mod = s_mod./max(abs(s_mod));

%% Checking the frequency response

[S, freqVec] = ssFFT(s, fs, 1);
[S_mod, ~] = ssFFT(s_mod, fs, 1);

[~, idx2] = min(abs(freqVec - 2000));
[~, idx1] = min(abs(freqVec - 1000));

decaimento = 20*log10(S_mod(idx2)) - 20*log10(S_mod(idx1));

fprintf('\nDecaimento: %2.2f dB/oct\n', decaimento);

%% Plots in time and frequency

fig = figure;
fredPlot(fig);

subplot(2, 2, 1);
plot(t, s, 'linewidth', 1.5); hold on; grid on;
xlabel('Time [s]');
ylabel('Amplitude [-]');
title({'Original sweep'});

subplot(2, 2, 2);
plot(t, s_mod, 'linewidth', 1.5); hold on; grid on;
xlabel('Time [s]');
ylabel('Amplitude [-]');
title({'Amp. modulated sweep'})

subplot(2, 2 ,3);
semilogx(freqVec, 20*log10(abs(S)), 'linewidth', 1.5); xlim([f1, f2]); grid on;
xlabel('Frequency [Hz]');
ylabel('Amplitude [-]');

subplot(2, 2, 4);
semilogx(freqVec, 20*log10(abs(S_mod)), 'linewidth', 1.5); xlim([f1, f2]); grid on;
xlabel('Frequency [Hz]');
ylabel('Amplitude [-]');


%% Using the amp. modulated sweep on an actual measurement

excitation = itaAudio(s_mod', fs, 'time');

%% Audio device config

ita_portaudio_deviceID2string(0);
ita_preferences('recDeviceID', 0);
ita_preferences('playDeviceID', 0);

%% MS definition

inCh = [1]; % input (mic 1)
outCh = [1, 2]; % output (L) 
outAmp = -3; % output amplification = -3 dBFS

ms = itaMSPlaybackRecord('inputChannels', inCh,...
                        'outputChannels', outCh,...
                        'outputamplification', outAmp,...
                        'fftDegree', fftDeg, 'precision', 'double');

ms.excitation = excitation;

%% Running

measurement = ms.run;

%% FFT

RI = ita_divide_spk(measurement, excitation, 'mode', 'linear');
RI.plot_time; RI.plot_freq;