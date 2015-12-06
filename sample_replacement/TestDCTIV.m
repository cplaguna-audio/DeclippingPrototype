clear;

% TestDCT
% x = [0; 1; 2; 3; 4; 5; 4; 3; 2; 1; 0];
% N = size(x, 1);
% ts = (0:(N-1)).';
% bases = NonUniformDCTBases(ts, N);
% y = ForwardTransform(x, bases);
% y_truth = TransformDCT(x.', 4).';
% 
% disp('[My-DCT-IV Truth-DCT-IV]');
% [y y_truth]
% 
% x_hat = BackwardTransform(y, bases);
% 
% disp('[Before-transform  after-transform]');
% [x x_hat]

% Test Partial Reconstruction
% N = 17;
% ts = (0:(N - 1)).';
% x = cos((ts + 0.5) * 1.5 * pi / N);
% % x = [8; 7; 6; 5; 4; 3; 2; 1; 0; 0; 1; 2; 3; 4; 5; 6; 7];
% 
% clip_intervals = [3 5; 9 10; 12 13];
% 
% x_hat = EstimateSamples(x, clip_intervals, 2);
% 
% disp('[Before-transform  after-transform]');
% figure;
% plot(x, 'g');
% hold on;
% plot(x_hat, 'r');
% title('Green: before transform. Red: after transform.');

% Test blocking.
% [x, fs] = audioread('test_replacement.wav');
% x = sum(x, 2);
% x = x ./ (abs(max(x)));
% x_length = size(x, 1);
% 
% WINDOW_SIZE = 2048;
% HOP_SIZE = WINDOW_SIZE / 4;
% 
% x_blocked = BlockSignal(x, WINDOW_SIZE, HOP_SIZE);
% num_blocks = size(x_blocked, 1);
% alpha_blocked = zeros(num_blocks, WINDOW_SIZE);
% y_blocked = zeros(num_blocks, WINDOW_SIZE);
% window = hamming(WINDOW_SIZE);
% ts = (0:(WINDOW_SIZE - 1)).';
% bases = NonUniformDCTBases(ts, WINDOW_SIZE);
% 
% for block_idx = 1:num_blocks
%   cur_block = x_blocked(block_idx, :).';
%   cur_block = cur_block .* window;
%   cur_alphas = ForwardTransform(cur_block, bases);
%   alpha_blocked(block_idx, :) = cur_alphas.';
% end
% 
% 
% for block_idx = 1:num_blocks
%   cur_alphas = alpha_blocked(block_idx, :).';
%   cur_block = BackwardTransform(cur_alphas, bases);
%   cur_block = cur_block .* window;
%   
%   y_blocked(block_idx, :) = cur_block.';
% end
% 
% % Reconstruct signal from blocks. Make sure to include the compensation
% % window.
% y = ReconstructSignal(y_blocked, WINDOW_SIZE, HOP_SIZE);
% window_size = size(window, 1);
% c_windowed = repmat(window .* window, 1, num_blocks).';
% compensation = ReconstructSignal(c_windowed, window_size, HOP_SIZE);
% y = y ./ compensation;
% y = y(1:x_length);
% error = norm(x - y);

% Test clipping.
CLIP_PERCENTAGE = 0.4;
[x, fs] = audioread('test_replacement.wav');
x = sum(x, 2);
x = x ./ (abs(max(x)));
x_length = size(x, 1);

WINDOW_SIZE = 2048;
HOP_SIZE = WINDOW_SIZE / 4;
SPARSITY = 204;
RESIDUAL_ENERGY = 0.01;

x_blocked = BlockSignal(x, WINDOW_SIZE, HOP_SIZE);

[clipped_x, clip_intervals] = ClipAudio(x, CLIP_PERCENTAGE);
clipped_x_blocked = BlockSignal(clipped_x, WINDOW_SIZE, HOP_SIZE);

num_blocks = size(clipped_x_blocked, 1);
alpha_blocked = zeros(num_blocks, WINDOW_SIZE);
y_blocked = zeros(num_blocks, WINDOW_SIZE);
window = hamming(WINDOW_SIZE);
ts = (0:(WINDOW_SIZE - 1)).';
bases = NonUniformDCTBases(ts, WINDOW_SIZE);

start = 1;
stop = start + WINDOW_SIZE - 1;
for block_idx = 1:num_blocks
  block_idx
  clipped_block = clipped_x_blocked(block_idx, :).';
  windowed_block = clipped_block .* window;
  
  cur_clipped_intervals = BlockedClipIntervals(clip_intervals, start, stop);
  cur_clipped_intervals = cur_clipped_intervals - start + 1;
  cur_clip_flags = FlagsFromIntervals(cur_clipped_intervals, WINDOW_SIZE);
  num_reliable_samples = sum(abs(cur_clip_flags - 1));
  
  if(num_reliable_samples == WINDOW_SIZE)
    y_blocked(block_idx, :) = windowed_block.';
    start = start + HOP_SIZE;
    stop = start + WINDOW_SIZE - 1;
    continue;
  end
  
  cur_y_block = EstimateSamplesOMP(windowed_block, cur_clipped_intervals, RESIDUAL_ENERGY);
  windowed_y_block = cur_y_block .* window;
  
  y_blocked(block_idx, :) = windowed_y_block.';
  
  % Plotting.
  unclipped_block = x_blocked(block_idx, :).' .* window;
  figure();
  ax1 = subplot(1, 1, 1);
  plot(unclipped_block);
  hold on;
  plot(windowed_block);
  hold on;
  plot(cur_y_block);
  legend('original', 'clipped', 'estimation');
  title('Reconstruction of windowed bock. Window Size = 2048, Residual = 0.01.');
%   ax2 = subplot(2, 1, 2);
%   plot(cur_clip_flags);
%   title('truth');
  
  start = start + HOP_SIZE;
  stop = start + WINDOW_SIZE - 1;
end

% Reconstruct signal from blocks. Make sure to include the compensation
% window.
y = ReconstructSignal(y_blocked, WINDOW_SIZE, HOP_SIZE);
window_size = size(window, 1);
c_windowed = repmat(window .* window, 1, num_blocks).';
compensation = ReconstructSignal(c_windowed, window_size, HOP_SIZE);
y = y ./ compensation;
y = y(1:x_length);
error = norm(x - y);


