clear;
% Test clipping.
CLIP_PERCENTAGE = 0.4;
ALGORITHM = 'PVoc'; % 'PVoc' 'Complex' 'FBWindow' 'FBResidual';

REIGON_START = 2259;
REIGON_STOP = 2705;

[x, fs] = audioread('test_replacement.wav');
x = sum(x, 2);
x = x ./ (abs(max(x)));
x_length = size(x, 1);
[clipped_x, clip_intervals] = ClipAudio(x, CLIP_PERCENTAGE);

clipped_x = x;
% fs = 44100;
% BLOCK_SIZE = 2048;
% freq = 13.8 * fs / BLOCK_SIZE;
% t = 0:1 / fs:1 - (1 / fs);
% x = sin(t * 2 * pi * freq).';
% clipped_x = x;


reigon_truth = x(REIGON_START:REIGON_STOP);
reigon_clipped = clipped_x(REIGON_START:REIGON_STOP);
clip_intervals = [158 175];

length_reigon = length(reigon_truth);

clip_start = clip_intervals(1,1);
clip_stop = clip_intervals(1,2);
clip_length = clip_stop - clip_start + 1;
left_samples = reigon_clipped(1:clip_start - 1);
right_samples = reigon_clipped(clip_stop + 1:end);


if(strcmp(ALGORITHM, 'FBWindow'))
  truth = reigon_clipped(clip_start:clip_stop);
  replacements = EstimateBurstFBWindowed(left_samples, right_samples, clip_length, truth);
  reigon_fixed = [left_samples; replacements; right_samples];
elseif(strcmp(ALGORITHM, 'FBResidual'))
  replacements = EstimateBurstFBResidual(left_samples, right_samples, clip_length);
  reigon_fixed = [left_samples; replacements; right_samples];
elseif(strcmp(ALGORITHM, 'Complex'))
  truth = reigon_clipped(clip_start:clip_stop);
  replacements = EstimateBurstComplexInterp(left_samples, right_samples, clip_length, truth);
elseif(strcmp(ALGORITHM, 'PVoc'))
  truth = reigon_clipped(clip_start:clip_stop);
  reigon_fixed = EstimateBurstPVocWindow(left_samples, right_samples, clip_length, truth, fs);
end

clip_flags = FlagsFromIntervals(clip_intervals, length_reigon) * 0.5;

% figure();
% title(ALGORITHM);
% ax1 = subplot(2,1,1);
% plot(reigon_truth);
% title('Truth');
% 
% ax2 = subplot(2,1,2);
% plot(reigon_fixed);
% hold on;
% plot(clip_flags);
% title(['Estimate - ' ALGORITHM]);
% linkaxes([ax1, ax2], 'xy');

figure();
title(ALGORITHM);
plot(reigon_truth);
hold on;
plot(reigon_fixed);
hold on;
plot(clip_flags * -1);
title(['Estimate - ' ALGORITHM]);
legend('truth', 'estimate', 'clip reigion');