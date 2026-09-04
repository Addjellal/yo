function valeurs = matlibre_khi_deux(degres, nombre)
%MATLIBRE_KHI_DEUX Tirages d'une loi du khi-deux.
%   Pour un nombre entier de degrés de liberté, la somme des carrés
%   d'autant de normales réduites est exactement un khi-deux, et coûte
%   moins qu'un appel à la loi gamma.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if abs(degres - round(degres)) < 1e-12 && degres >= 1 && degres <= 200
        valeurs = sum(randn(nombre, round(degres)) .^ 2, 2);
    else
        valeurs = chi2rnd(degres, nombre, 1);
    end
end
