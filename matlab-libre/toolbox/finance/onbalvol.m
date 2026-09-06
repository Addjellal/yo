function volumeCumule = onbalvol(cloture, volume)
%ONBALVOL Volume à la hausse et à la baisse, cumulé.
%   V = ONBALVOL(CLOTURE,VOLUME) ajoute le volume de la séance quand la
%   clôture monte, le retranche quand elle baisse, et l'ignore quand elle
%   ne bouge pas.
%
%   L'indicateur suppose que le volume précède le cours : une divergence
%   entre les deux annoncerait un retournement.
%
%   Exemple :
%      rng(1);
%      clotures = 100 + cumsum(randn(40, 1));
%      onbalvol(clotures, 1000 * ones(40, 1))
%
%   Voir aussi ADLINE, NEGVOLIDX, POSVOLIDX, PVTREND.
    if nargin < 2
        series = matlibre_colonnes_marche(cloture, {}, {'cloture', 'volume'});
    else
        series = matlibre_colonnes_marche(cloture, {volume}, {'cloture', 'volume'});
    end
    C = series{1}; V = series{2};
    signes = [0; sign(diff(C))];
    volumeCumule = cumsum(signes .* V);
end
