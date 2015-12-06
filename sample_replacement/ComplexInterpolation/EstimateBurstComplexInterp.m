function x_hat = EstimateBurstComplexInterp(left_samples, right_samples, burst_length, truth)
  HOP_RATIO = 1 / 4;
  WINDOW = ones(burst_length, 1); % hamming(burst_length);
  
  num_left_samples = length(left_samples);
  num_right_samples = length(right_samples);

  x = zeros(num_left_samples + burst_length + num_right_samples, 1);
  x(1:num_left_samples) = left_samples;
  x(end - num_right_samples + 1:end) = right_samples;
  x_length = length(x);
  
  burst_start = num_left_samples + 1;
  burst_stop = burst_start + burst_length - 1;
  x(burst_start:burst_stop) = truth;

  left_interp_start = burst_start - burst_length;
  left_interp_stop = left_interp_start + burst_length - 1;
  left_interp = x(left_interp_start:left_interp_stop);
  left_cpx = fft(left_interp .* WINDOW);
  
  x_2 = zeros(size(x));
  window_comp = zeros(size(x));
  
  hop_size = ceil(burst_length * HOP_RATIO);
  
  right_interp_start = left_interp_start;
  num_bs = 0;
  while(right_interp_start < burst_stop)
    right_interp_start = right_interp_start + hop_size;
    num_bs = num_bs + 1;
  end
  
  right_interp_stop = right_interp_start + burst_length - 1; 
  right_interp = x(right_interp_start:right_interp_stop);
  right_cpx = fft(right_interp .* WINDOW);
  
  num_bs = num_bs - 1;
  
  interp_width = right_interp_start - left_interp_start;
  
  % Plot time interpolation.
  figure();
  axes = [];
  b_start = left_interp_start;
  b_stop = b_start + burst_length - 1;
  for b_idx = 1:num_bs + 2
    left_weight = 1 - ( (b_start - left_interp_start) / interp_width)
    right_weight = 1 - left_weight
    
    b_interp_window = left_weight * left_interp + right_weight * right_interp;
    
    ax1 = subplot(4,5,b_idx);
    plot(x(b_start:b_stop));
    title(['x ' num2str(b_idx)]);
    ax2 = subplot(4,5,b_idx + 10);
    plot(b_interp_window);
    title(['x hat time ' num2str(b_idx)]);
    axes = [axes; ax1; ax2];
    
    window_comp(b_start:b_stop) = window_comp(b_start:b_stop) + WINDOW .* WINDOW;
    x_2(b_start:b_stop) = x_2(b_start:b_stop) + b_interp_window;
    
    % Move one block forward.
    b_start = b_start + hop_size;
    b_stop = b_start + burst_length - 1;
  end
  linkaxes(axes, 'xy');  
  
  % Do cpx interpolation.
  figure();
  axes = [];
  b_start = left_interp_start;
  b_stop = b_start + burst_length - 1;
  for b_idx = 1:num_bs + 2
    left_weight = 1 - ( (b_start - left_interp_start) / interp_width);
    right_weight = 1 - left_weight;
    
    b_cpx = (left_weight * left_cpx) + (right_weight * right_cpx);
    b_interp = ifft(b_cpx);
    b_interp_window = b_interp .* WINDOW;
        
    ax1 = subplot(4,5,b_idx);
    plot(x(b_start:b_stop));
    title(['x ' num2str(b_idx)]);
    ax2 = subplot(4,5,b_idx + 10);
    plot(b_interp_window);
    title(['x hat cpx ' num2str(b_idx)]);
    axes = [axes; ax1; ax2];
    
    window_comp(b_start:b_stop) = window_comp(b_start:b_stop) + WINDOW .* WINDOW;
    x_2(b_start:b_stop) = x_2(b_start:b_stop) + b_interp_window;
    
    % Move one block forward.
    b_start = b_start + hop_size;
    b_stop = b_start + burst_length - 1;
  end
  linkaxes(axes, 'xy');  
  
  window_comp(window_comp == 0) = 1;
  x_2 = x_2 ./ window_comp;
  figure();
  subplot(2,1,1);
  plot(x);
  hold on;
  plot(x_2);
  subplot(2,1,2);
  plot(window_comp);
  
  x_hat = x_2(burst_start:burst_stop);
  
end

