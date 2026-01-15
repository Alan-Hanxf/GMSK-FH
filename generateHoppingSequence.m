function hopIndices = generateHoppingSequence(config)
% 3. 跳频序列 (原 %% 3)
order = 4;
mSeq = generateMSequence_Decimal(order); % 依赖 Helpers 文件夹中的函数
mSeqExtended = repmat(mSeq, 1, ceil(config.numHops / length(mSeq)));
hopIndices = mod(mSeqExtended(1:config.numHops), length(config.freqSet)) + 1;
end