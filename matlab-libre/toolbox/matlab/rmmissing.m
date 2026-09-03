function [b, marque] = rmmissing(a, varargin)
%RMMISSING Retire les valeurs manquantes.
%   B = RMMISSING(A) retire d'un vecteur les valeurs manquantes, et
%   d'une matrice ou d'une table les lignes qui en contiennent une.
%
%   B = RMMISSING(A,DIM) travaille suivant la dimension DIM : 2 retire
%   les colonnes.
%
%   RMMISSING(...,'MinNumMissing',N) ne retire une ligne que si elle
%   compte au moins N valeurs manquantes.
%   RMMISSING(...,'DataVariables',V) ne regarde, dans une table, que les
%   variables nommées.
%
%   [B,MARQUE] = RMMISSING(A) rend en outre les positions retirées.
%
%   Exemple :
%      rmmissing([1 NaN 3])          % [1 3]
%
%   Voir aussi ISMISSING, STANDARDIZEMISSING, FILLMISSING, RMOUTLIERS.
    dimension = [];
    minimum = 1;
    variables = [];
    k = 1;
    if ~isempty(varargin) && isnumeric(varargin{1})
        dimension = double(varargin{1});
        k = 2;
    end
    while k <= numel(varargin)
        if k + 1 > numel(varargin)
            error('rmmissing:Paire', 'Option sans valeur : %s.', char(varargin{k}));
        end
        switch lower(char(varargin{k}))
            case 'minnummissing'
                minimum = double(varargin{k+1});
            case 'datavariables'
                variables = varargin{k+1};
            otherwise
                error('rmmissing:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    estTable = istable(a) || istimetable(a);
    if estTable
        noms = a.Properties.VariableNames;
        if isempty(variables)
            regardees = noms;
        elseif ischar(variables)
            regardees = {variables};
        else
            regardees = cellstr(variables);
        end
        manque = false(height(a), 1);
        compte = zeros(height(a), 1);
        for j = 1:numel(regardees)
            colonne = ismissing(a.(regardees{j}));
            if size(colonne, 2) > 1
                colonne = any(colonne, 2);
            end
            compte = compte + double(colonne);
        end
        marque = compte >= minimum;
        b = a(~marque, :);
        return;
    end
    tf = ismissing(a);
    if isvector(a) && isempty(dimension)
        marque = tf(:);
        if isrow(a)
            b = a(~marque');
        else
            b = a(~marque);
        end
        return;
    end
    if isempty(dimension)
        dimension = 1;
    end
    if dimension == 1
        compte = sum(tf, 2);
        marque = compte >= minimum;
        b = a(~marque, :);
    else
        compte = sum(tf, 1);
        marque = compte >= minimum;
        b = a(:, ~marque);
    end
    marque = marque(:);
end
