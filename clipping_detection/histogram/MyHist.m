function [values, edges] = MyHist(x, num_bins)
  
  max_amp = max(x);
  min_amp = min(x);

  bin_width = (max_amp - min_amp) / num_bins;
  edges = ((0:num_bins).' * bin_width) + min_amp;
  edges(end) = max_amp;

  values = zeros(num_bins, 1); 
  for i = 1:length(x)
    cur_x = x(i);
    cur_bin = FindBin(cur_x, edges);
    if(cur_bin == -1)
      i
      cur_x
    end
    values(cur_bin) = values(cur_bin) + 1;
  end
end

function y = FindBin(x, edges) 
  num_bins = length(edges) - 1;

  start_bin = 1;
  stop_bin = num_bins;
  while(true) 
    idx = floor(start_bin + (stop_bin - start_bin + 1) / 2);

    left_val = edges(idx);
    right_val = edges(idx + 1);
    if(left_val <= x && x <= right_val)
      y = idx;
      return;
    end

    % Value was not found.
    if((stop_bin - start_bin + 1) / 2 < 1)
      y = -1;
      return;
    end

    if(x > right_val)
      start_bin = idx + 1;
    else 
      stop_bin = idx - 1;
    end
  end
end

