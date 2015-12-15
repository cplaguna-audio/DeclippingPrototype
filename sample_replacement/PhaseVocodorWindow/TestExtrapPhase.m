function TestExtrapPhase()
NUM_EXTRAP = 26;
FS = 44100;
BLOCK_SIZE = 1024;
HOP_SIZE = BLOCK_SIZE / 4;
window = hann(BLOCK_SIZE);

freq = 2 * FS / 2048;
t = 0:1 / FS:1 - (1 / FS);
x = sin(t * 2 * pi * freq).';
x = x(5:end);

x_blocked = BlockSignal(x, BLOCK_SIZE, HOP_SIZE).';
num_blocks = size(x_blocked, 2);

x_blocked = x_blocked .* repmat(window, 1, num_blocks);
x_freqs = fft(fftshift(x_blocked, 1));

window_blocked = repmat(window, 1, NUM_EXTRAP);

extrap_x_freqs = ExtrapolatePhase(x_freqs(:, 1:2), HOP_SIZE, NUM_EXTRAP, FS);
extrap_x_times = ifftshift(real(ifft(extrap_x_freqs)), 1);
extrap_x_times = extrap_x_times .* window_blocked;

% figure()
% subplot(7,1,1);
% plot(extrap_x_times(:, 8));
% title('8');
% subplot(7,1,2);
% plot(extrap_x_times(:, 9));
% title('9');
% subplot(7,1,3);
% plot(extrap_x_times(:, 10));
% title('10');
% subplot(7,1,4);
% plot(extrap_x_times(:, 11));
% title('11');
% subplot(7,1,5);
% plot(extrap_x_times(:, 12));
% title('12');
% subplot(7,1,6);
% plot(extrap_x_times(:, 13));
% title('13');
% subplot(7,1,7);
% plot(extrap_x_times(:, 14));
% title('14');


y = ReconstructSignal(extrap_x_times.', BLOCK_SIZE, HOP_SIZE);

window_comp_freq = fft(fftshift(repmat(window, 1, NUM_EXTRAP)));
window_comp_time = ifftshift(real(ifft(window_comp_freq))) .* repmat(window, 1, NUM_EXTRAP);

window_comp = ReconstructSignal(window_comp_time.', BLOCK_SIZE, HOP_SIZE);
bad_indices = find(window_comp < 0.01);
y = y ./ window_comp;
y(bad_indices) = 0;

truth = ReconstructSignal(x_blocked(:, 3:3 + NUM_EXTRAP - 1).', BLOCK_SIZE, HOP_SIZE);
truth = truth ./ window_comp;
truth(bad_indices) = 0;
figure();
plot(y);
hold on;
plot(truth);


% figure();
% subplot(2,2,1);
% plot(next_x_times(:, end - 1));
% title('est 1');
% subplot(2,2,2);
% plot(next_x_times(:, end));
% title('est 2');
% subplot(2,2,3);
% plot(truth_x1);
% title('truth 1');
% subplot(2,2,4);
% plot(truth_x2);
% title('truth 2');
% 
% figure();
% subplot(2,2,1);
% plot(angle(next_x_freqs(:, end - 1)));
% title('est1');
% subplot(2,2,2);
% plot(angle(next_x_freqs(:, end)));
% title('est2');
% subplot(2,2,3);
% plot(angle(fftshift(fft(truth_x1))));
% title('truth1');
% subplot(2,2,4);
% plot(angle(fftshift(fft(truth_x2))));
% title('truth2');

end

