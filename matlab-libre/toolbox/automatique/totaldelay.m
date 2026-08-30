function d = totaldelay(sys)
%TOTALDELAY Retard total de chaque voie d'un modèle.
%   D = TOTALDELAY(SYS) rend la matrice des retards, une valeur par couple
%   entrée-sortie.
%
%   MatLibre ne représente pas les retards : la matrice est nulle. PADE
%   donne l'approximation d'un retard sous forme de transmittance.
%
%   Exemples :
%      totaldelay(tf(1, [1 1]))         % 0
%      isequal(size(totaldelay(ss(zeros(2), zeros(2), zeros(2), zeros(2)))), [2 2])
%
%   Voir aussi HASDELAY, PADE.
    sys = ss(sys);
    [ny, nu] = size(sys);
    d = zeros(ny, nu);
end
