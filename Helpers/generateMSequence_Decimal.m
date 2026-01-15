function mSeq_dec = generateMSequence_Decimal(order)
    % 仅支持 order=4
    if order ~= 4
        error('仅支持 order=4');
    end
    taps = [4,3];
    L = 2^order - 1; % 15
    reg = ones(1,order); % 初始状态 [1 1 1 1]
    mSeq_dec = zeros(1,L); % 存储十进制输出
    
    % MATLAB的位权，用于将二进制转十进制
    % [R1, R2, R3, R4] 对应 8, 4, 2, 1
    weights = 2.^(order-1:-1:0); % [8 4 2 1]

    for i = 1:L
        % 1. 计算十进制输出
        % 将当前寄存器状态（4位二进制）转换为十进制数（0-15）
        mSeq_dec(i) = sum(reg .* weights); % e.g., [1 1 1 1] * [8 4 2 1]' = 15
        
        % 2. 计算反馈比特
        feedback = xor(reg(taps(1)), reg(taps(2))); % R4 xor R3
        
        % 3. 移位
        reg = [feedback, reg(1:end-1)];
    end
    
    % 注意：如果寄存器从全1开始，第一个输出是15，而不是1
end