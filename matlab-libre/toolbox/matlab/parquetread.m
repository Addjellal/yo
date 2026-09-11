function T = parquetread(nomFichier, varargin)
%PARQUETREAD Lit un fichier Parquet dans une table.
%   T = PARQUETREAD(FICHIER) rend la table que contient le fichier.
%   T = PARQUETREAD(FICHIER,'SelectedVariableNames',NOMS) ne lit que les
%   colonnes nommées — c'est l'intérêt d'un format en colonnes : le reste
%   du fichier n'est pas touché.
%
%   Les classes sont restituées d'après le schéma : un int8 écrit revient
%   int8, une chaîne revient chaîne.
%
%   Une colonne facultative est lue : ses niveaux de définition disent où
%   sont les trous. Un trou devient NaN dans une colonne flottante ; dans
%   une colonne entière, booléenne ou textuelle, il n'existe pas de
%   valeur qui veuille dire « absent », et la lecture est refusée plutôt
%   que de mettre un zéro à la place.
%
%   Ce qui est lu : l'encodage PLAIN, sans compression. Un fichier
%   compressé ou encodé en dictionnaire est refusé avec la raison : mieux
%   vaut un refus net qu'une colonne muettement fausse.
%
%   Exemple :
%      f = fullfile(tempdir, 'lecture.parquet');
%      parquetwrite(f, table([1; 2], ["x"; "y"], 'VariableNames', {'a', 'b'}));
%      T = parquetread(f);
%      height(T)                       % 2
%
%   Voir aussi PARQUETWRITE, PARQUETINFO, READTABLE, TABLE.
    if nargin < 1
        error('MATLAB:minrhs', 'PARQUETREAD attend un nom de fichier.');
    end
    nomFichier = char(nomFichier);
    choix = {};
    for k = 1:2:numel(varargin) - 1
        if strcmpi(char(varargin{k}), 'SelectedVariableNames')
            choix = cellstr(string(varargin{k+1}));
        else
            error('MATLAB:parquet:OptionInconnue', ...
                  'Option inconnue « %s ».', char(varargin{k}));
        end
    end

    [metadonnees, octets] = matlibre_parquet_pied(nomFichier);
    schema = metadonnees.c2;
    nbLignes = double(metadonnees.c3);
    groupes = metadonnees.c4;

    noms = {};
    physiques = [];
    convertis = [];
    niveauxMax = [];
    for k = 2:numel(schema)
        element = schema{k};
        noms{end+1} = char(native2unicode(element.c4, 'UTF-8'));   %#ok<AGROW>
        physiques(end+1) = double(element.c1);                     %#ok<AGROW>
        if isfield(element, 'c6')
            convertis(end+1) = double(element.c6);                 %#ok<AGROW>
        else
            convertis(end+1) = -1;                                 %#ok<AGROW>
        end
        repetition = 0;
        if isfield(element, 'c3')
            repetition = double(element.c3);
        end
        if repetition == 2
            error('MATLAB:parquet:ColonneRepetee', ...
                  ['La colonne « %s » est répétée — une liste par ligne ; ' ...
                   'MatLibre lit les colonnes simples.'], noms{end});
        end
        niveauxMax(end+1) = repetition;   %#ok<AGROW>
    end

    valeurs = cell(1, numel(noms));
    lues = false(1, numel(noms));
    for g = 1:numel(groupes)
        colonnes = groupes{g}.c1;
        for k = 1:numel(colonnes)
            meta = colonnes{k}.c3;
            chemin = meta.c3;
            nomColonne = char(native2unicode(chemin{end}, 'UTF-8'));
            indice = find(strcmp(nomColonne, noms), 1);
            if isempty(indice)
                continue
            end
            if ~isempty(choix) && ~any(strcmp(nomColonne, choix))
                continue
            end
            if double(meta.c4) ~= 0
                error('MATLAB:parquet:Compression', ...
                      ['Le fichier est compressé (codec %d) ; MatLibre lit ' ...
                       'le format non compressé.'], double(meta.c4));
            end
            morceau = lireChunk(octets, meta, physiques(indice), ...
                                niveauxMax(indice), noms{indice}, ...
                                matlibre_parquet_classe(physiques(indice), convertis(indice)));
            if lues(indice)
                valeurs{indice} = [valeurs{indice}; morceau];
            else
                valeurs{indice} = morceau;
                lues(indice) = true;
            end
        end
    end

    gardes = {};
    donnees = {};
    for k = 1:numel(noms)
        if ~isempty(choix) && ~any(strcmp(noms{k}, choix))
            continue
        end
        if ~lues(k)
            error('MATLAB:parquet:ColonneAbsente', ...
                  'Aucune donnée pour la colonne « %s ».', noms{k});
        end
        gardes{end+1} = noms{k};                                              %#ok<AGROW>
        donnees{end+1} = convertir(valeurs{k}, physiques(k), convertis(k));   %#ok<AGROW>
    end
    if isempty(gardes)
        T = table();
        return
    end
    T = table(donnees{:}, 'VariableNames', gardes);
    if height(T) ~= nbLignes
        error('MATLAB:parquet:NombreDeLignes', ...
              'Le pied annonce %d lignes, les pages en portent %d.', nbLignes, height(T));
    end
