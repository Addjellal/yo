function [meilleur, valeur] = multistart(fonction, bas, haut, nDeparts)
%MULTISTART Minimisation locale répétée depuis des points tirés au hasard.
%   [X,VALEUR] = MULTISTART(F,BAS,HAUT,NDEPARTS) lance une minimisation
%   locale depuis NDEPARTS points tirés dans la boîte, et garde le
%   meilleur résultat.
%
%   C'est la méthode globale la plus simple, et souvent la plus efficace :
%   elle ne suppose rien de la fonction, et hérite de la vitesse du
%   solveur local. Sur une fonction à quelques bassins d'attraction, elle
%   les trouve tous pourvu qu'on tire assez de points.
%
%   Elle ne garantit rien : la probabilité de manquer un bassin étroit
%   décroît avec le nombre de départs, sans jamais s'annuler. Aucune
%   méthode globale ne fait mieux sans hypothèse supplémentaire.
%
%   Exemple :
%      f = @(x) x(1)^2 + x(2)^2 + 10 * sin(x(1)) * sin(x(2));
%      [x, v] = multistart(f, [-5 -5], [5 5], 50);
%
%   Voir aussi PARTICLESWARM, SIMULANNEALBND, GA, GLOBALSEARCH.
    if nargin < 4
        nDeparts = 20;
    end
    bas = bas(:).';
    haut = haut(:).';
    valeur = inf;
    meilleur = bas;
    for k = 1:nDeparts
        depart = bas + rand(size(bas)) .* (haut - bas);
        x = fminsearch(fonction, depart);
        v = fonction(x);
        if v < valeur
            valeur = v;
            meilleur = x;
        end
    end
end
