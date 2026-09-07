function valeur = champOptimisation(options, nom, defaut)
%CHAMPOPTIMISATION Lit une option, ou rend la valeur par défaut.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      champOptimisation(struct('PopulationSize', 30), 'PopulationSize', 50)     % 30
%      champOptimisation(struct(), 'PopulationSize', 50)                        % 50
%
%   Voir aussi GAOPTIMSET, SAOPTIMSET, PSOPTIMSET.
    valeur = defaut;
    if isstruct(options) && isfield(options, nom) && ~isempty(options.(nom))
        valeur = options.(nom);
    end
end
