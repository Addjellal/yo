function depart = matlibre_depart_puissance(x, y, ordre)
%MATLIBRE_DEPART_PUISSANCE Point de départ d'un ajustement en puissance.
%   D = MATLIBRE_DEPART_PUISSANCE(X,Y,ORDRE) ajuste une droite aux
%   logarithmes des abscisses et des ordonnées positives : le modèle en
%   puissance y devient linéaire.
%
%   Exemple :
%      x = (1:10)';
%      matlibre_depart_puissance(x, 2*x.^1.5, 1)      % 2, 1.5
%
%   Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
    x = x(:);
    y = y(:);
    utiles = x > 0 & y > 0;
    if sum(utiles) >= 2
        droite = polyfit(log(x(utiles)), log(y(utiles)), 1);
        a = exp(droite(2));
        b = droite(1);
    else
        a = 1;
        b = 1;
    end
    if ordre == 1
        depart = [a, b];
    else
        depart = [a, b, 0];
    end
end
