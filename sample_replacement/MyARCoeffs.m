function a = MyARCoeffs(x, order)
  length_x = length(x);
  if(length_x < order)
    error(['Model cannot be estimated with less than <order> number ' ...
           'of samples.']);
  end
  
  num_rows = length_x - order;
  num_cols = order;
  X = zeros(num_rows, num_cols);
  y = zeros(num_rows, 1);
  for row_idx = 1:num_rows
    y(row_idx) = x(row_idx + order);
    x_idx = row_idx + order - 1;
    for col_idx = 1:num_cols
      X(row_idx, col_idx) = x(x_idx);
      x_idx = x_idx - 1;
    end
  end
  X_big = transpose(X) * X;
  
  % Truncated inverse.
  [V, D] = eig(X_big);
  D_inv = zeros(size(D));
  D_inv(logical(eye(size(D)))) = 1 ./ diag(D);
  D_inv(D < 0.01) = 0;
  X_big_inv = V * D_inv * V.';

%   X_big_inv = inv(X_big);
  
  info_mat = X_big_inv * transpose(X);
  a = info_mat * y;
end

