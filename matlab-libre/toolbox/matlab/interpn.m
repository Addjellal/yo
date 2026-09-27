function Vq = interpn(varargin)
%INTERPN Interpolation sur une grille à N dimensions.
%   VQ = INTERPN(X1,X2,...,XN,V,XQ1,XQ2,...,XQN) interpole les valeurs V,
%   données sur la grille de NDGRID — X1 à XN sont ses vecteurs, ou les
%   tableaux qu'en fait NDGRID —, aux points (XQ1(k),...,XQN(k)). Les XQ
%   ont une même taille, qui est celle de VQ ; des vecteurs de tailles ou
%   d'orientations différentes décrivent une grille, que NDGRID déplie.
%   VQ = INTERPN(V,XQ1,...,XQN) prend la grille 1:size(V,D).
%
%   VQ = INTERPN(...,METHODE) choisit 'linear' (le défaut, multilinéaire),
%   'nearest' (le point le plus proche), 'pchip', 'makima', 'spline' ou
%   'cubic' — ces quatre-là appliquent l'interpolation de même nom
%   dimension après dimension ; 'cubic' est la convolution cubique sur une
%   grille à pas constant, la spline sinon. VQ = INTERPN(...,METHODE,
%   EXTRAPVAL) donne la valeur des points hors de la grille, NaN par
%   défaut.
%
%   Exemple :
%      [x1, x2, x3] = ndgrid(0:1, 0:2, 0:3);
%      V = x1 + 10 * x2 + 100 * x3;
%      interpn(0:1, 0:2, 0:3, V, 0.5, 1.5, 2)      % 215.5 : V est affine
%      interpn(0:1, 0:2, 0:3, V, 2, 0, 0)          % NaN : hors de la grille
%
%   Voir aussi INTERP1, INTERP2, INTERP3, NDGRID, GRIDDEDINTERPOLANT.
    [grille, V, questions, methode, horsGrille] = lireArguments(varargin, 'interpn');
    Vq = interpolerGrille(grille, V, questions, methode, horsGrille);
end

