function clip_intervals = DetectClipping(audio, fs)
  ALGORITHM = 'combined'; % 'combined', 'histogram-width', 'smoothed-histogram', 'derivative', 'slope'
  LEVEL_ALGORITHM = 'histogram-width'; % 'histogram-width', 'smoothed-histogram'
  IS_WINDOWED = true;
  WINDOW_SIZE_SECONDS = 3;
  
  if(IS_WINDOWED)
    window_size_samples = WINDOW_SIZE_SECONDS * fs;
    blocked_audio = BlockSignal(audio, window_size_samples, window_size_samples);
    num_blocks = size(blocked_audio, 1);
    
    clip_intervals = [];
    for block_idx = 1:num_blocks
      cur_block = blocked_audio(block_idx, :).';
      block_offset = (block_idx - 1) * window_size_samples;
      current_clip_intervals = [];
      
      if(strcmp(ALGORITHM, 'combined'))
        current_clip_intervals = DetectClippingCombined(cur_block, fs, LEVEL_ALGORITHM);
      elseif(strcmp(ALGORITHM, 'histogram-width'))
        current_clip_intervals = DetectClippingHistogram(cur_block, fs, ALGORITHM);
      elseif(strcmp(ALGORITHM, 'smoothed-histogram'))
        current_clip_intervals = DetectClippingHistogram(cur_block, fs, ALGORITHM);
      elseif(strcmp(ALGORITHM, 'derivative'))
        current_clip_intervals = DetectClippingDerivative(cur_block, fs);
      elseif(strcmp(ALGORITHM, 'slope'))
        current_clip_intervals = DetectClippingSlope(cur_block, fs);
      else
        error(['Algorithm choice (' ALGORITHM ') not supported.']);
      end
      
      if(~isempty(current_clip_intervals))
        current_clip_intervals = current_clip_intervals + block_offset;
        clip_intervals = [clip_intervals; current_clip_intervals];
      end
    end
  else
    if(strcmp(ALGORITHM, 'combined'))
      clip_intervals = DetectClippingCombined(audio, fs, LEVEL_ALGORITHM);
    elseif(strcmp(ALGORITHM, 'histogram-width'))
      clip_intervals = DetectClippingHistogram(audio, fs, ALGORITHM);
    elseif(strcmp(ALGORITHM, 'smoothed-histogram'))
      clip_intervals = DetectClippingHistogram(audio, fs, ALGORITHM);
    elseif(strcmp(ALGORITHM, 'derivative'))
      clip_intervals = DetectClippingDerivative(audio, fs);
    elseif(strcmp(ALGORITHM, 'slope'))
      clip_intervals = DetectClippingSlope(audio, fs);
    else
      error(['Algorithm choice (' ALGORITHM ') not supported.']);
    end
  end
end

