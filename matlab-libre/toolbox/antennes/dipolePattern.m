function E = dipolePattern(theta, longueurOnde)
%DIPOLEPATTERN Diagramme de rayonnement d'un dipôle de longueur L/lambda.
%   E = DIPOLEPATTERN(THETA,L) où THETA est en radians et L la longueur
%   rapportée à la longueur d'onde (0.5 pour un demi-onde).
%
%   Le diagramme est nul dans l'axe du fil et maximal
%   perpendiculairement : rien ne part dans la direction où l'on regarde
%   le fil par le bout, ce qui est une conséquence directe du rayonnement
%   d'un élément de courant.
%
%   Le demi-onde ouvre à 78 degrés à mi-puissance et a une directivité de
%   1,64, soit 2,15 dBi : ces deux nombres du cours se retrouvent en
%   passant le diagramme à BEAMWIDTH et DIRECTIVITY.
%
%   Allonger le dipôle resserre le faisceau et augmente la directivité,
%   jusqu'à une longueur d'onde environ ; au-delà, des lobes secondaires
%   apparaissent et lui reprennent de la puissance. Un dipôle très court
%   tend vers le doublet élémentaire, de directivité 1,5.
%
%   Exemple :
%      theta = linspace(1e-6, pi - 1e-6, 20001);
%      E = dipolePattern(theta, 0.5);
%      rad2deg(beamwidth(theta, E / max(E)))       % 78 degres
%      directivity(theta, E / max(E))              % 1.64
%
%   Voir aussi DIRECTIVITY, BEAMWIDTH, ARRAYFACTOR, FRIIS.
    if nargin < 2
        longueurOnde = 0.5;
    end
    kl = pi * longueurOnde;
    E = zeros(size(theta));
    for k = 1:numel(theta)
        s = sin(theta(k));
        if abs(s) < 1e-12
            E(k) = 0;
        else
            E(k) = abs((cos(kl * cos(theta(k))) - cos(kl)) / s);
        end
    end
end
