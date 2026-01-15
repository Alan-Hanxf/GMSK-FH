% calculateAndPlotResults.m (已修改)
function calculateAndPlotResults(results, config)
% 9. BER计算 (原 %% 9)

% --- 从结构体中解包数据 ---
data_bits = results.data;
rxData_original_bits = results.rxData_original;
rxData_fake_bits = results.rxData_fake; 

has_new_jam_data = isfield(results, 'rxData_newly_jammed');
if has_new_jam_data
    rxData_newly_jammed_bits = results.rxData_newly_jammed;
end

% --- 确保数据长度匹配 (基于比特) ---
len_original = length(rxData_original_bits);
len_fake = length(rxData_fake_bits);
min_len = min(len_original, len_fake); 

if has_new_jam_data
    len_new_jam = length(rxData_newly_jammed_bits);
    min_len = min(min_len, len_new_jam);
end

len_data = min(config.totalBits, min_len); 
dataUsed = data_bits(1:len_data);

% --- BER 计算 (逻辑不变, 基于比特) ---
BER_original = sum(xor(dataUsed, rxData_original_bits(1:len_data))) / len_data;
BER_fake = sum(xor(dataUsed, rxData_fake_bits(1:len_data))) / len_data;
if has_new_jam_data
    BER_newly_jammed = sum(xor(dataUsed, rxData_newly_jammed_bits(1:len_data))) / len_data;
end

% --- 打印结果 (修改) ---
fprintf('\n================================ BER 对比 ================================\n');
fprintf(' 调制方式: %s-%d (每符号 %d 比特)\n', ...
    config.modType, config.modOrder, config.bitsPerSymbol);
fprintf(' 1. 原信号 (仅AWGN) BER     = %.6f (SNR = %d dB)\n', BER_original, config.SNR_dB);
fprintf(' 2. Fake (GAN波形) 干扰 BER = %.6f\n', BER_fake);
if has_new_jam_data
    fprintf(' 3. "解调-再调制" 干扰 BER = %.6f\n', BER_newly_jammed);
end
fprintf('===========================================================================\n');

% --- 可视化 (修改) ---
% (图 30: 时域和前100比特)
len = length(results.Signal_original);
N = length(results.txSignal);
figure(30); 
% ... (subplot 1, 2 不变) ...
subplot(2,2,1);
t = (0:N-1)/config.Fs;
plot(t, real(results.txSignal), 'b-', 'LineWidth', 0.8); hold on;
plot(t(1:len), real(results.Signal_original), 'r--', 'LineWidth', 0.8);
title('原信号：发射时域（蓝）vs ISTFT恢复（红）');
xlabel('时间 (s)'); ylabel('幅度'); grid on; legend('发射','恢复'); xlim(t([1, N]));
subplot(2,2,2);
plot(t, real(results.fakeSignal_original), 'g-', 'LineWidth', 0.8);
title('Fake信号：ISTFT恢复时域');
xlabel('时间 (s)'); ylabel('幅度'); grid on; xlim(t([1, N]));

% (修改 Subplot 3, 4: 使用比特流)
subplot(2,2,3);
plot(1:100, dataUsed(1:100), 'bo-', 1:100, rxData_original_bits(1:100), 'rs--');
title('原信号解调（前100bit）');
xlabel('比特索引'); ylabel('比特值'); grid on; legend('原始','解调'); ylim([-0.2 1.2]);
subplot(2,2,4);
plot(1:100, dataUsed(1:100), 'bo-', 1:100, rxData_fake_bits(1:100), 'gs--');
title('Fake (GAN波形) 干扰解调（前100bit）'); 
xlabel('比特索引'); ylabel('比特值'); grid on; legend('原始','解调'); ylim([-0.2 1.2]);
set(gcf,'Position',[300,300,1200,800]);

% (图 31: 再调制干扰, 使用比特流)
if has_new_jam_data
    figure(31); 
    plot(1:100, dataUsed(1:100), 'bo-', 'LineWidth', 1.5); hold on;
    plot(1:100, rxData_newly_jammed_bits(1:100), 'mx--', 'LineWidth', 1); 
    title('"解调-再调制" 干扰解调（前100bit）');
    xlabel('比特索引'); ylabel('比特值'); grid on; 
    legend('原始','解调 (再调制干扰)'); ylim([-0.2 1.2]);
    set(gcf,'Position',[350,350,1200,400]);
end

% (图 40: 频谱图, 不变)
figure(40); 
subplot(2,1,1);
spectrogram(results.rxSignal, 256, 128, [], config.Fs, 'yaxis', 'centered');
title('原信号STFT频谱图'); colorbar;
subplot(2,1,2);
spectrogram(results.fakeSignal_original, 256, 128, [], config.Fs, 'yaxis', 'centered');
title('Fake信号ISTFT频谱图'); colorbar;
set(gcf,'Position',[400,400,1000,600]);

end