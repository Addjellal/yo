function y = matlibre_glissant(x, k, options, fonction)
%MATLIBRE_GLISSANT Applique une fonction sur une fenêtre glissante.
%   Y = MATLIBRE_GLISSANT(X,K,OPTIONS,F) parcourt X avec une fenêtre de K
%   points et applique F à chacune. K peut valoir [AVANT APRES].
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Les fonctions MOV... natives sont écrites en C++ ; celle-ci sert aux
%   quelques-unes qui demandent un calcul non incrémental — l'écart absolu
%   médian en est une, puisqu'une médiane ne se met pas à jour d'un point
%   à l'autre.
%
%   Exemple :
%      matlibre_glissant(1:5, 3, {}, @max)     % 2 3 4 5 5
%
%   Voir aussi MOVMAD, MOVMEAN, MOVMEDIAN.
    ligne = isrow(x);
    v = double(x(:));
    n = numel(v);
    k = double(k);
    if isscalar(k)
        avant = floor((k - 1) / 2);
        apres = k - 1 - avant;
    else
        avant = k(1);
        apres = k(2);
    end
    entiers = false;
    for j = 1:2:numel(options) - 1
        if strcmpi(char(options{j}), 'endpoints')
            entiers = strcmpi(char(options{j + 1}), 'discard');
        end
    end
    y = zeros(n, 1);
    for i = 1:n
        a = max(1, i - avant);
        b = min(n, i + apres);
        y(i) = fonction(v(a:b));
    end
    if entiers
        garde = (1:n)' - avant >= 1 & (1:n)' + apres <= n;
        y = y(garde);
    end
    if ligne
        y = y.';
    end
end
