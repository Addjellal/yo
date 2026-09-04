function depart = matlibre_depart_sinus(x, y, ordre)
%MATLIBRE_DEPART_SINUS Point de départ d'un ajustement de sinusoïdes.
%   D = MATLIBRE_DEPART_SINUS(X,Y,ORDRE) tire la pulsation du contenu
%   fréquentiel des données — la raie la plus forte du spectre —, et
%   l'amplitude de leur écart type.
%
%   La pulsation est le paramètre dont l'ajustement dépend le plus : partie
%   de trop loin, la descente tombe dans un minimum local à une fréquence
%   voisine. La lire dans le spectre évite ce piège.
%
%   Exemple :
%      t = (0:0.01:1)';
%      matlibre_depart_sinus(t, sin(2*pi*3*t), 1)
%
%   Voir aussi FIT, MATLIBRE_DEPART_FOURIER.
    x = x(:);
    y = y(:);
    pulsations = matlibre_pulsations_dominantes(x, y, ordre);
    depart = zeros(1, 3 * ordre);
    amplitude = std(y) * sqrt(2);
    for k = 1:ordre
        depart(3 * k - 2) = amplitude / k;
        depart(3 * k - 1) = pulsations(k);
        depart(3 * k) = 0;
    end
end
