function oui = hasdelay(sys)
%HASDELAY Vrai si le modèle porte un retard.
%   HASDELAY(SYS) dit si le modèle a un retard, en entrée, en sortie ou
%   sur un couple entrée-sortie.
%
%   Un modèle retardé se trace et se répond exactement : la réponse
%   fréquentielle porte e^(-jwD), la réponse temporelle est décalée. Les
%   calculs qui ne savent pas porter un retard — réalisation d'état,
%   synthèse par retour d'état, lieu des racines — le refusent en le
%   nommant, plutôt que de l'oublier. PADE en donne une approximation
%   rationnelle, qui passe alors partout.
%
%   Exemples :
%      hasdelay(tf(1, [1 1]))           % faux
%      g = tf(1, [1 1]); g.InputDelay = 0.5;
%      hasdelay(g)                      % vrai
%
%   Voir aussi TOTALDELAY, PADE, C2D, MATLIBRE_SANS_RETARD.
    oui = any(totaldelay(sys)(:) ~= 0);
end
