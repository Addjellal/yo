function c = cconv(a, b, n)
%CCONV Convolution circulaire.
%   C = CCONV(A,B,N) rend la convolution circulaire de longueur N. Sans N,
%   la longueur vaut numel(A)+numel(B)-1, et le résultat coïncide alors
%   avec la convolution ordinaire.
%
%   Exemple :
%      cconv([1 2], [1 1], 2)   % [3 3]
    ligne = isrow(a) || isrow(b);
    a = a(:);
    b = b(:);
    if nargin < 3 || isempty(n), n = numel(a) + numel(b) - 1; end
    c = real(ifft(fft(a, n) .* fft(b, n)));
    if ligne, c = c.'; end
end
