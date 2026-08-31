function D = divergence(varargin)
%DIVERGENCE Divergence d'un champ de vecteurs.
%   D = DIVERGENCE(X,Y,U,V) rend la divergence du champ (U,V) défini aux
%   points (X,Y) : la somme des dérivées partielles dU/dx et dV/dy. Elle
%   mesure ce qui sort d'un petit volume : positive là où le champ jaillit,
%   négative là où il converge, nulle pour un champ incompressible.
%
%   D = DIVERGENCE(U,V) prend une grille entière pour X et Y.
%
%   Exemples :
%      [X, Y] = meshgrid(-2:0.2:2);
%      divergence(X, Y, X, Y);          % 2 partout : le champ radial
%      max(max(abs(divergence(X, Y, -Y, X))))   % nul : le champ tournant
%
%   Voir aussi GRADIENT, CURL, DEL2, QUIVER.
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
        error('MATLAB:divergence:NotEnoughInputs', 'Not enough input arguments.');
    end
    hx = X(1, :);
    hy = Y(:, 1);
    dudx = gradient(U, hx, hy);
    [~, dvdy] = gradient(V, hx, hy);
    D = dudx + dvdy;
end
