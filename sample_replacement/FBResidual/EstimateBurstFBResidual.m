function x_hat = EstimateBurstFBResidual(left_samples, right_samples, burst_length, truth)
  MAX_SAMPLES_TO_USE = 150;
  ORDER = 60;
  
  num_left_samples = length(left_samples);
  if(num_left_samples > MAX_SAMPLES_TO_USE)
    left_samples = left_samples(end - MAX_SAMPLES_TO_USE + 1:end);
  end
  if(num_left_samples < ORDER)
    warning('Not enough left samples. Truncating.');
    ORDER = num_left_samples - 10;
  end
  
  num_right_samples = length(right_samples);
  if(num_right_samples > MAX_SAMPLES_TO_USE)
    right_samples = right_samples(1:MAX_SAMPLES_TO_USE);
  end
  if(num_right_samples < ORDER)
    warning('Not enough right samples. Truncating.');
    ORDER = num_right_samples - 10;
  end
  
  a = MyARCoeffs(left_samples, ORDER);
  b = MyARCoeffs(flipud(right_samples), ORDER);

  a = [-1; a];
  b = [-1; b];
  
  % Left variables.
  A = MakeA(a, burst_length);
  L = MakeL(left_samples, burst_length, ORDER);
  y_l = -1 * L * a;
  
  % Right variables.
  B = MakeB(b, burst_length);
  R = MakeR(right_samples, burst_length, ORDER);
  y_r = -1 * R * b;
  
  % Combined variables.
  y = MakeY(y_l, y_r, A, B);
  D = MakeD(A, B);
  
  x_hat = inv(D) * y;
end

function A = MakeA(a, burst_length)
  length_a = length(a);
  first_row = zeros(1, burst_length);
  first_row(1,1) = -1;
  first_col = zeros(1, burst_length);
  first_col(1:length_a) = a;
  A = toeplitz(first_col, first_row);
end

function L = MakeL(left_samples, burst_length, order)
  first_row = zeros(order + 1, 1);
  first_row(2:end) = flipud(left_samples(end - order + 1:end));
  first_col = zeros(burst_length, 1);
  L = toeplitz(first_col, first_row);
end

function B = MakeB(b, burst_length)
  length_b = length(b);
  first_row = zeros(1, burst_length);
  first_row(1:length_b) = b;
  first_col = zeros(1, burst_length);
  first_col(1,1) = -1;
  B = toeplitz(first_col, first_row);
end

function R = MakeR(right_samples, burst_length, order)
  first_row = zeros(order + 1, 1);
  first_row(2:end) = right_samples(1:order);
  first_col = zeros(burst_length, 1);
  R = toeplitz(first_col, first_row);
  R = flipud(R);
end

function y = MakeY(y_l, y_r, A, B)
  M = length(y_l);
  y = zeros(M, 1);
  for h_idx = 1:M
    cur_sum = 0;
    for k_idx = 1:M
      cur_sum = cur_sum + (A(k_idx, h_idx) * y_l(k_idx)) + (B(k_idx, h_idx) * y_r(k_idx));
    end
    y(h_idx) = cur_sum;
  end
end

function D = MakeD(A, B)
  D = (transpose(A) * A) + (transpose(B) * B);
end