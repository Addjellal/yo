function v = matlibre_ode_option(options, nom, defaut)
%MATLIBRE_ODE_OPTION Lit une option d'ODESET, ou rend la valeur par défaut.
%   Les structures d'ODESET portent des champs absents quand l'option
%   n'est pas posée, et parfois vides quand elle l'est sans valeur : les
%   deux cas retombent sur le défaut.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_ode_option(struct('RelTol', 1e-8), 'RelTol', 1e-6)
%
%   Voir aussi ODESET, ODEGET, ODE89.
    v = defaut;
    if isstruct(options) && isfield(options, nom) && ~isempty(options.(nom))
        v = double(options.(nom));
    end
end
