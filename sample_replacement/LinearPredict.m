function x_hat = LinearPredict(x, a, num_predictions)
  order = length(a);
  x_prev = x(end - order + 1:end);
  x_hat = zeros(num_predictions, 1);
  for idx = 1:num_predictions
    cur_prediction = x_prev.' * flipud(a);
    x_hat(idx) = cur_prediction;
    x_prev = [x_prev(2:end); cur_prediction];
  end
end

