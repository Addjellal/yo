function oscillateur = chaikosc(haut, bas, cloture, volume)
%CHAIKOSC Oscillateur de Chaikin.
%   O = CHAIKOSC(HAUT,BAS,CLOTURE,VOLUME) rend l'écart entre la moyenne
%   exponentielle à trois jours et celle à dix jours de la ligne
%   d'accumulation et de distribution.
%
%   Une ligne d'accumulation qui monte dit que les acheteurs
%   l'emportent ; l'écart de ses deux moyennes dit s'ils l'emportent de
%   plus en plus.
%
%   Exemple :
%      rng(1);
%      clotures = 100 + cumsum(randn(60, 1));
%      chaikosc(clotures + 1, clotures - 1, clotures, 1000 * ones(60, 1))
%
%   Voir aussi ADLINE, ADOSC, CHAIKVOLAT, MACD.
    if nargin < 2
        ligne = adline(haut);
    else
        ligne = adline(haut, bas, cloture, volume);
    end
    oscillateur = matlibre_moyenne_exp(ligne, 3) - matlibre_moyenne_exp(ligne, 10);
end
