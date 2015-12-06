function x = BackwardTransform(y, bases)
  N = size(y, 1);
  if(size(bases, 2) ~= N)
    error('Number of bases and y are not same size.');
  end
  
  x = bases * y;

end