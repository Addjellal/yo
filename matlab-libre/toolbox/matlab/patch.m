function H = patch(varargin)
%PATCH Polygones remplis.
%   PATCH(X,Y,C) trace le polygone dont les sommets sont (X,Y), rempli de
%   la couleur C. C est une lettre, un nom, ou un triplet [r v b].
%
%   Si X et Y sont des matrices, chaque colonne donne un polygone.
%
%   PATCH(X,Y,Z,C) accepte des sommets à trois dimensions ; le rendu de
%   MatLibre étant plan, Z ne change rien au dessin.
%
%   PATCH('Faces',F,'Vertices',V) décrit les polygones par une liste de
%   sommets V — un par ligne — et une liste de faces F, chaque ligne
%   donnant les indices des sommets d'une face. C'est la forme compacte,
%   celle qu'emploient les maillages : un sommet partagé n'est écrit
%   qu'une fois.
%
%   PATCH(...,'FaceColor',C) et PATCH(...,'EdgeColor',C) nomment les
%   couleurs séparément ; 'none' laisse la face ou le bord vide.
%
%   H = PATCH(...) rend les poignées des polygones.
%
%   Exemples :
%      patch([0 1 1 0], [0 0 1 1], 'r');            % un carre rouge
%
%      % Deux triangles qui partagent une arete
%      V = [0 0; 1 0; 1 1; 0 1];
%      F = [1 2 3; 1 3 4];
%      patch('Faces', F, 'Vertices', V, 'FaceColor', [0.6 0.8 1]);
%
%   Voir aussi FILL, RECTANGLE, TRIMESH, TRISURF, LINE, AREA.
    faces = [];
    sommets = [];
    couleur = [];
    entrees = varargin;
    % La forme « 'Faces', F, 'Vertices', V », et les paires nom-valeur.
    k = 1;
    positionnels = {};
    while k <= numel(entrees)
        if (ischar(entrees{k}) || isstring(entrees{k})) && k + 1 <= numel(entrees) && ...
           any(strcmpi(char(entrees{k}), {'faces', 'vertices', 'facecolor', ...
                                          'edgecolor', 'facealpha', 'linewidth', ...
                                          'facevertexcdata', 'cdata'}))
            nom = lower(char(entrees{k}));
            switch nom
                case 'faces'
                    faces = entrees{k + 1};
                case 'vertices'
                    sommets = entrees{k + 1};
                case 'facecolor'
                    couleur = entrees{k + 1};
                otherwise
                    % acceptes et sans effet
            end
            k = k + 2;
        else
            positionnels{end + 1} = entrees{k};       %#ok<AGROW>
            k = k + 1;
        end
    end

    aEffacer = ishold();
    hold('on');
    H = [];
    if ~isempty(faces) && ~isempty(sommets)
        if isempty(couleur)
            couleur = [0.6 0.8 1];
        end
        for f = 1:size(faces, 1)
            indices = faces(f, :);
            indices = indices(~isnan(indices));
            H(end + 1) = fill(sommets(indices, 1), sommets(indices, 2), ...
                              'FaceColor', couleur);   %#ok<AGROW>
        end
    else
        if numel(positionnels) < 2
            error('MATLAB:patch:NotEnoughInputs', 'Not enough input arguments.');
        end
        x = positionnels{1};
        y = positionnels{2};
        if numel(positionnels) >= 4
            couleurPositionnelle = positionnels{4};
        elseif numel(positionnels) >= 3
            couleurPositionnelle = positionnels{3};
        else
            couleurPositionnelle = [];
        end
        if isempty(couleur)
            couleur = couleurPositionnelle;
        end
        if isempty(couleur)
            couleur = [0.6 0.8 1];
        end
        if isvector(x)
            x = x(:);
            y = y(:);
        end
        for j = 1:size(x, 2)
            H(end + 1) = fill(x(:, j), y(:, j), 'FaceColor', couleur);   %#ok<AGROW>
        end
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
