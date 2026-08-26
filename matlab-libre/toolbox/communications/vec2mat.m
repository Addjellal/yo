function [matrice, reste] = vec2mat(vecteur, colonnes, remplissage)
%VEC2MAT Découpage d'un vecteur en matrice, ligne par ligne.
%   M = VEC2MAT(V,NCOL) range V dans une matrice de NCOL colonnes,
%   remplie ligne par ligne. La dernière ligne est complétée par des
%   zéros si le compte ne tombe pas juste.
%   M = VEC2MAT(V,NCOL,REMPLISSAGE) choisit de quoi la compléter.
%   [M,RESTE] = VEC2MAT(...) rend aussi le nombre d'éléments ajoutés.
%
%   Exemple :
%      vec2mat(1:5, 3)   % [1 2 3; 4 5 0]
%
%   Voir aussi RESHAPE, MATINTRLV.
    if nargin < 3 || isempty(remplissage), remplissage = 0; end
    v = double(vecteur(:))';
    colonnes = round(double(colonnes));
    lignes = ceil(numel(v) / colonnes);
    reste = lignes * colonnes - numel(v);
    if reste > 0
        v = [v, repmat(remplissage, 1, reste)];
    end
    matrice = reshape(v, colonnes, lignes)';
end
