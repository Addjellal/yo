function [morceaux, separateurs] = split(texte, separateur, dimension)
%SPLIT Découpe du texte en morceaux.
%   C = SPLIT(S) découpe S aux espaces.
%   C = SPLIT(S,SEP) découpe au séparateur donné ; SEP peut être un
%   tableau de séparateurs, tous reconnus.
%   C = SPLIT(S,SEP,DIM) range les morceaux suivant la dimension DIM.
%
%   [C,SEP] = SPLIT(...) rend en outre les séparateurs rencontrés.
%
%   La sortie est un tableau de chaînes quand l'entrée en est un, et un
%   tableau de cellules sinon. Toutes les entrées doivent donner le même
%   nombre de morceaux, comme dans MATLAB.
%
%   Exemples :
%      split('a,b,c', ',')
%      split(string({'a-b'; 'c-d'}), '-')
%
%   Voir aussi STRSPLIT, JOIN, SPLITLINES, STRTRIM, EXTRACTBEFORE.
    if nargin < 2 || isempty(separateur)
        separateur = {' '};
    end
    if ischar(separateur) || isstring(separateur)
        separateur = cellstr(separateur);
    end
    separateur = cellfun(@char, separateur(:)', 'UniformOutput', false);
    sortieChaine = isstring(texte);
    if ischar(texte)
        entrees = {texte};
        forme = [1 1];
    elseif isstring(texte)
        entrees = cell(1, numel(texte));
        for k = 1:numel(texte)
            entrees{k} = char(texte(k));
        end
        forme = size(texte);
    elseif iscell(texte)
        entrees = cellfun(@char, texte(:)', 'UniformOutput', false);
        forme = size(texte);
    else
        error('MATLAB:split:BadInput', 'split attend du texte.');
    end
    decoupes = cell(1, numel(entrees));
    trouves = cell(1, numel(entrees));
    largeur = 0;
    for k = 1:numel(entrees)
        [decoupes{k}, trouves{k}] = decouper(entrees{k}, separateur);
        if k == 1
            largeur = numel(decoupes{k});
        elseif numel(decoupes{k}) ~= largeur
            error('MATLAB:string:MustHaveSameNumberOfPieces', ...
                  'Chaque élément doit donner le même nombre de morceaux.');
        end
    end
    if nargin < 3 || isempty(dimension)
        if numel(entrees) == 1
            dimension = 1;
        else
            dimension = 2;
        end
    end
    morceaux = rangerMorceaux(decoupes, forme, largeur, dimension, numel(entrees));
    if sortieChaine
        morceaux = string(morceaux);
    end
    if nargout > 1
        separateurs = rangerMorceaux(trouves, forme, max(largeur - 1, 0), ...
                                     dimension, numel(entrees));
        if sortieChaine
            separateurs = string(separateurs);
        end
    end
end

function r = rangerMorceaux(decoupes, forme, largeur, dimension, n)
% Un seul texte donne une colonne ; plusieurs donnent une ligne par
% texte, les morceaux en colonnes — c'est le rangement de MATLAB.
    if n == 1
        r = decoupes{1}(:);
        if dimension == 2
            r = r';
        end
        return;
    end
    r = cell(n, largeur);
    for k = 1:n
        for j = 1:largeur
            r{k, j} = decoupes{k}{j};
        end
    end
    if numel(forme) == 2 && forme(1) == 1 && dimension == 2
        % Une ligne de textes reste une ligne : les morceaux s'ajoutent
        % en colonnes.
    elseif dimension == 1
        r = r';
    end
end

function [morceaux, trouves] = decouper(t, separateurs)
    morceaux = {};
    trouves = {};
    courant = '';
    k = 1;
    while k <= numel(t)
        pris = '';
        for s = 1:numel(separateurs)
            sep = separateurs{s};
            n = numel(sep);
            if n > 0 && k + n - 1 <= numel(t) && strcmp(t(k:k+n-1), sep)
                if numel(sep) > numel(pris)
                    pris = sep;
                end
            end
        end
        if ~isempty(pris)
            morceaux{end+1} = courant;   %#ok<AGROW>
            trouves{end+1} = pris;       %#ok<AGROW>
            courant = '';
            k = k + numel(pris);
        else
            courant(end+1) = t(k);       %#ok<AGROW>
            k = k + 1;
        end
    end
    morceaux{end+1} = courant;
end
