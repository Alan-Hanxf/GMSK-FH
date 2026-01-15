% main_GMSK_FH.m 
%% GMSK 跳频通信系统 - 模块化主脚本
clear; clc; close all;
format long;
% 添加辅助函数到路径
addpath('Helpers');

fprintf('仿真开始...\n');
%% 1. 初始化
fprintf('[1/9] 正在初始化参数...\n');
config = initializeParameters();
%% 2. 生成原始数据
fprintf('[2/9] 正在生成原始数据...\n');
[data_bits, data_antipodal, data_symbols] = generateData(config);
%% 3. 生成跳频序列 
fprintf('[3/9] 正在生成跳频序列...\n');
hopIndices = generateHoppingSequence(config);
%% 4. 调制 
fprintf('[4/9] 正在进行调制...\n');
% (修改) 调用新的包装函数
txBaseband = modulateSignal(data_antipodal, data_symbols, config);

% 绘制基带信号时域图
figure(1);
subplot(2,2,1);  % 调整子图布局为2行2列
plot((1:3000),real(txBaseband(1:3000))); 
title('调制后基带信号 实部');
xlabel('样本索引'); ylabel('幅值');

subplot(2,2,2);
plot((1:3000),imag(txBaseband(1:3000))); 
title('调制后基带信号 虚部');
xlabel('样本索引'); ylabel('幅值');

% 计算并绘制频谱图
N = length(txBaseband);  % 获取信号长度
fs = config.Fs;  % 假设配置中有采样率参数，根据实际情况调整
f = (-N/2 : N/2 - 1) * (fs / N);  % 计算频率轴

% 计算FFT并进行频谱搬移
tx_fft = fftshift(fft(txBaseband));
tx_amp = abs(tx_fft) / N;  % 幅度归一化

subplot(2,2,3);
plot(f, 20*log10(tx_amp));  % 转换为dB
title('基带信号频谱（幅频特性）');
xlabel('频率 (Hz)'); ylabel('幅度 (dB)');
grid on;
%% 5. 分段跳频与发送
fprintf('[5/9] 正在应用跳频与发送处理...\n');
txSignal = applyFrequencyHopping(txBaseband, config, hopIndices);

% 绘制信号实部与虚部
figure(11)
subplot(2,1,1);
plot(real(txSignal(1:20000)));
title('实部');
xlabel('样本点');
ylabel('幅值');
grid on;

subplot(2,1,2);
plot(imag(txSignal(1:20000)));
title('虚部');
xlabel('样本点');
ylabel('幅值');
grid on;

%% 6. 信道 + STFT + Fake信号处理
fprintf('[6/9] 正在应用信道、STFT 和处理 Fake 信号...\n');
[rxSignal, fakeSignal_original, fakeSignal2_original, Signal_original, stft_data]... 
= applyChannelAndSTFT(txSignal, config);

figure(13)
% 计算并绘制频谱图
N = length(rxSignal);  % 获取信号长度
fs = config.Fs;  % 假设配置中有采样率参数，根据实际情况调整
f = (-N/2 : N/2 - 1) * (fs / N);  % 计算频率轴

% 计算FFT并进行频谱搬移
tx_fft = fftshift(fft(rxSignal));
tx_amp = abs(tx_fft) / N;  % 幅度归一化

plot(f, 20*log10(tx_amp));  % 转换为dB
title('基带信号频谱（幅频特性）');
xlabel('频率 (Hz)'); ylabel('幅度 (dB)');
grid on;
%% 7. 接收端处理

rxBaseband_original = processReceiver(rxSignal, config, hopIndices);

rxBaseband_fake = processReceiver(0.1 * fakeSignal_original + rxSignal, config, hopIndices);

