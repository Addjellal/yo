function depart = matlibre_depart_exponentielle(x, y, ordre)
%MATLIBRE_DEPART_EXPONENTIELLE Point de départ d'un ajustement exponentiel.
%   D = MATLIBRE_DEPART_EXPONENTIELLE(X,Y,ORDRE) ajuste une droite au
%   logarithme des ordonnées positives : le modèle exponentiel y devient
%   linéaire, et sa solution est un départ déjà proche.
%
%   Exemple :
%      x = (0:0.1:2)';
%      matlibre_depart_exponentielle(x, 3*exp(-0.5*x), 1)      % 3, -0.5
%
%   Voir aussi FIT, MATLIBRE_MODELE_BIBLIOTHEQUE.
    x = x(:);
    y = y(:);
    positifs = y > 0;
    if sum(positifs) >= 2
        droite = polyfit(x(positifs), log(y(positifs)), 1);
        a = exp(droite(2));
        b = droite(1);
    else
        a = max(abs(y));
        b = -1;
    end
    if ordre == 1
        depart = [a, b];
    else
        % Deux exponentielles : on part d'une décomposition en une partie
        % rapide et une partie lente, sinon les deux termes se
        % confondent et le problème devient indéterminé.
        depart = [a, b, a / 2, b * 3];
    end
end
