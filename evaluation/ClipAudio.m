function [clipped_audio, clip_intervals] = ClipAudio(audio, clip_percentage)
  length_audio = size(audio, 1);
  clipped_audio = audio;
  clip_intervals = zeros(1, 2);

  clip_amplitude = max(abs(audio)) * (1 - clip_percentage);
  
  clip_interval_idx = 1;
  in_clip_zone = false;
  for idx = 1:length_audio
    % Clip the audio.
    if(abs(audio(idx, 1)) > clip_amplitude)
      clipped_audio(idx, 1) = sign(audio(idx, 1)) * clip_amplitude;
    end
    
    % Generate clipping labels.
    if(in_clip_zone)
      % Condition of exiting a clip zone.
      if(abs(audio(idx, 1)) < clip_amplitude)
        in_clip_zone = false;
        % The current sample is not in the clip zone, so don't include it.
        clip_intervals(clip_interval_idx, 2) = idx - 1;
        clip_interval_idx = clip_interval_idx + 1;
      end
    else
      % Condition of entering a new clip zone.
      if(abs(audio(idx, 1)) > clip_amplitude)
        clip_intervals(clip_interval_idx, 1) = idx;
        in_clip_zone = true;
      end
    end
  end

end

