function code = matlibre_gf_primitif(m)
%MATLIBRE_GF_PRIMITIF Polynôme primitif par défaut, sous forme d'entier.
%   L'entier porte les coefficients en binaire, poids fort en tête : le
%   polynôme 1+x+x^3 vaut donc 11.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    coefficients = gfprimdf(m, 2);
    % gfprimdf range par puissances croissantes ; l'entier les lit dans
    % l'autre sens.
    code = 0;
    for k = numel(coefficients):-1:1
        code = code * 2 + coefficients(k);
    end
end
