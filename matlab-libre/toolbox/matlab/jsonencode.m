function texte = jsonencode(v, varargin)
%JSONENCODE Écrit une valeur MATLAB en JSON.
%   T = JSONENCODE(V) rend le texte JSON de V : une structure devient un
%   objet, un tableau de cellules un tableau, une matrice un tableau de
%   tableaux, du texte une chaîne, [] la valeur null.
%
%   JSONENCODE(V,'PrettyPrint',true) met en forme sur plusieurs lignes.
%
%   Exemple :
%      jsonencode(struct('a', 1, 'b', 'deux'))
%
%   Voir aussi JSONDECODE, WEBWRITE.
    joli = false;
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'PrettyPrint')
            joli = logical(varargin{k+1});
        end
    end
    texte = ecrire(v, joli, 0);
end

function t = ecrire(v, joli, niveau)
    if isstruct(v)
        if numel(v) ~= 1
            morceaux = cell(1, numel(v));
            for k = 1:numel(v)
                morceaux{k} = ecrire(v(k), joli, niveau + 1);
            end
            t = enveloppe(morceaux, '[', ']', joli, niveau);
            return;
        end
        noms = fieldnames(v);
        morceaux = cell(1, numel(noms));
        for k = 1:numel(noms)
            morceaux{k} = [chaine(noms{k}) ':' espace(joli) ...
                           ecrire(v.(noms{k}), joli, niveau + 1)];
        end
        t = enveloppe(morceaux, '{', '}', joli, niveau);
        return;
    end
    if iscell(v)
        morceaux = cell(1, numel(v));
        for k = 1:numel(v)
            morceaux{k} = ecrire(v{k}, joli, niveau + 1);
        end
        t = enveloppe(morceaux, '[', ']', joli, niveau);
        return;
    end
    if ischar(v)
        t = chaine(v);
        return;
    end
    if isstring(v)
        if isscalar(v)
            t = chaine(char(v));
        else
            morceaux = cell(1, numel(v));
            for k = 1:numel(v)
                morceaux{k} = chaine(char(v(k)));
            end
            t = enveloppe(morceaux, '[', ']', joli, niveau);
        end
        return;
    end
    if islogical(v) || isnumeric(v)
        if isempty(v)
            t = '[]';
            return;
        end
        if isscalar(v)
            t = nombre(v, islogical(v));
            return;
        end
        if isvector(v)
            morceaux = cell(1, numel(v));
            for k = 1:numel(v)
                morceaux{k} = nombre(v(k), islogical(v));
            end
            t = enveloppe(morceaux, '[', ']', joli, niveau);
            return;
        end
        morceaux = cell(1, size(v, 1));
        for i = 1:size(v, 1)
            morceaux{i} = ecrire(v(i, :), joli, niveau + 1);
        end
        t = enveloppe(morceaux, '[', ']', joli, niveau);
        return;
    end
    t = chaine(char(string(v)));
end

function t = enveloppe(morceaux, ouvrant, fermant, joli, niveau)
    if isempty(morceaux)
        t = [ouvrant fermant];
        return;
    end
    if ~joli
        t = [ouvrant strjoin(morceaux, ',') fermant];
        return;
    end
    marge = repmat('  ', 1, niveau + 1);
    fin = repmat('  ', 1, niveau);
    t = [ouvrant sprintf('\n') marge ...
         strjoin(morceaux, [',' sprintf('\n') marge]) sprintf('\n') fin fermant];
end

function e = espace(joli)
    if joli
        e = ' ';
    else
        e = '';
    end
end

function t = nombre(x, booleen)
    if booleen
        if x
            t = 'true';
        else
            t = 'false';
        end
        return;
    end
    x = double(x);
    if isnan(x) || isinf(x)
        t = 'null';
    elseif x == fix(x) && abs(x) < 1e15
        t = sprintf('%d', x);
    else
        t = sprintf('%.15g', x);
    end
end

function t = chaine(s)
    sortie = '"';
    for k = 1:numel(s)
        c = s(k);
        switch c
            case '"',  sortie = [sortie '\"'];   %#ok<AGROW>
            case '\',  sortie = [sortie '\\'];   %#ok<AGROW>
            otherwise
                if double(c) < 32
                    switch double(c)
                        case 10, sortie = [sortie '\n'];   %#ok<AGROW>
                        case 9,  sortie = [sortie '\t'];   %#ok<AGROW>
                        case 13, sortie = [sortie '\r'];   %#ok<AGROW>
                        otherwise
                            sortie = [sortie sprintf('\\u%04X', double(c))];   %#ok<AGROW>
                    end
                else
                    sortie = [sortie c];   %#ok<AGROW>
                end
        end
    end
    t = [sortie '"'];
end
