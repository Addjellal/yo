function t = dbLoad(nomFichier)
%DBLOAD Lit une table depuis un fichier CSV.
%   T = DBLOAD(FICHIER) lit un fichier écrit par DBSAVE : la première
%   ligne donne les noms de colonnes, les suivantes les enregistrements.
%
%   Le fichier suit RFC 4180 : un champ entre guillemets est du texte,
%   virgules, guillemets doublés et retours à la ligne compris ; un champ
%   nu qui se lit comme un nombre est un nombre, les autres du texte. Un
%   fichier écrit par DBSAVE revient donc avec ses types exacts.
%
%   L'aller-retour DBSAVE puis DBLOAD est la vérification qui compte :
%   la table relue doit se comporter comme l'originale, groupements
%   compris.
%
%   Exemple :
%      t = dbTable({'nom', 'service', 'salaire', 'anciennete'});
%      t = dbInsert(t, {'Dupont', 'etudes', 45000, 6});
%      t = dbInsert(t, {'Martin', 'ventes', 38000, 3});
%      dbSave(t, 'personnel.csv');
%      relue = dbLoad('personnel.csv');
%      isequal(relue.colonnes, t.colonnes)     % true
%
%   Voir aussi DBSAVE, DBTABLE, READTABLE.
    texte = fileread(nomFichier);
    enregistrements = lireCsv(texte);
    if isempty(enregistrements)
        error('database:dbLoad:Vide', 'File ''%s'' has no header.', nomFichier);
    end
    entete = cellfun(@(c) c.texte, enregistrements{1}, 'UniformOutput', false);
    t = dbTable(entete);
    for k = 2:numel(enregistrements)
        champs = enregistrements{k};
        valeurs = cell(1, numel(champs));
        for j = 1:numel(champs)
            c = champs{j};
            nombre = str2double(c.texte);
            if c.cite || (isnan(nombre) && ~strcmpi(strtrim(c.texte), 'nan'))
                valeurs{j} = c.texte;
            else
                valeurs{j} = nombre;
            end
        end
        t = dbInsert(t, valeurs);
    end
end

% Les enregistrements d'un texte CSV : une cellule par ligne, une
% structure (texte, cite) par champ. Les lignes vides sont sautées.
function enregistrements = lireCsv(texte)
    enregistrements = {};
    champs = {};
    courant = '';
    cite = false;
    dansGuillemets = false;
    n = numel(texte);
    k = 1;
    while k <= n
        c = texte(k);
        if dansGuillemets
            if c == '"'
                if k < n && texte(k + 1) == '"'
                    courant(end + 1) = '"'; %#ok<AGROW>
                    k = k + 1;
                else
                    dansGuillemets = false;
                end
            else
                courant(end + 1) = c; %#ok<AGROW>
            end
        elseif c == '"' && isempty(strtrim(courant))
            dansGuillemets = true;
            cite = true;
            courant = '';
        elseif c == ','
            champs{end + 1} = struct('texte', courant, 'cite', cite); %#ok<AGROW>
            courant = '';
            cite = false;
        elseif c == sprintf('\n') || c == sprintf('\r')
            if c == sprintf('\r') && k < n && texte(k + 1) == sprintf('\n')
                k = k + 1;
            end
            [enregistrements, champs] = finir(enregistrements, champs, courant, cite);
            courant = '';
            cite = false;
        else
            courant(end + 1) = c; %#ok<AGROW>
        end
        k = k + 1;
    end
    enregistrements = finir(enregistrements, champs, courant, cite);
end

function [enregistrements, champs] = finir(enregistrements, champs, courant, cite)
    if isempty(champs) && isempty(courant) && ~cite
        return   % ligne vide
    end
    champs{end + 1} = struct('texte', courant, 'cite', cite);
    enregistrements{end + 1} = champs;
    champs = {};
end
