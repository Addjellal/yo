function [rotationnel, angulaire] = curl(varargin)
%CURL Rotationnel d'un champ de vecteurs plan.
%   Z = CURL(X,Y,U,V) rend la composante du rotationnel perpendiculaire
%   au plan : dV/dx - dU/dy. Elle mesure combien le champ tourne :
%   positive dans le sens direct, négative dans l'autre, nulle pour un
%   champ qui dérive d'un potentiel.
%
%   Z = CURL(U,V) prend une grille entière pour X et Y.
%
%   [Z,AV] = CURL(...) rend en outre la vitesse angulaire, qui vaut la
%   moitié du rotationnel.
%
%   Exemples :
%      [X, Y] = meshgrid(-2:0.2:2);
%      curl(X, Y, -Y, X);               % 2 partout : le champ tournant
%      max(max(abs(curl(X, Y, X, Y))))  % nul : le champ radial derive
%                                       % d'un potentiel
%
%   Voir aussi DIVERGENCE, GRADIENT, DEL2, QUIVER.
    if numel(varargin) >= 4
        X = varargin{1};
        Y = varargin{2};
        U = varargin{3};
        V = varargin{4};
    elseif numel(varargin) == 2
        U = varargin{1};
        V = varargin{2};
        [X, Y] = meshgrid(1:size(U, 2), 1:size(U, 1));
    else
        error('MATLAB:curl:NotEnoughInputs', 'Not enough input arguments.');
    end
    hx = X(1, :);
    hy = Y(:, 1);
    dvdx = gradient(V, hx, hy);
    [~, dudy] = gradient(U, hx, hy);
    rotationnel = dvdx - dudy;
    angulaire = rotationnel / 2;
end
