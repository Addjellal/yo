function [sysb, valeurs] = sysbal(sys, tolerance)
%SYSBAL Réalisation équilibrée d'un modèle stable.
%   [SYSB,G] = SYSBAL(SYS) rend la réalisation équilibrée de SYS et les
%   valeurs singulières de Hankel. Dans cette base, les deux grammiens
%   sont égaux et diagonaux : chaque état est aussi facile à atteindre
%   qu'à observer, ce qui donne un critère net pour décider lesquels
%   supprimer.
%
%   [SYSB,G] = SYSBAL(SYS,TOL) écarte au passage les états dont la valeur
%   de Hankel est sous TOL : ce sont ceux que la réalisation porte sans
%   qu'ils servent à rien.
%
%   SYSBAL est le nom que la boîte à outils robuste donne à ce que
%   BALREAL fait dans celle de l'automatique. Les deux rendent la même
%   chose ; SYSBAL existe pour les programmes écrits avec l'une ou avec
%   l'autre.
%
%   Exemples :
%      G = ss([-1 0; 0 -100], [1; 1], [1 1], 0);
%      [Gb, g] = sysbal(G);
%      max(max(abs(gram(Gb, 'c') - gram(Gb, 'o'))))   % nul
%      g                                              % la seconde est
%                                                     % beaucoup plus petite
%
%   Voir aussi BALREAL, HSVD, BALANCMR, HANKELMR, SCHURMR, REDUCE.
    [sysb, valeurs] = balreal(sys);
    if nargin >= 2 && ~isempty(tolerance)
        garde = valeurs > tolerance;
        if ~all(garde)
            sysb = modred(sysb, find(~garde), 'del');
            valeurs = valeurs(garde);
        end
    end
end
