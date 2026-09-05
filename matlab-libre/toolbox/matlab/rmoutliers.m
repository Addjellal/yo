function [b, marque] = rmoutliers(a, varargin)
%RMOUTLIERS Retire les valeurs aberrantes.
%   B = RMOUTLIERS(A) retire d'un vecteur les valeurs aberrantes, et
%   d'une matrice les lignes qui en contiennent une.
%   B = RMOUTLIERS(A,METHODE,...) choisit le critère, comme ISOUTLIER.
%
%   [B,MARQUE] = RMOUTLIERS(A) rend aussi ce qui a été retiré.
%
%   Retirer change la longueur : sur une série mesurée, cela décale tout
%   ce qui suit et rompt l'alignement avec le temps. FILLOUTLIERS, qui
%   remplace, est souvent préférable.
%
%   Exemple :
%      rmoutliers([1 2 3 100 5])       % [1 2 3 5]
%
%   Voir aussi ISOUTLIER, FILLOUTLIERS, RMMISSING.
    aberrantes = isoutlier(a, varargin{:});
    if isvector(a)
        marque = aberrantes(:).';
        b = a(~aberrantes);
        if size(a, 1) == 1
            b = b(:).';
        else
            b = b(:);
        end
        return
    end
    marque = any(aberrantes, 2);
    b = a(~marque, :);
end
