function p = pivot(t, varargin)
%PIVOT Tableau croisé d'une table.
%   P = PIVOT(T,'Columns',C,'Rows',R) compte les lignes de T pour chaque
%   couple de valeurs des variables R et C : une ligne de P par valeur
%   de R, une colonne par valeur de C.
%
%   P = PIVOT(T,'Columns',C,'Rows',R,'DataVariable',D) agrège la
%   variable D au lieu de compter.
%   PIVOT(...,'Method',M) choisit l'agrégation : 'count' par défaut,
%   'sum', 'mean', 'median', 'max', 'min', ou une fonction.
%   PIVOT(...,'IncludeTotals',true) ajoute une ligne et une colonne de
%   totaux.
%
%   Exemple :
%      t = table({'a';'a';'b'}, [1;2;1], [10;20;30], ...
%                'VariableNames', {'g', 'c', 'v'});
%      pivot(t, 'Rows', 'g', 'Columns', 'c', ...
%            'DataVariable', 'v', 'Method', 'sum')
%
%   Voir aussi GROUPSUMMARY, FINDGROUPS, SPLITAPPLY, UNSTACK.
    colonnes = '';
    lignes = '';
    donnee = '';
    methode = 'count';
    totaux = false;
    k = 1;
    while k + 1 <= numel(varargin)
        switch lower(char(varargin{k}))
            case 'columns'
                colonnes = char(varargin{k+1});
            case 'rows'
                lignes = char(varargin{k+1});
            case 'datavariable'
                donnee = char(varargin{k+1});
            case 'method'
                methode = varargin{k+1};
            case 'includetotals'
                totaux = logical(varargin{k+1});
            otherwise
                error('MATLAB:pivot:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(lignes)
        error('MATLAB:pivot:NoRows', 'pivot attend au moins ''Rows''.');
    end
    valeursLignes = t.(lignes);
    if isempty(colonnes)
        cles = {''};
        indexColonne = ones(height(t), 1);
    else
        [indexColonne, cles] = numeroter(t.(colonnes));
    end
    [indexLigne, etiquettes] = numeroter(valeursLignes);
    nl = numel(etiquettes);
    nc = numel(cles);
    resultat = zeros(nl, nc);
    if ~isempty(donnee)
        valeurs = t.(donnee);
    else
        valeurs = ones(height(t), 1);
    end
    for i = 1:nl
        for j = 1:nc
            choix = (indexLigne == i) & (indexColonne == j);
            resultat(i, j) = agreger(valeurs(choix), methode);
        end
    end
    if totaux
        resultat(:, end+1) = sommeParDefaut(resultat, 2, methode);
        resultat(end+1, :) = sommeParDefaut(resultat, 1, methode);
        etiquettes{end+1} = 'Total';
        cles{end+1} = 'Total';
    end
    noms = cell(1, nc + double(totaux));
    for j = 1:numel(noms)
        noms{j} = genvarname(nomColonne(cles{j}), noms(1:j-1));
    end
    donneesTable = cell(1, numel(noms) + 1);
    donneesTable{1} = etiquettes(:);
    for j = 1:numel(noms)
        donneesTable{j+1} = resultat(:, j);
    end
    p = table(donneesTable{:}, 'VariableNames', [{lignes}, noms]);
end

function n = nomColonne(cle)
    if isempty(cle)
        n = 'Valeur';
    else
        n = ['x' char(cle)];
        if isvarname(char(cle))
            n = char(cle);
        end
    end
end

function [index, etiquettes] = numeroter(v)
% Les valeurs distinctes, dans l'ordre croissant, et le rang de chacune.
    if iscell(v)
        textes = cellfun(@(x) char(string(x)), v(:), 'UniformOutput', false);
    elseif isstring(v) || iscategorical(v)
        textes = cellstr(v(:));
    else
        textes = cell(numel(v), 1);
        for k = 1:numel(v)
            textes{k} = sprintf('%.17g', double(v(k)));
        end
    end
    [distinctes, ~, index] = unique(textes);
    etiquettes = distinctes(:);
    if isnumeric(v)
        for k = 1:numel(etiquettes)
            etiquettes{k} = sprintf('%g', str2double(etiquettes{k}));
        end
    end
    index = index(:);
end

function r = agreger(v, methode)
    if isempty(v)
        r = 0;
        return;
    end
    if isa(methode, 'function_handle')
        r = methode(v);
        return;
    end
    switch lower(char(methode))
        case 'count',  r = numel(v);
        case 'sum',    r = sum(v);
        case 'mean',   r = mean(v);
        case 'median', r = median(v);
        case 'max',    r = max(v);
        case 'min',    r = min(v);
        otherwise
            error('MATLAB:pivot:Method', 'Méthode inconnue : %s.', char(methode));
    end
end

function s = sommeParDefaut(m, dimension, methode)
% Le total d'une ligne ou d'une colonne : une somme, sauf quand
% l'agrégation est une moyenne, auquel cas la moyenne a un sens.
    if ischar(methode) && strcmpi(methode, 'mean')
        s = mean(m, dimension);
    else
        s = sum(m, dimension);
    end
end
