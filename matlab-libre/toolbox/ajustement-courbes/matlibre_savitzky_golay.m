function lisse = matlibre_savitzky_golay(y, portee, degre)
%MATLIBRE_SAVITZKY_GOLAY Lissage par polynôme local de degré donné.
%   L = MATLIBRE_SAVITZKY_GOLAY(Y,PORTEE,DEGRE) ajuste un polynôme aux
%   points de chaque fenêtre et en garde la valeur au centre. Contrairement
%   à la moyenne mobile, il conserve les extremums et la largeur des pics :
%   un polynôme de degré deux suit une courbure, là où une moyenne
%   l'aplatit.
%
%   Aux extrémités, c'est le polynôme ajusté à la première — ou dernière —
%   fenêtre complète qui est évalué, ce qui évite de rétrécir la fenêtre
%   et de perdre le degré.
%
%   Exemple :
%      y = (1:9)'.^2;
%      max(abs(matlibre_savitzky_golay(y, 5, 2) - y)) < 1e-10      % vrai
%
%   Voir aussi SMOOTH.
    y = y(:);
    n = numel(y);
    portee = round(portee);
    if mod(portee, 2) == 0
        portee = portee + 1;
    end
    portee = min(max(portee, degre + 1), n);
    if mod(portee, 2) == 0
        portee = portee - 1;
    end
    demi = (portee - 1) / 2;
    lisse = y;
    positions = (-demi:demi).';
    A = matlibre_base_polynome(positions, degre);
    inverse = pinv(A);
    for k = 1:n
        centre = min(max(k, demi + 1), n - demi);
        fenetre = y((centre - demi):(centre + demi));
        coefficients = inverse * fenetre;
        lisse(k) = polyval(coefficients, k - centre);
    end
end
