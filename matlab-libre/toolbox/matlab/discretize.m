function [bins, bords] = discretize(x, repartition, varargin)
%DISCRETIZE Range des valeurs dans des classes.
%   BINS = DISCRETIZE(X,BORDS) rend, pour chaque valeur de X, le numéro
%   de la classe qui la contient : BINS(i) vaut j quand BORDS(j) <= X(i)
%   < BORDS(j+1). La dernière classe est fermée des deux côtés. Une
%   valeur hors des bords donne NaN.
%
%   BINS = DISCRETIZE(X,N) découpe l'étendue de X en N classes égales.
%
%   BINS = DISCRETIZE(X,BORDS,VALEURS) rend la valeur associée à la
%   classe au lieu de son numéro ; VALEURS peut être un tableau de
%   cellules de noms.
%
%   DISCRETIZE(...,'IncludedEdge','right') ferme les classes à droite.
%   DISCRETIZE(...,'categorical',NOMS) rend un tableau catégoriel.
%
%   [BINS,BORDS] = DISCRETIZE(...) rend aussi les bords employés.
%
%   Exemple :
%      discretize([1 2 3 4 5], [1 3 5])    % [1 1 2 2 2]
%
%   Voir aussi HISTCOUNTS, HISTOGRAM, INTERP1, CATEGORICAL.
    valeurs = [];
    categoriel = false;
    droite = false;
    k = 1;
    if ~isempty(varargin) && ~estOption(varargin{1})
        valeurs = varargin{1};
        k = 2;
    end
    while k <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'includededge'
                droite = strcmpi(char(varargin{k+1}), 'right');
                k = k + 2;
            case 'categorical'
                categoriel = true;
                if k < numel(varargin)
                    valeurs = varargin{k+1};
                    k = k + 2;
                else
                    k = k + 1;
                end
            otherwise
                error('discretize:Option', 'Option inconnue : %s.', nom);
        end
    end
    x = double(x);
    if isscalar(repartition)
        n = double(repartition);
        bas = min(x(:));
        haut = max(x(:));
        if isempty(bas) || ~isfinite(bas)
            bas = 0;
            haut = 1;
        elseif bas == haut
            bas = bas - 0.5;
            haut = haut + 0.5;
        end
        bords = linspace(bas, haut, n + 1);
    else
        bords = double(repartition(:))';
    end
    if numel(bords) < 2
        error('discretize:Bords', 'Il faut au moins deux bords.');
    end
    bins = NaN(size(x));
    n = numel(bords) - 1;
    for i = 1:numel(x)
        v = x(i);
        if isnan(v)
            continue;
        end
        j = trouver(v, bords, droite);
        if j >= 1 && j <= n
            bins(i) = j;
        end
    end
    if categoriel
        if isempty(valeurs)
            valeurs = cell(1, n);
            for j = 1:n
                valeurs{j} = sprintf('[%g, %g)', bords(j), bords(j+1));
            end
        end
        noms = cell(size(bins));
        for i = 1:numel(bins)
            if isnan(bins(i))
                noms{i} = '';
            else
                noms{i} = char(valeurs{bins(i)});
            end
        end
        bins = categorical(noms);
    elseif ~isempty(valeurs)
        sortie = valeurs;
        if iscell(valeurs)
            resultat = cell(size(bins));
            for i = 1:numel(bins)
                if isnan(bins(i))
                    resultat{i} = '';
                else
                    resultat{i} = valeurs{bins(i)};
                end
            end
            bins = resultat;
        else
            resultat = NaN(size(bins));
            for i = 1:numel(bins)
                if ~isnan(bins(i))
                    resultat(i) = sortie(bins(i));
                end
            end
            bins = resultat;
        end
    end
end

function tf = estOption(v)
    tf = (ischar(v) || isstring(v)) && ...
         any(strcmpi(char(v), {'IncludedEdge', 'categorical'}));
end

function j = trouver(v, bords, droite)
% La classe qui contient V. Le bord extrême du côté fermé appartient à
% la dernière classe de ce côté.
    n = numel(bords) - 1;
    j = 0;
    if droite
        if v <= bords(1)
            if v == bords(1)
                j = 1;
            end
            return;
        end
        for k = 1:n
            if v <= bords(k+1)
                j = k;
                return;
            end
        end
    else
        if v > bords(end)
            return;
        end
        if v == bords(end)
            j = n;
            return;
        end
        for k = 1:n
            if v >= bords(k) && v < bords(k+1)
                j = k;
                return;
            end
        end
    end
end
