function y = hilbert(x, n)
%HILBERT Signal analytique par transformée de Hilbert.
%   Y = HILBERT(X) rend un signal complexe dont la partie réelle est X et
%   la partie imaginaire sa transformée de Hilbert.
    x = x(:);
    if nargin < 2 || isempty(n)
        n = numel(x);
    end
    X = fft(x, n);
    h = zeros(n, 1);
    if mod(n, 2) == 0
        h(1) = 1;
        h(n/2 + 1) = 1;
        h(2:n/2) = 2;
    else
        h(1) = 1;
        h(2:(n+1)/2) = 2;
    end
    y = ifft(X .* h);
end
