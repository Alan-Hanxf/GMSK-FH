function rxData = gmskDemodulate_G(rxBaseband, L, BT, T, pulse_span)
    phase_diff = rxBaseband(2:end) .* conj(rxBaseband(1:end-1));
    freq_est = angle(phase_diff); 
    
    g_full = gaussianFilter(BT, T, L, pulse_span); 
    Ng = length(g_full);
    g_center_start = floor((Ng - L) / 2) + 1;
    g_center_end = g_center_start + L - 1;
    
    if g_center_start < 1 || g_center_end > Ng
        weights = ones(L, 1);
    else
        weights = g_full(g_center_start:g_center_end)'; 
        weights = weights / sum(weights);
    end

    symbol_ends = L : L : length(freq_est);
    integrated_freq = zeros(length(symbol_ends), 1);
    num_symbols_demodulated = length(symbol_ends);
    
    for k = 1:num_symbols_demodulated
        idx_end = symbol_ends(k);
        idx_start = idx_end - L + 1;
        if idx_start > 0
            current_freq_samples = freq_est(idx_start:idx_end);
            integrated_freq(k) = current_freq_samples' * weights; 
        else
            integrated_freq(k) = 0; 
        end
    end

    rxData_antipodal = sign(integrated_freq);
    total_bits = floor(length(rxBaseband) / L);
    if length(rxData_antipodal) > total_bits
        rxData_antipodal = rxData_antipodal(1:total_bits);
    end
    
    rxData = (rxData_antipodal + 1) / 2;
end