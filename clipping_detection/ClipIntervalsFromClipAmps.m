function clip_intervals = ...
    ClipIntervalsFromClipAmps(audio, negative_clip_amp, positive_clip_amp)
  
  clip_intervals = zeros(0, 2);
  
  interval_idx = 1;
  in_interval = false;
  start = 0;
  stop = 0;
  num_samples = size(audio, 1);
  for sample_idx = 1:num_samples
    cur_sample = audio(sample_idx);
    
    if(cur_sample > positive_clip_amp || cur_sample < negative_clip_amp)
      if(~in_interval)
        in_interval = true;
        start = sample_idx;
      end
    else
      if(in_interval)
        in_interval = false;
        stop = sample_idx - 1;
        
        clip_intervals(interval_idx, 1) = start;
        clip_intervals(interval_idx, 2) = stop;
        interval_idx = interval_idx + 1;
      end
    end
  end
end
