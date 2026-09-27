function r = matlibre_fixe_arrondir(x, methode)
%MATLIBRE_FIXE_ARRONDIR Arrondit comme Fixed-Point Designer.
%   R = MATLIBRE_FIXE_ARRONDIR(X,METHODE) : Nearest arrondit au plus proche,
%   les milieux vers +Inf ; Round de même, les milieux loin de zéro ;
%   Convergent de même, les milieux vers le pair ; Floor vers -Inf,
%   Ceiling vers +Inf, Zero vers zéro.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi FIMATH.
    switch methode
        case 'Nearest'
            r = floor(x + 0.5);
        case 'Round'
            r = round(x);
        case 'Convergent'
            r = floor(x);
            d = x - r;
            r = r + (d > 0.5) + (d == 0.5 & mod(r, 2) == 1);
        case 'Floor'
            r = floor(x);
        case 'Ceiling'
            r = ceil(x);
        otherwise
            r = fix(x);
    end
end
