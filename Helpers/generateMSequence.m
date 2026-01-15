function mSeq = generateMSequence(order)
    switch order
        case 4
            taps = [4,1];
        otherwise
            error('仅支持 order=4');
    end
    L = 2^order - 1;
    reg = ones(1,order);
    mSeq = zeros(1,L);
    for i = 1:L
        mSeq(i) = reg(end);
        feedback = xor(reg(taps(1)), reg(taps(2)));
        reg = [feedback, reg(1:end-1)];
    end
end