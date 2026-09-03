function v = matlibre_gf_valeurs(a)
%MATLIBRE_GF_VALEURS Les valeurs entières d'un tableau de corps.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isa(a, 'gf')
        v = a.x;
    else
        v = round(double(a));
    end
end
