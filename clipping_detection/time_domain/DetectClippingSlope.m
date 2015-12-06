function clip_intervals = DetectClippingSlope(x, fs)

  MIN_WIDTH = 18;
  D_THRESH = 0.0025;
  
  % Normalize audio.
  norm_x = mean(x, 2);
  X_THRESH = max(abs(norm_x)) / 2;
  
  num_samples = size(norm_x, 1);
  slopes = ones(num_samples, 1);
  
  half_width = floor(MIN_WIDTH / 2);
  
  % Compute the derivative.
  for d_idx = half_width + 1:num_samples - (half_width + 1)
    cur_slope = 0;
    start_idx = d_idx - half_width;
    stop_idx = d_idx + half_width;
    
    center_sample = norm_x(d_idx);
    for block_idx = start_idx:stop_idx
      cur_slope = cur_slope + abs(center_sample - norm_x(block_idx));
    end
    
    slopes(d_idx) = cur_slope / MIN_WIDTH;
  end
  
  % Find clipped reigions of derivative.
  clip_intervals = [];
  clip_values = [];
  start_idx = -1;
  stop_idx = -1;
  cur_width = 0;
  in_interval = false;
  for d_idx = 1:num_samples
     if(in_interval)
       % Remain in the interval.
       if(slopes(d_idx) < D_THRESH)
          cur_width = cur_width + 1;
          
       % The end of the interval is reached.
       else
         stop_idx = d_idx + half_width;
         
         % Only keep intervals of a certain width.
         if(cur_width >= MIN_WIDTH)
           clip_value = abs(mean(norm_x(start_idx:stop_idx)));
                      
           if(clip_value > X_THRESH)
             clip_values = [clip_values; clip_value];
             clip_intervals = [clip_intervals; [start_idx, stop_idx]];
           end
         end
         in_interval = false;
       end
     else
       % Begin an interval.
       if(slopes(d_idx) < D_THRESH)
         start_idx = max(d_idx - half_width, 1);
         cur_width = 1;
         in_interval = true;
       end
     end
  end
  
end