function [grille, V, questions, methode, horsGrille] = lireArguments(args, nom)
    methode = 'linear';
    horsGrille = NaN;
    nNum = numel(args);
    for k = 1:numel(args)
        if ischar(args{k}) || isstring(args{k})
            nNum = k - 1;
            methode = lower(char(args{k}));
            if k < numel(args)
                horsGrille = args{k + 1};
                if ~(ischar(horsGrille) || isstring(horsGrille))
                    horsGrille = double(horsGrille);
                end
            end
            break
        end
    end
    if ~any(strcmp(methode, {'linear', 'nearest', 'pchip', 'makima', 'spline', 'cubic'}))
        error(['MATLAB:' nom ':InvalidMethod'], ...
              ['%s : la methode est ''linear'', ''nearest'', ''pchip'', ''makima'', ' ...
               '''spline'' ou ''cubic'' ; pas ''%s''.'], nom, methode);
    end
    n2 = (nNum - 1) / 2;
    if nNum >= 3 && n2 == round(n2) && dimensionsDe(args{n2 + 1}) == n2
        V = args{n2 + 1};
        grille = cell(1, n2);
        for d = 1:n2
            grille{d} = vecteurDe(args{d}, d);
        end
        questions = args(n2 + 2:nNum);
    elseif nNum >= 2
        V = args{1};
        n = nNum - 1;
        if n == 1
            V = V(:);
        end
        grille = cell(1, n);
        for d = 1:n
            grille{d} = 1:size(V, d);
        end
        questions = args(2:nNum);
    else
        error('MATLAB:interpn:NotEnoughInputs', ...
              '%s(X1,...,XN,V,XQ1,...,XQN) ou %s(V,XQ1,...,XQN).', upper(nom), upper(nom));
    end
    n = numel(grille);
    if n == 1
        V = V(:);   % une seule dimension : V est un vecteur, ligne ou colonne
    end
    tailles = size(V);
    tailles(end + 1:n) = 1;
    for d = 1:n
        if numel(grille{d}) ~= tailles(d)
            error('MATLAB:interpn:GridSize', ...
                  ['%s : la grille a %d point(s) sur sa dimension %d, et V %d.'], nom, ...
                  numel(grille{d}), d, tailles(d));
        end
        if any(diff(grille{d}) <= 0)
            error('MATLAB:interpn:GridNotMonotonic', ...
                  '%s : les points de la dimension %d doivent croitre strictement.', nom, d);
        end
    end
end

% Le nombre de dimensions d'un tableau, un vecteur n'en ayant qu'une.
function n = dimensionsDe(V)
    if isvector(V)
        n = 1;
    else
        n = ndims(V);
    end
end

% Le vecteur d'une dimension : donné tel quel, ou tiré d'un tableau de
% NDGRID, le long de sa dimension D.
function x = vecteurDe(X, d)
    if isvector(X)
        x = double(X(:)).';
        return
    end
    indices = repmat({1}, 1, ndims(X));
    indices{d} = ':';
    x = double(X(indices{:}));
    x = x(:).';
end

function Vq = interpolerGrille(grille, V, questions, methode, horsGrille)
    n = numel(grille);
    if numel(questions) ~= n
        error('MATLAB:interpn:QueryCount', ...
              'La grille a %d dimension(s), et %d tableau(x) de points sont donnes.', n, ...
              numel(questions));
    end
    tousVecteurs = all(cellfun(@isvector, questions));
    memeTaille = all(cellfun(@(q) isequal(size(q), size(questions{1})), questions));
    if n > 1 && tousVecteurs && ~memeTaille
        [questions{1:n}] = ndgrid(questions{:});
    end
    taille = size(questions{1});
    for d = 2:n
        if numel(questions{d}) > numel(questions{1})
            taille = size(questions{d});
        end
    end
    m = prod(taille);
    if n == 1
        V = V(:);
    end
    tailles = size(V);
    tailles(end + 1:n) = 1;
    rang = zeros(m, n);
    part = zeros(m, n);
    dehors = false(m, 1);
    for d = 1:n
        q = double(questions{d}(:));
        if isscalar(q)
            q = repmat(q, m, 1);
        end
        b = grille{d}(:);
        dehors = dehors | q < b(1) | q > b(end) | isnan(q);
        if numel(b) == 1
            rang(:, d) = 1;
            continue
        end
        % la maille de chaque point : le nombre de points de rupture qu'il
        % dépasse ou atteint
        i = sum(min(max(q, b(1)), b(end)) >= b(:).', 2);
        i = min(max(i, 1), numel(b) - 1);
        f = (q - b(i)) ./ (b(i + 1) - b(i));
        if strcmp(methode, 'nearest')
            f = double(f >= 0.5);
        end
        rang(:, d) = i;
        part(:, d) = f;
    end
    if ~any(strcmp(methode, {'linear', 'nearest'}))
        Q = zeros(m, n);
        for d = 1:n
            q = double(questions{d}(:));
            Q(:, d) = q + zeros(m, 1);
        end
        Vq = interpolerSeparable(grille, V, Q, methode);
        Vq = poserHorsGrille(Vq, dehors, horsGrille);
        Vq = reshape(Vq, taille);
        return
    end
    Vq = zeros(m, 1);
    for coin = 0:2^n - 1
        bits = bitget(coin, 1:n);
        poids = prod(bits .* part + (1 - bits) .* (1 - part), 2);
        coins = min(rang + bits, tailles(1:n));
        indices = cell(1, n);
        for d = 1:n
            indices{d} = coins(:, d);
        end
        valeurs = V(sub2ind(tailles(1:n), indices{:}));
        Vq = Vq + poids .* valeurs(:);
    end
    Vq = poserHorsGrille(Vq, dehors, horsGrille);
    Vq = reshape(Vq, taille);
end

% Hors de la grille : EXTRAPVAL, ou le prolongement de l'interpolation
% quand on demande 'extrap' (ce que fait GRIDDEDINTERPOLANT).
function Vq = poserHorsGrille(Vq, dehors, horsGrille)
    if ischar(horsGrille) || isstring(horsGrille)
        if ~strcmpi(char(horsGrille), 'extrap')
            error('MATLAB:interpn:InvalidExtrapval', ...
                  'La valeur hors de la grille est un nombre, pas ''%s''.', char(horsGrille));
        end
        return
    end
    Vq(dehors) = horsGrille;
end

% Les méthodes d'ordre trois s'appliquent dimension après dimension : la
% table se réduit, pour chaque point, le long de sa dernière dimension,
% puis de l'avant-dernière, jusqu'à une valeur.
function Vq = interpolerSeparable(grille, V, Q, methode)
    n = numel(grille);
    tailles = size(V);
    tailles(end + 1:n) = 1;
    m = size(Q, 1);
    Vq = zeros(m, 1);
    for k = 1:m
        W = double(V);
        for d = n:-1:1
            W = reshape(W, [], tailles(d));
            r = zeros(size(W, 1), 1);
            for i = 1:size(W, 1)
                r(i) = interpoler1(grille{d}, W(i, :), Q(k, d), methode);
            end
            W = r;
        end
        Vq(k) = W;
    end
end

function v = interpoler1(x, y, q, methode)
    x = x(:).';
    if numel(x) == 1
        v = y(1);
        return
    end
    if strcmp(methode, 'cubic')
        h = diff(x);
        if numel(x) >= 3 && max(abs(h - h(1))) <= 1e-12 * max(abs(x))
            v = convolutionCubique(x, y, q);
            return
        end
        methode = 'spline';
    end
    v = interp1(x, y, q, methode, 'extrap');
end

% La convolution cubique de Keys (a = -1/2) sur une grille à pas constant ;
% aux bords, la table se prolonge d'un point, 3 f(1) - 3 f(2) + f(3).
function v = convolutionCubique(x, y, q)
    n = numel(x);
    f = [3 * y(1) - 3 * y(2) + y(3), y(:).', 3 * y(n) - 3 * y(n - 1) + y(n - 2)];
    s = (q - x(1)) / (x(2) - x(1));
    i = min(max(floor(s), 0), n - 2);
    t = s - i;
    poids = [(-t^3 + 2 * t^2 - t) / 2, (3 * t^3 - 5 * t^2 + 2) / 2, ...
             (-3 * t^3 + 4 * t^2 + t) / 2, (t^3 - t^2) / 2];
    v = poids * f(i + 1:i + 4).';
end
