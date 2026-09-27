classdef NumericType < embedded.numerictype
%NUMERICTYPE Un type de données de Simulink : ce que rend FIXDT.
%   T = SIMULINK.NUMERICTYPE rend le type par défaut de NUMERICTYPE ; ses
%   propriétés sont celles de NUMERICTYPE — DataTypeMode, Signedness,
%   WordLength, FractionLength, Slope, Bias... —, plus IsAlias,
%   DataScope, HeaderFile et Description, qui ne servent qu'au code
%   produit.
%
%   Rangé sous un nom dans l'espace de travail, il se donne aux blocs par
%   ce nom : OutDataTypeStr = 'T'.
%
%   Exemple :
%      T = fixdt(1, 16, 8);
%      class(T)                       % 'Simulink.NumericType'
%      fi(pi, T)                      % 3.1406
%
%   Voir aussi FIXDT, NUMERICTYPE, FI.
    properties
        IsAlias = false
        DataScope = 'Auto'
        HeaderFile = ''
        Description = ''
    end
    methods
        function T = NumericType(varargin)
            T@embedded.numerictype(varargin{:});
        end
        function disp(T)
            L = matlibre_fixe_type('lignes', T);
            valeurs = L(:, 2);
            for i = 1:numel(valeurs)
                if any(strcmp(L{i, 1}, {'DataTypeMode', 'Signedness'}))
                    valeurs{i} = ['''' valeurs{i} ''''];
                end
            end
            L = [L(:, 1), valeurs; {'IsAlias', sprintf('%d', T.IsAlias); ...
                                    'DataScope', ['''' T.DataScope '''']; ...
                                    'HeaderFile', ['''' T.HeaderFile '''']; ...
                                    'Description', ['''' T.Description '''']}];
            fprintf('  NumericType with properties:\n\n');
            largeur = max(cellfun(@numel, L(:, 1)));
            for i = 1:size(L, 1)
                fprintf('    %*s: %s\n', largeur, L{i, 1}, L{i, 2});
            end
        end
    end
end
