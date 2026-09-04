function indice = posvolidx(cloture, volume, depart)
%POSVOLIDX Indice des jours de volume en hausse.
%   I = POSVOLIDX(CLOTURE,VOLUME,DEPART) ne suit le cours que les séances
%   où le volume a monté par rapport à la veille. DEPART vaut 100 par
%   défaut.
%
%   Exemple :
%      posvolidx(clotures, volumes)
%
%   Voir aussi NEGVOLIDX, ONBALVOL, PVTREND.
    if nargin < 3 || isempty(depart), depart = 100; end
    if nargin < 2
        series = matlibre_colonnes_marche(cloture, {}, {'cloture', 'volume'});
    else
        series = matlibre_colonnes_marche(cloture, {volume}, {'cloture', 'volume'});
    end
    indice = matlibre_indice_volume(series{1}, series{2}, depart, 1);
end
