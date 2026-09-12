function trace = matlibre_sl_allure(bloc, x, y, largeur, hauteur)
%MATLIBRE_SL_ALLURE Dessine dans le bloc l'allure de ce qu'il produit.
%   TRACE = MATLIBRE_SL_ALLURE(BLOC,X,Y,L,H) trace la petite courbe qui
%   figure la fonction du bloc — l'échelon, la rampe, la sinusoïde, la
%   saturation — et rend vrai si elle a été tracée.
%
%   Un dessin dit d'un coup ce qu'un nom demande de lire. Les blocs sans
%   allure connue rendent faux, et c'est alors leur étiquette qui parle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      figure;
%      matlibre_sl_allure(struct('type', 'step'), 0, 0, 1.7, 1)   % 1
%
%   Voir aussi MATLIBRE_SL_FORME, MATLIBRE_SL_ETIQUETTE.
    trace = true;
    a = largeur * 0.32;
    b = hauteur * 0.28;
    couleur = [0.15 0.15 0.15];
    switch bloc.type
        case 'step'
            line([x - a, x, x, x + a], [y - b, y - b, y + b, y + b], 'Color', couleur);
        case 'ramp'
            line([x - a, x, x + a], [y - b, y - b, y + b], 'Color', couleur);
        case 'sine'
            t = linspace(-pi, pi, 40);
            line(x + a * t / pi, y + b * sin(t), 'Color', couleur);
        case 'saturation'
            line([x - a, x - a/2, x + a/2, x + a], [y - b, y - b, y + b, y + b], ...
                 'Color', couleur);
        case 'relay'
            line([x - a, x, x, x + a], [y - b, y - b, y + b, y + b], 'Color', couleur);
            line([x - a, x - a/3, x - a/3], [y + b, y + b, y - b], 'Color', couleur);
        case 'scope'
            line([x - a, x - a, x + a], [y + b, y - b, y - b], 'Color', couleur);
            t = linspace(0, 1, 20);
            line(x - a + 2 * a * t, y - b + 1.6 * b * t .^ 2, 'Color', couleur);
        otherwise
            trace = false;
    end
end
