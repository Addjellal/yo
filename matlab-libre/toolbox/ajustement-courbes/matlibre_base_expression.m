function base = matlibre_base_expression(expression, coefficients, probleme, independante)
%MATLIBRE_BASE_EXPRESSION Matrice de conception d'un modèle linéaire.
%   B = MATLIBRE_BASE_EXPRESSION(EXPRESSION,COEFFICIENTS,PROBLEME,
%   INDEPENDANTE) rend la fonction qui, pour des abscisses données,
%   construit la matrice dont la colonne k est le modèle évalué avec le
%   seul coefficient k à un. Le modèle étant linéaire, cette matrice le
%   décrit entièrement.
%
%   Exemple :
%      b = matlibre_base_expression('a*x + b', {'a', 'b'}, {}, 'x');
%      b([1; 2])      % [1 1; 2 1]
%
%   Voir aussi MATLIBRE_EXPRESSION_LINEAIRE, FIT.
    fonction = matlibre_fonction_expression(expression, coefficients, probleme, independante);
    base = @(x) matlibre_colonnes_base(fonction, numel(coefficients), x);
end
