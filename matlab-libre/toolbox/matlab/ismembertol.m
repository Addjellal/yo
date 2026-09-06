function tf = ismembertol(a, s, tol)
%ISMEMBERTOL Appartenance à un ensemble, à une tolérance près.
%   TF = ISMEMBERTOL(A,S) rend, pour chaque élément de A, vrai s'il existe
%   dans S un élément dont il s'écarte de moins de 1e-6 fois l'échelle des
%   données. TF = ISMEMBERTOL(A,S,TOL) impose la tolérance.
%
%   L'échelle est le plus grand module rencontré dans A et dans S, borné
%   par en dessous à un : la tolérance est donc relative, et une même
%   valeur de TOL a le même sens sur des données en mètres et sur les
%   mêmes en kilomètres.
%
%   C'est ISMEMBER rendu utilisable sur des flottants. 0.1+0.2 n'est pas
%   0.3 en binaire, et l'égalité exacte répond non là où toute autre
%   considération dit oui. La contrepartie est que la relation
%   « proche à TOL près » n'est pas transitive : elle ne partage pas les
%   données en classes, et le résultat peut dépendre de l'ordre de S.
%
%   Exemple :
%      ismembertol(0.1 + 0.2, [0.3 0.5])
%
%   Voir aussi ISMEMBER, UNIQUETOL, EPS.
    if nargin < 3
        tol = 1e-6;
    end
    echelle = max([abs(a(:)); abs(s(:)); 1]);
    tf = false(size(a));
    for k = 1:numel(a)
        tf(k) = any(abs(s(:) - a(k)) <= tol * echelle);
    end
end
