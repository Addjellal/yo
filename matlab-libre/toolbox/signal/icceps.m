function x = icceps(xhat, nd)
%ICCEPS Cepstre complexe inverse.
%   X = ICCEPS(XHAT,ND) reconstitue le signal à partir de son cepstre
%   complexe et du retard ND rendu par CCEPS.
%
%   Exemple :
%      x = [1 0.5 0.25 0.125]';
%      max(abs(icceps(cceps(x), 0) - x)) < 1e-6
%
%   Voir aussi CCEPS, RCEPS.
    if nargin < 2, nd = 0; end
    xhat = double(xhat(:));
    n = numel(xhat);
    spectre = fft(xhat);
    module = exp(real(spectre));
    phase = imag(spectre) + pi * nd * (0:n-1)' / (n / 2) / 2;
    x = real(ifft(module .* exp(1i * phase)));
end
