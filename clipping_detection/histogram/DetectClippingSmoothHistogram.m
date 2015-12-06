function [positive_clip_amp, negative_clip_amp] = DetectClippingSmoothHistogram(audio, fs)
  HISTOGRAM_SIZE = 6001;
  SEARCH_WIDTH_BINS = 400;
  
  has_negative_clipping = true;
  has_positive_clipping = true;
  
  normalization_value = max(abs(audio));
  normalized_audio = audio ./ normalization_value;
  
  [values, edges] = MyHist(normalized_audio, HISTOGRAM_SIZE);
  values = values.';
  smoothed_values = FrontBackExpSmoothing(values, 0.03);

  mid_idx = floor(HISTOGRAM_SIZE / 2);

  [peak_vals, peak_indices, peak_widths] = findpeaks(smoothed_values, 'WidthReference', 'halfprom');
  
  left_filter = find(peak_indices < 1000);
  left_peak_values = peak_vals(left_filter);
  left_peak_indices = peak_indices(left_filter);
  left_peak_widths = peak_widths(left_filter);
  
  negative_clip_amp = -1.1;
  if(~isempty(left_peak_indices))
    left_peak_idx = left_peak_indices(1) + floor(left_peak_widths(1));
    negative_clip_amp_normalized = mean([edges(left_peak_idx) edges(left_peak_idx + 1)]);
    negative_clip_amp = negative_clip_amp_normalized * normalization_value;
  end
  
  right_filter = find(peak_indices > (HISTOGRAM_SIZE - 1000));
  right_peak_values = peak_vals(right_filter);
  right_peak_indices = peak_indices(right_filter);
  right_peak_widths = peak_widths(right_filter);
  
  positive_clip_amp = 1.1;
  if(~isempty(right_peak_indices))
    right_peak_idx = right_peak_indices(end) - floor(right_peak_widths(1));
    positive_clip_amp_normalized = mean([edges(right_peak_idx) edges(right_peak_idx + 1)]);
    positive_clip_amp = positive_clip_amp_normalized * normalization_value;
  end
  
end
