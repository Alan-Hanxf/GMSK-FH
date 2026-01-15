function [rxBaseband_newly_jammed, rxData_newly_jammed_bits, jammerSignal_hopped] = ...
    evaluateDemodRemodJamming(rxSignal, rxData_fake_bits, config, hopIndices)
%EVALUATEDEMODREMODJAMMING 评估 "解调-再调制" 型干扰对接收信号的影响。
%   这个函数接收原始信号、从假信号解调的比特、配置参数和跳频索引，
%   然后模拟将解调后的比特再调制成干扰信号，并将其添加到原始信号中，
%   最后处理并解调这个新的被干扰信号。
%
%   输入:
%     rxSignal              - 原始接收信号 (无干扰)。
%     rxData_fake_bits      - 从假信号解调得到的比特流。
%     config                - 包含调制、解调、信号参数的配置结构体。
%     hopIndices            - 跳频索引。
%
%   输出:
%     rxBaseband_newly_jammed   - 经过“再调制”干扰处理后的基带信号。
%     rxData_newly_jammed_bits  - 从“再调制”干扰信号中解调出的比特。
%     jammerSignal_hopped       - 应用了跳频的干扰信号。

fprintf('[8.5/9] 正在评估 "解调-再调制" 型干扰...\n');

% 步骤 1: 获取干扰比特 (来自 fake 信号的解调结果)
jammer_data_bits = rxData_fake_bits; % (已是比特流)

% (修改) 确保长度正确
if length(jammer_data_bits) < config.totalBits
    pad_len = config.totalBits - length(jammer_data_bits);
    jammer_data_bits = [jammer_data_bits; zeros(pad_len, 1)];
    fprintf('  [8.5] 警告: jammer_data_bits 长度不足 config.totalBits，已填充零。\n');
elseif length(jammer_data_bits) > config.totalBits
    jammer_data_bits = jammer_data_bits(1:config.totalBits);
    fprintf('  [8.5] 警告: jammer_data_bits 长度超出 config.totalBits，已截断。\n');
end

% 步骤 2: 转换为 Antipodal (GMSK) 和 Symbols (PSK/QAM)
jammer_data_antipodal = 2*jammer_data_bits - 1; % 用于 GMSK 的 antipodal 映射

if strcmp(config.modType, 'GMSK')
    % GMSK 直接使用比特流 (或 antipodal 形式，取决于 modulateSignal 的实现)
    % 这里假设 modulateSignal 接收 antipodal 形式的比特进行 GMSK 调制
    % 或者直接接收原始比特。为了通用性，保留 jammer_data_bits 作为符号输入。
    % 如果 modulateSignal 专门为 GMSK 设计，可能只用 jammer_data_antipodal
    jammer_data_symbols_for_mod = jammer_data_bits; 
else
    % 对于 PSK/QAM，需要将比特转换为符号索引
    % 确保比特流长度是 bitsPerSymbol 的整数倍
    numBits = length(jammer_data_bits);
    if mod(numBits, config.bitsPerSymbol) ~= 0
        warning('jammer_data_bits 长度不是 bitsPerSymbol 的整数倍，可能导致 reshape 错误或数据丢失。');
        % 截断或填充以确保正确性，这里选择截断
        numBits = floor(numBits / config.bitsPerSymbol) * config.bitsPerSymbol;
        jammer_data_bits = jammer_data_bits(1:numBits);
    end
    jammer_data_symbols_for_mod = bi2de(reshape(jammer_data_bits, ...
        config.bitsPerSymbol, numBits/config.bitsPerSymbol)', 'left-msb');
end

% 步骤 3: 调制干扰比特 (重用 modulateSignal)
fprintf('  [8.5] 正在调制干扰比特...\n');
if strcmp(config.modType, 'GMSK')
    jammerBaseband = modulateSignal(jammer_data_antipodal, [], config); % GMSK 通常只用 antipodal 比特
else
    jammerBaseband = modulateSignal([], jammer_data_symbols_for_mod, config); % PSK/QAM 用符号
end

% 步骤 4: 应用相同跳频 (重用 applyFrequencyHopping)
fprintf('  [8.5] 正在对干扰信号应用跳频...\n');
jammerSignal_hopped = applyFrequencyHopping(jammerBaseband, config, hopIndices);

% 步骤 5: 构造新的被干扰信号
% 原始代码是 rxSignal + jammerSignal_hopped。
% 如果这里需要引入 SIR 概念，需要额外参数 K 或者 SIR_dB。
% 为了保持与您原代码一致，暂时不引入 SIR 调整。
% 如果需要 SIR 调整，则需要函数增加 SIR_dB 输入参数，并在这里计算 K。
rxSignal_newly_jammed = rxSignal + jammerSignal_hopped; 

% 步骤 6: 接收处理 (重用 processReceiver)
fprintf('  [8.5] 正在接收处理 "再调制" 干扰信号...\n');
rxBaseband_newly_jammed = processReceiver(rxSignal_newly_jammed, config, hopIndices);

% 步骤 7: 解调 (重用 demodulateSignal)
fprintf('  [8.5] 正在解调...\n');
[~, rxData_newly_jammed_bits] = demodulateSignal(rxBaseband_newly_jammed, config);

fprintf('  [8.5] "解调-再调制" 干扰评估完成。\n');

end