% 0. 初始化
% 定义 JIR 范围和步长
% SIR_range_dB = 1:1:1; % 从 -10 dB 到 20 dB，间隔 3 dB
% num_sir_points = length(SIR_range_dB);
% BER_results = zeros(1, num_sir_points); % 存储每个 SIR 下的误码率
% BER_of_Signal = zeros(1, num_sir_points);
% BER_results_dcgan = zeros(1, num_sir_points); % (可选) 存储干扰信号的误码率
% BER_results_mtj = zeros(1,num_sir_points);
% 
% % **【JSR 计算公共部分】**
% trim_ratio = 0.20; % 截取比例 (0.10 表示两端各 10%)
% P_S = mean(abs(rxSignal).^2); % 原始信号的平均功率
% txData_bits = data_bits;
% L = length(fakeSignal_original);
% start_index = floor(L * trim_ratio) + 1;
% end_index = L - floor(L * trim_ratio);
% fakeSignal_trimmed = fakeSignal_original(start_index:end_index);
% P_I_trimmed = mean(abs(fakeSignal_trimmed).^2); % 截取后干扰信号的平均功率
% 
% % ------------------------- SIR 循环开始 -------------------------
% fprintf('\n[7-9/9] 正在进行 SIR 循环误码率评估...\n');
% 
% for i = 1:num_sir_points
%     current_SIR_dB = SIR_range_dB(i);
%     fprintf('\n---> 正在评估 SIR = %d dB...\n', current_SIR_dB);
% 
%     % 1. 基于当前 SIR 计算缩放系数 K
%     SIR_linear = 10^(current_SIR_dB / 10);
%     P_I_target = P_S / SIR_linear; 
%     K = sqrt(P_I_target / P_I_trimmed);
%     fprintf("K%d \n",K);
%     % 2. 构造受干扰信号
% 
%     rxSignal_orig = awgn(txSignal, -current_SIR_dB, 'measured');
%     rxSignal_jammed = K *rxSignal +  fakeSignal_original; 
%     rxSignal_jammed_dcgan = K *rxSignal +  fakeSignal2_original; 
% 
%     % 单音干扰
%     M_tones = 20; % 
% 
%     % --- 调用函数 ---
%     % 使用 'targeted' 策略，这是最有效的一种经典干扰
%     % 它假设干扰机知道所有可能的跳频信道
%     [rxSignal_jammed_mtj, jammerSignal_mtj] = generateMTJ(txSignal, ...
%                                                           config, ...
%                                                           current_SIR_dB, ...
%                                                           M_tones, ...
%                                                           'targeted');
% 
%     % 3. 接收端处理
%     % 原信号处理 (只需计算一次，但此处放入循环便于展示流程)
%     % 实际应用中，如果 rxSignal 不变，rxBaseband_original 只需计算一次
%     rxBaseband_original = processReceiver(rxSignal_orig, config, hopIndices);
% 
%     % 受干扰信号处理
%     rxBaseband_fake = processReceiver(rxSignal_jammed, config, hopIndices);
% 
%     rxBaseband_fake_dcgan = processReceiver(rxSignal_jammed_dcgan, config, hopIndices);
% 
%     rxBaseband_jammed_mtj = processReceiver(rxSignal_jammed_mtj, config, hopIndices);
% 
%     % 4. 解调
%     [~, rxData_original_bits] = demodulateSignal(rxBaseband_original, config);
%     [~, rxData_fake_bits] = demodulateSignal(rxBaseband_fake, config);
%     [~, rxData_fake_bits_dcgan] = demodulateSignal(rxBaseband_fake_dcgan, config);
%     [~, rxData_fake_bits_mtj] = demodulateSignal(rxBaseband_jammed_mtj, config);
% 
% 
%     % 5. 计算误码率 (BER)
%     % 确保 txData_bits (原始发送比特) 已经定义并与 rxData_fake_bits 长度匹配
%     if length(txData_bits) ~= length(rxData_fake_bits)
%         % 确保 BER 计算的比特数一致
%         min_len = min(length(txData_bits), length(rxData_fake_bits));
%         txBits_comp = txData_bits(1:min_len);
%         rxBits_comp = rxData_fake_bits(1:min_len);
%         rxBits_orig_comp = rxData_original_bits(1:min_len);
%         rxBits_dcgan_comp = rxData_fake_bits_dcgan(1:min_len);
%         rxBits_mtj_comp = rxData_fake_bits_mtj(1:min_len);
%     else
%         txBits_comp = txData_bits;
%         rxBits_comp = rxData_fake_bits;
%         rxBits_orig_comp = rxData_original_bits;
%         rxBits_dcgan_comp = rxData_fake_bits_dcgan;
%         rxBits_mtj_comp = rxData_fake_bits_mtj;
%     end
% 
%     % 假设 txData_bits 存在并是正确的参考
%     num_errors = sum(xor(txBits_comp, rxBits_comp));
%     awgn_errors = sum(xor(txBits_comp, rxBits_orig_comp));
%     dcgan_errors = sum(xor(txBits_comp,rxBits_dcgan_comp));
%     mtj_errors = sum(xor(txBits_comp,rxBits_mtj_comp));
% 
%     current_BER = num_errors / length(txBits_comp);
%     awgn_BER = awgn_errors / length(txBits_comp);
%     dcgan_BER = dcgan_errors / length(txBits_comp);
%     mtj_BER = mtj_errors / length(txBits_comp);
% 
%     BER_results(i) = current_BER;
%     BER_of_Signal(i) = awgn_BER;
%     BER_results_dcgan(i) = dcgan_BER;
%     BER_results_mtj(i) = mtj_BER;
%     fprintf('  SIR = %d dB VL-GAN时的误码率 BER = %e\n', current_SIR_dB, current_BER);
%     fprintf('  SIR = %d dB AWGN时的误码率 BER = %e\n', current_SIR_dB, awgn_BER);
%     fprintf('  SIR = %d dB DCGAN时的误码率 BER = %e\n', current_SIR_dB, dcgan_BER);
%     fprintf('  SIR = %d dB 单音干扰时的误码率 BER = %e\n', current_SIR_dB, mtj_BER);
% end
% 
% % ------------------------- 绘图呈现 -------------------------
% 
% % 假设 SIR_range_dB, BER_results 和 BER_of_Signal 已经计算或定义
% 
% figure(32); % 使用您指定的图窗号
% 
% % 1. 绘制受干扰信号的 BER 曲线
% semilogy(SIR_range_dB, BER_results, 'ro-', ...
%     'LineWidth', 1.5, 'MarkerSize', 6, ...
%     'DisplayName', 'DCGAN干扰');
% hold on; % 保持图窗，以便绘制第二条曲线
% 
% % 2. 绘制无干扰信号的 BER 曲线
% % 注意：这里使用 plot 也是可以的，但为了保证 y 轴对数刻度，最好使用 semilogy
% semilogy(SIR_range_dB, BER_of_Signal, 'bo-', ...
%     'LineWidth', 1.5, ...
%     'DisplayName', '高斯白噪声');
% 
% hold on; % 释放图窗
% 
% semilogy(SIR_range_dB, BER_results_mtj, 'yo-', ...
%     'LineWidth', 1.5, ...
%     'DisplayName', '多音干扰');
% 
% hold on; % 释放图窗
% 
% semilogy(SIR_range_dB, BER_results_dcgan, 'go-', ...
%     'LineWidth', 1.5, ...
%     'DisplayName', 'VL-GAN干扰');
% 
% hold off; % 释放图窗
% 
% % 3. 设置图表属性和图例
% title('误码率 (BER) vs. 干信比 (JSR) 性能曲线');
% xlabel('干信比 JSR (dB)');
% ylabel('误码率 BER');
% grid on;
% 
% % 关键步骤：只调用一次 legend，并使用 'DisplayName' 属性来自动生成图例
% legend('show', 'Location', 'best'); 

