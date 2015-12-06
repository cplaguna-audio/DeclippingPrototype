function [f_measure, precision, recall, merged_pred_intervals, ...
          merged_truth_intervals, fp_flags, fn_flags] = ...
    GetSpecialFMeasure(predicted_clip_intervals, truth_clip_intervals, length)

  ADJUSTMENT = 4;
  THIN_WIDTH = 3;
  LEIGH_WAY = 4;

  % To count true positives/false positives: Merge/thin the predictions,
  % and merge the truths. For each positive prediction, check if there is a
  % positive truth within LEIGH_WAY samples. If so, mark true positive. If
  % not, mark false positive. 
  merged_pred_intervals = MergeIntervals(predicted_clip_intervals, ADJUSTMENT, THIN_WIDTH);
  merged_truth_intervals = MergeIntervals(truth_clip_intervals, ADJUSTMENT, 0);
  
  largest_pred_interval = max(merged_pred_intervals(:, 2) - merged_pred_intervals(:, 1)) + 1;
  largest_truth_interval = max(merged_truth_intervals(:, 2) - merged_truth_intervals(:, 1)) + 1;
  
  disp(['Largest intervals: pred - ' num2str(largest_pred_interval) ...
        ', truth - ' num2str(largest_truth_interval)]);
  
  tpfp_predicted_clip_flags = FlagsFromIntervals(merged_pred_intervals, length);
  tpfp_truth_clip_flags = FlagsFromIntervals(merged_truth_intervals, length);
  
  prediction_length = size(tpfp_predicted_clip_flags, 1);
  truth_length = size(tpfp_truth_clip_flags, 1);
  if(prediction_length ~= truth_length)
    error('Truth and prediction length must be equal.');
  end
  
  fp_flags = zeros(prediction_length, 1);
  fn_flags = zeros(prediction_length, 1);

  true_positives = 0;
  false_positives = 0;
  for sample_idx = 1:prediction_length
    if(tpfp_predicted_clip_flags(sample_idx) == 1)
      search_start = max(sample_idx - LEIGH_WAY, 1);
      search_stop = min(sample_idx + LEIGH_WAY, prediction_length);
      found_match = false;
      for search_idx = search_start:search_stop
        if(tpfp_truth_clip_flags(search_idx) == 1)
          found_match = true;
          break;
        end
      end
      if(found_match)
        true_positives = true_positives + 1;
      else
        false_positives = false_positives + 1;
        fp_flags(sample_idx) = 1;
      end
    end
  end
  
  % To count false negatives, merge/thin the predictions, and merge/thin
  % the truths. For each positive TRUTH, check if there is a positive
  % prediction within LEIGH_WAY samples. If not, mark false negative.
  merged_pred_intervals = MergeIntervals(predicted_clip_intervals, ADJUSTMENT, THIN_WIDTH);
  merged_truth_intervals = MergeIntervals(truth_clip_intervals, ADJUSTMENT, THIN_WIDTH);
  fn_predicted_clip_flags = FlagsFromIntervals(merged_pred_intervals, length);
  fn_truth_clip_flags = FlagsFromIntervals(merged_truth_intervals, length);
  
  false_negatives = 0;
  for sample_idx = 1:prediction_length
    if(fn_truth_clip_flags(sample_idx) == 1)
      search_start = max(sample_idx - LEIGH_WAY, 1);
      search_stop = min(sample_idx + LEIGH_WAY, prediction_length);
      found_match = false;
      for search_idx = search_start:search_stop
        if(fn_predicted_clip_flags(search_idx) == 1)
          found_match = true;
          break;
        end
      end
      if(~found_match)
        false_negatives = false_negatives + 1;
        fn_flags(sample_idx) = 1;
      end
    end
  end
  
  % Calculate metrics from the tp/fp/fn.
  if(true_positives + false_positives == 0)
    precision = 0;
  else
    precision = true_positives / (true_positives + false_positives);
  end
  
  if(true_positives + false_negatives == 0)
    recall = 0;
  else
    recall = true_positives / (true_positives + false_negatives);
  end
  
  if(precision + recall == 0)
    f_measure = 0;
  else
    f_measure = 2 * (precision * recall) / (precision + recall);
  end
end