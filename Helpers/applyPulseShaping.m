% Helpers/applyPulseShaping.m
function txSignal = applyPulseShaping(syms, config)
% applyPulseShaping.m
% 应用 RRC 脉冲成形 (上采样 + 滤波)
%
% syms:   理想的调制后符号 (1 采样点/符号)
% config: 包含 RRC 参数 (rrcRolloff, rrcSpan, samplesPerSymbol)
%
% txSignal: 经过脉冲成形和上采样后的基带信号

% 1. 创建 RRC 发射滤波器
% 使用 MATLAB Communications Toolbox 的 comm.RaisedCosineTransmitFilter
% 它的 'Shape' 默认为 'Square root' (即 RRC)
rrcTxFilter = comm.RaisedCosineTransmitFilter(...
    'RolloffFactor',          config.rrcRolloff, ...
    'FilterSpanInSymbols',    config.rrcSpan, ...
    'OutputSamplesPerSymbol', config.samplesPerSymbol);

% 2. 滤波
% 滤波器对象会自动对输入的 'syms' 进行上采样
txSignal = rrcTxFilter(syms);

end