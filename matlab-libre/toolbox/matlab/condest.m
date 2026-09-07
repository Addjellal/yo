function [c, v] = condest(A, t)
%CONDEST Estime le conditionnement en norme 1.
%   C = CONDEST(A) rend NORM(A,1) multiplié par une estimation de
%   NORM(INV(A),1), obtenue par l'algorithme de Hager sans former
%   l'inverse : chaque produit par l'inverse est une résolution.
%   [C,V] = CONDEST(A) rend en outre un vecteur qui témoigne du mauvais
%   conditionnement quand il y en a un.
%
%   Le conditionnement mesure de combien une erreur relative sur les
%   données peut être amplifiée dans le résultat : résoudre A*x = b avec
%   un conditionnement de 1e8 fait perdre huit chiffres significatifs sur
%   les seize que porte un double.
%
%   L'estimation est une borne inférieure. C'est ce qu'on veut : elle ne
%   promet jamais un conditionnement meilleur qu'il n'est.
%
%   Exemple :
%      condest(eye(3))                    % 1 : le mieux possible
%      condest(hilb(6)) > 1e6             % la matrice de Hilbert est infame
%      c = condest(magic(4));             % singuliere : c est enorme
%
%   Voir aussi COND, NORMEST1, NORM, RCOND.
    if nargin < 2, t = 2; end   %#ok<NASGU>  le nombre de colonnes d'essai
    A = double(A);
    if size(A, 1) ~= size(A, 2)
        error('MATLAB:condest:NotSquare', 'La matrice doit être carrée.');
    end
    n = size(A, 1);
    if n == 0
        c = 0; v = [];
        return
    end
    normeA = norm(A, 1);
    if normeA == 0
        c = Inf; v = zeros(n, 1);
        return
    end
    % L'estimation de la norme de l'inverse, sans former l'inverse : la
    % boucle de Hager, où chaque produit devient une résolution.
    v = ones(n, 1) / n;
    estimation = 0;
    vus = false(n, 1);
    avertissement = warning('off', 'MATLAB:singularMatrix');
    for k = 1:min(5 * n + 5, 200)   %#ok<NASGU>
        w = A \ v;
        estimation = norm(w, 1);
        if ~all(isfinite(w))
            estimation = Inf;
            break
        end
        signes = sign(w);
        signes(signes == 0) = 1;
        z = A' \ signes;
        [maximum, j] = max(abs(z));
        if maximum <= z' * v || vus(j)
            break
        end
        vus(j) = true;
        v = zeros(n, 1);
        v(j) = 1;
    end
    warning(avertissement);
    c = normeA * estimation;
end
