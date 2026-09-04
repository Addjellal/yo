function [u, v] = opticalFlowFarneback(I1, I2, varargin)
%OPTICALFLOWFARNEBACK Flot optique par expansion polynomiale.
%   [U,V] = OPTICALFLOWFARNEBACK(I1,I2) rend le déplacement estimé en
%   chaque pixel entre les deux images. La méthode approche le voisinage
%   de chaque pixel par un polynôme du second degré : deux images qui ne
%   diffèrent que d'un déplacement ont des polynômes liés par
%
%      A d = (b1 - b2) / 2
%
%   où A est la partie quadratique et b la partie linéaire. Le système est
%   résolu sur un voisinage, ce qui le rend inversible même là où l'image
%   n'a de structure que dans une direction.
%
%   Contrairement à Lucas-Kanade, la méthode part d'une pyramide : le
%   déplacement est d'abord estimé sur une image réduite, puis affiné à
%   chaque agrandissement. Elle attrape ainsi des déplacements de
%   plusieurs pixels.
%
%   Options et valeurs par défaut :
%     'NumPyramidLevels'  3
%     'PyramidScale'      0.5, le rapport d'un niveau au suivant
%     'NumIterations'     3, par niveau
%     'NeighborhoodSize'  5, la fenêtre de l'ajustement polynomial
%     'FilterSize'        15, la fenêtre où le système est moyenné
%
%   Exemple :
%      rng(1);
%      A = imfilter(rand(60, 60), fspecial('gaussian', 9, 2));
%      B = matlibre_deplacer_image(A, -3 * ones(60), zeros(60));
%      [u, v] = opticalFlowFarneback(A, B);
%      median(median(u(20:40, 20:40)))    % environ 3
%
%   Voir aussi OPTICALFLOWLK, OPTICALFLOWHS, MATLIBRE_EXPANSION_POLYNOMIALE.
    niveaux = 3;
    rapport = 0.5;
    iterations = 3;
    voisinage = 5;
    lissage = 15;
    for k = 1:2:numel(varargin) - 1
        switch lower(char(varargin{k}))
            case 'numpyramidlevels', niveaux = max(1, round(double(varargin{k + 1})));
            case 'pyramidscale',     rapport = double(varargin{k + 1});
            case 'numiterations',    iterations = max(1, round(double(varargin{k + 1})));
            case 'neighborhoodsize', voisinage = round(double(varargin{k + 1}));
            case 'filtersize',       lissage = round(double(varargin{k + 1}));
            otherwise
                error('vision:opticalFlowFarneback:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
    end
    A = enNiveaux(I1);
    B = enNiveaux(I2);
    if ~isequal(size(A), size(B))
        error('vision:opticalFlowFarneback:Taille', ...
              'Les deux images doivent avoir la même taille.');
    end
    % La pyramide se construit du plus fin au plus grossier ; le calcul la
    % remonte ensuite dans l'autre sens.
    pyramideA = {A};
    pyramideB = {B};
    for k = 2:niveaux
        precedent = pyramideA{k - 1};
        if min(size(precedent)) * rapport < 2 * voisinage
            break
        end
        pyramideA{k} = imresize(precedent, rapport);
        pyramideB{k} = imresize(pyramideB{k - 1}, rapport);
    end
    u = zeros(size(pyramideA{end}));
    v = zeros(size(pyramideA{end}));
    for niveau = numel(pyramideA):-1:1
        courantA = pyramideA{niveau};
        courantB = pyramideB{niveau};
        if ~isequal(size(u), size(courantA))
            facteur = size(courantA, 2) / size(u, 2);
            u = imresize(u, size(courantA)) * facteur;
            v = imresize(v, size(courantA)) * (size(courantA, 1) / size(v, 1));
        end
        for tour = 1:iterations
            recalee = matlibre_deplacer_image(courantB, u, v);
            [du, dv] = residuFarneback(courantA, recalee, voisinage, lissage);
            u = u + du;
            v = v + dv;
        end
    end
end

function [du, dv] = residuFarneback(A, B, voisinage, lissage)
% Le déplacement résiduel entre deux images déjà presque superposées.
    [b1a, b2a, a11a, a22a, a12a] = matlibre_expansion_polynomiale(A, voisinage);
    [b1b, b2b, a11b, a22b, a12b] = matlibre_expansion_polynomiale(B, voisinage);
    a11 = (a11a + a11b) / 2;
    a22 = (a22a + a22b) / 2;
    a12 = (a12a + a12b) / 2;
    d1 = (b1a - b1b) / 2;
    d2 = (b2a - b2b) / 2;
    % Système normal de la moindre carrée A d = d, moyenné sur une
    % fenêtre : c'est ce moyennage qui rend le problème bien posé le long
    % d'un contour, où A seule est singulière.
    m11 = a11 .^ 2 + a12 .^ 2;
    m12 = a11 .* a12 + a12 .* a22;
    m22 = a12 .^ 2 + a22 .^ 2;
    q1 = a11 .* d1 + a12 .* d2;
    q2 = a12 .* d1 + a22 .* d2;
    noyau = fspecial('gaussian', max(3, lissage), max(1, lissage / 6));
    m11 = imfilter(m11, noyau, 'replicate');
    m12 = imfilter(m12, noyau, 'replicate');
    m22 = imfilter(m22, noyau, 'replicate');
    q1 = imfilter(q1, noyau, 'replicate');
    q2 = imfilter(q2, noyau, 'replicate');
    % Une petite quantité sur la diagonale évite la division par zéro là
    % où l'image est plate et où aucun déplacement n'est observable.
    regularisation = 1e-6 * max(1, mean(m11(:) + m22(:)));
    m11 = m11 + regularisation;
    m22 = m22 + regularisation;
    determinant = m11 .* m22 - m12 .^ 2;
    du = (m22 .* q1 - m12 .* q2) ./ determinant;
    dv = (m11 .* q2 - m12 .* q1) ./ determinant;
end

function J = enNiveaux(I)
    J = double(I);
    if ndims(J) == 3
        J = rgb2gray(J);
    end
end
