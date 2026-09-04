function v = matlibre_case_risque(tableau, k)
%MATLIBRE_CASE_RISQUE Case K d'un vecteur, ou son unique valeur.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isscalar(tableau)
        v = tableau;
    else
        v = tableau(k);
    end
end
