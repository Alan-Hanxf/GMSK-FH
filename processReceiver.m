function rxBaseband = processReceiver(signalIn, config, hopIndices)
% 7. 接收端处理 (可复用的单分支流程) (原 %% 7)
N = length(signalIn);
rxBaseband = zeros(N, 1);
phase_offset_rx = 0;
samplesPerHop = config.samplesPerHop;
t_local = (0:samplesPerHop-1)' / config.Fs; 

for hop = 1:config.numHops
    idx_start = (hop-1)*samplesPerHop + 1;
    idx_end   = hop*samplesPerHop;
    
    % 确保索引在信号范围内
    if idx_end > N
        warning('接收端索引越界，处理在第 %d 跳提前终止', hop-1);
        rxBaseband = rxBaseband(1:idx_start-1);
        break;
    end
    
    f_hop = config.freqSet(hopIndices(hop));
    
    % 动态设计BPF
    f_center_abs = abs(f_hop); 
    f_pass1 = max(1e-6, f_center_abs - config.BPF_Bandwidth/2);
    f_pass2 = min(config.Fs/2 - 1, f_center_abs + config.BPF_Bandwidth/2);
    
    if f_pass1 >= f_pass2
        error('BPF设计失败：跳 %d, 频率 %.2f, 通带 [%.2f, %.2f] 无效', hop, f_hop, f_pass1, f_pass2);
    end
    
    rxBpf = designfilt('bandpassiir', ...
        'FilterOrder', config.BPF_Order, ...
        'PassbandFrequency1', f_pass1, ...
        'PassbandFrequency2', f_pass2, ...
        'SampleRate', config.Fs);
    
    % 步骤1：BPF滤波
    segment_received = signalIn(idx_start:idx_end);
    segment_filtered_bpf = filter(rxBpf, real(segment_received)) + 1j*filter(rxBpf, imag(segment_received));
    
    % 步骤2：下变频（相位连续）
    carrier_down_phase = - (2*pi*f_hop*t_local + phase_offset_rx);
    carrier_down = exp(1j * carrier_down_phase);
    segment_downconverted = segment_filtered_bpf .* carrier_down;
    phase_offset_rx = 2*pi*f_hop*t_local(end) + phase_offset_rx;
    
    % 步骤3：LPF滤波
    segment_filtered_baseband = filter(config.rxLpf, segment_downconverted);
    rxBaseband(idx_start:idx_end) = segment_filtered_baseband;
end
end