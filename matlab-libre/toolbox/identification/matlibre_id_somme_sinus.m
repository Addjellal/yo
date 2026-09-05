function u = matlibre_id_somme_sinus(N, bande)
%MATLIBRE_ID_SOMME_SINUS Somme de sinusoïdes couvrant une bande.
%   U = MATLIBRE_ID_SOMME_SINUS(N,BANDE) additionne des sinusoïdes de
%   fréquences réparties dans la bande, de phases tirées au hasard.
%
%   Répartir la puissance sur quelques fréquences plutôt que sur tout le
%   spectre donne, à amplitude égale, bien plus d'énergie là où l'on veut
%   connaître le système — c'est l'intérêt d'une entrée sinusoïdale.
%
%   Exemple :
%      u = matlibre_id_somme_sinus(200, [0.1 0.5]);
%
%   Voir aussi IDINPUT.
    nombre = 10;
    fractions = linspace(max(bande(1), 1 / N), bande(2), nombre);
    t = (0:(N - 1)).';
    u = zeros(N, 1);
    for k = 1:nombre
        u = u + sin(pi * fractions(k) * t + 2 * pi * rand());
    end
end
