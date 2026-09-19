function sys = matlibre_sans_retard(sys, quoi)
%MATLIBRE_SANS_RETARD Refuse un modèle retardé, en le nommant.
%   SYS = MATLIBRE_SANS_RETARD(SYS,QUOI) rend le modèle tel quel s'il ne
%   porte aucun retard, et échoue sinon en disant quel calcul ne sait pas
%   le porter.
%
%   Un retard pur n'est pas une fraction rationnelle : il n'a pas de
%   réalisation d'état de dimension finie, et un retour d'état calculé
%   sur (A,B,C,D) ignorerait le temps qu'il faut au signal pour arriver.
%   Le laisser passer donnerait un correcteur qui a l'air réglé et ne
%   l'est pas ; PADE en donne une approximation rationnelle, qui passe
%   alors partout.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sans_retard(tf(1, [1 1]), 'LQR');   % passe : aucun retard
%
%   Voir aussi HASDELAY, TOTALDELAY, PADE, THIRAN.
    if ~hasdelay(sys)
        return
    end
    d = totaldelay(sys);
    error('Control:ltiobject:delayNotSupported', ...
          ['%s ne sait pas porter un retard : le modele en porte un de %g. ' ...
           'PADE en donne une approximation rationnelle -- par exemple ' ...
           'PADE(SYS,2) --, qui se calcule partout.'], upper(char(quoi)), max(d(:)));
end
