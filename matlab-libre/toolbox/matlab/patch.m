function H = patch(varargin)
%PATCH Polygones remplis, dans le plan ou dans l'espace.
%   PATCH(X,Y,C) trace le polygone dont les sommets sont (X,Y), rempli de
%   la couleur C : une lettre, un nom, un triplet [r v b], ou une valeur
%   que la palette met à l'échelle (CLIM).
%
%   Si X et Y sont des matrices, chaque colonne donne un polygone ; C peut
%   alors donner une valeur ou un triplet par polygone, ou une valeur par
%   sommet (le polygone prend leur moyenne).
%
%   PATCH(X,Y,Z,C) pose les sommets dans l'espace : la vue en perspective
%   (VIEW(3)) les montre, triés du plus lointain au plus proche.
%
%   PATCH('Faces',F,'Vertices',V) décrit les polygones par une liste de
%   sommets V — un par ligne, deux ou trois colonnes — et une liste de
%   faces F, chaque ligne donnant les indices des sommets d'une face (NaN
%   complète les faces plus courtes). C'est la forme compacte des
%   maillages. 'FaceVertexCData' donne la couleur : une valeur ou un
%   triplet par face, ou une valeur par sommet.
%
%   PATCH(...,'FaceColor',C) et PATCH(...,'EdgeColor',C) nomment les
%   couleurs séparément ; 'none' laisse la face ou le bord vide, 'flat'
%   prend la couleur de la face. 'FaceAlpha', 'LineWidth', 'LineStyle' et
%   'DisplayName' sont lus.
%
%   Comme dans MATLAB, PATCH est de bas niveau : il ajoute ses polygones
%   sans effacer le tracé ni changer la vue. H = PATCH(...) rend la
%   poignée de l'objet, un seul pour toutes ses faces.
%
%   Exemples :
%      patch([0 1 1 0], [0 0 1 1], 'r');            % un carre rouge
%
%      % Deux triangles qui partagent une arete
%      V = [0 0; 1 0; 1 1; 0 1];
%      F = [1 2 3; 1 3 4];
%      patch('Faces', F, 'Vertices', V, 'FaceColor', [0.6 0.8 1]);
%
%      % Un tetraedre, colore face par face
%      V = [0 0 0; 1 0 0; 0 1 0; 0 0 1];
%      F = [1 2 3; 1 2 4; 1 3 4; 2 3 4];
%      clf; patch('Faces', F, 'Vertices', V, 'FaceVertexCData', (1:4)', ...
%                 'FaceColor', 'flat'); view(3);
%
%   Voir aussi FILL, FILL3, RECTANGLE, TRIMESH, TRISURF, LINE, AREA.
    faces = [];
    sommets = [];
    couleurs = [];
    reglages = {};
    positionnels = {};
    k = 1;
    while k <= numel(varargin)
        entree = varargin{k};
        if (ischar(entree) || isstring(entree)) && k + 1 <= numel(varargin) && ...
           any(strcmpi(char(entree), {'faces', 'vertices', 'facevertexcdata', 'cdata', ...
                                      'facecolor', 'edgecolor', 'facealpha', 'linewidth', ...
                                      'linestyle', 'displayname', 'edgealpha', ...
                                      'facelighting'}))
            switch lower(char(entree))
                case 'faces'
                    faces = varargin{k + 1};
                case 'vertices'
                    sommets = varargin{k + 1};
                case {'facevertexcdata', 'cdata'}
                    couleurs = varargin{k + 1};
                otherwise
                    reglages(end + 1:end + 2) = {char(entree), varargin{k + 1}};
            end
            k = k + 2;
        else
            positionnels{end + 1} = entree; %#ok<AGROW>
            k = k + 1;
        end
    end

    if ~isempty(sommets)
        if isempty(faces)
            faces = 1:size(sommets, 1);
        end
        % Une face par colonne ; les indices NaN complètent les faces courtes.
        F = faces';
        X = nan(size(F));
        Y = nan(size(F));
        Z = [];
        dedans = ~isnan(F);
        X(dedans) = sommets(F(dedans), 1);
        Y(dedans) = sommets(F(dedans), 2);
        if size(sommets, 2) >= 3
            Z = nan(size(F));
            Z(dedans) = sommets(F(dedans), 3);
        end
        C = [];
        if ~isempty(couleurs)
            if size(couleurs, 1) == size(sommets, 1) && size(couleurs, 2) == 1 && ...
               size(sommets, 1) ~= size(faces, 1)
                % Une valeur par sommet : la face prend leur moyenne.
                C = nan(size(F));
                C(dedans) = couleurs(F(dedans));
            else
                C = couleurs;
            end
        end
        if isvector(X) && size(faces, 1) == 1
            X = X(:);
            Y = Y(:);
            if ~isempty(Z)
                Z = Z(:);
            end
        end
    else
        if numel(positionnels) < 2
            error('MATLAB:patch:NotEnoughInputs', 'Not enough input arguments.');
        end
        X = positionnels{1};
        Y = positionnels{2};
        Z = [];
        C = [];
        if numel(positionnels) >= 4
            Z = positionnels{3};
            C = positionnels{4};
        elseif numel(positionnels) == 3
            C = positionnels{3};
        end
    end
    if isempty(C) && ~any(strcmpi(reglages(1:2:end), 'facecolor'))
        C = [0 0 0];
    end
    H = matlibre_patch(X, Y, Z, C, reglages{:});
    if nargout == 0
        clear H;
    end
end
