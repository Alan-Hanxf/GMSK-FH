function g = gaussianFilter(BT, T, L, pulse_span)
    Ts = T/L; 
    B = BT / T;
    sigma = (1 / (2*pi*B)) * sqrt(log(2)); 
    t_min = -pulse_span/2 * T;
    t_max = pulse_span/2 * T - Ts;
    t = t_min : Ts : t_max;
    g = (1/(sigma * sqrt(2*pi))) * exp(-(t.^2) / (2*sigma^2));
    g = g / (sum(g) * Ts); % 归一化
end