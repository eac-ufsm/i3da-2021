%   Construção de uma curva de correção baseada nas medições de comparação
%   com o bruel
%
%% Cleaning service

clear all; close all; clc; clear memory;

%% Carregando os dados

% Na pastinha tem um txt com as curvas de correção de ambos os mics, só
% ajustar para elas
mic10 = readmatrix('mic10.txt');

correction = mic10(:, 4); 
freqVec = mic10(:, 1);

% Aqui eu verifico quais são as bandas que faltam para completar o espectro
% de 0 Hz à fs/2
f1 = [0 ita_ANSI_center_frequencies([1, 15], 3)];
f2 = [ita_ANSI_center_frequencies([14500, 44100/2], 6) 44100/2];

% Vetores que usarei para a interpolação
freqInterp = [f1 freqVec'];
% Aqui eu estrapolo o primeiro valor que medi (em 60 Hz) até 0 Hz. Se
% quiser, pode fazer com que eles sejam 0 dB, é uma opção tbm
correctionInterp = [correction(1)*ones(1, length(f1)) correction'];

%% Plot

figure('Name', 'Correction', 'outerposition', [100 100 1300 750], 'defaultaxesfontsize', 18);
semilogx(freqInterp, correctionInterp, 'linewidth', 2); hold on;
grid on;

%% Filtro 1

% Eu fiz um teste para usar dois filtros ao invés de apenas 1. Pareceu que
% funcionou melhor, devido ao formato da curva. Mas deixarei comentado,
% creio que não será necessário
% filter1 = [correctionInterp(1:50) zeros(1, length(correctionInterp(51:end)))];
% filter2 = [zeros(1, length(correctionInterp(1:50))) correctionInterp(51:end)];

%% Curve fitting

xq1 = linspace(0, 44100/2, 1000); % pontos de 0 à fs/2 (1000 no total)
p1 = pchip(freqInterp, correctionInterp, xq1);

figure('Name', 'Correction', 'outerposition', [100 100 1300 750], 'defaultaxesfontsize', 18);
semilogx(freqInterp, correctionInterp, 'linewidth', 2); hold on;
semilogx(xq1, p1, 'linewidth', 2); hold on;
legend('Correction curve', 'p1');
grid on;

%% Geração do filtro de correção

F = xq1/(44100/2); % O vetor de frequências precisa ser normalizado
A1 = 10.^(p1/20); % A curva de correção precisa estar numa escala linear

N = 16; % Ordem do filtro (vale a pena testar outros valores)
D1 = fdesign.arbmag('N,F,A', N, F, A1); % Gera os coeficientes para o filtro
hd1 = design(D1, 'iirlpnorm'); % Construção de um filtro IIR com as especificações de D


%% Para gerar rapidamente um sweep

% sweep = ita_generate_gui;
sweep = ita_generate_sweep('fftDegree', 21, 'mode', 'exp', 'samplingRate', 44100,...
    'freqRange', [1 22000]);

%% Cálculo da FRF do filtro 1

% Resposta ao impulso do filtro gerado por resposta em freq arbitrária
impulse_response = hd1.filter(sweep.time); % resposta ao impulso do filtro hd
impulse_response_ITA = itaAudio(impulse_response,  44100, 'time'); % resposta ao impulso itaAudio

frfITA = ita_divide_spk(impulse_response_ITA, sweep);

%% Plot para comparação

close all;

frf = frfITA.freqData_dB;
freqVec = frfITA.freqVector;

figure('Name', 'n', 'outerposition', [100 100 1300 750], 'DefaultAxesFontSize', 18)
semilogx(freqVec, frf, 'linewidth', 2); hold on;
semilogx(mic10(:, 1), mic10(:, 4), '--', 'linewidth', 2);
legend('Filtro via resposta arbitrária', 'Curva medida', 'location', 'south');
grid on;
xlabel('Frequência [Hz]');
ylabel('Magnitude [dB ref. 1]');
title({'Comparação entre a curva de correção medida e o filtro gerado'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Essa parte é mais relacionada ao teensy, não precisa se preocupar tanto

%% Construção de um filtro biquadrático (IIR) à partir dos coeficientes de hd

sosMatrix1 = hd1.sos; % Coeficientes [b0, b1, b2, a0, a1, a2]
scaleValues1 = hd1.ScaleValues; % Valores de ganho aplicados entre os estágios

%% Coeficientes filtro1 para aplicar no Teensy

scaleValue = prod(hd1.ScaleValues); % Ganho acumulado de todos os estágios
sosMatrix = hd1.sos;

% Aqui realizo uns ajustes para que os coeficientes fiquem de acordo com o
% padrão da biblioteca CMSIS
coeffs = sosMatrix(:, [1:3 5:6]); % Retiro a0 
coeffs(:, 4:5) = -1*coeffs(:, 4:5); % Inverto o sinal de a1 e a2
coeffs(1, 1:3) = coeffs(1, 1:3)*scaleValue; % Aplico o ganho

% Imprimo no command window os coeficientes no formato adequado para
% aplicar diretamente ao objeto de áudio do Teensy
clc;
for i = 1:length(coeffs)
%     input("Digite enter para continuar \n");
    fprintf('%.18f, %.18f, %.18f, %.18f, %.18f,\n', coeffs(i, :));
end
