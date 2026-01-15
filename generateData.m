% generateData.m (已修改 - 随机生成)
function [data_bits, data_antipodal, data_symbols] = generateData(config)
% 2. 原始数据 (原 %% 2)

% --- (修改) ---
% 随机生成特定长度的比特流
% data_bits_raw = readmatrix('binary_data.csv'); % (原代码)
% (原代码的错误检查和截取部分也一并移除)

fprintf('  [数据] 正在随机生成 %d 个比特...\n', config.totalBits);
data_bits = randi([0, 1], config.totalBits, 1);
% ---------------

% 1. 生成 GMSK 所需的 Antipodal 信号
data_antipodal = 2*data_bits - 1; 

% 2. 生成 PSK/QAM 所需的符号 (0 到 M-1)
if strcmp(config.modType, 'GMSK')
    % GMSK (1 bit/sym) 伪符号 (虽然 gmskModulate 用 antipodal)
    data_symbols = data_bits; 
else
    % 将比特流转换为整数符号
    % bi2de (Binary to Decimal)
    % 我们需要 'left-msb' 来匹配 pskmod/qammod 的默认映射
    data_reshaped = reshape(data_bits, config.bitsPerSymbol, config.totalSymbols)';
    data_symbols = bi2de(data_reshaped, 'left-msb');
end

fprintf('  [数据] 已生成 %d 个比特, %d 个符号 (M=%d)\n', ...
    length(data_bits), length(data_symbols), config.modOrder);

end