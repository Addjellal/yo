function modele = ar(donnees, ordre, varargin)
%AR Estimation d'un modèle autorégressif.
%   M = AR(Z,N) ajuste y(t) + a1 y(t-1) + ... + aN y(t-N) = e(t) à une
%   série sans entrée. C'est le modèle des séries temporelles pures :
%   chaque valeur s'explique par les précédentes et par un choc.
%
%   Exemple :
%      rng(1);
%      y = filter(1, [1 -0.7 0.2], randn(500, 1));
%      m = ar(iddata(y), 2);
%      m.A      % environ 1 -0.7 0.2
%
%   Voir aussi ARX, ARMAX, FORECAST, POLYEST.
    ordres = [round(ordre), 0, 0, 0, 0, 0];
    modele = matlibre_id_moindres_carres(donnees, ordres, 'ar');
end
