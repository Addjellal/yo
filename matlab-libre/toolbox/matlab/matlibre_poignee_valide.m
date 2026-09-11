function t = matlibre_poignee_valide(h)
%MATLIBRE_POIGNEE_VALIDE Une poignée désigne-t-elle un objet vivant ?
%   T = MATLIBRE_POIGNEE_VALIDE(H) rend vrai si H est une poignée
%   graphique dont l'objet existe encore, ou un numéro de figure ouverte.
%
%   La vérification se fait en lisant le type de l'objet : une poignée
%   dont la figure a été fermée lève, et c'est cette levée qui répond.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure;
%      matlibre_poignee_valide(gca)    % 1
%
%   Voir aussi ISHANDLE, ISGRAPHICS.
    t = false;
    if isnumeric(h) && isscalar(h)
        % FIGURE rend un numero : c'est encore une poignee valide tant
        % que la figure est ouverte.
        t = any(matlibre_figures_ouvertes() == h);
        return;
    end
    if ~isobject(h)
        return;
    end
    try
        genre = get(h, 'Type');
        t = ~isempty(genre);
    catch
        t = false;
    end
end
