%   Função que retorna o "single-sided" amplitude spectrum de um sinal 
%   e seu vetor de frequências
%
%   Felipe Ramos de Mello
%%

function [spectrum, freqVec] = ssFFT(signal, fs)

N = length(signal);
freqVec = (fs*(0:N/2)/N)';

Y = fft(signal); % cálculo da fft
P2 = abs(Y/N); % ajuste da escala de amplitude do espectro duplo (com as freqs negativas)
spectrum = P2(1:N/2+1); % conversão para o espectro simples (apenas freqs positivas)
spectrum(2:end-1) = 2*spectrum(2:end-1); % ajuste da amplitude

end