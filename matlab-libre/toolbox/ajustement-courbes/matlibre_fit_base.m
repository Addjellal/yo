function A = matlibre_fit_base(modele, x, imposees)
%MATLIBRE_FIT_BASE Matrice de conception d'un modèle linéaire.
%   A = MATLIBRE_FIT_BASE(MODELE,X,IMPOSEES) rend la matrice dont la
%   colonne k est le modèle évalué avec le seul coefficient k à un.
%
%   Exemple :
%      matlibre_fit_base(fittype('poly1'), [1; 2], {})      % [1 1; 2 1]
%
%   Voir aussi FIT, MATLIBRE_AJUSTER_LINEAIRE.
    if ~isempty(modele.Base)
        A = modele.Base(x);
        return
    end
    nombre = numel(modele.Coefficients);
    A = zeros(numel(x), nombre);
    for k = 1:nombre
        c = zeros(1, nombre);
        c(k) = 1;
        A(:, k) = matlibre_evaluer_modele(modele, [{c}, imposees, {x}]);
    end
end
