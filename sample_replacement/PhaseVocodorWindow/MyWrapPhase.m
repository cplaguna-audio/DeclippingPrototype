function y = MyWrapPhase(x)
  y = x + pi;
  y = mod(y, 2 * pi);
  y = y - pi;
end