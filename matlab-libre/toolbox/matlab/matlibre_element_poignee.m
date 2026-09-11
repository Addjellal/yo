function e = matlibre_element_poignee(h, k)
%MATLIBRE_ELEMENT_POIGNEE Un élément d'un tableau de poignées.
%   E = MATLIBRE_ELEMENT_POIGNEE(H,K) rend le K-ième élément, que H soit
%   un tableau de poignées, une cellule ou un scalaire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_element_poignee([10 20], 2)   % 20
%
%   Voir aussi ISHANDLE, ISGRAPHICS.
    if iscell(h)
        e = h{k};
    elseif numel(h) == 1
        e = h;
    else
        e = h(k);
    end
end
