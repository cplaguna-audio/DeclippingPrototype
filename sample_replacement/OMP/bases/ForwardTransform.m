function y = ForwardTransform(x, bases)
  N = size(x, 1);
  if(size(bases, 1) ~= N)
    error('Bases and x are not same size.');
  end
  
  y = bases.' * x;

end

