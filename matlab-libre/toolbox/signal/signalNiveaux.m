function [bas, haut, seuils] = signalNiveaux(x, pourcentages, niveaux)
%SIGNALNIVEAUX Niveaux d'état et seuils de référence d'un signal.
%   Traduit des pourcentages de l'écart entre les deux états en valeurs
%   absolues, comme le font toutes les mesures de transition de MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      t = (0:0.001:0.1)';
%      [bas, haut, seuils] = signalNiveaux(double(t >= 0.05), [10 90 50]);
%      seuils(1) < seuils(3) && seuils(3) < seuils(2)     % 1
%
%   Voir aussi STATELEVELS, SIGNALTRAVERSES, SIGNALTRANSITIONS.
    if nargin < 3 || isempty(niveaux)
        niveaux = statelevels(x);
    end
    bas = niveaux(1);
    haut = niveaux(2);
    seuils = bas + (haut - bas) * pourcentages(:)' / 100;
end
