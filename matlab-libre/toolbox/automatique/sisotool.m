function sisotool(sys, C)
%SISOTOOL Analyse d'une boucle à une entrée et une sortie.
%   SISOTOOL(SYS) trace ensemble le lieu des racines, le diagramme de
%   Bode et la réponse indicielle en boucle fermée : les trois vues qui
%   servent à régler un correcteur.
%   SISOTOOL(SYS,C) place le correcteur C dans la boucle.
%
%   MATLAB ouvre une application où l'on déplace les pôles et les zéros
%   du correcteur à la souris. MatLibre n'a pas d'application
%   interactive : il montre les mêmes vues, calculées une fois.
%
%   Exemple :
%      sisotool(tf(1, [1 3 3 1]));
%
%   Voir aussi RLOCUS, BODE, STEP, MARGIN, PIDTOOL.
    if nargin < 2 || isempty(C)
        C = tf(1, 1);
    end
    ouverte = C * sys;
    fermee = feedback(ouverte, 1);
    subplot(2, 2, 1);
    rlocus(ouverte);
    title('Lieu des racines');
    subplot(2, 2, 2);
    bode(ouverte);
    title('Boucle ouverte');
    subplot(2, 2, [3 4]);
    step(fermee);
    [gain, phase] = margin(ouverte);
    title(sprintf('Boucle fermée — marge de gain %.3g, de phase %.1f degrés', gain, phase));
end
