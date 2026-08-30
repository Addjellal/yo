function oui = hasdelay(sys)
%HASDELAY Vrai si le modèle porte un retard.
%   HASDELAY(SYS) dit si le modèle a un retard, en entrée, en sortie ou
%   dans la boucle.
%
%   MatLibre ne représente pas les retards autrement que par leur
%   approximation : la fonction rend donc toujours faux. Pour porter un
%   retard dans un calcul, PADE en donne une fonction de transfert.
%
%   Exemples :
%      hasdelay(tf(1, [1 1]))           % faux
%      hasdelay(ss(-1, 1, 1, 0))        % faux
%
%   Voir aussi PADE, TOTALDELAY, C2D.
    oui = false;
end
