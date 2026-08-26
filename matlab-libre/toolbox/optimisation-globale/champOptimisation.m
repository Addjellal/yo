function valeur = champOptimisation(options, nom, defaut)
%CHAMPOPTIMISATION Lit une option, ou rend la valeur par défaut.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    valeur = defaut;
    if isstruct(options) && isfield(options, nom) && ~isempty(options.(nom))
        valeur = options.(nom);
    end
end
