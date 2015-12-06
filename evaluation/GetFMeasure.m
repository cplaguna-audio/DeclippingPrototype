function [f_measure, precision, recall, merged_pred_intervals, merged_truth_intervals] = ...
    GetFMeasure(predicted_clip_intervals, truth_clip_intervals, length)

  ADJUSTMENT = 0;
  THIN_WIDTH = 0;
  
  predicted_clip_intervals = MergeIntervals(predicted_clip_intervals, ADJUSTMENT, THIN_WIDTH);
  merged_pred_intervals = predicted_clip_intervals;
  
  truth_clip_intervals = MergeIntervals(truth_clip_intervals, ADJUSTMENT, THIN_WIDTH);
  merged_truth_intervals = truth_clip_intervals;
  
  predicted_clip_flags = FlagsFromIntervals(predicted_clip_intervals, length);
  truth_clip_flags = FlagsFromIntervals(truth_clip_intervals, length);
  
  prediction_length = size(predicted_clip_flags, 1);
  truth_length = size(truth_clip_flags, 1);
  if(prediction_length ~= truth_length)
    error('Truth and prediction length must be equal.');
  end

  true_clip_indices = find(truth_clip_flags == 1);
  true_not_clip_indices = find(truth_clip_flags == 0);
  
  true_positives = sum(predicted_clip_flags(true_clip_indices));
  false_positives = sum(predicted_clip_flags(true_not_clip_indices));
  
  % true_negatives = sum(~predicted_clip_flags(true_not_clip_indices));
  false_negatives = sum(~predicted_clip_flags(true_clip_indices));
  
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