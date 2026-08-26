function [R, m] = signalMatriceCorrelation(x, p, estCorrelation)
%SIGNALMATRICECORRELATION Matrice d'autocorrélation pour les méthodes sous-espace.
%   Si le premier argument est déjà une matrice de corrélation carrée, on
%   la prend telle quelle. Sinon on l'estime par la méthode de la
%   covariance modifiée, avant et arrière, sur une fenêtre d'ordre
%   suffisant pour laisser un sous-espace bruit non vide.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin >= 3 && estCorrelation
        R = double(x);
        m = size(R, 1);
        return
    end
    x = double(x(:));
    n = numel(x);
    m = max(p + 1, min(2 * p, floor(n / 2)));
    m = min(m, n - 1);
    X = corrmtx(x, m - 1, 'modified');
    R = X' * X;
end
