function acceleration = longitudinal(force, masse, vitesse, cx, surface, rho, crr, pente)
%LONGITUDINAL Accélération longitudinale avec résistances.
%   A = LONGITUDINAL(FORCE,MASSE,VITESSE,CX,SURFACE,RHO,CRR,PENTE) rend
%   l'accélération, en mètres par seconde carrée, sous une force motrice
%   et contre les trois résistances :
%
%      la traînée      0.5 RHO CX SURFACE V^2, qui croît comme le carré
%      le roulement    CRR MASSE g cos(PENTE), à peu près constant
%      la pente        MASSE g sin(PENTE)
%
%   SURFACE vaut 2,2 m2, RHO 1,225 kg/m3, CRR 0,012 et PENTE zéro par
%   défaut.
%
%   La vitesse maximale est celle où la poussée égale les résistances :
%   on la trouve en cherchant le zéro de cette fonction. Doubler la
%   vitesse quadruple la traînée, d'où le peu qu'on gagne en puissance
%   aux grandes vitesses.
%
%   Une pente de dix pour cent coûte g sin(atan(0,1)), près d'un mètre par
%   seconde carrée : à la portée d'un petit moteur, mais pas négligeable.
%
%   Exemple :
%      longitudinal(0, 1500, 0, 0.3)             % -0.118 : le roulement
%      fzero(@(v) longitudinal(2500, 1500, v, 0.3), [1 200])
%
%   Voir aussi TIREFORCE, GEARRATIOSPEED, BICYCLEMODEL.
    if nargin < 5, surface = 2.2; end
    if nargin < 6, rho = 1.225; end
    if nargin < 7, crr = 0.012; end
    if nargin < 8, pente = 0; end
    g = 9.81;
    trainee = 0.5 * rho * cx * surface * vitesse ^ 2;
    roulement = crr * masse * g * cos(pente);
    gravite = masse * g * sin(pente);
    acceleration = (force - trainee - roulement - gravite) / masse;
end
