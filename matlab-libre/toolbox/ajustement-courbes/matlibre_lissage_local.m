function lisse = matlibre_lissage_local(x, y, fraction, ordre, robuste)
%MATLIBRE_LISSAGE_LOCAL Régression locale pondérée, éventuellement robuste.
%   L = MATLIBRE_LISSAGE_LOCAL(X,Y,FRACTION,ORDRE,ROBUSTE) ajuste, autour
%   de chaque point, un polynôme aux voisins pondérés par la tricube de
%   leur distance.
%
%   La variante robuste recommence en pondérant à la baisse les points que
%   le premier passage a laissés loin : cinq tours suffisent à écarter les
%   valeurs aberrantes sans déformer le reste.
%
%   Exemple :
%      x = (1:20)';
%      matlibre_lissage_local(x, x, 0.5, 1, false);      % la droite elle-meme
%
%   Voir aussi SMOOTH, MATLIBRE_REGRESSION_LOCALE.
    x = x(:);
    y = y(:);
    lisse = matlibre_regression_locale(x, y, x, fraction, ordre);
    if ~robuste
        return
    end
    for tour = 1:5
        residus = y - lisse;
        echelle = median(abs(residus - median(residus))) / 0.6745;
        if echelle < eps
            break
        end
        u = residus / (6 * echelle);
        poids = (1 - min(abs(u), 1) .^ 2) .^ 2;
        lisse = matlibre_regression_locale_ponderee(x, y, x, fraction, ordre, poids);
    end
end
