% BlockSignal(x, windowSize, hopSize)
%
% Blocks the signal into a matrix.
% x (n x 1): 
function x_blocked = BlockSignal(x, windowSize, hopSize)

  x_length = size(x, 1);
  num_blocks = ceil((x_length - windowSize) / hopSize) + 1;
  padded_length = ((num_blocks - 1) * hopSize) + windowSize;
    
  % Zero pad so we have equal-lenghts for each block.
  padded_x = zeros(padded_length, 1);
  padded_x(1:x_length) = x;
  
  x_blocked = zeros(num_blocks, windowSize);
  
  start_idx = 1;
  stop_idx = start_idx + windowSize - 1;
  for block_idx = 1:num_blocks
    x_blocked(block_idx, :) = padded_x(start_idx:stop_idx, 1);
    
    start_idx = start_idx + hopSize;
    stop_idx = start_idx + windowSize - 1;
  end

end

