function func_norm = normalized_STFT_signal(spec)
for i = 1:size(spec,2)
    spec(:,i) = spec(:,i) / (2 * norm(spec(:,i),Inf)) + 0.5;
end
func_norm = spec;
end

function func_inorm = inormalized_STFT_signal(maspec,maxValue)
for i = 1:size(maspec,2)
    maspec(:,i) = (maspec(:,i) - 0.5) * maxValue(i); % 修正：maxValue为1维
end
func_inorm = maspec;
end