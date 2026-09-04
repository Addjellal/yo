function A = matlibre_colonnes_base(fonction, nombre, x)
%MATLIBRE_COLONNES_BASE Colonnes de la matrice de conception.
%   A = MATLIBRE_COLONNES_BASE(FONCTION,NOMBRE,X) évalue le modèle avec un
%   seul coefficient à un et les autres à zéro, une fois par coefficient.
%
%   Exemple :
%      % appelée par MATLIBRE_BASE_EXPRESSION
%
%   Voir aussi MATLIBRE_BASE_EXPRESSION.
    x = x(:);
    A = zeros(numel(x), nombre);
    for k = 1:nombre
        c = zeros(1, nombre);
        c(k) = 1;
        A(:, k) = fonction(c, {}, x);
    end
end
