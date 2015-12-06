function merged_intervals = MergeIntervals(redundant_intervals, max_distance_apart, thin_width)
  if(isempty(redundant_intervals))
    merged_intervals = [];
    return;
  end

  sorted_intervals = sortrows(redundant_intervals);
  num_redundant_intervals = size(sorted_intervals, 1);
  
  prev_start = sorted_intervals(1,1);
  prev_stop = sorted_intervals(1,2);
  merged_intervals = [prev_start, prev_stop];
  for interval_idx = 2:num_redundant_intervals
    cur_start = sorted_intervals(interval_idx, 1);
    cur_stop = sorted_intervals(interval_idx, 2);
    
    % Check to merge.
    if(cur_start <= prev_stop + 1 + max_distance_apart)
      new_start = prev_start;
      new_stop = max(prev_stop, cur_stop);
      merged_intervals(end, :) = [new_start, new_stop];
      
    % No merging.
    else
      merged_intervals = [merged_intervals; [cur_start, cur_stop]];
    end
    
    prev_start = merged_intervals(end, 1);
    prev_stop = merged_intervals(end, 2);
  end
  
  num_merged_intervals = size(merged_intervals, 1);
  thinned_intervals = [];
  % First, remove the thin intervals.
  for interval_idx = 1:num_merged_intervals
    cur_start = merged_intervals(interval_idx, 1);
    cur_stop = merged_intervals(interval_idx, 2);
    cur_width = cur_stop - cur_start + 1;
    
    % Check to merge.
    if(cur_width > thin_width)
      thinned_intervals = [thinned_intervals; [cur_start, cur_stop]];
    end
  end
  
  merged_intervals = thinned_intervals;
end

