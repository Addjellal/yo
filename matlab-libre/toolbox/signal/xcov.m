function [c, decalages] = xcov(x, y, maxDecalage, echelle)
%XCOV Covariance croisée : la corrélation des signaux centrés.
%   [C,LAGS] = XCOV(X,Y) retranche la moyenne avant de corréler.
%   XCOV(X) donne l'autocovariance.
%
%   Exemple :
%      c = xcov([1 2 3 4], 'coeff');   % c(4) == 1
    if nargin < 2 || (ischar(y) || isstring(y))
        if nargin >= 2, echelle = y; end
        y = x;
    end
    if nargin < 3 || isempty(maxDecalage) || ischar(maxDecalage)
        if nargin >= 3 && ischar(maxDecalage), echelle = maxDecalage; end
        maxDecalage = [];
    end
    x = x(:) - mean(x(:));
    y = y(:) - mean(y(:));
    if isempty(maxDecalage)
        [c, decalages] = xcorr(x, y);
    else
        [c, decalages] = xcorr(x, y, maxDecalage);
    end
    if nargin >= 2 && exist('echelle', 'var') && ~isempty(echelle) && ischar(echelle)
        switch lower(echelle)
            case 'coeff'
                normalisation = sqrt(sum(x.^2) * sum(y.^2));
                if normalisation > 0, c = c / normalisation; end
            case 'biased'
                c = c / numel(x);
            case 'unbiased'
                c = c(:) ./ (numel(x) - abs(decalages(:)));
        end
    end
end
