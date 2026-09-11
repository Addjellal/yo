function c = matlibre_comparer_textes(a, b)
%MATLIBRE_COMPARER_TEXTES Compare deux textes, comme le fait un tri.
%   Rend -1 si A vient avant B, 0 s'ils sont égaux, 1 sinon. La
%   comparaison est celle des codes de caractères, position par position ;
%   à préfixe égal, le plus court vient d'abord.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_comparer_textes('a', 'b')      % -1
%      matlibre_comparer_textes('ab', 'a')     % 1
%      matlibre_comparer_textes('a', 'a')      % 0
%
%   Voir aussi ISSORTED, SORT, STRCMP.
    a = char(a);
    b = char(b);
    n = min(numel(a), numel(b));
    for k = 1:n
        if a(k) < b(k)
            c = -1;
            return
        elseif a(k) > b(k)
            c = 1;
            return
        end
    end
    if numel(a) < numel(b)
        c = -1;
    elseif numel(a) > numel(b)
        c = 1;
    else
        c = 0;
    end
end
