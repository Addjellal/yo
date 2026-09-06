function s = vswr(g)
%VSWR Taux d'ondes stationnaires à partir du coefficient de réflexion.
%   S = VSWR(G) rend (1 + |G|) / (1 - |G|), le rapport du maximum au
%   minimum de la tension le long de la ligne.
%
%   Le TOS vaut un quand rien ne revient, et croît sans borne quand tout
%   revient. C'est le même renseignement que le module du coefficient de
%   réflexion, sur une échelle que les appareils de mesure affichent.
%
%   Il ne distingue pas la nature du désaccord : cent ohms et vingt-cinq
%   sur une ligne de cinquante donnent le même deux, l'un par excès,
%   l'autre par défaut.
%
%   Exemple :
%      vswr(0)                         % 1 : adaptee
%      vswr(1/3)                       % 2
%      vswr(z2gamma(100)) == vswr(z2gamma(25))    % true
%
%   Voir aussi Z2GAMMA, GAMMA2Z.
    m = abs(g);
    s = (1 + m) ./ (1 - m);
end
