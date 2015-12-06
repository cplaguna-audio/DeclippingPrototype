function x_hat = EstimateBurstFBWindowed(left_samples, right_samples, burst_length, truth)
  MAX_SAMPLES_TO_USE = 60;
  ORDER = 45;
  
  num_left_samples = length(left_samples);
  if(num_left_samples > MAX_SAMPLES_TO_USE)
    left_samples = left_samples(end - MAX_SAMPLES_TO_USE + 1:end);
  end
  if(num_left_samples < ORDER)
    warning('Not enough left samples. Truncating.');
    ORDER = num_left_samples - 1;
  end
  
  num_right_samples = length(right_samples);
  if(num_right_samples > MAX_SAMPLES_TO_USE)
    right_samples = right_samples(1:MAX_SAMPLES_TO_USE);
  end
  if(num_right_samples < ORDER)
    warning('Not enough right samples. Truncating.');
    ORDER = num_right_samples - 1;
  end
    
  x_hat = WindowedFBPredict(left_samples, right_samples, ORDER, burst_length);
  
%   flags = zeros(length(left_samples) + burst_length + length(right_samples), 1);
%   flags(length(left_samples) + 1:length(left_samples) + burst_length) = 1;
%   figure();
%   subplot(4,1,1);
%   plot([left_samples; x_forward; right_samples]);
%   hold on; 
%   plot(flags);
%   title('Forward prediction');
%   subplot(4,1,2);
%   plot([left_samples; x_backward; right_samples]);
%   hold on;
%   plot(flags);
%   title('Backward prediction');
%   subplot(4,1,3);
%   plot([left_samples; x_hat; right_samples]);
%   hold on;
%   plot(flags);
%   title('Windowed');
%   subplot(4,1,4);
%   plot([left_samples; truth; right_samples]);
%   hold on;
%   plot(flags);
%   title('Truth');
end

function x_hat = WindowedFBPredict(left_samples, right_samples, order, burst_length)
  a = MyARCoeffs(left_samples, order);
  b = MyARCoeffs(flipud(right_samples), order);

  % Do forward prediction.
  x_forward = LinearPredict(left_samples, a, burst_length);
  
  % Do backward prediction.
  x_backward = LinearPredict(flipud(right_samples), b, burst_length);
  x_backward = flipud(x_backward);
  
  forward_window = zeros(burst_length, 1);
  for idx = 1:burst_length
    forward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (burst_length + idx - 1) / (2 * burst_length)));
  end
  
  backward_window = zeros(burst_length, 1);
  for idx = 1:burst_length
    backward_window(idx) = (1 / 2) * (1 - cos(2 * pi * (idx - 1) / (2 * burst_length)));
  end
  
  x_hat = x_forward .* forward_window + x_backward .* backward_window;
end

