% x = myReconstruct(xmat, windowSize, hopSize)
% xmat = float, windowSize*numBlocks matrix of signal
% windowSize = int, window size in samples
% hopSize = int, hop size in samples
% x = float, N*1 vector of input signal
%
% Chris Laguna
function y = ReconstructSignal(x_blocked, window_size, hop_size) 

num_windows = size(x_blocked, 1);
length = ((num_windows - 1) * hop_size) + window_size;

y = zeros(length,1);

window_start = 1;
window_end = window_start + window_size - 1;
for window_idx = 1:num_windows
  window = x_blocked(window_idx, :);
  y(window_start:window_end) = window + y(window_start:window_end).';

  window_start = window_start + hop_size;
  window_end = window_start + window_size - 1;
end

end