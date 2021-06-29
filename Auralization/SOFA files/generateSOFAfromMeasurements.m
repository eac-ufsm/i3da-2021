clear; clc
% Generate sofa BRIR from measurements

%% Load measurements
load('measurements/car_cabin_front_left_BRIR')
ri_front_left = ms_to_ir(ms, results);
BRIRs = ri_front_left;

load('measurements/car_cabin_front_right_BRIR')
ri_front_right = ms_to_ir(ms, results);
BRIRs = cat(4, BRIRs, ri_front_right);

load('measurements/car_cabin_rear_left_BRIR')
ri_rear_left = ms_to_ir(ms, results);
BRIRs = cat(4, BRIRs, ri_rear_left);

load('measurements/car_cabin_rear_right_BRIR')
ri_rear_right = ms_to_ir(ms, results);  
BRIRs = cat(4, BRIRs, ri_rear_right);

load('measurements/passenger_loudspeaker_BRIR')
ri_passenger = ms_to_ir(ms, results);
BRIRs = cat(4, BRIRs, ri_passenger);

BRIRs = shiftdim(BRIRs, 1);
BRIRs = BRIRs./max(abs(BRIRs(:)))*.976;

% size(BRIRs)
% plot(ri_rear_right(:,:,2))
% plot(ri_front_left(:,:,2))
% plot(ri_rear_right(:,:,2))
% plot(ri_passenger(:,:,2))

%% Coordenadas
%%% Listener coordinates
% yaw = (-40:5:40);
yaw = [40:-5:0, 355:-5:320]';
ListenerView = [yaw, zeros(length(yaw),1), ones(length(yaw),1)];
% coords_cart = deg2rad(coords_sph);
% [ListenerView(:,1), ListenerView(:,2), ListenerView(:,3)] = sph2cart(coords_cart(:,1),...
%                                                                      coords_cart(:,2),...
%                                                                      coords_cart(:,3));
% % Conferir se ta certo mesmo
% [t(:,1), t(:,2), t(:,3)] = cart2sph(ListenerView(:,1), ListenerView(:,2), ListenerView(:,3));
% t=rad2deg(t);

%%% Source coordinates (cartesian)
FL = [ 0.58, -0.37, -0.75];
FR = [ 0.58,  1.05, -0.75];
RL = [-0.50, -0.37, -0.75];
RR = [-0.50,  1.05, -0.75];
PS = [ 0.00,  0.70,  0.00];
EmitterPos_cart = [FL;FR;RL;RR;PS];

% Convert to spheric with the SOFA angle conventions
[EmitterPos_sph(:,1),EmitterPos_sph(:,2),EmitterPos_sph(:,3)] = ...
                                        cart2sph(EmitterPos_cart(:,1),...
                                                 EmitterPos_cart(:,2),...
                                                 EmitterPos_cart(:,3));
EmitterPos_sph(:,1:2)= rad2deg(EmitterPos_sph(:,1:2));
[EmitterPos_sph(:,1), EmitterPos_sph(:,2)] = nav2sph(-EmitterPos_sph(:,1),...
                                                      EmitterPos_sph(:,2));

%% Saving as MultispeakerBRIR conventions
Obj = SOFAgetConventions('MultispeakerBRIR'); % carrega o template
Obj.ListenerView = ListenerView;
Obj.ListenerView_Type = 'spherical';
Obj.ListenerView_Units = 'degree, degree, metre';

Obj.EmitterPosition_Type = 'spherical';
Obj.EmitterPosition = EmitterPos_sph;
Obj.EmitterView = zeros(5,3);
Obj.EmitterUp = zeros(5,3);

Obj.Data.Delay = zeros(1,2,5);
Obj.Data.IR = BRIRs; 
Obj.Data.SamplingRate = 44100;

Obj = SOFAupdateDimensions(Obj);


%% SAVE SOFA FILE
filename = 'car_BRIRs.sofa';
SOFAsave(filename, Obj);


%% Saving as SimpleFreeFieldHRIR conventions
% ObjHRTF = SOFAgetConventions('SimpleFreeFieldHRIR'); % carrega o template
% ObjHRTF.SourcePosition = [FL;FR;RL;RR;PS];
% ObjHRTF.Data.IR = permute(squeeze(BRIRs(9,:,:,:)), [2,1,3]);
% ObjHRTF.Data.SamplingRate = 44100;
% ObjHRTF = SOFAupdateDimensions(ObjHRTF);
% 
% filename = 'car_BRIRs_HATO_0.sofa';
% SOFAsave(filename, ObjHRTF);


%%

% path = 'C:\Users\rdavi\Desktop\artigo Fred\jake files\SOFAfiles\bbcrdlr_systemB.sofa';
% obj2 = SOFAload(path);


%% Internal functions ---------------------------------------------------

function room_response = ms_to_ir(ms, results)
    excitation_freq = fft(ms.sweep);
    for k = 1:size(results, 1)
        % BRIR
        measurement_freq = fft(results{k,2});    
        room_response(:,k,:) = ifft(measurement_freq./excitation_freq);
    end
end