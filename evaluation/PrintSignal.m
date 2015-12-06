[x, fs] = audioread('test.wav');

for idx = 1:length(x)
  x(idx) = round(x(idx) * 10000) / 10000;
end
  
x_str = num2str(x, '%10.5f\n');
x_str(:, end) = [];

dlmwrite('test.txt', x_str, 'delimiter', '');
