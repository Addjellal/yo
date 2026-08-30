function [y, t, x] = initial(systeme, x0, tFinal)
%INITIAL Réponse libre à une condition initiale.
%   [Y,T,X] = INITIAL(SYS,X0) intègre xdot = A*x sans entrée, en partant
%   de l'état X0, et rend la sortie, les instants et la trajectoire de
%   l'état. Sans sortie demandée, la fonction trace la réponse.
%
%   [Y,T,X] = INITIAL(SYS,X0,TFINAL) impose l'horizon.
%
%   Exemples :
%      s = ss(-1, 0, 1, 0);
%      y = initial(s, 1, 5);
%      abs(y(1) - 1) < 1e-9                 % on part bien de x0
%      y(end) < 0.01                        % et l'on decroit en exp(-t)
%
%   Voir aussi STEP, IMPULSE, LSIM, SS.
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
