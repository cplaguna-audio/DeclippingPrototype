function indices = IndicesFromClipIntervals(clip_intervals, N)
  num_clip_intervals = size(clip_intervals, 1);
  if(num_clip_intervals < 1)
    indices = 1:N; 
    return;
  end
  
  indices = 1:clip_intervals(1, 1) - 1;
  for interval_idx = 2:num_clip_intervals
    start = clip_intervals(interval_idx - 1, 2) + 1;
    stop = clip_intervals(interval_idx, 1) - 1;
    indices = [indices start:stop];
  end
  
  indices = [indices clip_intervals(end, 2) + 1: N];
end

