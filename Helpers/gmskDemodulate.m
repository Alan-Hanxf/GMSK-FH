function rxData_antipodal = gmskDemodulate(rxBaseband, L)
    phase_diff = rxBaseband(2:end) .* conj(rxBaseband(1:end-1));
    freq_est = angle(phase_diff);
    
    symbol_centers = L/2 : L : length(freq_est);
    integrated_freq = zeros(length(symbol_centers), 1);
    for k = 1:length(symbol_centers)
        idx_end = symbol_centers(k);
        idx_start = idx_end - L + 1;
        if idx_start > 0
            integrated_freq(k) = sum(freq_est(idx_start:idx_end));
        else
            integrated_freq(k) = 0; 
        end
    end
    
    rxData_antipodal = sign(integrated_freq);
    rxData_antipodal = rxData_antipodal(1:end); 
end