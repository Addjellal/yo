function [y, t, x] = initial(systeme, x0, tFinal)
%INITIAL Réponse libre d'un système d'état à une condition initiale.
%   [Y,T,X] = INITIAL(SYS,X0,TFINAL) intègre xdot = A x sans entrée.
%
%   Exemple :
%      s = ss(-1, 0, 1, 0);
%      y = initial(s, 1, 5);   % y(1) == 1, décroissance en exp(-t)
    if nargin < 3 || isempty(tFinal), tFinal = 10; end
    a = systeme.A;
    c = systeme.C;
    n = size(a, 1);
    pas = tFinal / 500;
    t = (0:pas:tFinal)';
    x = zeros(numel(t), n);
    etat = x0(:);
    for k = 1:numel(t)
        x(k, :) = etat';
        % Exponentielle de matrice sur un pas : exact pour un système
        % linéaire à temps continu, sans erreur d'intégration.
        etat = expm(a * pas) * etat;
    end
    y = (c * x')';
end
