function y = wconv1(x, f, forme)
%WCONV1 Convolution monodimensionnelle, orientation conservée.
    if nargin < 3 || isempty(forme), forme = 'full'; end
    ligne = isrow(x);
    y = conv(double(x(:)).', double(f(:)).', forme);
    if ~ligne, y = y'; end
end
