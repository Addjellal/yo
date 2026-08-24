function [F, valides, statut] = estimateFundamentalMatrix(points1, points2, varargin)
%ESTIMATEFUNDAMENTALMATRIX Matrice fondamentale d'une paire d'images.
%   F = ESTIMATEFUNDAMENTALMATRIX(P1,P2) rend la matrice qui lie deux vues
%   d'une même scène : pour tout couple de points correspondants,
%
%      [x2 y2 1] * F * [x1 y1 1]' = 0
%
%   F est de rang deux, ce qui est imposé explicitement : la troisième
%   valeur singulière est mise à zéro. Sans cela, les droites épipolaires
%   ne concourraient pas.
%
%   L'algorithme est celui des huit points normalisé de Hartley : les
%   points sont d'abord centrés et mis à l'échelle pour que leur distance
%   moyenne à l'origine vaille racine de deux. Sans cette normalisation,
%   le système est mal conditionné et le résultat sans valeur.
%
%   [F,VALIDES,STATUT] = ESTIMATEFUNDAMENTALMATRIX(...,'Method',M) où M
%   vaut 'Norm8Point' (défaut), 'RANSAC' ou 'MSAC' ; les deux derniers
%   écartent les appariements aberrants et rendent leur masque. Options
%   'DistanceThreshold' (0.01) et 'NumTrials' (500). Le seuil est une
%   distance symétrique aux droites épipolaires, en pixels : à la
%   différence de l'erreur de Sampson, elle ne dépend pas de l'échelle
%   choisie pour F.
%
%   Exemple :
%      F = estimateFundamentalMatrix(p1, p2);
%      max(abs(sum(([p2 ones(n,1)] * F) .* [p1 ones(n,1)], 2)))   % petit
%
%   Voir aussi EPIPOLARLINE, TRIANGULATE, ESTIMATEGEOMETRICTRANSFORM.
    methode = 'norm8point';
    seuil = 0.01;
    tirages = 500;
    for k = 1:2:numel(varargin)-1
        switch lower(char(varargin{k}))
            case 'method',            methode = lower(char(varargin{k+1}));
            case 'distancethreshold', seuil = double(varargin{k+1});
            case 'numtrials',         tirages = double(varargin{k+1});
        end
    end
    P1 = double(points1);
    P2 = double(points2);
    n = size(P1, 1);
    if n < 8
        error('vision:estimateFundamentalMatrix:TooFewPoints', ...
              'Il faut au moins huit correspondances.');
    end
    statut = 0;
    switch methode
        case {'ransac', 'msac'}
            [F, valides] = estimerRobuste(P1, P2, seuil, tirages, strcmp(methode, 'msac'));
            if sum(valides) < 8
                statut = 1;
            end
        otherwise
            F = huitPointsNormalise(P1, P2);
            valides = true(n, 1);
    end
end

function F = huitPointsNormalise(P1, P2)
    [Q1, T1] = normaliser(P1);
    [Q2, T2] = normaliser(P2);
    n = size(Q1, 1);
    A = zeros(n, 9);
    for k = 1:n
        x1 = Q1(k, 1); y1 = Q1(k, 2);
        x2 = Q2(k, 1); y2 = Q2(k, 2);
        A(k, :) = [x2*x1, x2*y1, x2, y2*x1, y2*y1, y2, x1, y1, 1];
    end
    [~, ~, V] = svd(A);
    F = reshape(V(:, end), 3, 3)';
    % Rang deux imposé.
    [U, S, W] = svd(F);
    S(3, 3) = 0;
    F = U * S * W';
    F = T2' * F * T1;
    % Normalisation par la norme de Frobenius, et non par F(3,3) : ce
    % coefficient peut être minuscule, et diviser par lui gonflerait la
    % matrice au point de rendre indistinguables un bon et un mauvais
    % ajustement — l'erreur de Sampson, qui divise par le gradient,
    % tomberait à zéro pour tout le monde.
    normeF = norm(F, 'fro');
    if normeF > 0
        F = F / normeF;
    end
    % Signe déterministe : F est définie au signe près.
    [~, plusGrand] = max(abs(F(:)));
    if F(plusGrand) < 0
        F = -F;
    end
end

function [Q, T] = normaliser(P)
%NORMALISER Centre les points et met leur distance moyenne à sqrt(2).
    centre = mean(P, 1);
    centres = P - repmat(centre, size(P, 1), 1);
    distanceMoyenne = mean(sqrt(sum(centres .^ 2, 2)));
    if distanceMoyenne < eps
        echelle = 1;
    else
        echelle = sqrt(2) / distanceMoyenne;
    end
    Q = centres * echelle;
    T = [echelle, 0, -echelle * centre(1);
         0, echelle, -echelle * centre(2);
         0, 0, 1];
end

function [F, valides] = estimerRobuste(P1, P2, seuil, tirages, msac)
    n = size(P1, 1);
    meilleurCout = Inf;
    F = huitPointsNormalise(P1, P2);
    valides = true(n, 1);
    for essai = 1:tirages
        indices = randperm(n, 8);
        candidat = huitPointsNormalise(P1(indices, :), P2(indices, :));
        distances = distancesEpipolaires(candidat, P1, P2);
        if msac
            cout = sum(min(distances, seuil));
        else
            cout = sum(distances > seuil);
        end
        if cout < meilleurCout
            meilleurCout = cout;
            F = candidat;
            valides = distances <= seuil;
        end
    end
    if sum(valides) >= 8
        F = huitPointsNormalise(P1(valides, :), P2(valides, :));
    end
end

function d = distancesEpipolaires(F, P1, P2)
%DISTANCESEPIPOLAIRES Distance symétrique aux droites épipolaires, en
%   pixels : chaque point est comparé à la droite que son correspondant
%   engendre, dans les deux sens. Contrairement à l'erreur de Sampson,
%   cette mesure ne change pas si l'on multiplie F par un scalaire, ce qui
%   la rend utilisable comme critère de rejet.
    n = size(P1, 1);
    X1 = [P1, ones(n, 1)]';
    X2 = [P2, ones(n, 1)]';
    Fx1 = F * X1;
    Ftx2 = F' * X2;
    numerateur = abs(sum(X2 .* Fx1, 1));
    normeDeux = sqrt(Fx1(1, :) .^ 2 + Fx1(2, :) .^ 2);
    normeUn = sqrt(Ftx2(1, :) .^ 2 + Ftx2(2, :) .^ 2);
    d = (numerateur ./ max(normeDeux, eps) + numerateur ./ max(normeUn, eps))' / 2;
end