% 假设 rxBaseband_original 和 rxBaseband_fake 已经是您在 MATLAB 工作区中处理好的复数向量

% 1. 创建一个新的图窗
% figure(13);
% sgtitle('接收信号基带对比：原信号 vs. 受干扰信号'); % 设置总标题
% 
% % --- 子图 1: 实部对比 ---
% subplot(2, 1, 1); % 创建第一个子图 (2行, 1列, 第1个位置)
% hold on; % 允许在同一坐标系内绘制多条曲线
% 
% % 绘制原信号的实部
% plot(real(rxBaseband_original(100:2000)), 'b--', 'LineWidth', 1, 'DisplayName', '原信号实部 (Original)');
% 
% % 绘制受干扰信号的实部
% plot(real(rxBaseband_fake(100:2000)), 'r--', 'LineWidth', 1, 'DisplayName', '受干扰信号实部 (Jammed)');
% 
% hold off; % 结束多曲线绘制
% title('实部对比 (Real Part Comparison)');
% xlabel('样本序号');
% ylabel('幅值');
% legend('show'); % 显示图例
% grid on; % 显示网格线
% 
% % --- 子图 2: 虚部对比 ---
% subplot(2, 1, 2); % 创建第二个子图 (2行, 1列, 第2个位置)
% hold on;
% 
% % 绘制原信号的虚部
% plot(imag(rxBaseband_original(100:2000)), 'b-', 'LineWidth', 1.5, 'DisplayName', '原信号虚部 (Original)');
% 
% % 绘制受干扰信号的虚部
% plot(imag(rxBaseband_fake(100:2000)), 'r--', 'LineWidth', 1, 'DisplayName', '受干扰信号虚部 (Jammed)');
% 
% hold off;
% title('虚部对比 (Imaginary Part Comparison)');
% xlabel('样本序号');
% ylabel('幅值');
% legend('show');
% grid on;

%% 8. 解调
fprintf('[8/9] 正在解调信号...\n');
% (修改) 调用新的包装函数
[~, rxData_original_bits] = demodulateSignal(rxBaseband_original, config);
[~, rxData_fake_bits] = demodulateSignal(rxBaseband_fake, config);

% [rxBaseband_newly_jammed, rxData_newly_jammed_bits, jammerSignal_hopped] = ...
%     evaluateDemodRemodJamming(rxSignal, rxData_fake_bits, config, hopIndices);
% 
% % 现在您可以对 rxBaseband_newly_jammed 和 rxData_newly_jammed_bits 进行进一步的分析和绘图
% % 例如，对比 rxBaseband_newly_jammed 和 rxBaseband_original 的实部和虚部
% % 或者计算 BER (误码率)
%% 9. BER 计算与可视化 (原 %% 9, 10, 11) (修改)
fprintf('[9/9] 正在计算 BER 并生成可视化图表...\n');
% 封装结果以便传递 (全部使用比特流)
results.data = data_bits;
results.rxData_original = rxData_original_bits;
results.rxData_fake = rxData_fake_bits; 
% results.rxData_newly_jammed = rxData_newly_jammed_bits;

results.txSignal = txSignal;
results.Signal_original = Signal_original;
results.fakeSignal_original = 0.8 * fakeSignal_original + rxSignal;
results.rxSignal = rxSignal;
results.stft_data = stft_data;

calculateAndPlotResults(results, config);
% err = sum(xor(data_bits,rxData_original_bits))/length(data_bits);
% fprintf("BER %d",err)
fprintf('\n仿真完成。\n');