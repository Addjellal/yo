function y = upfirdn(x, h, p, q)
%UPFIRDN Sur-échantillonne d'un facteur P, filtre par H, décime par Q.
    if nargin < 3, p = 1; end
    if nargin < 4, q = 1; end
    x = x(:).';
    sur = zeros(1, numel(x) * p);
    sur(1:p:end) = x;
    filtre = conv(sur, h(:).');
    y = filtre(1:q:end);
end
