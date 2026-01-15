% Helpers/demodulateSignal.m (新建)
function [rxSymbols, rxBits] = demodulateSignal(rxBaseband, config)
% 根据 config.modType 选择解调器

switch config.modType
    case 'GMSK'
        fprintf('  [解调] 使用 GMSK (custom)...\n');
        % 调用你原来的 GMSK 解调器 (它返回 bits)
        rxBits = gmskDemodulate_G(rxBaseband, config.samplesPerSymbol, ...
            config.BT, config.T, config.pulse_span);
        
        % 确保长度正确
        if length(rxBits) > config.totalBits
            rxBits = rxBits(1:config.totalBits);
        end
        
        % (可选) 将 bits 转为 symbols
        rxSymbols = rxBits; % GMSK 是 1-bit 符号

    case {'PSK', 'QAM'}
        fprintf('  [解调] 使用 %s-%d (built-in) + RRC 匹配滤波...\n', ...
            config.modType, config.modOrder);

        % 1. 应用 RRC 匹配滤波 (滤波 + 抽取)
        rxSymbols_downsampled = applyMatchedFilter(rxBaseband, config);
        
        % 2. 解调
        if strcmp(config.modType, 'PSK')
            rxSymbols = pskdemod(rxSymbols_downsampled, config.modOrder, ...
                0, 'gray');
        else
            % 归一化 (如果 QAM 使用了 UnitAveragePower)
            rxSymbols_downsampled = rxSymbols_downsampled / ...
                sqrt(mean(abs(rxSymbols_downsampled).^2));
            
            rxSymbols = qamdemod(rxSymbols_downsampled, config.modOrder, ...
                'gray', 'UnitAveragePower', true);
        end

        % 3. 符号转比特
        % de2bi (Decimal to Binary)
        rxBits_matrix = de2bi(rxSymbols, config.bitsPerSymbol, 'left-msb')';
        rxBits = rxBits_matrix(:); % 转换回比特流

    otherwise
        error('未知的调制类型: %s', config.modType);
end

% 确保比特流长度正确
if length(rxBits) > config.totalBits
    rxBits = rxBits(1:config.totalBits);
elseif length(rxBits) < config.totalBits
    padLen = config.totalBits - length(rxBits);
    rxBits = [rxBits; zeros(padLen, 1)]; % 补零
end

end