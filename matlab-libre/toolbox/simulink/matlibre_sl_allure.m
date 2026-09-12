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
        case 'deadzone'
            % La bande morte : plat au centre, deux pentes aux bouts.
            line([x - a, x - a/3, x + a/3, x + a], [y - b, y, y, y + b], ...
                 'Color', couleur);
        case 'quantizer'
            % Un escalier : trois marches suffisent à le dire.
            line([x - a, x - a/3, x - a/3, x + a/3, x + a/3, x + a], ...
                 [y - b, y - b, y, y, y + b, y + b], 'Color', couleur);
        case 'sign'
            line([x - a, x - a/8, x - a/8, x + a/8, x + a/8, x + a], ...
                 [y - b, y - b, y, y, y + b, y + b], 'Color', couleur);
        case 'ratelimiter'
            % La pente est bornée : le trait ne monte jamais plus vite
            % qu'une droite, quoi que fasse l'entrée.
            line([x - a, x, x + a], [y - b, y + b, y + b], 'Color', couleur);
            line([x - a, x + a], [y - b, y + b * 1.1], 'Color', couleur, ...
                 'LineStyle', ':');
        case 'zoh'
            % Une tenue d'ordre zéro : des paliers.
            line([x - a, x - a/3, x - a/3, x + a/3, x + a/3, x + a], ...
                 [y - b, y - b, y + b/2, y + b/2, y - b/2, y - b/2], 'Color', couleur);
        case {'lookup', 'lookup1d'}
            line([x - a, x - a/3, x + a/4, x + a], [y - b, y + b/3, y - b/4, y + b], ...
                 'Color', couleur);
        case 'transportdelay'
            % Le même motif, deux fois, décalé : c'est ce que fait le bloc.
            line([x - a, x - a/2, x - a/2, x], [y + b/4, y + b/4, y + b, y + b], ...
                 'Color', couleur);
            line([x - a/4, x + a/4, x + a/4, x + a], ...
                 [y - b, y - b, y - b/4, y - b/4], 'Color', couleur, 'LineStyle', ':');
        otherwise
            trace = false;
    end
end
