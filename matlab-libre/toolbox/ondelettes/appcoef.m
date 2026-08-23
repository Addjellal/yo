function a = appcoef(c, l, ondelette, niveau)
%APPCOEF Coefficients d'approximation d'une décomposition WAVEDEC.
%   A = APPCOEF(C,L,ONDELETTE) rend l'approximation du dernier niveau.
%   A = APPCOEF(C,L,ONDELETTE,N) reconstruit celle du niveau N.
    if nargin < 4 || isempty(niveau), niveau = numel(l) - 2; end
    maximum = numel(l) - 2;
    a = c(1:l(1));
    a = a(:)';
    for k = maximum:-1:niveau + 1
        d = detcoef(c, l, k);
        a = idwt(a, d, ondelette);
        a = a(1:l(maximum - k + 2));
    end
end
