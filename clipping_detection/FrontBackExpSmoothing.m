function y = FrontBackExpSmoothing(x, alpha)
  y = x;
  length_x = size(x, 1);
  for sample_idx = 2:length_x
    cur_sample = y(sample_idx);
    prev_sample = y(sample_idx - 1);
    y(sample_idx) = alpha * cur_sample + (1 - alpha) * prev_sample;
  end

  for sample_idx = length_x - 1:-1:1
    cur_sample = y(sample_idx);
    prev_sample = y(sample_idx + 1);
    y(sample_idx) = alpha * cur_sample + (1 - alpha) * prev_sample;
  end

end

