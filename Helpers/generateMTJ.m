function [rxSignal_jammed, jammerSignal] = generateMTJ(rxSignal, config, JSR_dB, M, strategy)
% generateMTJ - 生成多音干扰 (Multitone Jamming)
%
% 输入:
%   rxSignal:         原始的、干净的FH-GMSK信号 (复基带, Nx1)
%   config:           仿真配置结构体 (需要 .fs 和 .hoppingBandwidth)
%   JSR_dB:           干扰信号功率比 (Jamming-to-Signal Ratio) in dB
%   M:                要生成的干扰音（tone）的数量
%   strategy:         干扰音的频率分布策略:
%                     'uniform': 在整个跳频带宽内均匀分布 (梳状干扰)
%                     'random': 在整个跳频带宽内随机分布
%                     'targeted': (推荐) 随机选择 M 个已知的跳频信道进行干扰
%                                (需要 config.hopChannels 字段)
%
% 输出:
%   rxSignal_jammed:  添加了干扰的信号
%   jammerSignal:     生成的干扰信号本身

%% 步骤 1: 计算信号功率和总干扰功率
L = length(rxSignal);
if L == 0
    error('输入信号 rxSignal 不能为空。');
end

% 计算原始信号的平均功率
P_signal = mean(abs(rxSignal).^2);

% 从 JSR (dB) 计算线性的总干扰功率
JSR_linear = 10^(JSR_dB / 10);
P_jammer_total = P_signal * JSR_linear;

if M <= 0
    error('干扰音数量 M 必须为正。');
end

%% 步骤 2: 计算每个干扰音的功率和幅度
% 假设功率在 M 个音之间均匀分配
P_tone = P_jammer_total / M;

% 幅度 A 对于复指数信号 A*exp(j*...) 来说，其功率为 A^2
% 因此 A = sqrt(P_tone)
A_tone = sqrt(P_tone);

%% 步骤 3: 确定 M 个干扰音的频率
jamToneFreqs = zeros(M, 1);
M_actual = M; % 实际使用的M，在'targeted'策略下可能被修改

switch lower(strategy)
    case 'uniform'
        % 策略 1: 均匀分布 (梳状)
        % 在整个基带跳频带宽内 (-BW/2 到 +BW/2) 均匀放置 M 个音
        fprintf('  [MTJ] 策略: 均匀 (Uniform) 梳状干扰。\n');
        if ~isfield(config, 'hoppingBandwidth')
             error('Uniform 策略需要 config.hoppingBandwidth 字段。');
        end
        BW = config.hoppingBandwidth;
        jamToneFreqs = linspace(-BW/2, BW/2, M)';

    case 'random'
        % 策略 2: 随机分布
        fprintf('  [MTJ] 策略: 随机 (Random) 分布。\n');
        if ~isfield(config, 'hoppingBandwidth')
             error('Random 策略需要 config.hoppingBandwidth 字段。');
        end
        BW = config.hoppingBandwidth;
        % 在 -BW/2 和 +BW/2 之间随机选择 M 个频率
        jamToneFreqs = -BW/2 + BW * rand(M, 1);
        
    case 'targeted'
        % 策略 3: 针对性干扰 (最有效的基准)
        % 假设干扰机知道合法的信道列表(Hop Set)，并从中随机选M个
        fprintf('  [MTJ] 策略: 针对性 (Targeted) 干扰。\n');
        
        availableChannels = config.freqSet(:); % 确保是列向量
        numChannels = length(availableChannels);
        
        if M > numChannels
            warning('M (%d) 大于可用信道数 (%d)。将干扰所有 %d 个信道。', ...
                    M, numChannels, numChannels);
            M_actual = numChannels;
            jamToneFreqs = availableChannels;
        else
            % 从所有可用信道中随机抽取 M 个
            indices = randperm(numChannels, M);
            jamToneFreqs = availableChannels(indices);
        end
        
        % 如果 M 发生变化，重新计算每个音的幅度和功率
        if M_actual ~= M
            P_tone = P_jammer_total / M_actual;
            A_tone = sqrt(P_tone);
        end
        
    otherwise
        error('未知的 MTJ 策略: "%s". 请使用 "uniform", "random", 或 "targeted".', strategy);
end

%% 步骤 4: 生成干扰信号 (M 个复指数信号的叠加)
fprintf('  [MTJ] 正在生成 %d 个干扰音 (JSR = %.1f dB)...\n', M_actual, JSR_dB);

% 创建时间向量
t = (0:L-1)' / config.Fs; 

% 初始化干扰信号
jammerSignal = zeros(L, 1, 'like', rxSignal); % 确保数据类型一致 (例如 double 或 complex double)

for k = 1:M_actual
    f_k = jamToneFreqs(k);
    
    % 随机化初始相位，避免所有音同相
    phi_k = 2 * pi * rand;
    
    % 生成单个复指数干扰音 (A * exp(j*(2*pi*f*t + phi)))
    tone_k = A_tone * exp(1j * (2 * pi * f_k * t + phi_k));
    
    % 累加到总干扰信号中
    jammerSignal = jammerSignal + tone_k;
end

%% 步骤 5: 将干扰添加到原始信号
rxSignal_jammed = rxSignal + jammerSignal;

fprintf('  [MTJ] 多音干扰已添加。\n');
end