function courbe = matlibre_courbe_deplacer(courbe, decalage)
%MATLIBRE_COURBE_DEPLACER Déplace toute la courbe d'un même écart.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    courbe = intenvset(courbe, 'Rates', courbe.Rates + decalage);
end
