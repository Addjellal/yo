function [entrees, options] = matlibre_par_options(arguments_, reconnues)
%MATLIBRE_PAR_OPTIONS Sépare les entrées des options nommées.
%   [ENTREES,OPTIONS] = MATLIBRE_PAR_OPTIONS(ARGUMENTS,RECONNUES) retire
%   des arguments les paires nom-valeur dont le nom figure dans RECONNUES,
%   et rend une structure à deux champs : uniforme et gestionnaire.
%
%   Une option ne se reconnaît qu'en fin de liste et suivie d'une valeur :
%   une cellule de chaînes passée comme donnée ne doit pas être prise pour
%   un nom d'option.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    entrees = arguments_;
    options = struct('uniforme', true, 'gestionnaire', []);
    k = 1;
    while k <= numel(entrees)
        estNom = (ischar(entrees{k}) || isstring(entrees{k})) && ...
                 k < numel(entrees) && ...
                 any(strcmpi(char(entrees{k}), reconnues));
        if estNom
            switch lower(char(entrees{k}))
                case 'uniformoutput'
                    options.uniforme = logical(entrees{k + 1});
                case 'errorhandler'
                    options.gestionnaire = entrees{k + 1};
            end
            entrees(k:k + 1) = [];
        else
            k = k + 1;
        end
    end
    if isempty(entrees)
        error('parallel:options:SansEntree', ...
              'Il faut au moins un tableau a parcourir.');
    end
end
