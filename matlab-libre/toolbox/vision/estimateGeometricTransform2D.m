function [T, valides, statut] = estimateGeometricTransform2D(points1, points2, type, varargin)
%ESTIMATEGEOMETRICTRANSFORM2D Transformation géométrique robuste entre deux jeux de points.
%   T = ESTIMATEGEOMETRICTRANSFORM2D(P1,P2,TYPE) estime la transformation
%   qui envoie les points P1 (N x 2) sur les points appariés P2, en
%   écartant les appariements aberrants par l'algorithme MSAC (Torr et
%   Zisserman, 2000), comme MATLAB. TYPE vaut 'rigid', 'similarity',
%   'affine' ou 'projective'.
%   [T,VALIDES] = ... rend aussi le masque des appariements retenus, et
%   [T,VALIDES,STATUT] le statut : 0 si tout va bien, 1 s'il y a trop peu
%   de points, 2 si trop peu d'appariements sont retenus. Sans STATUT,
%   ces deux cas sont des erreurs.
%
%   MATLAB rend un objet (rigid2d, affine2d, projective2d) ; MatLibre rend
%   sa matrice T, 3 x 3, dans la convention de MATLAB : les points sont
%   des lignes et la transformation s'applique à droite, [x y 1] * T.
%
%   Options, comme MATLAB :
%      'MaxDistance'   distance de reprojection, en pixels, au-delà de
%                      laquelle un appariement est aberrant (1.5)
%      'MaxNumTrials'  nombre maximal de tirages (1000)
%      'Confidence'    confiance, en pour cent, de trouver le meilleur
%                      ensemble, qui fixe l'arrêt des tirages (99)
%
%   Chaque tirage ajuste la transformation sur le plus petit nombre de
%   points qui la détermine (2 pour 'rigid' et 'similarity', 3 pour
%   'affine', 4 pour 'projective') et la note par le coût de MSAC, la
%   somme des min(d², MaxDistance²). Le nombre de tirages s'adapte à la
%   proportion d'appariements retenus. La transformation finale est
%   ajustée sur tous les appariements retenus : par Kabsch (rigide),
%   moindres carrés exacts (similitude, affine) ou transformation
%   linéaire directe normalisée de Hartley (projective).
%
%   Exemple :
%      p1 = [0 0; 10 0; 0 10; 20 20; 5 15];
%      p2 = p1 * 2 + 3;  p2(5, :) = [100 -40];      % un appariement faux
%      [T, valides] = estimateGeometricTransform2D(p1, p2, 'similarity');
%      valides.'                                    % 1 1 1 1 0
%
%   Voir aussi ESTIMATEGEOMETRICTRANSFORM, ESTIMATEFUNDAMENTALMATRIX.
    if nargin < 3 || isempty(type)
        error('vision:estimateGeometricTransform2D:Type', ...
              'Type must be ''rigid'', ''similarity'', ''affine'', or ''projective''.');
    end
    type = lower(char(type));
    distanceMax = 1.5;
    tiragesMax = 1000;
    confiance = 99;
    if mod(numel(varargin), 2) ~= 0
        error('vision:estimateGeometricTransform2D:Options', ...
              'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        switch lower(char(varargin{k}))
            case 'maxdistance',  distanceMax = double(varargin{k + 1});
            case 'maxnumtrials', tiragesMax = double(varargin{k + 1});
            case 'confidence',   confiance = double(varargin{k + 1});
            otherwise
                error('vision:estimateGeometricTransform2D:Option', ...
                      'Option inconnue : ''%s''.', char(varargin{k}));
        end
    end
    if ~(distanceMax > 0) || ~(confiance > 0 && confiance < 100) || tiragesMax < 1
        error('vision:estimateGeometricTransform2D:Options', ...
              ['MaxDistance must be positive, Confidence between 0 and 100, and MaxNumTrials at ' ...
               'least 1.']);
    end
    P1 = double(points1);
    P2 = double(points2);
    if size(P1, 2) ~= 2 || ~isequal(size(P1), size(P2))
        error('vision:estimateGeometricTransform2D:Points', ...
              'P1 and P2 must be N-by-2 matrices of matched points.');
    end
    n = size(P1, 1);
    minimum = minimumPoints(type);
    T = eye(3);
    valides = false(n, 1);
    if n < minimum
        statut = 1;
        signaler(statut, nargout, minimum);
        return
    end
    seuil2 = distanceMax ^ 2;
    meilleurCout = inf;
    tirages = tiragesMax;
    essai = 0;
    while essai < tirages
        essai = essai + 1;
        indices = randperm(n, minimum);
        candidat = ajuster(P1(indices, :), P2(indices, :), type);
        if isempty(candidat) || any(~isfinite(candidat(:)))
            continue
        end
        d2 = erreursReprojection(candidat, P1, P2) .^ 2;
        cout = sum(min(d2, seuil2));
        if cout < meilleurCout
            meilleurCout = cout;
            valides = d2 < seuil2;
            proportion = nnz(valides) / n;
            if proportion >= 1
                tirages = essai;
            elseif proportion > 0
                besoin = log(1 - confiance / 100) / log(1 - proportion ^ minimum);
                tirages = min(tiragesMax, max(essai, ceil(besoin)));
            end
        end
    end
    if nnz(valides) < minimum
        statut = 2;
        signaler(statut, nargout, minimum);
        valides = false(n, 1);
        return
    end
    T = ajuster(P1(valides, :), P2(valides, :), type);
    % Le modèle final peut retenir quelques points de plus, ou de moins.
    valides = erreursReprojection(T, P1, P2) < distanceMax;
    if nnz(valides) >= minimum
        T = ajuster(P1(valides, :), P2(valides, :), type);
    end
    statut = 0;
end

function signaler(statut, nSorties, minimum)
    if nSorties >= 3
        return
    end
    if statut == 1
        error('vision:points:notEnoughMatchedPts', ...
              'At least %d matched pairs are required for this transformation type.', minimum);
    end
    error('vision:points:notEnoughInlierMatches', ...
          'Too few inlier matches: increase MaxDistance or MaxNumTrials.');
end

function m = minimumPoints(type)
    switch type
        case {'rigid', 'similarity'}, m = 2;
        case 'affine',                m = 3;
        case 'projective',            m = 4;
        otherwise
            error('vision:estimateGeometricTransform2D:Type', ...
                  'Type must be ''rigid'', ''similarity'', ''affine'', or ''projective''.');
    end
end

function T = ajuster(P1, P2, type)
    n = size(P1, 1);
    switch type
        case 'rigid'
            % Kabsch : la rotation qui aligne au mieux les nuages centrés.
            c1 = mean(P1, 1); c2 = mean(P2, 1);
            [U, ~, V] = svd((P1 - c1).' * (P2 - c2));
            D = diag([1, sign(det(V * U.'))]);
            R = V * D * U.';                   % colonne : q = R p + t
            t = c2 - c1 * R.';
            T = [R.', [0; 0]; t, 1];
        case 'similarity'
            % [x' y'] = s R [x y] + t : quatre inconnues, deux équations
            % par point ; les moindres carrés linéaires sont exacts.
            A = zeros(2 * n, 4);
            b = zeros(2 * n, 1);
            A(1:2:end, :) = [P1(:, 1), -P1(:, 2), ones(n, 1), zeros(n, 1)];
            A(2:2:end, :) = [P1(:, 2), P1(:, 1), zeros(n, 1), ones(n, 1)];
            b(1:2:end) = P2(:, 1);
            b(2:2:end) = P2(:, 2);
            if rank(A) < 4
                T = [];
                return
            end
            p = A \ b;
            T = [p(1), p(2), 0; -p(2), p(1), 0; p(3), p(4), 1];
        case 'affine'
            A = [P1, ones(n, 1)];
            if rank(A) < 3
                T = [];
                return
            end
            T = [A \ P2, [0; 0; 1]];
        otherwise
            T = ajusterProjective(P1, P2);
    end
end

function T = ajusterProjective(P1, P2)
%AJUSTERPROJECTIVE Homographie par transformation linéaire directe normalisée.
%   Hartley (1997) : chaque nuage est centré et mis à l'échelle (distance
%   moyenne racine de deux) avant la décomposition en valeurs singulières,
%   ce qui rend le système bien conditionné en coordonnées de pixels.
    [Q1, N1] = normaliser(P1);
    [Q2, N2] = normaliser(P2);
    n = size(P1, 1);
    A = zeros(2 * n, 9);
    x = Q1(:, 1); y = Q1(:, 2); u = Q2(:, 1); v = Q2(:, 2);
    o = ones(n, 1); z = zeros(n, 1);
    A(1:2:end, :) = [-x, -y, -o, z, z, z, u .* x, u .* y, u];
    A(2:2:end, :) = [z, z, z, -x, -y, -o, v .* x, v .* y, v];
    % Quatre points donnent huit équations pour neuf inconnues : la SVD
    % économique n'aurait alors que huit vecteurs, sans celui du noyau.
    if size(A, 1) >= 9
        [~, S, V] = svd(A, 0);
    else
        [~, S, V] = svd(A);
    end
    s = diag(S);
    if numel(s) >= 8 && s(8) <= eps * s(1) * 9
        T = [];                         % points alignés : pas d'homographie
        return
    end
    H = reshape(V(:, end), 3, 3).';
    H = N2 \ H * N1;
    if abs(H(3, 3)) <= eps * norm(H)
        T = [];
        return
    end
    H = H / H(3, 3);
    % Convention de MATLAB : les points sont des lignes, donc la matrice
    % est la transposée de l'homographie usuelle.
    T = H.';
end

function [Q, N] = normaliser(P)
    c = mean(P, 1);
    echelle = sqrt(2) / max(mean(sqrt(sum((P - c) .^ 2, 2))), eps);
    N = [echelle, 0, -echelle * c(1); 0, echelle, -echelle * c(2); 0, 0, 1];
    Q = (P - c) * echelle;
end

function d = erreursReprojection(T, P1, P2)
    n = size(P1, 1);
    h = [P1, ones(n, 1)] * T;
    w = h(:, 3);
    w(w == 0) = eps;
    d = sqrt(sum((h(:, 1:2) ./ w - P2) .^ 2, 2));
end
