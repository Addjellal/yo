function v = matlibre_evaluer_courbe(fonction, t)
%MATLIBRE_EVALUER_COURBE Évalue une poignée sur un vecteur de paramètres.
%   Une poignée vectorisée est appelée une fois ; une poignée qui ne l'est
%   pas est appelée point par point. On essaie la première façon et l'on
%   se rabat sur la seconde si le résultat n'a pas la bonne taille — c'est
%   plus sûr que d'exiger de l'appelant qu'il vectorise.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      v = matlibre_evaluer_courbe(@(t) t.^2, [1 2 3]);
%      isequal(v, [1 4 9])
%
%   Voir aussi FPLOT3, FPLOT, ARRAYFUN.
    v = [];
    try
        v = fonction(t);
    catch
        v = [];
    end
    if numel(v) ~= numel(t)
        v = arrayfun(@(u) double(fonction(u)), t);
    end
    v = reshape(double(v), size(t));
end
