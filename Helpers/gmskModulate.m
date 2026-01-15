function txBaseband = gmskModulate(data_antipodal, BT, h, L, T, pulse_span)
    g = gaussianFilter(BT, T, L, pulse_span);
    Ng = length(g);
    target_len = length(data_antipodal) * L;
    
    delay_samples = floor(Ng/2);
    up_data = upsample(data_antipodal, L);
    up_len = length(up_data);
    
    head_pad = zeros(delay_samples, 1);
    tail_pad_len = target_len + Ng - 1 - delay_samples - up_len;
    tail_pad = zeros(max(0, tail_pad_len), 1); 
    
    padded_data = [head_pad; up_data; tail_pad];
    filtered_data = conv(padded_data, g, 'valid');
    
    w_t = pi * h * filtered_data * (T/(2*T)); 
    phase_accum = cumsum(w_t) * (T/L); 
    txBaseband_full = exp(1j * phase_accum);
    txBaseband = txBaseband_full(1:target_len);
end