end

function valeurs = lireChunk(octets, meta, physique, niveauMax, nom, classe)
% Une page commence par son en-tête, écrit dans le même protocole que le
% pied ; les niveaux de définition, s'il y en a, puis les données suivent.
    position = double(meta.c9) + 1;
    nbRestant = double(meta.c5);
    valeurs = [];
    premier = true;
    while nbRestant > 0
        [entete, suite] = matlibre_thrift_lire(octets, position);
        if double(entete.c1) ~= 0
            error('MATLAB:parquet:PageNonSupportee', ...
                  ['Seules les pages de données de première version sont lues ; ' ...
                   'celle-ci est de type %d.'], double(entete.c1));
        end
        taille = double(entete.c3);
        detail = entete.c5;
        if double(detail.c2) ~= 0
            error('MATLAB:parquet:EncodageNonSupporte', ...
                  ['Seul l''encodage PLAIN est lu ; celui de cette page est %d ' ...
                   '(un dictionnaire, le plus souvent).'], double(detail.c2));
        end
        nombre = double(detail.c1);
        page = octets(suite:suite+taille-1);
        presents = [];
        if niveauMax > 0
            if double(detail.c3) ~= 3
                error('MATLAB:parquet:NiveauxNonSupportes', ...
                      ['Les niveaux de définition ne sont lus qu''en codage RLE ; ' ...
                       'celui-ci est %d.'], double(detail.c3));
            end
            longueur = double(typecast(uint8(page(1:4)), 'uint32'));
            niveaux = matlibre_parquet_niveaux(page(5:4+longueur), 1, nombre);
            page = page(5+longueur:end);
            presents = niveaux >= niveauMax;
        end
        if isempty(presents)
            morceau = matlibre_parquet_decoder(page, physique, nombre, classe);
        else
            morceau = repartir(matlibre_parquet_decoder(page, physique, sum(presents), classe), ...
                               presents, physique, nom);
        end
        if premier
            valeurs = morceau;
            premier = false;
        else
            valeurs = [valeurs; morceau];   %#ok<AGROW>
        end
        position = suite + taille;
        nbRestant = nbRestant - nombre;
    end
end

function pleine = repartir(presentes, presents, physique, nom)
% Les valeurs lues ne couvrent que les lignes présentes ; il faut les
% remettre à leur place et marquer les trous.
    if all(presents)
        pleine = presentes;
        return
    end
    if physique ~= 5 && physique ~= 4
        error('MATLAB:parquet:ValeursAbsentes', ...
              ['La colonne « %s » a des valeurs absentes, et sa classe n''a ' ...
               'pas de valeur pour les dire ; seules les colonnes flottantes ' ...
               'les portent, sous forme de NaN.'], nom);
    end
    pleine = nan(numel(presents), 1);
    if physique == 4
        pleine = single(pleine);
    end
    pleine(presents) = presentes;
end

function v = convertir(v, physique, converti)
    classe = matlibre_parquet_classe(physique, converti);
    switch classe
        case 'string',  v = string(v);
        case 'logical', v = logical(v);
        case 'double',  v = double(v);
        case 'single',  v = single(v);
        otherwise,      v = cast(v, classe);
    end
end
