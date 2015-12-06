function Evaluate()
  DATA_DIR = '../data/homburg';
  TMP_DIR = 'eval_files';
  TRUTH_NAME = 'truth';
  TEST_NAME = 'test';

  NORMALIZATION_AMPLITUDE = 0.8;
  CLIP_PERCENTAGE = 0.4;
  AAC_ENCODING_QUALITY = 5;

  audio_file_paths = GetAudioPaths(DATA_DIR);

  path1 = getenv('PATH');
  path1 = ['/usr/local/bin:' path1];
  setenv('PATH', path1);
  
  exp_dir = [TMP_DIR '/' num2str(NORMALIZATION_AMPLITUDE) ...
             '-' num2str(CLIP_PERCENTAGE) '-' ...
             num2str(AAC_ENCODING_QUALITY)];
  
  if(exist(exp_dir, 'dir') ~= 7)
    mkdir(exp_dir);
  end
  
  accumulated_f_measure = 0;
  accumulated_precision = 0;
  accumulated_recall = 0;
  num_test_data = size(audio_file_paths, 1);
  for test_idx = 1:num_test_data
    cur_audio_path = audio_file_paths{test_idx};
    [~, cur_filename] = fileparts(cur_audio_path);
    file_dir = [exp_dir '/' cur_filename];

    % If files already exist, use them. Otherwise, create them.
    if(exist(file_dir, 'dir') == 7)
      truth_labels_path = [file_dir '/' TRUTH_NAME '_intervals.txt'];
      test_path = [file_dir '/' TEST_NAME '_cropped.wav'];
      
      truth_clip_intervals = dlmread(truth_labels_path);
      [test_audio, test_fs] = audioread(test_path);
      audio_length = size(test_audio, 1);
      
      % Test Algorithm.
      predicted_clip_intervals = DetectClipping(test_audio, test_fs);
      
      % Evaluation Metrics.
      [file_f_measure, file_precision, file_recall] = ...
          GetFMeasure(predicted_clip_intervals, truth_clip_intervals, audio_length);
      accumulated_f_measure = accumulated_f_measure + file_f_measure;
      accumulated_precision = accumulated_precision + file_precision;
      accumulated_recall = accumulated_recall + file_recall;
    else
      mkdir(file_dir);

      [raw_audio, truth_fs] = audioread(cur_audio_path);

      % Normalize Audio.
      % To mono.
      normalized_audio = mean(raw_audio, 2);
      % Peak at 1.
      normalized_audio = normalized_audio ./ max(abs(normalized_audio));
      % Peak at NORMALIZATION_AMPLITUDE.
      normalized_audio = normalized_audio .* NORMALIZATION_AMPLITUDE;

      % Clip Audio.
      [clipped_audio, truth_clip_intervals] = ...
          ClipAudio(normalized_audio, CLIP_PERCENTAGE);
      truth_path = [file_dir '/' TRUTH_NAME '.wav'];
      truth_labels_path = [file_dir '/' TRUTH_NAME '_intervals.txt'];
      audiowrite(truth_path, clipped_audio, truth_fs);
      dlmwrite(truth_labels_path, truth_clip_intervals, 'precision', 10);
      
      % Encode as aac using ffmpeg.
      coded_path = [file_dir '/' TEST_NAME '.aac'];

      % ffmpeg -i <input_path> -c:a libfdk_aac -vbr <quality> <output_path>
      command_string = ['ffmpeg -i ' truth_path ' -c:a ' ...
                        'libfdk_aac -aq ' num2str(AAC_ENCODING_QUALITY) ...
                        ' ' coded_path ' >/dev/null 2>&1'];
      system(command_string); 

      % Crop test file to remove the zero padding done by aac.
      test_path = [file_dir '/' TEST_NAME '_cropped.wav'];  % Don't want to encode again.
      [coded_audio, test_fs] = audioread(coded_path);
      test_audio = coded_audio(2049:end);
      length_truth = size(clipped_audio, 1);
      test_audio = test_audio(1:length_truth);
      audiowrite(test_path, test_audio, test_fs);

      % Test Algorithm.
      [test_audio, test_fs] = audioread(test_path);
      predicted_clip_flags = DetectClipping(test_audio, test_fs);

      % Evaluation Metrics.
      [file_f_measure, file_precision, file_recall] = ...
          GetFMeasure(predicted_clip_flags, truth_clip_intervals, length_truth);
      accumulated_f_measure = accumulated_f_measure + file_f_measure;
      accumulated_precision = accumulated_precision + file_precision;
      accumulated_recall = accumulated_recall + file_recall;
    end
  
  
  disp(['F, p, r for File ' cur_audio_path ': ' ...
        num2str(file_f_measure) ', ' num2str(file_precision) ', ' ...
        num2str(file_recall)]);

  end
  average_f_measure = accumulated_f_measure / num_test_data;
  average_precision = accumulated_precision / num_test_data;
  average_recall = accumulated_recall / num_test_data;
  
  disp(['Average F Measure: ' num2str(average_f_measure)]);
  disp(['Average precision: ' num2str(average_precision)]);
  disp(['Average recall: ' num2str(average_recall)]);
end

function audio_paths = GetAudioPaths(dataset_dir)
  audio_paths = {};
  
  genres = dir(dataset_dir);
  genres(~[genres.isdir]) = [];
  genres = genres(arrayfun(@(x) x.name(1), genres) ~= '.');
  
  num_genres = size(genres, 1);
  for genre_idx = 1:num_genres
    genre_path = [dataset_dir '/' genres(genre_idx).name];
    
    file_names = dir(genre_path);
    file_names([file_names.isdir]) = [];
    file_names = file_names(arrayfun(@(x) x.name(1), file_names) ~= '.');
    num_files = size(file_names, 1);
    
    for file_idx = 1:num_files
      file_path = [genre_path '/' file_names(file_idx).name];
      audio_paths = [audio_paths; file_path];
    end
  end
end