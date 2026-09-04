function [x, y, poids] = matlibre_fit_selection(x, y, options)
%MATLIBRE_FIT_SELECTION Points retenus pour l'ajustement, et leurs poids.
%   [X,Y,P] = MATLIBRE_FIT_SELECTION(X,Y,OPTIONS) écarte les points exclus
%   et ceux qui ne sont pas finis, et rend les poids — un par point,
%   valant un par défaut.
%
%   Un point non fini ne s'écarte pas tout seul : il contaminerait la
%   somme des carrés et rendrait tout l'ajustement indéterminé.
%
%   Exemple :
%      [x, y] = matlibre_fit_selection([1;2;NaN], [1;2;3], fitoptions());
%
%   Voir aussi FIT, EXCLUDEDATA.
    n = numel(x);
    garde = isfinite(x) & isfinite(y);
    if ~isempty(options.Exclude)
        exclus = options.Exclude;
        if islogical(exclus)
            garde = garde & ~exclus(:);
        else
            masque = false(n, 1);
            masque(exclus) = true;
            garde = garde & ~masque;
        end
    end
    if isempty(options.Weights)
        poids = ones(n, 1);
    else
        poids = double(options.Weights(:));
    end
    x = x(garde);
    y = y(garde);
    poids = poids(garde);
end
