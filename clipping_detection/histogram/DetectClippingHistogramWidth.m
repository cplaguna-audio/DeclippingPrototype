function [positive_clip_amp, negative_clip_amp, ...
          positive_clip_up, negative_clip_up] = DetectClippingHistogramWidth(audio, fs)
  HISTOGRAM_SIZE = 6000;
  MIN_WIDTH = 18;
  SEARCH_WIDTH_BINS = 600;

  % Normalize audio.
  normalized_audio = mean(audio, 2);

  [values, edges] = MyHist(normalized_audio, HISTOGRAM_SIZE);
  % [values, edges] = histcounts(normalized_audio, HISTOGRAM_SIZE);
  % values = values.';
  
  smoothed_values = FrontBackExpSmoothing(values, 0.2);
  % smoothed_values = medfilt1(smoothed_values, 7);

  super_smoothed_values = FrontBackExpSmoothing(smoothed_values, 0.025);

  differences = smoothed_values - super_smoothed_values;

  % First, find negative clipping value.
  negative_clip_idx = -1;
  negative_clip_lower_idx = -1;
  in_bump = false;
  width = 0;
  for idx = 1:SEARCH_WIDTH_BINS
    cur_val = differences(idx);

    % You are in a bump.
    if(cur_val > 0)
      if(in_bump)
        width = width + 1;
      else
        width = 1;
        in_bump = true;
      end
    % You are not in a bump.
    else
      if(in_bump)
        % We encounter clipping.
        if(width > MIN_WIDTH)
          % Use the index halfway between bump boundaries.
          negative_clip_idx = (idx - 1) - (floor(width / 2));
          negative_clip_lower_idx = idx;
          negative_clip_upper_idx = negative_clip_lower_idx - width;
          break;
        end
        width = 0;
        in_bump = false;
      end
    end
  end
  
  negative_clip_amp = min(audio) - 1;
  negative_clip_lower_amp = negative_clip_amp;
  negative_clip_upper_amp = 0;
  if(negative_clip_idx > 0)
    negative_clip_amp = edges(negative_clip_idx);
    negative_clip_lower_amp = edges(negative_clip_lower_idx + 1);
    negative_clip_upper_amp = edges(negative_clip_upper_idx);
  end
  
  % Next, find posiitive clipping_value.
  positive_clip_idx = -1;
  positive_clip_lower_idx = -1;
  in_bump = false;
  width = 0;
  for idx = HISTOGRAM_SIZE:-1:(HISTOGRAM_SIZE - SEARCH_WIDTH_BINS)
    cur_val = differences(idx);
    
    % You are in a bump.
    if(cur_val > 0)
      if(in_bump)
        width = width + 1;
      else
        in_bump = true;
        width = 1;
      end
    % You are not in a bump.
    else
      if(in_bump)
        % We encounter clipping.
        if(width > MIN_WIDTH)
          % Use index halfway between bump boundaries.
          positive_clip_idx = (idx - 1) + (floor(width / 2));
          positive_clip_lower_idx = idx;
          positive_clip_upper_idx = positive_clip_lower_idx + width;
          break;
        end
        width = 0;
        in_bump = false;
      end
    end
  end
  
  positive_clip_amp = max(audio) + 1;
  positive_clip_lower_amp = positive_clip_amp;
  positive_clip_upper_amp = 0;
  if(positive_clip_idx > 0)
    positive_clip_amp = edges(positive_clip_idx);
    positive_clip_lower_amp = edges(positive_clip_lower_idx);
    positive_clip_upper_amp = edges(positive_clip_upper_idx + 1);
  end
  
  negative_clip_amp = negative_clip_lower_amp;
  positive_clip_amp = positive_clip_lower_amp;
  
  negative_clip_up = negative_clip_upper_amp;
  positive_clip_up = positive_clip_upper_amp;
end
