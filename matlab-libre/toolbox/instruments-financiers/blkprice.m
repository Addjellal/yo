function [achat, vente] = blkprice(terme, exercice, taux, duree, volatilite)
%BLKPRICE Prix d'options sur contrat à terme, modèle de Black.
%   [C,P] = BLKPRICE(TERME,EXERCICE,TAUX,DUREE,VOLATILITE) rend les prix
%   de l'achat et de la vente sur un contrat à terme de cours TERME.
%
%   La formule est celle de Black et Scholes où le cours comptant est
%   remplacé par le cours à terme actualisé : un contrat à terme ne coûte
%   rien à l'entrée, si bien que le taux n'intervient plus que pour
%   ramener le gain final à aujourd'hui.
%
%   Exemple :
%      blkprice(100, 100, 0.05, 1, 0.2)
%
%   Voir aussi BLKIMPV, BLSPRICE, CAPBYBLK, FLOORBYBLK, SWAPTIONBYBLK.
    terme = double(terme);
    exercice = double(exercice);
    d1 = (log(terme ./ exercice) + volatilite .^ 2 / 2 .* duree) ./ ...
         (volatilite .* sqrt(duree));
    d2 = d1 - volatilite .* sqrt(duree);
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    escompte = exp(-taux .* duree);
    achat = escompte .* (terme .* N(d1) - exercice .* N(d2));
    vente = escompte .* (exercice .* N(-d2) - terme .* N(-d1));
end
