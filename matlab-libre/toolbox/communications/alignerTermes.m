function [a, b] = alignerTermes(a, b)
%ALIGNERTERMES Met deux tableaux à la même taille, terme à terme.
%   À la différence d'ALIGNERPOLYNOMES, un scalaire se répand ici sur
%   tout le tableau : c'est ce qu'attendent les opérations terme à terme,
%   GFMUL et GFDIV, où l'on multiplie souvent tout un vecteur par une
%   même valeur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    a = double(a);
    b = double(b);
    if isequal(size(a), size(b))
        return
    end
    if isscalar(a)
        a = repmat(a, size(b));
        return
    end
    if isscalar(b)
        b = repmat(b, size(a));
        return
    end
    error('comm:gf:Tailles', ...
          'Les deux tableaux doivent avoir la même taille, ou l''un être scalaire.');
end
