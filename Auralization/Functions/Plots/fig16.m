%% 
% plot fig 16 
clear all;clc; close all

uiopen('C:\Users\rdavi\Desktop\artigo Fred\BRIR_ms\BRIRcalib.fig',1)

%% Carregar janela 
load('window_for_plot')
win_save(1:5150) = [];
N1 = length(win_save);
fs1=44100;
tx1 = (0:N1-1)/fs1; 

                  

%
h = figure(1);
 
subplot(211)
color= [150 0 255]./255;
plot(tx1, win_save , 'color', color, 'linewidth', 2);
legend('Original', 'Window + Calibration + Band filter', 'Time window', ...
                        'location', 'southeast')

 
set(gca, 'FontSize', 20)                    
    
% subplot(211)
% set(gca, 'FontSize', 20)                    
% sgtitle(gtitle, 'Fontsize', 20, 'FontWeight', 'bold'); 
% 

hFigure = figure(1);
filename = [pwd, '\BRIRcalib.pdf' ];
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')
