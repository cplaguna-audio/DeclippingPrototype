function x_hat = EstimateBurstPVocWindow(left_samples, right_samples, burst_length, truth, fs)
  HOP_RATIO = 1 / 8;
  WINDOW = hamming(burst_length);
  
  num_left_samples = length(left_samples)
  num_right_samples = length(right_samples)

  x = zeros(num_left_samples + burst_length + num_right_samples, 1);
  x(1:num_left_samples) = left_samples;
  x(end - num_right_samples + 1:end) = right_samples;
  x_length = length(x);
  
  burst_start = num_left_samples + 1;
  burst_stop = burst_start + burst_length - 1;
  x(burst_start:burst_stop) = zeros(burst_length, 1);

  hop_size = ceil(burst_length * HOP_RATIO);
  forward_start = burst_start - burst_length;
  forward_stop = forward_start + burst_length - 1;
  right_interp_start = forward_start;
  num_extraps = 0;
  while(right_interp_start < burst_stop)
    right_interp_start = right_interp_start + hop_size;
    num_extraps = num_extraps + 1;
  end
  
  interp_width = right_interp_start - forward_start;
  
  forward_start = forward_start - hop_size;
  forward_train_first = x(forward_start:forward_start + burst_length - 1);
  second_start = forward_start + hop_size;
  second_stop = second_start + burst_length - 1;
  forward_train_second = x(second_start:second_stop);
  forward_train = [forward_train_first forward_train_second];
  forward_train = forward_train .* repmat(WINDOW, 1, 2);
  forward_train = fft(fftshift(forward_train, 1));

  forward_extrap_freqs = ExtrapolatePhase(forward_train, hop_size, num_extraps, fs);
  forward_extrap = ifftshift(real(ifft(forward_extrap_freqs)), 1);
  forward_extrap = forward_extrap .* repmat(WINDOW, 1, num_extraps);
  
  forward_train = ifftshift(real(ifft(forward_train)), 1);
  forward_train = forward_train .* repmat(WINDOW, 1, 2);
  forward_extrap = [forward_train forward_extrap];
  forward_extrap = ReconstructSignal(forward_extrap.', burst_length, hop_size);
  
  forward_window_comp = repmat(WINDOW, 1, num_extraps + 2);
  forward_window_comp_freq = fft(fftshift(forward_window_comp));
  forward_window_comp_time = ifftshift(real(ifft(forward_window_comp_freq))) .* repmat(WINDOW, 1, num_extraps + 2);

  forward_window_comp = ReconstructSignal(forward_window_comp_time.', burst_length, hop_size);

  forward_window_comp(1:3 * hop_size) = 1;
  forward_window_comp(end - (3 * hop_size) + 1:end) = 1;
  forward_extrap = forward_extrap ./ forward_window_comp;
  forward_extrap(1:burst_length / 2) = forward_train_first(1:burst_length / 2);
  forward_extrap = forward_extrap(hop_size + 1:end);
  
  backward_extrap_stop = right_interp_start + burst_length - 1;
  backward_first_stop = backward_extrap_stop + hop_size;
  backward_first_start = backward_first_stop - burst_length + 1;
  backward_train_first = flipud(x(backward_first_start:backward_first_stop));
  backward_second_stop = backward_extrap_stop;
  backward_second_start = backward_second_stop - burst_length + 1;
  backward_train_second = flipud(x(backward_second_start:backward_second_stop));
  
  backward_train = [backward_train_first backward_train_second];
  backward_train = backward_train .* repmat(WINDOW, 1, 2);
  backward_train = fft(fftshift(backward_train, 1));

  backward_extrap_freqs = ExtrapolatePhase(backward_train, hop_size, num_extraps, fs);
  backward_extrap = ifftshift(real(ifft(backward_extrap_freqs)), 1);
  backward_extrap = backward_extrap .* repmat(WINDOW, 1, num_extraps);
  
  backward_train = ifftshift(real(ifft(backward_train)), 1);
  backward_train = backward_train .* repmat(WINDOW, 1, 2);
  backward_extrap = [backward_train backward_extrap];
  backward_extrap = ReconstructSignal(backward_extrap.', burst_length, hop_size);
  
  backward_extrap = backward_extrap ./ forward_window_comp;
  backward_extrap = backward_extrap(hop_size + 1:end);
  backward_extrap = flipud(backward_extrap);
  
  length_estimate = size(backward_extrap, 1);

  % Window between them.
  forward_window = zeros(length_estimate, 1);
  for idx = 1:length_estimate
    forward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (length_estimate + idx - 1) / (2 * length_estimate)));
  end
  
  backward_window = zeros(length_estimate, 1);
  for idx = 1:length_estimate
    backward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (idx - 1) / (2 * length_estimate)));
  end
  
  x_hat = x;
  
  new_start = second_start;
  new_stop = backward_extrap_stop;
  x_hat(new_start:new_stop) = forward_extrap .* forward_window + backward_extrap .* backward_window;
  
  figure();
  subplot(2,1,1);
  plot(forward_extrap);
  hold on;
  plot(backward_extrap);
  subplot(2,1,2);
  plot(x_hat);
  hold on;
  plot(x);
    
end

