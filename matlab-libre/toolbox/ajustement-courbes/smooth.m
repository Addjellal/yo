function lisse = smooth(varargin)
%SMOOTH Lissage d'une suite de données.
%   YY = SMOOTH(Y) lisse par moyenne mobile sur cinq points.
%   YY = SMOOTH(Y,PORTEE) impose la largeur de la fenêtre.
%   YY = SMOOTH(Y,METHODE) ou SMOOTH(Y,PORTEE,METHODE) choisit la
%   méthode : 'moving' (moyenne mobile), 'lowess' (régression locale
%   linéaire), 'loess' (quadratique), 'rlowess' et 'rloess' (les mêmes,
%   rendues robustes aux valeurs aberrantes), 'sgolay' (filtre de
%   Savitzky et Golay).
%   YY = SMOOTH(X,Y,...) tient compte d'abscisses non régulières.
%   YY = SMOOTH(X,Y,PORTEE,'sgolay',DEGRE) impose le degré.
%
%   Pour les méthodes locales, une portée inférieure à un se lit comme
%   une fraction du nombre de points.
%
%   Aux extrémités, la moyenne mobile rétrécit sa fenêtre de façon
%   symétrique plutôt que de déborder : le premier point est rendu tel
%   quel, le deuxième est la moyenne de trois, et ainsi de suite. C'est ce
%   qui évite le biais qu'un remplissage introduirait.
%
%   Exemple :
%      y = [1 2 3 4 5];
%      smooth(y)'      % 1  2  3  4  5, une droite reste une droite
%
%   Voir aussi CSAPS, SPAPS, FIT, MEDFILT1.
    [x, y, portee, methode, degre] = matlibre_smooth_arguments(varargin);
    n = numel(y);
    if n == 0
        lisse = y;
        return
    end
    switch methode
        case 'moving'
            lisse = matlibre_moyenne_mobile(y, portee);
        case {'lowess', 'loess', 'rlowess', 'rloess'}
            robuste = methode(1) == 'r';
            if any(strcmp(methode, {'loess', 'rloess'}))
                ordre = 2;
            else
                ordre = 1;
            end
            fraction = portee;
            if fraction > 1
                fraction = fraction / n;
            end
            lisse = matlibre_lissage_local(x, y, fraction, ordre, robuste);
        case 'sgolay'
            lisse = matlibre_savitzky_golay(y, portee, degre);
        otherwise
            error('curvefit:smooth:Methode', 'Méthode inconnue : %s.', methode);
    end
    lisse = reshape(lisse, size(y));
end
