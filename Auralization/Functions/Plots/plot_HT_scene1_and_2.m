% Plot head tracking over time for scenes 1 nd 2
clear all; clc
%% LOAD files
path = 'C:\Users\rdavi\Desktop\artigo Fred\';
path1 = [path 'Musica\cena1\conversa_pai_e_filho_resampled.mat'];
path2 = [path 'Musica\cena2\taxi_pt1_resampled.mat'];

cena1 = load(path1);
cena2 = load(path2);
data1 = cena1.resampled_HT(:,1);
data2 = cena2.resampled_HT(:,1);
% data1 = nav2sph(cena1.resampled_HT(:,1));
% data2 = nav2sph(cena2.resampled_HT(:,1));
k = 2048*15;
data1smooth = smoothdata(data1, 'sgolay',k);
data2smooth = smoothdata(data2, 'sgolay',k);

ytik = 40:-10:-40;
ytiklabel = (nav2sph(ytik));

%%
fs= 44100;
N1=length(data1);
tx1=(0:N1-1)./fs;

N2=length(data2);
tx2=(0:N2-1)./fs;

hFigure = figure('outerposition', [100 100 1200 675]);

subplot(211)
plot(tx1, data1smooth, 'b','linewidth', 1.2);hold on 

legend('Scene 1 - Father and son','Location', 'southwest')
xlabel('Time (s)')
ylabel('Angle (°)')
set(gca, 'FontSize', 18)

yticks(flip(ytik))
yticklabels(ytiklabel)
% xticks(sort([0:20:120, floor(tx1(end))]))
% xticklabels(sort([0:20:120, floor(tx1(end))]))
axis tight
ylim([-30 30])
grid on 



subplot(212)
plot(tx2, data2smooth, 'r', 'linewidth', 1.2)
axis tight
legend('Scene 2 - Taxi', 'Location', 'southwest')
xlabel('Time (s)')
ylabel('Angle (°)')
set(gca, 'FontSize', 18)
ylim([-30 30])
yticks(flip(ytik))
yticklabels(ytiklabel)
grid on 


sgtitle('Horizontal head moviments over time',...
            'Fontsize', 18, 'FontWeight', 'bold'); 
set(gca, 'Fontsize', 18)

% % Moving mean 
% M1 = movmean(data1,fs*20);
% M2 = movmean(data2,fs*20);
% plot(tx1, M1, '--o', 'linewidth', 0.5)
% plot(tx2, M2, 'linewidth', 1)

%%

filename = [pwd, '\Yaw_scenes1and2.pdf' ];      
exportgraphics(hFigure,filename,'BackgroundColor','none','ContentType','vector')