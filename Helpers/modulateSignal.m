% Helpers/modulateSignal.m (新建)
function txBaseband = modulateSignal(data_antipodal, data_symbols, config)
% 根据 config.modType 选择调制器

switch config.modType
    case 'GMSK'
        fprintf('  [调制] 使用 GMSK (custom)...\n');
        % 调用你原来的 GMSK 调制器
        txBaseband = gmskModulate(data_antipodal, config.BT, config.h, ...
            config.samplesPerSymbol, config.T, config.pulse_span);
        
    case {'PSK', 'QAM'}
        fprintf('  [调制] 使用 %s-%d (built-in) + RRC 脉冲成形...\n', ...
            config.modType, config.modOrder);
        
        % 1. 理想调制 (1 采样点/符号)
        if strcmp(config.modType, 'PSK')
            % PSK 调制 (0 相位偏移, 'gray' 编码)
            syms = pskmod(data_symbols, config.modOrder, 0, 'gray');
        else
            % QAM 调制 ('gray' 编码, 单位平均功率)
            syms = qammod(data_symbols, config.modOrder, 'gray', ...
                'UnitAveragePower', true);
        end
        
        % 2. 应用 RRC 脉冲成形 (上采样 + 滤波)
        txBaseband = applyPulseShaping(syms, config);
        
    otherwise
        error('未知的调制类型: %s', config.modType);
end

% 确保输出长度正确
if length(txBaseband) > config.N
    txBaseband = txBaseband(1:config.N);
elseif length(txBaseband) < config.N
    padLen = config.N - length(txBaseband);
    txBaseband = [txBaseband; zeros(padLen, 1)];
end

end