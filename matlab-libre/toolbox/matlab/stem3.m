function H = stem3(varargin)
%STEM3 Tiges dans l'espace.
%   STEM3(X,Y,Z) trace, pour chaque point (X,Y,Z), une tige verticale qui
%   part du plan Z = 0, surmontée d'un cercle.
%   STEM3(Z) place les tiges aux nœuds d'une grille entière : la colonne
%   J et la ligne I de Z en (J, I).
%   STEM3(...,'filled') remplit les cercles ; STEM3(...,STYLE) prend une
%   chaîne de style (« 'r--d' »).
%
%   H = STEM3(...) rend la poignée des tiges.
%
%   Exemples :
%      t = linspace(0, 2*pi, 20);
%      stem3(cos(t), sin(t), t);
%      stem3(rand(4, 4), 'filled');
%
%   Voir aussi STEM, PLOT3, SCATTER3, BAR3.
    entrees = varargin;
    rempli = false;
    style = '';
    while ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        if strcmpi(char(entrees{end}), 'filled')
            rempli = true;
        else
            style = char(entrees{end});
        end
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) == 1
        Z = entrees{1};
        if isvector(Z)
            X = 1:numel(Z);
            Y = ones(size(X));
        else
            [X, Y] = meshgrid(1:size(Z, 2), 1:size(Z, 1));
        end
    elseif numel(entrees) == 3
        [X, Y, Z] = entrees{:};
    else
        error('MATLAB:stem3:NotEnoughInputs', 'Not enough input arguments.');
    end
    x = X(:)';
    y = Y(:)';
    z = Z(:)';
    if numel(x) ~= numel(z) || numel(y) ~= numel(z)
        error('MATLAB:stem3:InvalidData', 'X, Y et Z doivent avoir le même nombre d''éléments.');
    end
    % Le style : la couleur et le trait des tiges, le marqueur des têtes.
    trait = '-';
    marqueur = 'o';
    couleur = '';
    for c = style
        if any(c == 'rgbcmykw')
            couleur = c;
        elseif any(c == 'o+*xsd^v<>ph.')
            marqueur = c;
        end
    end
    for motif = {'--', '-.', ':'}
        if contains(style, motif{1})
            trait = motif{1};
        end
    end
    n = numel(z);
    % Les tiges, séparées par des NaN : une seule courbe.
    xs = [x; x; nan(1, n)];
    ys = [y; y; nan(1, n)];
    zs = [zeros(1, n); z; nan(1, n)];
    tenu = ishold();
    H = plot3(xs(:), ys(:), zs(:), [trait couleur]);
    hold('on');
    teinte = get(H, 'Color');
    if rempli
        plot3(x, y, z, marqueur, 'Color', teinte, 'MarkerFaceColor', teinte);
    else
        plot3(x, y, z, marqueur, 'Color', teinte);
    end
    if ~tenu
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
