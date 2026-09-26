function varargout = matlibre_sf_verite(table, varargin)
%MATLIBRE_SF_VERITE Évalue une table de vérité de Stateflow.
%   [S1,S2,...] = MATLIBRE_SF_VERITE(TABLE,E1,E2,...) pose les entrées,
%   évalue chaque condition, prend la première décision dont les
%   conditions s'accordent, fait son action et rend les sorties : c'est la
%   fonction que bâtit SFTRUTHTABLE.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      t = struct('nom', 't', 'entrees', {{'x'}}, 'sorties', {{'y'}}, ...
%                 'conditions', {{'x > 0'}}, 'decisions', 'TF', ...
%                 'actions', {{'y = 1;', 'y = 2;'}});
%      matlibre_sf_verite(t, 5)             % 1
%
%   Voir aussi SFTRUTHTABLE.
    if numel(varargin) ~= numel(table.entrees)
        error('Stateflow:TableDeVeriteArguments', ...
              'La table de verite ''%s'' prend %d argument(s), et en recoit %d.', ...
              table.nom, numel(table.entrees), numel(varargin));
    end
    variables = struct();
    for j = 1:numel(table.entrees)
        variables.(table.entrees{j}) = varargin{j};
    end
    for j = 1:numel(table.sorties)
        variables.(table.sorties{j}) = 0;
    end
    vraies = false(numel(table.conditions), 1);
    for j = 1:numel(table.conditions)
        [~, valeur] = matlibre_sf_evaluer(table.conditions{j}, variables, [], true);
        vraies(j) = logical(valeur);
    end
    for d = 1:size(table.decisions, 2)
        colonne = table.decisions(:, d);
        if all(colonne == '-' | (colonne == 'T' & vraies) | (colonne == 'F' & ~vraies))
            variables = matlibre_sf_evaluer(table.actions{d}, variables, [], false);
            break
        end
    end
    varargout = cell(1, max(1, nargout));
    for j = 1:min(numel(varargout), numel(table.sorties))
        varargout{j} = variables.(table.sorties{j});
    end
end
