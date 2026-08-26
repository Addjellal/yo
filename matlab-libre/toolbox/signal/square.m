function y = square(t, rapport)
%SQUARE Signal carré de période 2*pi.
%   Y = SQUARE(T) vaut +1 sur la première moitié de la période, -1 sur la
%   seconde. Y = SQUARE(T,RAPPORT) fixe le rapport cyclique en pour cent.
    if nargin < 2
        rapport = 50;
    end
    phase = mod(t, 2 * pi) / (2 * pi) * 100;
    y = ones(size(t));
    y(phase >= rapport) = -1;
end
