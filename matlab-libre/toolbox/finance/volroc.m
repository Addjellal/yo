function taux = volroc(volume, periode)
%VOLROC Taux de variation du volume.
%   T = VOLROC(VOLUME,N) rend, en pourcentage, la variation du volume sur
%   N séances. N vaut 12 par défaut.
%
%   Exemple :
%      rng(1);
%      volroc(1000 + 100 * randn(40, 1), 12)
%
%   Voir aussi PRCROC, CHAIKVOLAT, ONBALVOL.
    if nargin < 2 || isempty(periode), periode = 12; end
    taux = matlibre_taux_variation(volume, periode);
end
