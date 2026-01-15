% initializeParameters.m (已修改)
function config = initializeParameters()

% ----------------- 1. 调制选择 -----------------
config.modType = 'GMSK';  config.modOrder = 2;
% config.modType = 'PSK';   config.modOrder = 2;  % BPSK
% config.modType = 'PSK';   config.modOrder = 4;  % QPSK
% config.modType = 'PSK';   config.modOrder = 8;  % 8PSK
% config.modType = 'QAM';   config.modOrder = 16; % 16QAM
% config.modType = 'QAM';   config.modOrder = 64; % 64QAM

% ----------------- 2. 计算每符号比特 -----------------
config.bitsPerSymbol = log2(config.modOrder);
if strcmp(config.modType, 'GMSK')
    config.bitsPerSymbol = 1; % GMSK 固定为 1 bit/sym
end

% ----------------- 3. (核心修改) 固定速率和总长 -----------------
% (原) config.bitRate = 4120; (已移除)

% 1. 固定符号速率
config.symbolRate = 4120; % 符号速率 (Sps)
config.T = 1/config.symbolRate; % 符号周期

% 2. 固定每符号采样
config.samplesPerSymbol = 8;    % 每符号采样点数 (L)

% 3. 采样频率 Fs (因此固定)
config.Fs = config.symbolRate * config.samplesPerSymbol; % 4120 * 8 = 32960 Hz

% 4. 跳频参数 (用于定义总长)
config.hopRate = 10;
config.hopPeriod = 1 / config.hopRate; % 0.1s
config.symbolsPerHop = round(config.hopPeriod * config.symbolRate); % 0.1 * 4120 = 412 符号/跳
config.numHops = 10;

% 5. 总符号数 (因此固定)
config.totalSymbols = config.numHops * config.symbolsPerHop; % 10 * 412 = 4120 符号

% 6. 总采样点数 N (因此固定)
config.N = config.totalSymbols * config.samplesPerSymbol; % 4120 * 8 = 32960 采样点

% 7. 总比特数 (!! 这是现在会变化的值 !!)
config.totalBits = config.totalSymbols * config.bitsPerSymbol; % 4120 * k

% 8. 每跳采样点数 (因此固定)
config.samplesPerHop = config.symbolsPerHop * config.samplesPerSymbol; % 412 * 8 = 3296
%% 4. 调制特定参数 (无修改)
% GMSK 参数
config.BT = 0.3;                
config.h = 0.5;                 
config.pulse_span = 4;          % GMSK 高斯滤波器跨度
% PSK/QAM 的 RRC 脉冲成形参数
config.rrcRolloff = 0.25;       
config.rrcSpan = 6;             
%% 5. 跳频频率集 (无修改)
fMax = config.Fs/2 * 0.8;
freqSet = linspace(-fMax, fMax, 11); 
freqSet(freqSet == 0) = [];          
if length(freqSet) ~= 10
    freqSet = linspace(-fMax, fMax, 10); 
end
config.freqSet = freqSet;
config.channelBandwidth = config.symbolRate * 2.0; % (基于 symbolRate, 已固定)

%% 6. 滤波器参数 (无修改)
config.BPF_Order = 4;
config.BPF_Bandwidth = config.symbolRate * 1; % (基于 symbolRate, 已固定)
config.LPF_cutoff = config.symbolRate * 1;    % (基于 symbolRate, 已固定)
config.LPF_Order = 2;

config.rxLpf = designfilt('lowpassiir', ...
    'FilterOrder', config.LPF_Order, ...
    'PassbandFrequency', config.LPF_cutoff, ...
    'SampleRate', config.Fs);

%% 7. STFT 和信道参数 (无修改)
config.SNR_dB = 15;
config.nfft = 256; % (固定)
config.noverlap = round(config.nfft * 0.5); % (固定)
config.rxSignal_high_gain = 1; 
config.fakeImage_real_path = 'reconstructed_image_real.png';
config.fakeImage_imag_path = 'reconstructed_image_imag.png';
config.save_stft_real_path = 'GMSKSTFT_10dB_real256.mat';
config.save_stft_imag_path = 'GMSKSTFT_10dB_imag256.mat';
config.fakeImage2_real_path = 'dcgan_real.png'; % 第二路干扰的实部图像路径
config.fakeImage2_imag_path = 'dcgan_imag.png'; % 第二路干扰的虚部图像路径

% ----------------- 8. 打印参数 (已修改) -----------------
fprintf('--- 仿真参数 (固定STFT尺寸模式) ---\n');
fprintf('调制方式: %s-%d\n', config.modType, config.modOrder);
fprintf('符号速率: %.1f Sps (固定)\n', config.symbolRate);
fprintf('采样频率 Fs: %d Hz (固定)\n', config.Fs);
fprintf('总符号数: %d (固定)\n', config.totalSymbols);
fprintf('总采样点数 N: %d (固定)\n', config.N);
fprintf('STFT 窗/重叠: %d/%d (固定)\n', config.nfft, config.noverlap);
fprintf('--- !! 注意: 总比特数会变化 !! ---\n');
fprintf('每符号比特: %d\n', config.bitsPerSymbol);
fprintf('总比特数: %d (变化)\n', config.totalBits);
fprintf('----------------\n');
end