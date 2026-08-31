function H = annotation(genre, varargin)
%ANNOTATION Flèche, trait, rectangle ou texte posé sur la figure.
%   ANNOTATION('arrow',[X1 X2],[Y1 Y2]) trace une flèche.
%   ANNOTATION('line',[X1 X2],[Y1 Y2]) trace un trait.
%   ANNOTATION('doublearrow',...) trace une flèche à deux pointes.
%   ANNOTATION('rectangle',[X Y L H]) trace un rectangle.
%   ANNOTATION('ellipse',[X Y L H]) trace l'ellipse inscrite.
%   ANNOTATION('textbox',[X Y L H],'String',T) écrit un texte.
%   ANNOTATION('textarrow',[X1 X2],[Y1 Y2],'String',T) trace une flèche
%   et écrit le texte à sa base.
%
%   Dans MATLAB, les coordonnées sont celles de la figure entière, de 0 à
%   1. MatLibre n'a pas d'axe superposé à la figure : il les prend pour
%   des fractions de l'axe courant, et l'annotation suit donc le tracé
%   plutôt que le cadre. C'est la seule différence.
%
%   ANNOTATION(...,'Color',C) et ANNOTATION(...,'LineWidth',E) règlent le
%   trait.
%
%   H = ANNOTATION(...) rend les poignées.
%
%   Exemples :
%      plot(1:10);
%      annotation('arrow', [0.3 0.5], [0.3 0.6]);
%      annotation('textbox', [0.2 0.7 0.2 0.1], 'String', 'le sommet');
%      annotation('ellipse', [0.4 0.4 0.2 0.2]);
%
%   Voir aussi TEXT, LINE, RECTANGLE, GTEXT, TITLE.
    genre = lower(char(genre));
    positionnels = {};
    texte = '';
    couleur = 'k';
    epaisseur = 1;
    k = 1;
    while k <= numel(varargin)
        argument = varargin{k};
        if (ischar(argument) || isstring(argument)) && k + 1 <= numel(varargin)
            nom = lower(char(argument));
            switch nom
                case 'string'
                    texte = varargin{k + 1};
                    if iscell(texte)
                        texte = char(texte{1});
                    else
                        texte = char(texte);
                    end
                case 'color'
                    couleur = varargin{k + 1};
                case 'linewidth'
                    epaisseur = varargin{k + 1};
                otherwise
                    % les autres proprietes sont acceptees sans effet
            end
            k = k + 2;
        else
            positionnels{end + 1} = argument;      %#ok<AGROW>
            k = k + 1;
        end
    end

    bornesX = xlim();
    bornesY = ylim();
    versX = @(u) bornesX(1) + u * (bornesX(2) - bornesX(1));
    versY = @(u) bornesY(1) + u * (bornesY(2) - bornesY(1));

    aEffacer = ishold();
    hold('on');
    H = [];
    switch genre
        case {'arrow', 'line', 'doublearrow', 'textarrow'}
            if numel(positionnels) < 2
                error('MATLAB:annotation:NotEnoughInputs', ...
                      'This annotation needs an X and a Y pair.');
            end
            u = positionnels{1};
            v = positionnels{2};
            x1 = versX(u(1)); x2 = versX(u(2));
            y1 = versY(v(1)); y2 = versY(v(2));
            taille = 0.03 * max(bornesX(2) - bornesX(1), bornesY(2) - bornesY(1));
            if strcmp(genre, 'line')
                H(end + 1) = plot([x1 x2], [y1 y2], 'Color', couleur, ...
                                  'LineWidth', epaisseur);
            else
                [tx, ty] = matlibre_fleche(x1, y1, x2 - x1, y2 - y1, taille);
                H(end + 1) = plot(tx, ty, 'Color', couleur, 'LineWidth', epaisseur);
                if strcmp(genre, 'doublearrow')
                    [tx2, ty2] = matlibre_fleche(x2, y2, x1 - x2, y1 - y2, taille);
                    H(end + 1) = plot(tx2, ty2, 'Color', couleur, ...
                                      'LineWidth', epaisseur);
                end
            end
            if ~isempty(texte)
                H(end + 1) = text(x1, y1, texte, 'Color', couleur);
            end
        case {'rectangle', 'ellipse', 'textbox'}
            if isempty(positionnels)
                error('MATLAB:annotation:NotEnoughInputs', ...
                      'This annotation needs a position.');
            end
            p = positionnels{1};
            x = versX(p(1));
            y = versY(p(2));
            largeur = p(3) * (bornesX(2) - bornesX(1));
            hauteur = p(4) * (bornesY(2) - bornesY(1));
            if strcmp(genre, 'ellipse')
                courbure = 1;
            else
                courbure = 0;
            end
            if strcmp(genre, 'textbox') && ~isempty(texte)
                H(end + 1) = text(x + largeur / 2, y + hauteur / 2, texte, ...
                                  'HorizontalAlignment', 'center', 'Color', couleur);
            else
                H = [H, rectangle('Position', [x y largeur hauteur], ...
                                  'Curvature', courbure, 'EdgeColor', couleur, ...
                                  'LineWidth', epaisseur)];
            end
        otherwise
            error('MATLAB:annotation:BadType', ...
                  'Unknown annotation type ''%s''.', genre);
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
