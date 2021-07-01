% check HT vs audio sampling 
clear; clc;

%% LOAD data 
path = 'C:\Users\rdavi\Desktop\artigo Fred\Musica\Gravações Biauriculares-20210626T195523Z-001\Gravações Biauriculares';
name_list = dir([path, '\*.mat']);
idx_del=[];
for i=1:numel(name_list)
    if contains((name_list(i).name), '_resampled')
        idx_del = [idx_del,i];
    end
end
name_list(idx_del) = [];

for k = 1:size(name_list,1)
    [tmp,~] = split(name_list(k).name, '_mat');
    name=tmp{1};
    load([path '\' name '_mat.mat']);
    resampled_HT = resample_HT(headtracking);
    filename = [path '\' name, '_resampled.mat'];
    save(filename, 'resampled_HT');
end



%% PLOTS
% % time_vec_audio = (0:N_audio-1)/fs_audio;
% % plot(time_vec_audio, audio(:,1)); hold on 
% 
% % Real
% N_ht = length(headtracking);
% time_vec_ht = (0:N_ht-1)/fs_ht;
% plot(time_vec_ht, headtracking); hold on
% 
% % Interpolado
% N_ht = length(headtracking);
% time_vec_ht = (0:N_audio-1)/fs_audio;
% plot(time_vec_ht, resampled_HT); hold off
% 
% xlabel('Time (s)')
% legend({'Yaw'; 'Pitch'; 'Roll'})


function resampled_HT = resample_HT(HT_data)
      N_in = length(HT_data);
      N_out = N_in * 2048; % 2048 is the buffer size used during recording
      resampled_HT = zeros(N_out, 3);
      h1 = 1;
      h2 = h1 + 2048 - 1;     
      for k=1:N_in
          resampled_HT(h1:h2,:) = repmat(HT_data(k,:), [2048,1]);
          h1 = h2 + 1;
          h2 = h1+2048 -1;
      end
      resampled_HT(:,1) = smoothdata(5*ceil(resampled_HT(:,1)./5));
end





