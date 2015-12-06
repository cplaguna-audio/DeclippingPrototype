function clip_intervals = DetectClippingCombined(audio, fs, level_algo)

  % First, estimate the positive and negative amplitudes where clipping 
  % occurs.
  if(strcmp(level_algo, 'smoothed-histogram'))
    [positive_clip_amp, negative_clip_amp] = DetectClippingSmoothHistogram(audio, fs);
  elseif(strcmp(level_algo, 'histogram-width'))
    [positive_clip_amp, negative_clip_amp, ...
     positive_clip_amp_up, negative_clip_amp_up] = DetectClippingHistogramWidth(audio, fs);
  else
    error('Level detection algorithm specified does not exist.');
  end
    
  [~, positive_peak_locs] = MyFindPeaks(audio, positive_clip_amp, true);
  [~, negative_peak_locs] = MyFindPeaks(-1 * audio, abs(negative_clip_amp), true);
  
  
  positive_thresh = abs(positive_clip_amp - positive_clip_amp_up) / 2;
  negative_thresh = abs(negative_clip_amp - negative_clip_amp_up) / 2;

  positive_clip_intervals = TimeDomainClipIntervals(audio, positive_peak_locs, positive_thresh);
  negative_clip_intervals = TimeDomainClipIntervals(audio, negative_peak_locs, negative_thresh);
  clip_intervals = [positive_clip_intervals; negative_clip_intervals];
  clip_intervals = MergeIntervals(clip_intervals, 0, 0);

end

function clip_intervals = TimeDomainClipIntervals(audio, peak_locs, derivative_threshold)
  num_peaks = size(peak_locs, 1);
  x_length = size(audio, 1);

  clip_intervals = [];
  for cur_peak_number = 1:num_peaks
    cur_peak_loc = peak_locs(cur_peak_number);
    
    % Descend left.
    working_avg = abs(audio(cur_peak_loc));
    start_idx = cur_peak_loc;
    left_idx = cur_peak_loc - 1;
    num_iters = 1;
    while(left_idx >= 1)
      num_iters = num_iters + 1;
      
      cur_mag = abs(audio(left_idx));
      prev_mag = abs(audio(left_idx + 1));
      working_avg = (((num_iters - 1) * working_avg) / num_iters) + (cur_mag / num_iters);
      
      avg_diff = abs(working_avg - cur_mag);
      if(avg_diff > derivative_threshold)
        start_idx = left_idx + 1;
        break;
      end
      
      % We hit a sample outside of the clipping range. Save the sample to
      % the right, because it's the last sample in the clipping range.
      cur_derivative = abs(cur_mag - prev_mag);
      if(cur_derivative > derivative_threshold)
        start_idx = left_idx + 1;
        break;
      end
      
      left_idx = left_idx - 1;
    end
    
    % Decend right.
    working_avg = abs(audio(cur_peak_loc));
    stop_idx = cur_peak_loc;
    right_idx = cur_peak_loc + 1;
    num_iters = 1;
    while(right_idx <= x_length)
      num_iters = num_iters + 1;
      
      cur_mag = abs(audio(right_idx));
      prev_mag = abs(audio(right_idx - 1));
      working_avg = (((num_iters - 1) * working_avg) / num_iters) + (cur_mag / num_iters);

      avg_diff = abs(working_avg - cur_mag);
      if(avg_diff > derivative_threshold)
        stop_idx = right_idx - 1;
        break;
      end
      
      % We hit a sample outside of the clipping range. Save the sample to
      % the right, because it's the last sample in the clipping range.
      cur_derivative = abs(cur_mag - prev_mag);
      if(cur_derivative > derivative_threshold)
        stop_idx = right_idx - 1;
        break;
      end
      
      right_idx = right_idx + 1;
    end
    
    clip_intervals = [clip_intervals; [start_idx, stop_idx]];
  end
  
  clip_intervals = MergeIntervals(clip_intervals, 0, 0);
end

