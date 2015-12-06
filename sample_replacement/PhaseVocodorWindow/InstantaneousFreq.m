function inst_freqs = InstantaneousFreq(prev_x_freq, cur_x_freq, hop_size, fs)
  prev_phase = angle(prev_x_freq);
  cur_phase = angle(cur_x_freq);

  num_bins = size(prev_x_freq, 1);
  inst_freqs = zeros(num_bins, 1);
  for freq_idx = 1:num_bins
    c = ((2 * pi * (freq_idx - 0.5)) / num_bins) * hop_size;
    guess_shift = prev_phase(freq_idx) + c;
    unwrapped_phase = guess_shift + MyWrapPhase(cur_phase(freq_idx) - guess_shift);
    delta_phase = unwrapped_phase - prev_phase(freq_idx);
    inst_freqs(freq_idx) = (delta_phase * (fs / hop_size)) / (2 * pi);
  end
end

