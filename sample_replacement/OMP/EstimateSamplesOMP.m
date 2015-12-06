function x_hat = EstimateSamplesOMP(x, clip_intervals, sparsity)
  N = size(x, 1);
  all_indices = (1:N).';
  reliable_indices = IndicesFromClipIntervals(clip_intervals, N).';
  reliable_x = x(reliable_indices);

  bases = NonUniformDCTBases(all_indices - 1, N);
  partial_bases = NonUniformDCTBases(reliable_indices - 1, N);
  
  w = zeros(N, 1); % Weights to normalize the partial bases.
  
  % Normalize the partial bases.
  normed_partial_bases = zeros(size(partial_bases));
  for basis_idx = 1:N
    cur_basis = partial_bases(:, basis_idx);
    w(basis_idx) = norm(cur_basis);
    normed_partial_bases(:, basis_idx) = cur_basis ./ w(basis_idx);
  end

  % Find the alphas using Orthogonal Matching Pursuit.
  alpha_hat = OMP(normed_partial_bases, reliable_x, sparsity);
  
  alpha_hat = alpha_hat ./ w;
  x_hat = BackwardTransform(alpha_hat, bases);
end
