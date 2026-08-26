function [Vx, Vy] = opticalFlowHS(I1, I2, varargin)
%OPTICALFLOWHS Flot optique de Horn et Schunck.
%   [VX,VY] = OPTICALFLOWHS(I1,I2) estime le déplacement de chaque pixel
%   entre deux images. La méthode complète l'équation du flot optique,
%   qui ne donne qu'une contrainte pour deux inconnues, par une hypothèse
%   de régularité : le champ doit varier lentement.
%
%   On minimise
%      somme (Ix u + Iy v + It)^2 + alpha^2 (|grad u|^2 + |grad v|^2)
%   dont les équations d'Euler-Lagrange donnent une itération de
%   Gauss-Seidel où chaque vitesse est ramenée vers la moyenne de ses
%   voisines, corrigée par le résidu de la contrainte.
%
%   À la différence de Lucas et Kanade, qui suppose le flot constant sur
%   un voisinage et laisse indéterminées les zones sans texture, la
%   régularisation propage l'information depuis les bords : le champ est
%   dense partout.
%
%   Options : 'Smoothness' (1, le poids alpha) et 'MaxIteration' (100).
%
%   Exemple :
%      I = zeros(30); I(10:20, 10:20) = 1;
%      J = zeros(30); J(10:20, 12:22) = 1;
%      [vx, vy] = opticalFlowHS(I, J);
%      mean(mean(vx(12:18, 12:18)))   % voisin de 2
%
%   Voir aussi OPTICALFLOWLK.
    regularite = 1;
    iterations = 100;
    for k = 1:2:numel(varargin)-1
        switch lower(char(varargin{k}))
            case 'smoothness',   regularite = double(varargin{k+1});
            case 'maxiteration', iterations = double(varargin{k+1});
        end
    end
    A = enGrisFlot(I1);
    B = enGrisFlot(I2);
    if ~isequal(size(A), size(B))
        error('vision:opticalFlowHS:BadSize', ...
              'Les deux images doivent avoir la même taille.');
    end
    noyauX = [-1 1; -1 1] / 4;
    noyauY = [-1 -1; 1 1] / 4;
    noyauT = ones(2) / 4;
    Ix = imfilter(A, noyauX) + imfilter(B, noyauX);
    Iy = imfilter(A, noyauY) + imfilter(B, noyauY);
    It = imfilter(B, noyauT) - imfilter(A, noyauT);
    Vx = zeros(size(A));
    Vy = zeros(size(A));
    % Moyenne des quatre voisins directs, pondérée comme chez Horn et
    % Schunck : un sixième pour les voisins directs, un douzième pour les
    % diagonaux.
    noyauMoyenne = [1/12 1/6 1/12; 1/6 0 1/6; 1/12 1/6 1/12];
    for k = 1:iterations
        moyenneX = imfilter(Vx, noyauMoyenne);
        moyenneY = imfilter(Vy, noyauMoyenne);
        correction = (Ix .* moyenneX + Iy .* moyenneY + It) ./ ...
                     (regularite ^ 2 + Ix .^ 2 + Iy .^ 2);
        Vx = moyenneX - Ix .* correction;
        Vy = moyenneY - Iy .* correction;
    end
end

function I = enGrisFlot(I)
    I = double(I);
    if ndims(I) == 3
        I = rgb2gray(I);
    end
end
