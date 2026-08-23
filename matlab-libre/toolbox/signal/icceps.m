function x = icceps(xhat, nd)
%ICCEPS Cepstre complexe inverse.
%   X = ICCEPS(XHAT,ND) reconstitue le signal à partir de son cepstre
%   complexe et du retard ND rendu par CCEPS.
    if nargin < 2, nd = 0; end
    xhat = double(xhat(:));
    n = numel(xhat);
    spectre = fft(xhat);
    module = exp(real(spectre));
    phase = imag(spectre) + pi * nd * (0:n-1)' / (n / 2) / 2;
    x = real(ifft(module .* exp(1i * phase)));
end
