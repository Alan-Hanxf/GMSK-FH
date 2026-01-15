function txSignal = applyFrequencyHopping(txBaseband, config, hopIndices)
% 5. 分段跳频与发送处理 (原 %% 5)
N = length(txBaseband);
samplesPerHop = config.samplesPerHop;
txSignal = zeros(N, 1);
t_local = (0:samplesPerHop-1)' / config.Fs; 
phase_offset_tx = 0; 

for hop = 1:config.numHops
    idx_start = (hop-1)*samplesPerHop + 1;
    idx_end   = hop*samplesPerHop;
    
    % 确保索引在基带信号范围内
    if idx_end > N
        warning('索引超出 txBaseband 长度，跳频提前终止在第 %d 跳', hop-1);
        txSignal = txSignal(1:idx_start-1); % 截断
        break;
    end
    
    f_hop = config.freqSet(hopIndices(hop));
    fprintf('  跳: %d/%d, 频率: %.2f Hz\n', hop, config.numHops, f_hop);
    
    carrier_phase = 2*pi*f_hop*t_local + phase_offset_tx;
    carrier = exp(1j * carrier_phase);
    
    segment_hopped = txBaseband(idx_start:idx_end) .* carrier;
    phase_offset_tx = carrier_phase(end);
    
    txSignal(idx_start:idx_end) = segment_hopped; 
end
fprintf('发射处理完成。\n');
end