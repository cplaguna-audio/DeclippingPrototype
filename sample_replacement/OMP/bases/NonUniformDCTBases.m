% Bases are columns.
function bases = NonUniformDCTBases(ts, num_bases)
  N = size(ts, 1);
  bases = zeros(N, num_bases);
  
  for bases_idx = 1:num_bases
    k = bases_idx - 1;
    for time_idx = 1:N
      t = ts(time_idx);
      bases(time_idx, bases_idx) = cos(pi * (k + 0.5) * (t + 0.5) / num_bases);
    end
  end
  bases  = bases .* sqrt(2 / num_bases);
end

