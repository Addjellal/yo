function [ordre, o] = matlibre_qam_options(M, arguments, fonction, o)
%MATLIBRE_QAM_OPTIONS Ordre des symboles et options nom-valeur de QAMMOD et QAMDEMOD.
%   [ORDRE,O] = MATLIBRE_QAM_OPTIONS(M,ARGUMENTS,FONCTION,O) vérifie que M
%   est un carré, puissance de deux, lit l'ordre facultatif ('gray' par
%   défaut, 'bin' ou un vecteur personnalisé) puis les paires nom, valeur
%   dont O donne les noms et les valeurs par défaut.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [ordre, o] = matlibre_qam_options(16, {'bin'}, 'qammod', struct('UnitAveragePower', false))
%
%   Voir aussi QAMMOD, QAMDEMOD.
    cote = sqrt(M);
    if ~isscalar(M) || abs(cote - round(cote)) > 1e-9 || abs(log2(M) - round(log2(M))) > 1e-9 ...
            || M < 4
        error(['comm:' fonction ':notSquare'], ...
              'M must be an even power of two (4, 16, 64...): MatLibre does not draw cross constellations.');
    end
    ordre = 'gray';
    if ~isempty(arguments) && (~ischar(arguments{1}) && ~isstring(arguments{1}) ...
                               || any(strcmpi(arguments{1}, {'gray', 'bin'})))
        ordre = arguments{1};
        arguments = arguments(2:end);
    end
    if ~ischar(ordre) && ~isstring(ordre)
        v = ordre(:).';
        if numel(v) ~= M || ~isequal(sort(v), 0:M - 1)
            error(['comm:' fonction ':Ordre'], ...
                  'A custom symbol order must be a permutation of 0 to M-1.');
        end
    end
    noms = fieldnames(o);
    if mod(numel(arguments), 2) ~= 0
        error(['comm:' fonction ':Options'], 'Options must come in name-value pairs.');
    end
    for k = 1:2:numel(arguments)
        trouve = find(strcmpi(arguments{k}, noms), 1);
        if isempty(trouve)
            error(['comm:' fonction ':Option'], '%s has no option ''%s''.', ...
                  fonction, char(string(arguments{k})));
        end
        o.(noms{trouve}) = arguments{k + 1};
    end
end
