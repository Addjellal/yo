function depart = matlibre_depart_fourier(x, y, ordre)
%MATLIBRE_DEPART_FOURIER Point de départ d'un ajustement de Fourier.
%   D = MATLIBRE_DEPART_FOURIER(X,Y,ORDRE) part de la moyenne pour la
%   constante, de zéro pour les harmoniques, et de la raie spectrale la
%   plus forte pour la pulsation fondamentale — le seul paramètre que la
%   descente ne retrouve pas de loin.
%
%   Exemple :
%      t = (0:0.01:1)';
%      matlibre_depart_fourier(t, cos(2*pi*t), 1)
%
%   Voir aussi FIT, MATLIBRE_DEPART_SINUS.
    x = x(:);
    y = y(:);
    depart = zeros(1, 2 * ordre + 2);
    depart(1) = mean(y);
    pulsations = matlibre_pulsations_dominantes(x, y, 1);
    depart(end) = pulsations(1);
    amplitude = std(y) * sqrt(2);
    for k = 1:ordre
        depart(2 * k) = amplitude / k;
        depart(2 * k + 1) = 0;
    end
end
