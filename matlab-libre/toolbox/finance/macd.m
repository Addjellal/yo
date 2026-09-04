function [ligne, signal] = macd(cloture, courte, longue, lissage)
%MACD Convergence et divergence des moyennes mobiles.
%   [L,S] = MACD(CLOTURE) rend l'écart entre la moyenne exponentielle à
%   douze jours et celle à vingt-six, ainsi que la moyenne exponentielle
%   à neuf jours de cet écart. Les trois périodes se règlent.
%
%   L'écart de deux moyennes est positif quand la courte est au-dessus de
%   la longue, c'est-à-dire quand la tendance récente est plus forte que
%   l'ancienne. Le croisement de la ligne et de son signal est ce que
%   guettent ses utilisateurs.
%
%   Exemple :
%      [l, s] = macd(clotures);
%
%   Voir aussi MOVAVG, RSINDEX, TSMOM, CHAIKOSC.
    if nargin < 2 || isempty(courte),  courte = 12;  end
    if nargin < 3 || isempty(longue),  longue = 26;  end
    if nargin < 4 || isempty(lissage), lissage = 9;  end
    series = matlibre_colonnes_marche(cloture, {}, {'cloture'});
    C = series{1};
    ligne = matlibre_moyenne_exp(C, courte) - matlibre_moyenne_exp(C, longue);
    signal = matlibre_moyenne_exp(ligne, lissage);
end
