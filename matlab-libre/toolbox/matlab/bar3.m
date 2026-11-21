function H = bar3(varargin)
%BAR3 Diagramme en barres à trois dimensions.
%   BAR3(Z) trace une barre par élément de Z : la colonne J et la ligne I
%   de Z donnent une barre posée en (J, I), haute de Z(I,J). Chaque
%   colonne prend sa couleur dans l'ordre des couleurs de MATLAB.
%   BAR3(Y,Z) place les lignes aux ordonnées Y.
%   BAR3(...,LARGEUR) donne aux barres une largeur relative (0,8 par
%   défaut).
%
%   H = BAR3(...) rend une poignée par colonne de Z, comme MATLAB.
%
%   Exemples :
%      bar3(magic(4));
%      bar3(rand(5, 3), 0.5);
%
%   Voir aussi BAR, BARH, BAR3H, WATERFALL, HEATMAP.
    entrees = varargin;
    while ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        entrees = entrees(1:end - 1);
    end
    largeur = 0.8;
    if numel(entrees) >= 2 && isscalar(entrees{end}) && ~isscalar(entrees{end - 1})
        largeur = entrees{end};
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) >= 2
        positions = entrees{1}(:);
        Z = entrees{2};
    else
        Z = entrees{1};
        positions = [];
    end
    if isvector(Z)
        Z = Z(:);
    end
    [lignes, colonnes] = size(Z);
    if isempty(positions)
        positions = (1:lignes)';
    end
    % Une série par colonne, comme MATLAB : six faces par barre — le bas,
    % le haut, puis les quatre côtés.
    demi = largeur / 2;
    tenu = ishold();
    H = [];
    for j = 1:colonnes
        X = zeros(4, 6 * lignes);
        Y = zeros(4, 6 * lignes);
        W = zeros(4, 6 * lignes);
        rang = 0;
        for i = 1:lignes
            x0 = j - demi; x1 = j + demi;
            y0 = positions(i) - demi; y1 = positions(i) + demi;
            z0 = 0; z1 = Z(i, j);
            faces = {[x0 x1 x1 x0], [y0 y0 y1 y1], [z0 z0 z0 z0];
                     [x0 x1 x1 x0], [y0 y0 y1 y1], [z1 z1 z1 z1];
                     [x0 x1 x1 x0], [y0 y0 y0 y0], [z0 z0 z1 z1];
                     [x0 x1 x1 x0], [y1 y1 y1 y1], [z0 z0 z1 z1];
                     [x0 x0 x0 x0], [y0 y1 y1 y0], [z0 z0 z1 z1];
                     [x1 x1 x1 x1], [y0 y1 y1 y0], [z0 z0 z1 z1]};
            for f = 1:6
                rang = rang + 1;
                X(:, rang) = faces{f, 1}';
                Y(:, rang) = faces{f, 2}';
                W(:, rang) = faces{f, 3}';
            end
        end
        H(end + 1) = fill3(X, Y, W, matlibre_couleur_secteur(j)); %#ok<AGROW>
        hold('on');
    end
    if ~tenu
        hold('off');
    end
    xticks(1:colonnes);
    yticks(positions');
    if nargout == 0
        clear H;
    end
end
