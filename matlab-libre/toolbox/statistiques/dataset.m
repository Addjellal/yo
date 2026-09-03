function t = dataset(varargin)
%DATASET Tableau de données, ancienne forme.
%   D = DATASET(X,Y,...) range des colonnes dans un tableau de données.
%   C'est la forme d'avant R2013b, remplacée depuis par TABLE : MatLibre
%   la fabrique donc comme une table, dont elle a toutes les propriétés.
%
%   D = DATASET({X,'nom'},{Y,'autre'}) nomme les variables ; sans nom,
%   elles s'appellent Var1, Var2…
%
%   Exemple :
%      d = dataset({[1;2;3], 'x'}, {[4;5;6], 'y'});
%      d.x
%
%   Voir aussi TABLE, ARRAY2TABLE, STRUCT2TABLE, READTABLE.
    colonnes = {};
    noms = {};
    for k = 1:numel(varargin)
        argument = varargin{k};
        if iscell(argument) && numel(argument) >= 2 && ...
                (ischar(argument{2}) || isstring(argument{2}))
            colonnes{end + 1} = argument{1};             %#ok<AGROW>
            noms{end + 1} = char(argument{2});           %#ok<AGROW>
        elseif iscell(argument) && numel(argument) == 1
            colonnes{end + 1} = argument{1};             %#ok<AGROW>
            noms{end + 1} = sprintf('Var%d', numel(noms) + 1);   %#ok<AGROW>
        else
            colonnes{end + 1} = argument;                %#ok<AGROW>
            noms{end + 1} = sprintf('Var%d', numel(noms) + 1);   %#ok<AGROW>
        end
    end
    if isempty(colonnes)
        t = table();
        return;
    end
    t = table(colonnes{:}, 'VariableNames', noms);
end
