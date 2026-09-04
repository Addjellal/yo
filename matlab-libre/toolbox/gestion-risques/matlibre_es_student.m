function valeur = matlibre_es_student(p, degres)
%MATLIBRE_ES_STUDENT Perte moyenne au-delà du quantile d'une loi de Student.
%   La forme fermée existe : elle fait intervenir la densité au quantile
%   et un facteur qui tend vers un quand le nombre de degrés de liberté
%   grandit, ramenant la formule au cas gaussien.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    q = tinv(p, degres);
    densite = gamma((degres + 1) / 2) / (sqrt(degres * pi) * gamma(degres / 2)) * ...
              (1 + q ^ 2 / degres) ^ (-(degres + 1) / 2);
    valeur = -densite / p * (degres + q ^ 2) / (degres - 1);
end
