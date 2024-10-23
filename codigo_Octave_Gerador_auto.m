%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%TEC430-PDS-UEFS2024.2
%Problema 02
%Arquivo para teste na recepção de dados pela USB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%% LIMPA E FECHA TUDO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc;							% limpa a tela do octave
clear all;				% limpa todas as variáveis do octave
close all;				% fecha todas as janelas

%%%%%%%%%%%%%%%%%%% CHAMADA DAS BIBLIOTECAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pkg load signal					% biblioteca para processamento de sinais
pkg load instrument-control		% biblioteca para comunicação serial

%%%%%%%%%%%%%%%%%%% ALOCAÇÃO DE VARIÁVEIS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MAX_RESULTS = 2560;
fs = 10000;           % Frequência de amostragem
amostras = 1000;      % Quantidade de amostras para visualizar na tela
raw = [];             % Variável para armazenar os dados crus recebidos pela USB

%%%%%%%%%%%%%%%%%%% ABERTURA DA PORTA SERIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
s1 = serial("COM5"); 	    		% Abre a porta serial do microcontrolador
set(s1,'baudrate',2000000);		  % Velocidade de transmissão 2Mbps
set(s1,'bytesize',8); 			    % 8 bits de dados
set(s1,'parity','n'); 			    % Sem paridade
set(s1,'stopbits',1); 			    % 1 bit de parada
set(s1,'timeout',200);			    % Tempo ocioso sem conexão de 200 segundos
pause(1);				          		% Espera 1 segundo antes de ler dados

%%%%%%%%%%%%%%%%%%% LEITURA DA MENSAGEM INICIAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
i = 1;
while(1)
	t(i) = fread(s1,1);			% Lê amostras de uma em uma
	if (t(i)==10)				% Se for lido um enter (10 em ASCII)
		break;					% Sai do loop
	endif
	i = i+1;
end
c = char(t); 					      % Transforma caracteres recebidos em string
printf('Recebido: %s', c);		% Imprime o que foi recebido

%%%%%%%%%%%%%%%%%%% CAPTURA DAS AMOSTRAS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure(1);
tic;							          % Captura o tempo inicial
data = fread(s1, amostras, 'uint8');	% Captura as amostras
raw = cat(2, raw, data);			    % Armazena o dado bruto
x = char(raw);                   % Converte os dados recebidos em caracteres
d = str2num(x);                  % Converte a string de caracteres em números
x = double(d);                   % Converte os números inteiros em double
time = [(0:1:length(d)-1) / fs]; % Domínio do tempo normalizado

%%%%%%%%%%%%%%%%%%% PLOT DO SINAL NO DOMÍNIO DO TEMPO %%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(3,1,1);
plot(time, d*5/1023);            % Plota o sinal no domínio do tempo
xlabel('t(s)');
title('Sinal gerado x(t)');

subplot(3,1,2);
stem(d, '.');		                % Plota a janela de amostras
xlabel('n');
title('Amostras discretas x[n]');

subplot(3,1,3);
stairs(d);	        		          % Plota as amostras em "escada"
xlabel('n');
title('Sinal x[n] segurado');
hold on;

%%%%%%%%%%%%%%%%%%% CODIFICAÇÃO BINÁRIA DO SINAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Passo 1: Normalizando o sinal entre 0 e 1
sinal_normalizado = (d - min(d)) / (max(d) - min(d));
disp('Valores normalizados:');
disp(sinal_normalizado);

% Passo 2: Quantizando o sinal (usando 8 bits de resolução, por exemplo)
n_bits = 8;  % Número de bits para quantização
niveis_quantizacao = 2^n_bits;
sinal_quantizado = round(sinal_normalizado * (niveis_quantizacao - 1));

% Passo 3: Convertendo todos os valores quantizados para binário
% Cada valor quantizado agora será representado em binário com 10 bits
sinal_binario = dec2bin(sinal_quantizado, n_bits);

% Captura das amostras
data = fread(s1, amostras, 'uint8'); % Captura todas as amostras (em decimal)
% Exibindo todos os valores codificados em binário
disp("Sinal quantizado em binário (todos os valores):");
disp(sinal_binario);  % Exibe todos os valores quantizados em binário

% Conversão dos valores decimais para voltagem
voltage = (data * 5) / 1023;  % Fórmula para calcular a voltagem (assumindo resolução de 10 bits ADC)
time = (0:length(data)-1) / fs;  % Tempo correspondente para cada amostra

% Ajustando o loop para evitar o erro "out of bounds"
n_amostras = min(length(sinal_binario), length(data));  % Garante que o índice não ultrapasse o menor tamanho

for i = 1:n_amostras
  printf('Binário: %s -> Decimal: %d -> Voltagem: %.2f V\n', sinal_binario(i,:), data(i), voltage(i));
end

%%%%%%%%%%%%%%%%%%% APLICAÇÃO DA FFT (DFT) NO SINAL %%%%%%%%%%%%%%%%%%%%%%%%%%%%
toc;							            % Captura o tempo final
N = length(d);                   % Número de pontos
window = hamming(N);  % Cria uma janela de Hamming com N pontos
d_windowed = d .* window;  % Aplica a janela ao sinal
transf = fft(d_windowed);  % Aplica a FFT no sinal janelado
f = (0:N-1)*(fs/N);              % Eixo de frequências

figure(2);                       % Nova figura para a DFT
plot(f, abs(transf)/N);           % Plota o módulo da DFT
xlabel('Frequência (Hz)');
ylabel('Magnitude');
title('Transformada Discreta de Fourier (DFT)');
xlim([0 fs/2]);                  % Limita o eixo x a metade da frequência de amostragem (frequência de Nyquist)

%%%%%%%%%%%%%%%%%%% PLOT DA FFT APÓS JANELAMENTO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
w = hamming(length(d));
d_windowed = d .* w';  % Aplicação da janela
transf_windowed = fft(d_windowed);
figure(3);
plot(f, abs(transf_windowed)/N);
title('Espectro após janelamento');

%%%%%%%%%%%%%%%%%%% FECHA A PORTA DE COMUNICAÇÃO %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fclose(s1);
