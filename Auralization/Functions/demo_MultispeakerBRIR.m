clear; clc

%% Especificar propriedades do objeto
N_fontes = 5; % Numero de fontes sonoras distintas 
N_amostras = 2000; % Numero de amostras nas BRIRs (deve ser o mesmo para todos as RIs)
N_mics = 2; % Numero de canais de entrada, microfones ...
N_posi_ouvinte = 100; % Numero total de orientacoes de cabeca no caso
N_coords = 3; % Numero de coordenadas (coordenadas cartesianas -- x, y, z -- espera-se 3 sempre)

%% Criar variaveis com metadatas
% Coordenadas fontes e ouvintes 
posi_ouvinte = ones(N_posi_ouvinte, N_coords); % orientaçao do ouvinte (sao esperadas coordenadas cartesianas, tenho 'quase' certeza que a funcao pra isso e: eul2quat)
% aplicada sobre o angulos retornados pelo head tracker 
posi_fonte = ones(N_fontes, N_coords); % acredito que essa medida não seja seja obrigatoria

% Sinais
BRIRs = zeros(N_posi_ouvinte, N_mics, N_fontes, N_amostras);
Fs = 44100; % taxa de amostragem dos sinais

% Detalhe muito importante!! a ordem das coordenadas em 'posi_ouvinte' deve
% corresponder ao sinal para aquela posicao em 'BRIRs'

%% Criar BRIR sofa com as variaveis criadas
Obj = SOFAgetConventions('MultispeakerBRIR'); % carrega o template
Obj.ListenerView = posi_ouvinte;
Obj.EmitterView = posi_fonte;
Obj.Data.IR = BRIRs; 
Obj.Data.SaimplingRate = Fs;