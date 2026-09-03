function b = standardizeMissing(a, indicateurs, varargin)
%STANDARDIZEMISSING Remplace des valeurs par la marque de manquant.
%   B = STANDARDIZEMISSING(A,IND) remplace par la valeur manquante
%   propre au type — NaN, '', <undefined>, NaT — toutes les valeurs
%   énumérées dans IND. C'est le pas à faire avant RMMISSING quand un
%   fichier code l'absence par -99 ou par 'N/A'.
%
%   STANDARDIZEMISSING(T,IND,'DataVariables',V) ne touche, dans une
%   table, que les variables nommées.
%
%   Exemple :
%      standardizeMissing([1 2 -99], -99)    % [1 2 NaN]
%
%   Voir aussi ISMISSING, RMMISSING, FILLMISSING.
    variables = [];
    k = 1;
    while k <= numel(varargin)
        if strcmpi(char(varargin{k}), 'datavariables') && k < numel(varargin)
            variables = varargin{k+1};
            k = k + 2;
        else
            error('standardizeMissing:Option', ...
                  'Option inconnue : %s.', char(varargin{k}));
        end
    end
    if istable(a) || istimetable(a)
        b = a;
        noms = b.Properties.VariableNames;
        if isempty(variables)
            regardees = noms;
        elseif ischar(variables)
            regardees = {variables};
        else
            regardees = cellstr(variables);
        end
        for j = 1:numel(regardees)
            b.(regardees{j}) = standardizeMissing(b.(regardees{j}), indicateurs);
        end
        return;
    end
    marque = ismissing(a, indicateurs);
    b = a;
    if isnumeric(b)
        b(marque) = NaN;
    elseif iscell(b)
        for k = find(marque(:)')
            b{k} = '';
        end
    elseif isstring(b)
        b(marque) = "";
    elseif ischar(b)
        b(marque) = ' ';
    else
        for k = find(marque(:)')
            b(k) = missingDe(b);
        end
    end
end

function m = missingDe(b)
% La marque de manquant du type, quand il n'y a pas d'affectation
% directe : une date sans date, une catégorie sans catégorie.
    if isdatetime(b)
        m = NaT;
    elseif iscategorical(b)
        m = categorical(missingTexte());
    else
        m = NaN;
    end
end

function t = missingTexte()
    t = {''};
end
