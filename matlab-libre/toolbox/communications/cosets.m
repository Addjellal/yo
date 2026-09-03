function classes = cosets(m, prim)
%COSETS Classes cyclotomiques de GF(2^M), rangées par classe.
%   C = COSETS(M) rend une cellule : chaque case porte les exposants
%   d'une classe cyclotomique de GF(2^M), la première étant celle de
%   l'élément un.
%
%   MATLAB rend les éléments eux-mêmes, sous forme d'un tableau de corps
%   de Galois ; MatLibre rend leurs exposants, la table du corps se
%   lisant par GFTABLE.
%
%   Exemple :
%      c = cosets(3);
%      numel(c)                       % 3 classes
%      c{2}                           % [1 2 4]
%
%   Voir aussi GFCOSETS, GFTABLE, GFPRIMDF, GFROOTS.
    if nargin < 2, prim = []; end   %#ok<INUSA>
    matrice = gfcosets(m, 2);
    classes = cell(size(matrice, 1), 1);
    for k = 1:size(matrice, 1)
        ligne = matrice(k, :);
        classes{k} = ligne(~isnan(ligne));
    end
end
