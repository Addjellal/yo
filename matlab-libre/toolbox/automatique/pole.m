function p = pole(sys)
%POLE Pôles d'un modèle.
%   P = POLE(SYS) rend les pôles : les racines du dénominateur d'une
%   fonction de transfert, les valeurs propres de A pour un modèle
%   d'état. Ils disent la stabilité — partie réelle négative en temps
%   continu, module inférieur à un en discret — et la vitesse.
%
%   Exemples :
%      pole(tf(1, [1 3 2]))                 % -2  -1
%      max(real(pole(feedback(tf(1, [1 1]), 1)))) < 0   % boucle stable
%      abs(pole(ss(-3, 1, 1, 0)) + 3) < 1e-12
%
%   Voir aussi ZERO, PZMAP, DAMP, EIG, ROOTS.
    if strcmp(sys.type, 'ss')
        p = eig(sys.A);
    else
        p = roots(sys.den);
    end
end
