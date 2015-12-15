function x_hat = EstimateBurstPVocWindow(left_samples, right_samples, burst_length, truth, fs)
  OVERLAP_WINDOW_LENGTH = 4;
  HOP_RATIO = 1 / 4;
  block_size = 16;
  hop_size = ceil(block_size * HOP_RATIO);
  WINDOW = hann(block_size);
  
  num_left_samples = length(left_samples)
  num_right_samples = length(right_samples)

  x = zeros(num_left_samples + burst_length + num_right_samples, 1);
  x(1:num_left_samples) = left_samples;
  x(end - num_right_samples + 1:end) = right_samples;
  x_length = length(x);

  x_blocked = BlockSignal(x, block_size, hop_size).';
  
  % Look for the blocks surrounding the clipping reigion.
  left_edge_idx = floor((num_left_samples - block_size) / hop_size) + 1;
  right_edge_idx = ceil((num_left_samples + burst_length) / hop_size) + 1;
  num_extraps = right_edge_idx - left_edge_idx + 1;
  
  left_start = left_edge_idx - 1;
  left_stop = left_edge_idx;
  num_left = left_stop - left_start + 1;
  forward_train = x_blocked(:, left_start:left_stop);
  forward_train_window = forward_train .* repmat(WINDOW, 1, num_left);
  forward_train_freq = fft(fftshift(forward_train_window, 1));

  forward_extrap_freq = ExtrapolatePhase(forward_train_freq, hop_size, num_extraps, fs);
  forward_extrap = ifftshift(real(ifft(forward_extrap_freq)), 1);
  forward_extrap = forward_extrap .* repmat(WINDOW, 1, num_extraps);
  
  forward_train_inverse = ifftshift(real(ifft(forward_train_freq)), 1) .* repmat(WINDOW, 1, num_left);
  
  forward_guess = ReconstructSignal([forward_train_inverse forward_extrap].', block_size, hop_size);
 
  window_comp_blocked = repmat(WINDOW, 1, num_extraps + num_left);
  window_comp_freq = fft(fftshift(window_comp_blocked));
  window_comp_time = ifftshift(real(ifft(window_comp_freq))) .* window_comp_blocked;
  window_comp = ReconstructSignal(window_comp_time.', block_size, hop_size);

  forward_guess = forward_guess(hop_size+1:end - hop_size);
  window_comp = window_comp(hop_size + 1:end - hop_size);
  forward_guess = forward_guess ./ window_comp;
  
  right_start = right_edge_idx;
  right_stop = right_edge_idx + 1;
  num_right = right_stop - right_start + 1;
  backward_train = x_blocked(:, right_start:right_stop);
  backward_train = fliplr(flipud(backward_train));
  backward_train_window = backward_train .* repmat(WINDOW, 1, num_right);
  backward_train_freq = fft(fftshift(backward_train_window, 1));

  backward_extrap_freq = ExtrapolatePhase(backward_train_freq, hop_size, num_extraps, fs);
  backward_extrap = ifftshift(real(ifft(backward_extrap_freq)), 1);
  backward_extrap = backward_extrap .* repmat(WINDOW, 1, num_extraps);
  
  backward_train_inverse = ifftshift(real(ifft(backward_train_freq)), 1) .* repmat(WINDOW, 1, num_left);
  
  backward_guess = ReconstructSignal([backward_train_inverse backward_extrap].', block_size, hop_size);
  
  window_comp_blocked = repmat(WINDOW, 1, num_extraps + num_right);
  window_comp_freq = fft(fftshift(window_comp_blocked));
  window_comp_time = ifftshift(real(ifft(window_comp_freq))) .* window_comp_blocked;
  window_comp = ReconstructSignal(window_comp_time.', block_size, hop_size);
  
  backward_guess = backward_guess(hop_size + 1:end - hop_size);
  window_comp = window_comp(hop_size + 1:end - hop_size);  
  backward_guess = backward_guess ./ window_comp;
  backward_guess = flipud(backward_guess);
  
  % Window between them.
  length_estimate = size(forward_guess, 1);
  forward_window = zeros(length_estimate, 1);
  for idx = 1:length_estimate
    forward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (length_estimate + idx - 1) / (2 * length_estimate)));
  end
  
  backward_window = zeros(length_estimate, 1);
  for idx = 1:length_estimate
    backward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (idx - 1) / (2 * length_estimate)));
  end
  
  combined_guess = forward_guess .* forward_window + backward_guess .* backward_window;
  guess_offset = (left_edge_idx - 1) * hop_size;
  
  x_hat = x;
  
  % Window in the combined guess, starting from the left_edge_idx+1 block and
  % going up till the end of left_samples. Then, window out the combined
  % guess, starting at the start of the right samples and going until the
  % end of the right_edge_idx-1 block.
  
  overlapping_segment_start = num_left_samples + 1 - OVERLAP_WINDOW_LENGTH;
  overlapping_segment_stop = num_left_samples + burst_length + 1 + OVERLAP_WINDOW_LENGTH - 1;
  
  overlapping_x = x(overlapping_segment_start:overlapping_segment_stop);
  
  left_window_start = overlapping_segment_start;
  left_window_stop = num_left_samples;
  left_window_length = left_window_stop - left_window_start + 1;
  forward_window = zeros(left_window_length, 1);
  for idx = 1:left_window_length
    forward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (left_window_length + idx - 1) / (2 * left_window_length)));
  end
  
  backward_window = zeros(left_window_length, 1);
  for idx = 1:left_window_length
    backward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (idx - 1) / (2 * left_window_length)));
  end
  
  forward_signal = x(left_window_start:left_window_stop);
  
  guess_left_stop = num_left_samples - guess_offset;
  guess_left_start = guess_left_stop - OVERLAP_WINDOW_LENGTH + 1;
  backward_signal = combined_guess(guess_left_start:guess_left_stop);
  x_hat(left_window_start:left_window_stop) = forward_signal .* forward_window + backward_signal .* backward_window;
  
  right_window_start = num_left_samples + burst_length + 1;
  right_window_stop = overlapping_segment_stop;
  right_window_length = right_window_stop - right_window_start + 1;
  forward_window = zeros(right_window_length, 1);
  for idx = 1:right_window_length
    forward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (right_window_length + idx - 1) / (2 * right_window_length)));
  end
  
  backward_window = zeros(right_window_length, 1);
  for idx = 1:right_window_length
    backward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (idx - 1) / (2 * right_window_length)));
  end
  
  guess_right_start = num_left_samples + burst_length + 1 - guess_offset;
  guess_right_stop = guess_right_start + OVERLAP_WINDOW_LENGTH - 1;
  forward_signal = combined_guess(guess_right_start:guess_right_stop);
  backward_signal = x(right_window_start:right_window_stop);
  x_hat(right_window_start:right_window_stop) = forward_signal .* forward_window + backward_signal .* backward_window;
  
  new_reigion_start = num_left_samples + 1 - guess_offset;
  new_reigion_stop = num_left_samples + burst_length - guess_offset;
  new_reigion = combined_guess(new_reigion_start:new_reigion_stop);
  x_hat(num_left_samples + 1:num_left_samples + burst_length) = new_reigion;
  
  x_truth = [left_samples; truth; right_samples];
  plot_truth = x_truth(guess_offset + 1:guess_offset + length(combined_guess));
  figure();
  subplot(2,1,1);
  plot(forward_guess);
  hold on;
  plot(backward_guess);
  hold on;
  plot(combined_guess);
  hold on;
  plot(plot_truth);
  legend('forward', 'backward', 'combined', 'truth');
%     
%   figure();
%   plot(overlapping_x);
%   hold on;
%   plot(combined_guess);
%   legend('overlap', 'combined');
  
end

