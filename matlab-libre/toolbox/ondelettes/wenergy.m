function [energieApproximation, energiesDetails] = wenergy(C, L)
%WENERGY Répartition de l'énergie entre approximation et détails.
%   [EA,ED] = WENERGY(C,L) rend la part d'énergie, en pour cent, portée
%   par l'approximation et par chacun des détails d'une décomposition
%   rendue par WAVEDEC. Les détails sont donnés du plus profond au plus
%   fin, dans l'ordre où ils figurent dans C.
%
%   La somme des pour cent vaut cent parce que la transformation est
%   orthogonale : elle conserve la norme, et l'énergie du signal se
%   répartit entre les sous-bandes sans se créer ni se perdre. C'est le
%   théorème de Parseval appliqué à un banc de filtres.
%
%   Cette répartition est un résumé utile : un signal lisse concentre
%   presque tout dans l'approximation, un signal bruité verse l'essentiel
%   dans les détails les plus fins. Le seuil de débruitage se choisit à
%   partir de là — retirer un niveau de détail qui ne porte qu'un pour
%   cent de l'énergie ne change presque rien au signal.
%
%   Exemple :
%      x = sin((1:64) / 8);
%      [c, l] = wavedec(x, 3, 'db2');
%      [ea, ed] = wenergy(c, l);
%
%   Voir aussi WAVEDEC, WAVEREC, WDENOISE.
    total = sum(C .^ 2);
    a = C(1:L(1));
    energieApproximation = 100 * sum(a .^ 2) / total;
    energiesDetails = [];
    debut = L(1) + 1;
    for k = 2:numel(L)-1
        d = C(debut:debut + L(k) - 1);
        energiesDetails(end+1) = 100 * sum(d .^ 2) / total;
        debut = debut + L(k);
    end
end
