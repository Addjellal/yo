function y = wconv2(x, f, forme)
%WCONV2 Convolution bidimensionnelle.
    if nargin < 3 || isempty(forme), forme = 'full'; end
    y = conv2(double(x), double(f), forme);
end
