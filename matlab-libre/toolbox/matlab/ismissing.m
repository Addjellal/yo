function tf = ismissing(a, indicateurs)
%ISMISSING Repère les valeurs manquantes.
%   TF = ISMISSING(A) rend un tableau de booléens marquant les valeurs
%   absentes : NaN pour un nombre, '' pour une cellule de texte, la
%   chaîne manquante pour un tableau de chaînes, <undefined> pour une
%   catégorie, NaT pour une date.
%
%   TF = ISMISSING(A,IND) traite en outre comme manquantes les valeurs
%   énumérées dans IND.
%
%   Pour une table, TF a une colonne par variable.
%
%   Exemple :
%      ismissing([1 NaN 3])          % [false true false]
%      ismissing([1 2 -99], -99)     % [false false true]
%
%   Voir aussi RMMISSING, STANDARDIZEMISSING, ISNAN, ISNAT.
    if nargin < 2
        indicateurs = [];
    end
    if istable(a) || istimetable(a)
        noms = a.Properties.VariableNames;
        tf = false(height(a), numel(noms));
        for k = 1:numel(noms)
            colonne = a.(noms{k});
            marque = ismissing(colonne, indicateurs);
            if size(marque, 2) > 1
                marque = any(marque, 2);
            end
            tf(:, k) = marque;
        end
        return;
    end
    tf = manquantes(a);
    if ~isempty(indicateurs)
        tf = tf | correspond(a, indicateurs);
    end
end

function tf = manquantes(a)
    if isnumeric(a)
        tf = isnan(double(a));
    elseif isdatetime(a) || isduration(a)
        tf = isnat(a);
    elseif iscategorical(a)
        tf = isundefined(a);
    elseif isstring(a)
        tf = strlength(a) == 0;
    elseif iscell(a)
        tf = false(size(a));
        for k = 1:numel(a)
            v = a{k};
            tf(k) = (ischar(v) && isempty(v)) || (isstring(v) && strlength(v) == 0);
        end
    elseif ischar(a)
        tf = (a == ' ');
    else
        tf = false(size(a));
    end
end

function tf = correspond(a, indicateurs)
% Les valeurs déclarées manquantes par l'appelant.
    if ~iscell(indicateurs) && ~isstring(indicateurs) && isnumeric(a)
        tf = false(size(a));
        for k = 1:numel(indicateurs)
            tf = tf | (a == indicateurs(k));
        end
        return;
    end
    if ischar(indicateurs)
        indicateurs = {indicateurs};
    end
    tf = false(size(a));
    for k = 1:numel(a)
        if iscell(a)
            v = a{k};
        else
            v = a(k);
        end
        for j = 1:numel(indicateurs)
            if iscell(indicateurs)
                w = indicateurs{j};
            else
                w = indicateurs(j);
            end
            if isequal(char(string(v)), char(string(w)))
                tf(k) = true;
            end
        end
    end
end
