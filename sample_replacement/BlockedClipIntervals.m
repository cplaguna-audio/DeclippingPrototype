function  block_clip_intervals = BlockedClipIntervals(clip_intervals, start, stop)
  num_intervals = size(clip_intervals, 1);
  
  block_clip_intervals = clip_intervals;
  
  start_interval_idx = -1;
  stop_interval_idx = -1;
  
  % Find the earliest interval in our reigon.
  for interval_idx = 1:num_intervals
    if(clip_intervals(interval_idx, 1) >= start)
      start_interval_idx = interval_idx;
      break;
    end
    
    if(clip_intervals(interval_idx, 2) >= start)
      block_clip_intervals(interval_idx, 1) = start;
      start_interval_idx = interval_idx;
      break;
    end
  end
  
  if(start_interval_idx < 1)
    block_clip_intervals = [];
    return;
  end

  % Find the latest interval in our reigon.
  for interval_idx = start_interval_idx:num_intervals
    if(clip_intervals(interval_idx, 1) > stop)
      stop_interval_idx = interval_idx - 1;
      break;
    end
    
    if(clip_intervals(interval_idx, 2) >= stop)
      block_clip_intervals(interval_idx, 2) = stop;
      stop_interval_idx = interval_idx;
      break;
    end
  end
  
  block_clip_intervals = block_clip_intervals(start_interval_idx:stop_interval_idx, :);
end

