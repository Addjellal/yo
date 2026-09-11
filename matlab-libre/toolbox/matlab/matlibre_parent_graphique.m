function p = matlibre_parent_graphique(h)
%MATLIBRE_PARENT_GRAPHIQUE Objet qui contient une poignée graphique.
%   P = MATLIBRE_PARENT_GRAPHIQUE(H) rend l'axe d'une courbe ou d'un
%   texte, la figure d'un axe, et un tableau vide au-dessus d'une figure.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure; courbe = plot(1:3);
%      strcmp(get(matlibre_parent_graphique(courbe), 'Type'), 'axes')   % 1
%
%   Voir aussi ANCESTOR, GCA, GCF.
    p = [];
    if ~isobject(h)
        return;
    end
    if strcmpi(get(h, 'Type'), 'figure')
        % Au-dessus d'une figure, MATLAB place la racine ; MatLibre n'en a
        % pas, et la remontee s'arrete donc là.
        p = [];
        return;
    end
    p = get(h, 'Parent');
end
