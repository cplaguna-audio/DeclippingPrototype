function flags = FlagsFromIntervals(intervals, length)
  flags = zeros(length, 1);
  
  num_intervals = size(intervals, 1);
  for interval_idx = 1:num_intervals
    start = intervals(interval_idx, 1);
    stop = intervals(interval_idx, 2);
    flags(start:stop, 1) = 1;
  end
end
