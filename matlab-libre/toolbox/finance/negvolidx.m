function indice = negvolidx(cloture, volume, depart)
%NEGVOLIDX Indice des jours de volume en baisse.
%   I = NEGVOLIDX(CLOTURE,VOLUME,DEPART) ne suit le cours que les séances
%   où le volume a baissé par rapport à la veille ; les autres, l'indice
%   ne bouge pas. DEPART vaut 100 par défaut.
%
%   L'idée est que les jours calmes révèlent l'argent avisé, qui
%   n'agit pas dans la foule.
%
%   Exemple :
%      negvolidx(clotures, volumes)
%
%   Voir aussi POSVOLIDX, ONBALVOL, PVTREND.
    if nargin < 3 || isempty(depart), depart = 100; end
    if nargin < 2
        series = matlibre_colonnes_marche(cloture, {}, {'cloture', 'volume'});
    else
        series = matlibre_colonnes_marche(cloture, {volume}, {'cloture', 'volume'});
    end
    indice = matlibre_indice_volume(series{1}, series{2}, depart, -1);
end
