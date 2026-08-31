function H = bar3(varargin)
%BAR3 Diagramme en barres à trois dimensions.
%   BAR3(Z) trace une barre par élément de Z, rangées en lignes et en
%   colonnes. BAR3(Y,Z) place les rangées aux ordonnées Y.
%   BAR3(...,LARGEUR) donne aux barres une largeur relative.
%
%   H = BAR3(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : les colonnes de Z sont tracées côte à
%   côte en groupes de barres, ce qui montre la même chose sans la
%   perspective — laquelle, sur un diagramme en barres, cache
%   régulièrement les barres du fond.
%
%   Exemples :
%      bar3(magic(4));
%      bar3(rand(5, 3));
%
%   Voir aussi BAR, BARH, BAR3H, WATERFALL, HEATMAP.
    entrees = varargin;
    if ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) >= 2 && isscalar(entrees{end})
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) >= 2
        Z = entrees{2};
    else
        Z = entrees{1};
    end
    if isvector(Z)
        Z = Z(:);
    end
    [lignes, colonnes] = size(Z);
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = [];
    largeur = 0.8 / max(colonnes, 1);
    for j = 1:colonnes
        for i = 1:lignes
            gauche = i - 0.4 + (j - 1) * largeur;
            droite = gauche + largeur * 0.9;
            H(end + 1) = fill([gauche droite droite gauche], ...
                              [0 0 Z(i, j) Z(i, j)], ...
                              'FaceColor', matlibre_couleur_secteur(j));   %#ok<AGROW>
        end
    end
    if ~aEffacer
        hold('off');
    end
    xlim([0.4, lignes + 0.6]);
    xticks(1:lignes);
    if nargout == 0
        clear H;
    end
end
