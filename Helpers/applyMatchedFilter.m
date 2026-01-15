% Helpers/applyMatchedFilter.m
function rxSymbols_downsampled = applyMatchedFilter(rxBaseband, config)
% applyMatchedFilter.m
% 应用 RRC 匹配滤波 (滤波 + 抽取)
%
% rxBaseband: 接收到的基带信号 (在 Fs 采样率下)
% config:     包含 RRC 参数 (rrcRolloff, rrcSpan, samplesPerSymbol)
%
% rxSymbols_downsampled: 经过匹配滤波和抽取后的符号 (1 采样点/符号)

% 1. 创建 RRC 接收滤波器 (匹配滤波器)
% 使用 comm.RaisedCosineReceiveFilter
% 它同时执行匹配滤波和抽取 (downsampling)
rrcRxFilter = comm.RaisedCosineReceiveFilter(...
    'Shape',                  'Square root', ...
    'RolloffFactor',          config.rrcRolloff, ...
    'FilterSpanInSymbols',    config.rrcSpan, ...
    'InputSamplesPerSymbol',  config.samplesPerSymbol, ...
    'DecimationFactor',       config.samplesPerSymbol);
    
% 2. 滤波和抽取
% 滤波器会自动处理所需的群延迟，以在最佳采样点进行抽取
rxSymbols_downsampled = rrcRxFilter(rxBaseband);

end