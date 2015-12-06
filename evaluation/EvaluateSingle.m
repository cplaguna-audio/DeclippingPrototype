function EvaluateSingle(file_path)

  TEST_NAME = 'test';
  TRUTH_NAME = 'truth.wav';
  TMP_DIR = 'inspect';
  rmdir(TMP_DIR, 's');
  mkdir(TMP_DIR);
  
  NORMALIZATION_AMPLITUDE = 0.8;
  CLIP_PERCENTAGE = 0.4;
  AAC_ENCODING_QUALITY = 5;

  [raw_audio, truth_fs] = audioread(file_path);

  % Normalize Audio.
  % To mono.
  normalized_audio = mean(raw_audio, 2);
  % Peak at 1.
  normalized_audio = normalized_audio ./ max(abs(normalized_audio));
  % Peak at NORMALIZATION_AMPLITUDE.
  normalized_audio = normalized_audio .* NORMALIZATION_AMPLITUDE;

  % Clip Audio.
  [clipped_audio, truth_clip_intervals] = ClipAudio(normalized_audio, ...
                                                CLIP_PERCENTAGE);
  clipped_length = size(clipped_audio, 1);
  truth_path = [TMP_DIR '/' TRUTH_NAME];
  audiowrite(truth_path, clipped_audio, truth_fs);

  % Encode as aac using ffmpeg.
  coded_path = [TMP_DIR '/' TEST_NAME '.aac'];

  % ffmpeg -i <input_path> -c:a libfdk_aac -vbr <quality> <output_path>
  command_string = ['/usr/local/bin/ffmpeg -i ' truth_path ' -c:a ' ...
                    'libfdk_aac -aq ' num2str(AAC_ENCODING_QUALITY) ...
                    ' ' coded_path];
  system(command_string); 

  % Crop test file to remove the zero padding done by aac.
  test_path = [TMP_DIR '/' TEST_NAME '_cropped.wav'];  % Don't want to encode again.
  [coded_audio, test_fs] = audioread(coded_path);
  test_audio = coded_audio(2049:end);
  length_truth = size(clipped_audio, 1);
  test_audio = test_audio(1:length_truth);
  audiowrite(test_path, test_audio, test_fs);

  % Test Algorithm.
  [test_audio, test_fs] = audioread(test_path);
  predicted_clip_intervals = DetectClipping(test_audio, test_fs);
  test_length = size(test_audio, 1);
  
  % Evaluation Metrics.
  [file_f_measure, precision, recall, merged_pred_intervals, ...
   merged_truth_intervals, fp_flags, fn_flags] = ...
      GetSpecialFMeasure(predicted_clip_intervals, truth_clip_intervals, test_length);
%   [file_f_measure, precision, recall, merged_pred_intervals, merged_truth_intervals] = ...
%       GetFMeasure(predicted_clip_intervals, truth_clip_intervals, test_length);
    
  figure();
  ax1 = subplot(4, 1, 1);
  plot(test_audio);
  hold on;
  plot(clipped_audio);
  legend('encoded', 'clipped');
  
  truth_clip_flags = FlagsFromIntervals(truth_clip_intervals, clipped_length);
  merged_truth_clip_flags = FlagsFromIntervals(merged_truth_intervals, clipped_length);
  predicted_clip_flags = FlagsFromIntervals(predicted_clip_intervals, test_length);
  merged_predicted_clip_flags = FlagsFromIntervals(merged_pred_intervals, test_length);

  
  ax2 = subplot(4, 1, 2);
  plot(truth_clip_flags);
  hold on;
  plot(merged_truth_clip_flags);
  title('truth');
  legend('original', 'merged');
  
  ax3 = subplot(4, 1, 3);
  plot(predicted_clip_flags);
  hold on;
  plot(merged_predicted_clip_flags);
  title('prediction');
  legend('original', 'merged');

  ax4 = subplot(4,1,4);
  plot(fp_flags);
  hold on;
  plot(fn_flags);
  title('Error positions');
  legend('false positives', 'false negatives');
  
  linkaxes([ax1, ax2, ax3, ax4], 'xy');
  
  % Plot the histograms.
%   figure();
%   ax1 = subplot(3,1,1);
%   histogram(normalized_audio, 6000);
%   title('Original');
%   
%   ax2 = subplot(3,1,2);
%   histogram(clipped_audio, 6000);
%   title('Clipped');
%   
%   ax3 = subplot(3,1,3);
%   histogram(test_audio, 6000);
%   title(['Encoded (aac q = ' num2str(AAC_ENCODING_QUALITY) ')']);
%   linkaxes([ax1,ax2, ax3], 'xy');
  
  disp(['F, P, R: ' num2str(file_f_measure) ', ' num2str(precision) ', ' num2str(recall)]);
end

