fs = 44100;
PREDICT_AMOUNT = 1000;
ORDER = 95;

t = (0:1/fs:(2 - (1/fs))).';
x1 = 0.5 * cos(2 * pi * 441 * t(1:200));
% x1 = [1 2 3 4 5 6].';

a = MyARCoeffs(x1(1:100), ORDER);
b = MyARCoeffs(flipud(x1(1:100)), ORDER);

% a = lpc(x1, ORDER); % MyARCoeffs(x1, ORDER);
% b = lpc(flipud(x1), ORDER); % MyARCoeffs(flipud(x1), ORDER);
% a = a(2:end).';
% b = b(2:end).';

% Do forward prediction.
x_forward = LinearPredict(x1, a, PREDICT_AMOUNT);

% Do backward prediction.
x_backward = LinearPredict(flipud(x1), b, PREDICT_AMOUNT);
x_backward = flipud(x_backward);

% flags = zeros(length(left_samples) + burst_length + length(right_samples), 1);
% flags(length(left_samples) + 1:length(left_samples) + burst_length) = 1;
figure();
subplot(3,1,1);
plot(x1);
subplot(3,1,2);
plot([x1(1:100); x_forward]);
% hold on; 
% plot(flags);
title('Forward prediction');

subplot(3,1,3);
plot([x_backward; x1(1:100)]);
% hold on;
% plot(flags);
title('Backward prediction');