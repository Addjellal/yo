function v = matlibre_case(tableau, k)
%MATLIBRE_CASE Case K d'un tableau, ou son unique valeur s'il est scalaire.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isempty(tableau)
        v = 0;
    elseif isscalar(tableau)
        v = tableau;
    else
        v = tableau(k);
    end
end
