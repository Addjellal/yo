function v = jsondecode(texte)
%JSONDECODE Lit du JSON et rend la valeur MATLAB correspondante.
%   V = JSONDECODE(TEXTE) traduit un document JSON :
%      un objet        devient une structure ;
%      un tableau      devient une matrice colonne s'il ne porte que des
%                      nombres de même forme, un tableau de cellules
%                      sinon ;
%      une chaîne      devient du texte ;
%      true, false     deviennent des booléens ;
%      null            devient [].
%
%   Les noms de champs qui ne sont pas des noms de variables valides sont
%   corrigés comme le fait MATLAB, par GENVARNAME.
%
%   Exemple :
%      s = jsondecode('{"nom":"a","valeurs":[1,2,3]}');
%      s.valeurs(2)      % 2
%
%   Voir aussi JSONENCODE, WEBREAD, READSTRUCT.
    texte = char(texte);
    position = 1;
    [v, position] = lireValeur(texte, sauterBlancs(texte, position));
    position = sauterBlancs(texte, position);
    if position <= numel(texte)
        error('MATLAB:json:ExpectedEOF', ...
              'Texte en trop après la valeur JSON, à la position %d.', position);
    end
end

function p = sauterBlancs(t, p)
    while p <= numel(t) && any(t(p) == [' ', sprintf('\t'), sprintf('\n'), sprintf('\r')])
        p = p + 1;
    end
end

function [v, p] = lireValeur(t, p)
    if p > numel(t)
        error('MATLAB:json:UnexpectedEOF', 'Document JSON incomplet.');
    end
    switch t(p)
        case '{'
            [v, p] = lireObjet(t, p);
        case '['
            [v, p] = lireTableau(t, p);
        case '"'
            [v, p] = lireChaine(t, p);
        otherwise
            if strncmp(t(p:end), 'true', 4)
                v = true;
                p = p + 4;
            elseif strncmp(t(p:end), 'false', 5)
                v = false;
                p = p + 5;
            elseif strncmp(t(p:end), 'null', 4)
                v = [];
                p = p + 4;
            else
                [v, p] = lireNombre(t, p);
            end
    end
end

function [s, p] = lireObjet(t, p)
    s = struct();
    p = sauterBlancs(t, p + 1);
    if p <= numel(t) && t(p) == '}'
        p = p + 1;
        return;
    end
    while true
        p = sauterBlancs(t, p);
        if p > numel(t) || t(p) ~= '"'
            error('MATLAB:json:ExpectedName', ...
                  'Nom de champ attendu à la position %d.', p);
        end
        [nom, p] = lireChaine(t, p);
        p = sauterBlancs(t, p);
        if p > numel(t) || t(p) ~= ':'
            error('MATLAB:json:ExpectedColon', ...
                  'Deux-points attendus à la position %d.', p);
        end
        p = sauterBlancs(t, p + 1);
        [valeur, p] = lireValeur(t, p);
        s.(genvarname(nom)) = valeur;
        p = sauterBlancs(t, p);
        if p <= numel(t) && t(p) == ','
            p = p + 1;
            continue;
        end
        if p <= numel(t) && t(p) == '}'
            p = p + 1;
            return;
        end
        error('MATLAB:json:ExpectedBrace', ...
              'Virgule ou accolade attendue à la position %d.', p);
    end
end

function [v, p] = lireTableau(t, p)
    elements = {};
    p = sauterBlancs(t, p + 1);
    if p <= numel(t) && t(p) == ']'
        v = [];
        p = p + 1;
        return;
    end
    while true
        [element, p] = lireValeur(t, sauterBlancs(t, p));
        elements{end+1} = element;   %#ok<AGROW>
        p = sauterBlancs(t, p);
        if p <= numel(t) && t(p) == ','
            p = p + 1;
            continue;
        end
        if p <= numel(t) && t(p) == ']'
            p = p + 1;
            break;
        end
        error('MATLAB:json:ExpectedBracket', ...
              'Virgule ou crochet attendu à la position %d.', p);
    end
    v = rassembler(elements);
end

function v = rassembler(elements)
% MATLAB empile ce qui s'empile : des scalaires donnent une colonne, des
% vecteurs de même longueur une matrice, des structures aux mêmes champs
% un tableau de structures. Le reste reste en cellules.
    tousScalaires = true;
    tousNumeriques = true;
    memeTaille = true;
    taille = numel(elements{1});
    for k = 1:numel(elements)
        e = elements{k};
        if ~(isnumeric(e) || islogical(e))
            tousNumeriques = false;
            tousScalaires = false;
        elseif ~isscalar(e)
            tousScalaires = false;
        end
        if numel(e) ~= taille
            memeTaille = false;
        end
    end
    if tousScalaires
        v = zeros(numel(elements), 1);
        for k = 1:numel(elements)
            v(k) = double(elements{k});
        end
        return;
    end
    if tousNumeriques && memeTaille && taille > 0
        v = zeros(numel(elements), taille);
        for k = 1:numel(elements)
            e = elements{k};
            v(k, :) = double(e(:))';
        end
        return;
    end
    toutesStructures = true;
    for k = 1:numel(elements)
        if ~isstruct(elements{k})
            toutesStructures = false;
        end
    end
    if toutesStructures && memesChamps(elements)
        v = elements{1};
        for k = 2:numel(elements)
            v(k, 1) = elements{k};
        end
        return;
    end
    v = elements(:);
end

function tf = memesChamps(elements)
    tf = true;
    reference = sort(fieldnames(elements{1}));
    for k = 2:numel(elements)
        if ~isequal(sort(fieldnames(elements{k})), reference)
            tf = false;
            return;
        end
    end
end

function [s, p] = lireChaine(t, p)
    p = p + 1;
    s = '';
    while p <= numel(t)
        c = t(p);
        if c == '"'
            p = p + 1;
            return;
        end
        if c == '\'
            p = p + 1;
            if p > numel(t)
                break;
            end
            switch t(p)
                case 'n', s(end+1) = sprintf('\n');   %#ok<AGROW>
                case 't', s(end+1) = sprintf('\t');   %#ok<AGROW>
                case 'r', s(end+1) = sprintf('\r');   %#ok<AGROW>
                case 'b', s(end+1) = char(8);         %#ok<AGROW>
                case 'f', s(end+1) = char(12);        %#ok<AGROW>
                case 'u'
                    code = hex2dec(t(p+1:p+4));
                    s(end+1) = char(code);            %#ok<AGROW>
                    p = p + 4;
                otherwise
                    s(end+1) = t(p);                  %#ok<AGROW>
            end
            p = p + 1;
            continue;
        end
        s(end+1) = c;   %#ok<AGROW>
        p = p + 1;
    end
    error('MATLAB:json:UnterminatedString', 'Chaîne JSON non fermée.');
end

function [v, p] = lireNombre(t, p)
    debut = p;
    if p <= numel(t) && (t(p) == '-' || t(p) == '+')
        p = p + 1;
    end
    while p <= numel(t) && ((t(p) >= '0' && t(p) <= '9') || any(t(p) == '.eE+-'))
        if any(t(p) == '+-') && ~any(lower(t(p-1)) == 'e')
            break;
        end
        p = p + 1;
    end
    v = str2double(t(debut:p-1));
    if isnan(v) && ~strcmpi(strtrim(t(debut:p-1)), 'nan')
        error('MATLAB:json:BadNumber', ...
              'Nombre attendu à la position %d.', debut);
    end
end
