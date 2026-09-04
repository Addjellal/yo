function taux = prcroc(cloture, periode)
%PRCROC Taux de variation du cours.
%   T = PRCROC(CLOTURE,N) rend, en pourcentage, la variation du cours sur
%   N séances. N vaut 12 par défaut.
%
%   Exemple :
%      prcroc([100 102 105 103], 1)   % [0 2 2.94 -1.90]
%
%   Voir aussi VOLROC, TSMOM, TSACCEL, MACD.
    if nargin < 2 || isempty(periode), periode = 12; end
    taux = matlibre_taux_variation(cloture, periode);
end
