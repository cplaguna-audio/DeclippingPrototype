function y_freq = ExtrapolatePhase(x_freqs, hop_size, num_blocks, fs)

  [block_size, num_input] = size(x_freqs);
  fft_size = ceil(block_size / 2);
  inst_freq = zeros(block_size, 1);
  freq_resolution = fs / block_size;
  if(num_input == 1)
    % Use bin-frequencies (center freqs).
    for idx = 1:block_size
      inst_freq(idx) = (idx - 1) * freq_resolution;
    end
  else
    prev_x_freq = x_freqs(:, end - 1);
    cur_x_freq = x_freqs(:, end);
    inst_freq = InstantaneousFreq(prev_x_freq, cur_x_freq, hop_size, fs);
  end
  
  first_freq = x_freqs(:, end);
  first_mag = abs(first_freq);
  first_phase = angle(first_freq);
  
%   WIDTH = 2;
%   [freq_peaks, freq_locs] = findpeaks(first_mag, 'MinPeakHeight', 10);
%   num_peaks = size(freq_locs, 1);
  
  delta_phase = MyWrapPhase(2 * pi * (inst_freq / fs) * hop_size);
  extrap_phases = zeros(block_size, num_blocks);
  for extrap_idx = 1:num_blocks
    cur_phase_change = delta_phase * extrap_idx;
    cur_phase = first_phase + cur_phase_change;

    extrap_phases(:, extrap_idx) = MyWrapPhase(cur_phase);
  end
  
  y_freq = zeros(block_size, num_blocks);
  for idx = 1:num_blocks
    cur_extrap = extrap_phases(:, idx);
    cur_half_phase = cur_extrap(1:fft_size);
    
    if(mod(block_size, 2) == 0)
      cur_phase = [cur_half_phase; 0; flipud(-1 * cur_half_phase(2:end))];
    else
      cur_phase = [cur_half_phase; flipud(-1 * cur_half_phase(2:end))];
    end

    y_freq(:, idx) = first_mag .* exp(1i * cur_phase);
  end

end