function c = matlibre_cellule(valeur)
%MATLIBRE_CELLULE Range une liste de coefficients en tableau de cellules.
%   Un vecteur numérique devient une cellule par élément ; un tableau de
%   cellules passe tel quel.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if iscell(valeur)
        c = valeur(:).';
    elseif isempty(valeur)
        c = {};
    else
        c = num2cell(double(valeur(:)).');
    end
end
