function savefig(varargin)
%SAVEFIG Enregistre une figure dans un fichier.
%   SAVEFIG(NOM) enregistre la figure courante sous le nom donné.
%   SAVEFIG(H,NOM) enregistre la figure désignée par H.
%
%   MATLAB écrit un fichier .fig, qui est un fichier MAT portant son
%   modèle d'objets graphiques. MatLibre n'a pas ce modèle : il
%   enregistre la figure sous la forme que dit l'extension du nom —
%   .svg, .png, .pdf —, et prend le SVG quand le nom n'en porte aucune.
%   Le dessin est conservé ; ce qui ne l'est pas est la possibilité de
%   rouvrir la figure pour la modifier.
%
%   Exemples :
%      plot(1:10);
%      savefig('courbe.svg');
%      savefig('courbe');            % ecrit courbe.svg
%
%   Voir aussi SAVEAS, PRINT, OPENFIG, EXPORTGRAPHICS, FIGURE.
    entrees = varargin;
    if ~isempty(entrees) && ~(ischar(entrees{1}) || isstring(entrees{1}))
        figure(entrees{1});
        entrees = entrees(2:end);
    end
    if isempty(entrees)
        error('MATLAB:savefig:NoFileName', 'SAVEFIG needs a file name.');
    end
    nom = char(entrees{1});
    point = find(nom == '.', 1, 'last');
    if isempty(point) || numel(nom) - point > 4
        nom = [nom, '.svg'];
    elseif strcmpi(nom(point:end), '.fig')
        nom = [nom(1:point - 1), '.svg'];
    end
    saveas(gcf(), nom);
end
