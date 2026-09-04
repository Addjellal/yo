function lisse = matlibre_moyenne_mobile(y, portee)
%MATLIBRE_MOYENNE_MOBILE Moyenne mobile à fenêtre rétrécie aux bords.
%   L = MATLIBRE_MOYENNE_MOBILE(Y,PORTEE) moyenne sur une fenêtre
%   centrée. Près des extrémités, la fenêtre rétrécit symétriquement au
%   lieu de déborder : le premier point est rendu tel quel. Un
%   remplissage, ou une fenêtre décentrée, biaiserait les bords.
%
%   Exemple :
%      matlibre_moyenne_mobile([1 2 3 4 5]', 3)'      % 1 2 3 4 5
%
%   Voir aussi SMOOTH.
    y = y(:);
    n = numel(y);
    portee = round(portee);
    if mod(portee, 2) == 0
        portee = portee - 1;
    end
    portee = max(portee, 1);
    demi = (portee - 1) / 2;
    lisse = zeros(n, 1);
    for k = 1:n
        rayon = min([demi, k - 1, n - k]);
        lisse(k) = mean(y((k - rayon):(k + rayon)));
    end
end
