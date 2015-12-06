function clip_intervals = DetectClippingHistogram(audio, fs, level_algo)

  if(strcmp(level_algo, 'smoothed-histogram'))
    [positive_clip_amp, negative_clip_amp] = DetectClippingSmoothHistogram(audio, fs);
  elseif(strcmp(level_algo, 'histogram-width'))
    [positive_clip_amp, negative_clip_amp] = DetectClippingHistogramWidth(audio, fs);
  else
    error('Level detection algorithm specified does not exist.');
  end
  
  clip_intervals = ClipIntervalsFromClipAmps(audio, negative_clip_amp, positive_clip_amp);
end

