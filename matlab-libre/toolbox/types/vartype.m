classdef vartype
%VARTYPE Sélecteur de variables d'une table, par type.
%   S = VARTYPE(TYPE) désigne les variables du type demandé. On s'en sert
%   comme d'un indice de colonne :
%
%      t(:, vartype('numeric'))
%
%   TYPE vaut 'numeric', 'logical', 'cellstr', 'string', 'categorical',
%   'datetime', 'duration', 'char', ou le nom exact d'une classe.
%
%   C'est ce qu'il faut pour appliquer un calcul à toutes les colonnes
%   numériques d'une table qui en contient d'autres.
%
%   Exemple :
%      t = table([1;2], {'a';'b'}, 'VariableNames', {'n','lettre'});
%      width(t(:, vartype('numeric')))   % 1
%
%   Voir aussi TIMERANGE, WITHTOL, VARFUN.
    properties
        Type
    end
    methods
        function v = vartype(type)
            if nargin < 1
                error('MATLAB:vartype:NotEnoughInputs', 'Il faut un type.');
            end
            v.Type = lower(char(type));
        end

        function j = variablesRetenues(v, donnees)
%VARIABLESRETENUES Indices des colonnes dont le type correspond.
            j = [];
            for k = 1:numel(donnees)
                if vartype.correspond(donnees{k}, v.Type)
                    j(end+1) = k;                                %#ok<AGROW>
                end
            end
            j = reshape(j, 1, []);
        end
    end
    methods (Static)
        function oui = correspond(colonne, type)
            switch type
                case 'numeric',     oui = isnumeric(colonne);
                case 'logical',     oui = islogical(colonne);
                case 'cellstr',     oui = iscellstr(colonne);
                case 'string',      oui = isstring(colonne);
                case 'char',        oui = ischar(colonne);
                case 'categorical', oui = isa(colonne, 'categorical');
                case 'datetime',    oui = isa(colonne, 'datetime');
                case 'duration',    oui = isa(colonne, 'duration');
                case 'cell',        oui = iscell(colonne);
                case 'table',       oui = isa(colonne, 'table');
                otherwise,          oui = isa(colonne, type);
            end
        end
    end
end
