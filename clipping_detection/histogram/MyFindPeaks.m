function [peaks, locs] = MyFindPeaks(x, thresh, should_sort)
  peaks = [];
  locs = [];
  for idx = 2:length(x) - 1
    cur_x = x(idx);
    if(cur_x >= thresh)
      prev_x = x(idx - 1);
      next_x = x(idx + 1);
      if(cur_x > prev_x && cur_x > next_x)
        peaks = [peaks; cur_x];
        locs = [locs; idx];
      end
    end
  end

  % Sort descending.
  if(should_sort) 
    [peaks, indices] = sort(peaks, 'descend');
    locs = locs(indices);
  end

end

