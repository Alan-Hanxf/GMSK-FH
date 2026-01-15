function [rxSignal, fakeSignal1_original, fakeSignal2_original, Signal_original, stft_data] = applyChannelAndSTFT(txSignal, config)
% 6. 信道 + STFT处理 + 多路干扰恢复
% 此函数现在处理：
% 1. 原始信号加AWGN噪声并进行STFT。
% 2. 恢复第一路干扰信号（基于fakeImage_real/imag_path）。
% 3. 恢复第二路干扰信号（基于fakeImage2_real/imag_path）。
% 4. 对恢复后的干扰信号进行长度对齐。

% --- 辅助函数：处理单个Fake信号图像 ---
    function [fakeSignal_original, fakeSiganl_real, fakeSiganl_imag] = processFakeSignal(config, image_real_path, image_imag_path, maxValue_real, maxValue_imag, figNum, title_prefix)
        fprintf('正在加载和处理 %s 信号图像...\n', title_prefix);
        fakeSiganl_real = im2double(imread(image_real_path));
        fakeSiganl_imag = im2double(imread(image_imag_path));

        % 显示fake信号STFT灰度图
        figure(figNum);
        subplot(1,2,1);
        imshow(fakeSiganl_real, [0 1]); title(sprintf('%s STFT实部', title_prefix));
        subplot(1,2,2);
        imshow(fakeSiganl_imag, [0 1]); title(sprintf('%s STFT虚部', title_prefix));
        set(gcf,'Position',[figNum*100+100, figNum*100+100, 1000, 400]);

        % 逆归一化 (依赖 Helpers)
        % 假设 inormalized_STFT_signal 依赖于原信号的 maxValue_real/imag
        fakeSignal_inorm_real = inormalized_STFT_signal(fakeSiganl_real, maxValue_real);
        fakeSignal_inorm_imag = inormalized_STFT_signal(fakeSiganl_imag, maxValue_imag);

        % 合成fake STFT信号并逆变换为时域信号
        fakeSignal_stft = fakeSignal_inorm_real + 1j*fakeSignal_inorm_imag;
        fakeSignal_original = istft(fakeSignal_stft, config.Fs, ...
            'Window', hann(config.nfft, "periodic"), ...
            'OverlapLength', config.noverlap, ...
            'FFTLength', config.nfft);
    end

% --- 1. 信道处理（原信号） ---
rxSignal = awgn(txSignal, config.SNR_dB, 'measured');
fprintf('已添加 %d dB AWGN 噪声。\n', config.SNR_dB);

% --- 2. 原信号STFT变换 ---
[spec, ~, ~] = stft(rxSignal, config.Fs, ...
    'Window', hann(config.nfft, "periodic"), ...
    'OverlapLength', config.noverlap, ...
    'FFTLength', config.nfft);

% --- 3. 归一化处理STFT信号 & 获取归一化参数 ---
realValue = real(spec);
imgaValue = imag(spec);
maxValue_real = zeros(1, size(spec,2));
maxValue_imag = zeros(1, size(spec,2));
for i = 1:size(spec,2)
    % 假设这里计算的是用于逆归一化的最大值/缩放因子
    maxValue_real(i) = 2 * norm(realValue(:,i), Inf); 
    maxValue_imag(i) = 2 * norm(imgaValue(:,i), Inf);
end

% 归一化 (依赖 Helpers)
spec_real_norm = normalized_STFT_signal(real(spec));
spec_imag_norm = normalized_STFT_signal(imag(spec));
% gray_image_real = spec_real_norm * 255; % 仅为图像显示或保存
% gray_image_imag = spec_imag_norm * 255; % 仅为图像显示或保存

% 显示原信号STFT灰度图
figure(21); 
subplot(1,2,1);
imshow(spec_real_norm, [0 1]); title('原信号STFT实部（归一化）'); 
subplot(1,2,2);
imshow(spec_imag_norm, [0 1]); title('原信号STFT虚部（归一化）');
set(gcf,'Position',[100,100,1000,400]);

% 存储STFT数据用于后续绘图
stft_data.spec_real_norm = spec_real_norm;
stft_data.spec_imag_norm = spec_imag_norm;

% --- 4. 处理第一路干扰信号 (Fake 1) ---
[fakeSignal1_original, fakeSiganl1_real, fakeSiganl1_imag] = processFakeSignal( ...
    config, config.fakeImage_real_path, config.fakeImage_imag_path, ...
    maxValue_real, maxValue_imag, 22, 'Fake 1');

% --- 5. 处理第二路干扰信号 (Fake 2) ---
% 假设 config 中新增了 fakeImage2_real_path 和 fakeImage2_imag_path
[fakeSignal2_original, fakeSiganl2_real, fakeSiganl2_imag] = processFakeSignal( ...
    config, config.fakeImage2_real_path, config.fakeImage2_imag_path, ...
    maxValue_real, maxValue_imag, 23, 'Fake 2');


% --- 6. 原信号ISTFT恢复（用于对比）---
Signal_original = istft(spec, config.Fs, ...
    'Window', hann(config.nfft, "periodic"), ...
    'OverlapLength', config.noverlap, ...
    'FFTLength', config.nfft);

% --- 7. 长度对齐与误差计算 ---
len_rx = length(rxSignal);

% 长度对齐函数
    function alignedSignal = alignLength(signal, targetLength, signalName)
        len_sig = length(signal);
        if len_sig < targetLength
            pad_length = targetLength - len_sig;
            alignedSignal = [signal; zeros(pad_length, 1)];
            fprintf('已对%s补零%d个数据，对齐长度为 %d\n', signalName, pad_length, targetLength);
        elseif len_sig > targetLength
            alignedSignal = signal(1:targetLength);
            fprintf('%s过长，已截断至与rxSignal相同长度 %d\n', signalName, targetLength);
        else
            alignedSignal = signal;
            fprintf('%s与rxSignal长度一致（%d），无需处理\n', signalName, targetLength);
        end
    end

% 对齐第一路干扰信号
fakeSignal1_original = alignLength(fakeSignal1_original, len_rx, 'fakeSignal1_original');
% 对齐第二路干扰信号
fakeSignal2_original = alignLength(fakeSignal2_original, len_rx, 'fakeSignal2_original');

% 计算STFT像素误差 (保留对第一路的误差计算)
s1_real_abs = abs(spec_real_norm - fakeSiganl1_real);
s1_imag_abs = abs(spec_imag_norm - fakeSiganl1_imag);
fprintf('Fake 1 STFT实部平均误差: %.6f\n', sum(s1_real_abs(:))/numel(s1_real_abs));
fprintf('Fake 1 STFT虚部平均误差: %.6f\n', sum(s1_imag_abs(:))/numel(s1_imag_abs));

% 增加第二路的误差计算
s2_real_abs = abs(spec_real_norm - fakeSiganl2_real);
s2_imag_abs = abs(spec_imag_norm - fakeSiganl2_imag);
fprintf('Fake 2 STFT实部平均误差: %.6f\n', sum(s2_real_abs(:))/numel(s2_real_abs));
fprintf('Fake 2 STFT虚部平均误差: %.6f\n', sum(s2_imag_abs(:))/numel(s2_imag_abs));

end