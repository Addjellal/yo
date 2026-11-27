function h = imshow(I, varargin)
%IMSHOW Affiche une image, comme MATLAB : en niveaux de gris, en couleurs
%vraies, binaire ou indexée.
%   IMSHOW(I) affiche l'image d'intensités I en niveaux de gris, sur la
%   plage de son type : [0 255] pour un uint8, [0 65535] pour un uint16,
%   [-32768 32767] pour un int16, [0 1] pour un double, un single ou un
%   logical — une image binaire est donc noire et blanche.
%   IMSHOW(I,[BAS HAUT]) fixe la plage : BAS s'affiche en noir, HAUT en
%   blanc. IMSHOW(I,[]) la prend de min(I(:)) à max(I(:)).
%   IMSHOW(RGB) affiche un tableau m x n x 3 en couleurs vraies.
%   IMSHOW(X,MAP) affiche l'image indexée X avec la palette MAP.
%   IMSHOW(NOMFICHIER) lit l'image avec IMREAD puis l'affiche.
%   IMSHOW(...,'DisplayRange',[BAS HAUT]) et 'Colormap',MAP comme
%   ci-dessus ; 'InitialMagnification', 'Border', 'Interpolation',
%   'Parent', 'XData', 'YData' et 'Reduce' sont acceptés.
%   H = IMSHOW(...) rend la poignée de l'image.
%
%   Comme MATLAB, IMSHOW donne à l'axe une palette grise (sauf pour une
%   image indexée ou en couleurs vraies), des échelles égales et serrées
%   sur l'image, et cache les graduations ; le titre reste.
%
%   Exemple :
%      I = uint8(magic(64));
%      imshow(I);                  % plage [0 255] : une image sombre
%      imshow(I, []);              % plage [min max] : tout le contraste
%      imshow(I > 128);            % noir et blanc
%
%   Voir aussi IMAGE, IMAGESC, COLORMAP, CLIM, IMREAD.
    carte = [];
    plage = [];
    plageDonnee = false;
    reste = varargin;
    if ischar(I) || (isstring(I) && isscalar(I))
        [I, carteFichier] = imread(char(I));
        if ~isempty(carteFichier)
            carte = carteFichier;
        end
    end
    % Le second argument positionnel : une plage ou une palette.
    if ~isempty(reste) && isnumeric(reste{1})
        second = reste{1};
        reste = reste(2:end);
        if isempty(second)
            plage = [];
            plageDonnee = true;
        elseif isequal(size(second), [1 2]) || isequal(size(second), [2 1])
            plage = double(second(:)');
            plageDonnee = true;
        elseif size(second, 2) == 3
            carte = second;
        else
            error('images:imshow:invalidInput', ...
                  ['IMSHOW: the second argument must be a display range [LOW HIGH] or an m-by-3 ' ...
                   'colormap.']);
        end
    end
    for k = 1:2:numel(reste)
        if k + 1 > numel(reste)
            error('images:imshow:invalidInput', 'IMSHOW: options must be name-value pairs.');
        end
        switch lower(char(reste{k}))
            case 'displayrange'
                plage = double(reste{k + 1}(:)');
                plageDonnee = true;
            case 'colormap'
                carte = reste{k + 1};
            case {'initialmagnification', 'border', 'interpolation', 'parent', ...
                  'xdata', 'ydata', 'reduce'}
                % Acceptées : le rendu de MatLibre n'en a pas l'usage.
            otherwise
                error('images:imshow:invalidInput', ...
                      'IMSHOW : option inconnue ''%s''.', char(reste{k}));
        end
    end

    rvb = ndims(I) == 3 && size(I, 3) == 3;
    if ~rvb && ~ismatrix(I)
        error('images:imshow:invalidImage', ...
              'IMSHOW requires an m-by-n image, or an m-by-n-by-3 truecolor image.');
    end
    if rvb
        poignee = image(I);
    elseif ~isempty(carte)
        % Image indexée : les valeurs désignent les couleurs de la palette.
        poignee = image(I);
        colormap(gca, carte);
    else
        if plageDonnee && isempty(plage)
            valeurs = double(I(isfinite(double(I))));
            if isempty(valeurs)
                plage = [0 1];
            else
                plage = [min(valeurs) max(valeurs)];
            end
        elseif ~plageDonnee
            plage = plageDuType(I);
        end
        if ~(plage(2) > plage(1))
            plage = [plage(1) - 0.5, plage(1) + 0.5];
        end
        poignee = image(double(I), 'CDataMapping', 'scaled');
        clim(gca, plage);
        colormap(gca, gray(256));
    end
    axis('image');
    axis('off');
    if nargout > 0
        h = poignee;
    end
end

% La plage d'affichage par défaut d'une image d'intensités : celle de son
% type.
function plage = plageDuType(I)
    switch class(I)
        case 'uint8',  plage = [0 255];
        case 'uint16', plage = [0 65535];
        case 'int16',  plage = [-32768 32767];
        case 'uint32', plage = [0 4294967295];
        case 'int8',   plage = [-128 127];
        case 'int32',  plage = [-2147483648 2147483647];
        otherwise,     plage = [0 1];
    end
end
