function correspondance = validatestring(chaine, options, varargin)
%VALIDATESTRING Complète une option textuelle parmi une liste.
%   S = VALIDATESTRING(CHAINE,OPTIONS) rend l'élément de OPTIONS dont
%   CHAINE est un préfixe, sans distinction de casse. Une erreur est levée
%   si aucun ou plusieurs éléments correspondent.
    chaine = lower(strtrim(char(chaine)));
    trouves = {};
    for k = 1:numel(options)
        candidat = char(options{k});
        if strncmpi(candidat, chaine, numel(chaine))
            trouves{end+1} = candidat;
        end
    end
    if isempty(trouves)
        error('MATLAB:unrecognizedStringChoice', ...
              'Expected input to match one of these values:\n\n%s', ...
              strjoin(options, ', '));
    end
    if numel(trouves) > 1
        exact = {};
        for k = 1:numel(trouves)
            if strcmpi(trouves{k}, chaine)
                exact{end+1} = trouves{k};
            end
        end
        if numel(exact) == 1
            correspondance = exact{1};
            return;
        end
        error('MATLAB:ambiguousStringChoice', ...
              'The input matched more than one valid value.');
    end
    correspondance = trouves{1};
end
