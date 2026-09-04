function volatilite = chaikvolat(haut, bas, periode, decalage)
%CHAIKVOLAT Volatilité de Chaikin.
%   V = CHAIKVOLAT(HAUT,BAS,N,M) mesure la variation, sur M séances, de
%   la moyenne exponentielle à N jours de l'amplitude quotidienne. N vaut
%   10 par défaut, M aussi.
%
%   Une amplitude qui s'élargit vite annonce souvent un retournement ;
%   une amplitude qui se resserre, une phase calme.
%
%   Exemple :
%      chaikvolat(hauts, bas, 10, 10)
%
%   Voir aussi CHAIKOSC, ADLINE, PRCROC.
    if nargin < 3 || isempty(periode),  periode = 10;  end
    if nargin < 4 || isempty(decalage), decalage = 10; end
    if nargin < 2
        series = matlibre_colonnes_marche(haut, {}, {'haut', 'bas'});
    else
        series = matlibre_colonnes_marche(haut, {bas}, {'haut', 'bas'});
    end
    amplitude = series{1} - series{2};
    lissee = matlibre_moyenne_exp(amplitude, periode);
    volatilite = zeros(size(lissee));
    for k = (decalage + 1):numel(lissee)
        precedent = lissee(k - decalage);
        if precedent ~= 0
            volatilite(k) = 100 * (lissee(k) - precedent) / precedent;
        end
    end
end
