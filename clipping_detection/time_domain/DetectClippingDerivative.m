function clip_intervals = DetectClippingDerivative(x, fs)
  x_length = size(x, 1);
  
  MIN_WIDTH = 1;
  D_THRESH = 0.01;
  % D_THRESH = 0.02;

  AVG_THRESH = 1 * D_THRESH;
  
  % Normalize audio.
  norm_x = mean(x, 2);
  X_THRESH = max(abs(norm_x)) * 0.85;
  
  num_samples = size(norm_x, 1);
  
  % Compute the derivative.
  derivative = zeros(num_samples, 1);

  derivative(1) = abs(log(abs(norm_x(2))) - log(abs(norm_x(1))));
  for d_idx = 2:num_samples - 1

%     left_difference = abs(log(abs(norm_x(d_idx))) - log(abs(norm_x(d_idx - 1))));
%     right_difference = abs(log(abs(norm_x(d_idx + 1))) - log(abs(norm_x(d_idx))));
    
    left_difference = abs(norm_x(d_idx) - norm_x(d_idx - 1));
    right_difference = abs(norm_x(d_idx + 1) - norm_x(d_idx));
    
    derivative(d_idx) = min(left_difference, right_difference);
  end
  derivative(end) = abs(log(abs(norm_x(end))) - log(abs(norm_x(end - 1))));
  
  
  [~, peak_locs] = findpeaks(abs(norm_x), 'MinPeakHeight', X_THRESH, 'SortStr', 'descend');
  
  num_peaks = size(peak_locs, 1);
  clip_intervals = [];
  for cur_peak_number = 1:num_peaks
    cur_peak_loc = peak_locs(cur_peak_number);
    
    % Nope.
    if(derivative(cur_peak_loc) > D_THRESH)
      continue;
    end
    
    % Descend left.
    working_avg = abs(norm_x(cur_peak_loc));
    start_idx = cur_peak_loc;
    left_idx = cur_peak_loc - 1;
    num_iters = 1;
    while(left_idx >= 1)
      num_iters = num_iters + 1;
      cur_mag = abs(norm_x(left_idx));
      working_avg = (((num_iters - 1) * working_avg) / num_iters) + (cur_mag / num_iters);
      
      % log_diff = abs(log(abs(working_avg)) - log(cur_mag));
      log_diff = abs(working_avg - cur_mag);
      
      if(log_diff > AVG_THRESH)
        start_idx = left_idx + 1;
        break;
      end
      
      % We hit a sample outside of the clipping range. Save the sample to
      % the right, because it's the last sample in the clipping range.
      if(derivative(left_idx) > D_THRESH)
        start_idx = left_idx + 1;
        break;
      end
      
      left_idx = left_idx - 1;
    end
    
    % Decend right.
    working_avg = abs(norm_x(cur_peak_loc));
    stop_idx = cur_peak_loc;
    right_idx = cur_peak_loc + 1;
    num_iters = 1;
    while(right_idx <= x_length)
      num_iters = num_iters + 1;
      cur_mag = abs(norm_x(right_idx));
      working_avg = (((num_iters - 1) * working_avg) / num_iters) + (cur_mag / num_iters);

      % log_diff = abs(log(abs(working_avg)) - log(cur_mag));
      log_diff = abs(working_avg - cur_mag);

      if(log_diff > AVG_THRESH)
        stop_idx = right_idx - 1;
        break;
      end
      
      % We hit a sample outside of the clipping range. Save the sample to
      % the right, because it's the last sample in the clipping range.
      if(derivative(right_idx) > D_THRESH)
        stop_idx = right_idx - 1;
        break;
      end
      
      right_idx = right_idx + 1;
    end
    
    clip_intervals = [clip_intervals; [start_idx, stop_idx]];
  end
  
%   % Find clipped reigions of derivative.
%   clip_intervals = [];
%   clip_values = [];
%   start_idx = -1;
%   stop_idx = -1;
%   cur_width = 0;
%   in_interval = false;
%   for d_idx = 1:num_samples
%      if(d_idx == 13588)
%        d_idx;
%      end
%      
%      if(in_interval)
%        % Remain in the interval.
%        if(derivative(d_idx) < D_THRESH)
%           cur_width = cur_width + 1;
%           
%        % The end of the interval is reached.
%        else
%          stop_idx = d_idx - 1;
%          
%          % Only keep intervals of a certain width.
%          if(true)
%            clip_value = abs(mean(norm_x(start_idx:stop_idx)));
%            
%            if(clip_value > X_THRESH);
%            
%              clip_values = [clip_values; clip_value];
%              clip_intervals = [clip_intervals; [start_idx, stop_idx]];
%            end
%          end
%          in_interval = false;
%        end
%      else
%        % Begin an interval.
%        if(derivative(d_idx) < D_THRESH)
%          start_idx = d_idx;
%          cur_width = 1;
%          in_interval = true;
%        end
%      end
%   end
  
end


