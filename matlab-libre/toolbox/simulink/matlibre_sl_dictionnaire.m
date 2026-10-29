function varargout = matlibre_sl_dictionnaire(action, varargin)
%MATLIBRE_SL_DICTIONNAIRE Les dictionnaires de données ouverts dans la session.
%   Un dictionnaire de données (.sldd) range les variables d'un ou de
%   plusieurs modèles hors de l'espace de travail de base, par sections —
%   'Design Data', 'Configurations', 'Other Data' — et peut en référencer
%   d'autres (DataSources), dont il voit les entrées. Un modèle le désigne
%   par son réglage DataDictionary : ses blocs lisent ses variables après
%   celles de l'espace du modèle et avant celles de l'espace de base, que
%   EnableAccessToBaseWorkspace à 'off' leur ferme. Ce que l'on change
%   dans un dictionnaire ouvert vaut aussitôt pour les modèles ;
%   SAVECHANGES l'écrit, DISCARDCHANGES le défait.
%
%   Le fichier est un fichier MAT propre à MatLibre : il ne se lit pas
%   dans Simulink, et un .sldd de Simulink ne s'y lit pas.
%
%   Actions : 'creer', 'ouvrir', 'fermer', 'fermertout', 'enregistrer',
%   'abandonner', 'entrees', 'lire', 'ecrire', 'retirer', 'existe',
%   'statut', 'date', 'rendre', 'sources', 'ajoutersource', 'retirersource',
%   'modifie', 'nombre', 'variables', 'ouverts', 'chemin'.
%
%   SAVECHANGES, DISCARDCHANGES et HASUNSAVEDCHANGES valent pour le
%   dictionnaire et ceux qu'il référence, comme dans Simulink.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      matlibre_sl_dictionnaire('creer', f);
%      matlibre_sl_dictionnaire('ecrire', f, 'Design Data', 'K', 3);
%      matlibre_sl_dictionnaire('lire', f, 'Design Data', 'K')   % 3
%      matlibre_sl_dictionnaire('fermer', f, '-discard');
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY.CREATE, SIMULINK.DATA.DICTIONARY.OPEN.
    persistent ouverts
    if isempty(ouverts)
        ouverts = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    switch lower(char(action))
        case 'chemin'
            varargout{1} = cheminDe(char(varargin{1}), numel(varargin) > 1 && varargin{2});
        case 'ouverts'
            varargout{1} = keys(ouverts);
        case 'creer'
            f = cheminDe(char(varargin{1}), false);
            if exist(f, 'file') == 2
                error('SLDD:sldd:DictionaryAlreadyExists', ...
                      ['Le dictionnaire ''%s'' existe deja : SIMULINK.DATA.DICTIONARY.OPEN ' ...
                       'l''ouvre.'], f);
            end
            D = vide();
            ecrireFichier(f, D);
            D.disque = D.donnees;
            ouverts(f) = D;
            varargout{1} = f;
        case 'ouvrir'
            f = cheminDe(char(varargin{1}), true);
            if ~isKey(ouverts, f)
                D = lireFichier(f);
                ouverts(f) = D;
            end
            varargout{1} = f;
        case 'fermer'
            f = cheminDe(char(varargin{1}), false);
            mode = '';
            if numel(varargin) > 1
                mode = lower(char(varargin{2}));
            end
            if ~isKey(ouverts, f)
                return
            end
            if modifie(ouverts, f, {})
                switch mode
                    case '-save'
                        enregistrer(ouverts, f, {});
                    case '-discard'
                    otherwise
                        error('SLDD:sldd:DictionaryNotSaved', ...
                              ['Le dictionnaire ''%s'' porte des changements non ecrits : ' ...
                               'SAVECHANGES les ecrit, DISCARDCHANGES les defait, ou ' ...
                               'CLOSE(DD, ''-save'') et CLOSE(DD, ''-discard'').'], f);
                end
            end
            remove(ouverts, f);
        case 'fermertout'
            mode = '';
            if ~isempty(varargin)
                mode = lower(char(varargin{1}));
            end
            for f = keys(ouverts)
                D = ouverts(f{1});
                if ~isequal(D.donnees, D.disque) && ~any(strcmp(mode, {'-save', '-discard'}))
                    error('SLDD:sldd:DictionaryNotSaved', ...
                          ['Le dictionnaire ''%s'' porte des changements non ecrits : ' ...
                           'CLOSEALL(''-save'') ou CLOSEALL(''-discard'').'], f{1});
                end
            end
            for f = keys(ouverts)
                D = ouverts(f{1});
                if ~isequal(D.donnees, D.disque) && strcmp(mode, '-save')
                    ecrireFichier(f{1}, D);
                end
                remove(ouverts, f{1});
            end
        case 'enregistrer'
            enregistrer(ouverts, ouvert(ouverts, varargin{1}), {});
        case 'abandonner'
            abandonner(ouverts, ouvert(ouverts, varargin{1}), {});
        case 'modifie'
            varargout{1} = modifie(ouverts, ouvert(ouverts, varargin{1}), {});
        case 'nombre'
            f = ouvert(ouverts, varargin{1});
            n = 0;
            for s = {'Design_Data', 'Configurations', 'Other_Data'}
                n = n + numel(entreesVues(ouverts, f, s{1}, {}));
            end
            varargout{1} = n;
        case 'statut'
            % 'New', 'Modified' ou 'Unchanged' : l'entrée au regard du
            % fichier du dictionnaire qui la définit
            [f, section, nom] = varargin{1:3};
            s = clef(section);
            nom = char(nom);
            [~, origine] = lireEntree(ouverts, ouvert(ouverts, f), s, nom, {});
            statut = 'Deleted';
            if ~isempty(origine)
                D = ouverts(origine);
                if ~isfield(D.disque.sections.(s), nom)
                    statut = 'New';
                elseif isequal(D.disque.sections.(s).(nom), D.donnees.sections.(s).(nom))
                    statut = 'Unchanged';
                else
                    statut = 'Modified';
                end
            end
            varargout{1} = statut;
        case 'date'
            [f, section, nom] = varargin{1:3};
            s = clef(section);
            nom = char(nom);
            [~, origine] = lireEntree(ouverts, ouvert(ouverts, f), s, nom, {});
            date = '';
            if ~isempty(origine)
                D = ouverts(origine);
                if isfield(D.donnees.dates, s) && isfield(D.donnees.dates.(s), nom)
                    date = D.donnees.dates.(s).(nom);
                end
            end
            varargout{1} = date;
        case 'entrees'
            % les noms des entrées d'une section, celles des sources comprises
            [f, section] = varargin{1:2};
            noms = entreesVues(ouverts, ouvert(ouverts, f), clef(section), {});
            varargout{1} = noms;
        case 'lire'
            [f, section, nom] = varargin{1:3};
            [v, origine] = lireEntree(ouverts, ouvert(ouverts, f), clef(section), char(nom), {});
            if isempty(origine)
                error('SLDD:sldd:EntryNotFound', ...
                      'Le dictionnaire ''%s'' n''a pas d''entree ''%s'' dans sa section ''%s''.', ...
                      ouvert(ouverts, f), char(nom), char(section));
            end
            varargout{1} = v;
            varargout{2} = origine;
        case 'existe'
            [f, section, nom] = varargin{1:3};
            [~, origine] = lireEntree(ouverts, ouvert(ouverts, f), clef(section), char(nom), {});
            varargout{1} = ~isempty(origine);
        case 'ecrire'
            [f, section, nom, valeur] = varargin{1:4};
            creation = numel(varargin) > 4 && varargin{5};
            f = ouvert(ouverts, f);
            nom = char(nom);
            if ~isvarname(nom)
                error('SLDD:sldd:InvalidEntryName', ...
                      ['''%s'' n''est pas un nom d''entree : une entree porte le nom d''une ' ...
                       'variable de MATLAB.'], nom);
            end
            D = ouverts(f);
            s = clef(section);
            if creation && isfield(D.donnees.sections.(s), nom)
                error('SLDD:sldd:DuplicateEntry', ...
                      ['Le dictionnaire ''%s'' porte deja une entree ''%s'' dans sa section ' ...
                       '''%s'' : GETENTRY la rend, SETVALUE la change.'], f, nom, char(section));
            end
            if ~creation && ~isfield(D.donnees.sections.(s), nom)
                % une entrée d'une source se change dans la source
                [~, origine] = lireEntree(ouverts, f, s, nom, {});
                if ~isempty(origine) && ~strcmp(origine, f)
                    matlibre_sl_dictionnaire('ecrire', origine, section, nom, valeur);
                    return
                end
            end
            D.donnees.sections.(s).(nom) = valeur;
            D.donnees.dates.(s).(nom) = datestr(now, 31);
            ouverts(f) = D;
        case 'rendre'
            % l'entrée reprend sa valeur écrite ; une entrée neuve s'en va
            [f, section, nom] = varargin{1:3};
            s = clef(section);
            nom = char(nom);
            [~, origine] = lireEntree(ouverts, ouvert(ouverts, f), s, nom, {});
            if isempty(origine)
                return
            end
            D = ouverts(origine);
            if isfield(D.disque.sections.(s), nom)
                D.donnees.sections.(s).(nom) = D.disque.sections.(s).(nom);
                if isfield(D.disque.dates.(s), nom)
                    D.donnees.dates.(s).(nom) = D.disque.dates.(s).(nom);
                end
            else
                D.donnees.sections.(s) = rmfield(D.donnees.sections.(s), nom);
                if isfield(D.donnees.dates.(s), nom)
                    D.donnees.dates.(s) = rmfield(D.donnees.dates.(s), nom);
                end
            end
            ouverts(origine) = D;
        case 'retirer'
            [f, section, nom] = varargin{1:3};
            f = ouvert(ouverts, f);
            D = ouverts(f);
            s = clef(section);
            nom = char(nom);
            if ~isfield(D.donnees.sections.(s), nom)
                % une entrée d'une source se retire de la source
                [~, origine] = lireEntree(ouverts, f, s, nom, {});
                if ~isempty(origine)
                    matlibre_sl_dictionnaire('retirer', origine, section, nom);
                    return
                end
                error('SLDD:sldd:EntryNotFound', ...
                      'Le dictionnaire ''%s'' n''a pas d''entree ''%s'' dans sa section ''%s''.', ...
                      f, nom, char(section));
            end
            D.donnees.sections.(s) = rmfield(D.donnees.sections.(s), nom);
            if isfield(D.donnees.dates, s) && isfield(D.donnees.dates.(s), nom)
                D.donnees.dates.(s) = rmfield(D.donnees.dates.(s), nom);
            end
            ouverts(f) = D;
        case 'sources'
            f = ouvert(ouverts, varargin{1});
            D = ouverts(f);
            varargout{1} = D.donnees.sources;
        case 'ajoutersource'
            f = ouvert(ouverts, varargin{1});
            % un nom sans dossier se cherche d'abord à côté du dictionnaire
            source = char(varargin{2});
            [dossier, base, ext] = fileparts(source);
            if isempty(ext)
                ext = '.sldd';
            end
            if isempty(dossier) && exist(fullfile(fileparts(f), [base ext]), 'file') == 2
                source = fullfile(fileparts(f), [base ext]);
            end
            source = cheminDe(source, true);
            if strcmp(source, f)
                error('SLDD:sldd:CircularReference', ...
                      'Le dictionnaire ''%s'' ne se reference pas lui-meme.', f);
            end
            D = ouverts(f);
            [~, nomSource, ext] = fileparts(source);
            if ~any(strcmp(D.donnees.sources, [nomSource ext]))
                D.donnees.sources{end + 1} = [nomSource ext];
            end
            ouverts(f) = D;
        case 'retirersource'
            f = ouvert(ouverts, varargin{1});
            D = ouverts(f);
            [~, nomSource, ext] = fileparts(char(varargin{2}));
            k = strcmp(D.donnees.sources, [nomSource ext]);
            if ~any(k)
                error('SLDD:sldd:DataSourceNotFound', ...
                      'Le dictionnaire ''%s'' ne reference pas ''%s''.', f, [nomSource ext]);
            end
            D.donnees.sources(k) = [];
            ouverts(f) = D;
        case 'variables'
            % les variables de 'Design Data' que voit un modèle lié au
            % dictionnaire, sources comprises
            f = char(varargin{1});
            noms = {};
            valeurs = {};
            try
                f = cheminDe(f, true);
                if ~isKey(ouverts, f)
                    ouverts(f) = lireFichier(f);
                end
                [noms, valeurs] = toutesVues(ouverts, f, 'Design_Data', {});
            catch err
                if strcmp(err.identifier, 'SLDD:sldd:DictionaryNotFound')
                    rethrow(err);
                end
            end
            varargout = {noms, valeurs};
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

% --- les fichiers ------------------------------------------------------------------

function D = vide()
    donnees = struct('version', 1, 'sources', {{}}, ...
                     'sections', struct('Design_Data', struct(), 'Configurations', struct(), ...
                                        'Other_Data', struct()), ...
                     'dates', struct('Design_Data', struct(), 'Configurations', struct(), ...
                                     'Other_Data', struct()));
    D = struct('donnees', donnees, 'disque', donnees);
end

function f = cheminDe(f, doitExister)
    [dossier, base, ext] = fileparts(f);
    if isempty(ext)
        ext = '.sldd';
    end
    if ~strcmpi(ext, '.sldd')
        error('SLDD:sldd:InvalidFileName', ...
              '''%s'' n''est pas un dictionnaire de donnees : son nom finit par .sldd.', f);
    end
    if isempty(dossier)
        % le dossier courant, puis le chemin de MATLAB
        dossiers = [{pwd()}, strsplit(path(), pathsep())];
        for k = 1:numel(dossiers)
            candidat = fullfile(dossiers{k}, [base ext]);
            if ~isempty(dossiers{k}) && exist(candidat, 'file') == 2
                f = candidat;
                return
            end
        end
        dossier = pwd();
    elseif ~(dossier(1) == '/' || (numel(dossier) > 1 && dossier(2) == ':'))
        dossier = fullfile(pwd(), dossier);
    end
    f = fullfile(dossier, [base ext]);
    if doitExister && exist(f, 'file') ~= 2
        error('SLDD:sldd:DictionaryNotFound', ...
              'Le dictionnaire de donnees ''%s'' n''existe pas.', f);
    end
end

function D = lireFichier(f)
    try
        contenu = load(f);
    catch err
        error('SLDD:sldd:InvalidDictionary', ...
              'Le fichier ''%s'' ne se lit pas comme un dictionnaire de donnees : %s', f, ...
              err.message);
    end
    if ~isfield(contenu, 'sections') || ~isfield(contenu, 'sources')
        error('SLDD:sldd:InvalidDictionary', ...
              ['Le fichier ''%s'' n''est pas un dictionnaire de donnees de MatLibre ; un ' ...
               '.sldd de Simulink ne s''y lit pas.'], f);
    end
    donnees = vide();
    donnees = donnees.donnees;
    donnees.sources = contenu.sources;
    for s = fieldnames(contenu.sections).'
        donnees.sections.(s{1}) = contenu.sections.(s{1});
    end
    if isfield(contenu, 'dates')
        for s = fieldnames(contenu.dates).'
            donnees.dates.(s{1}) = contenu.dates.(s{1});
        end
    end
    D = struct('donnees', donnees, 'disque', donnees);
end

function ecrireFichier(f, D)
    contenu = D.donnees; %#ok<NASGU>
    save(f, '-struct', 'contenu');
end

function f = ouvert(ouverts, f)
    f = cheminDe(char(f), false);
    if ~isKey(ouverts, f)
        error('SLDD:sldd:DictionaryNotOpen', ...
              ['Le dictionnaire ''%s'' n''est pas ouvert : SIMULINK.DATA.DICTIONARY.OPEN ' ...
               'l''ouvre.'], f);
    end
end

function s = clef(section)
    s = strrep(char(section), ' ', '_');
    if ~any(strcmp(s, {'Design_Data', 'Configurations', 'Other_Data'}))
        error('SLDD:sldd:InvalidSection', ...
              ['''%s'' n''est pas une section de dictionnaire : ''Design Data'', ' ...
               '''Configurations'' ou ''Other Data''.'], char(section));
    end
end

% --- un dictionnaire et ceux qu'il référence, ensemble ------------------------

function oui = modifie(ouverts, f, vus)
    oui = false;
    if any(strcmp(vus, f))
        return
    end
    D = assurer(ouverts, f);
    oui = ~isequal(D.donnees, D.disque);
    for c = sourcesDe(f, D)
        oui = oui || modifie(ouverts, c{1}, [vus, {f}]);
    end
end

function enregistrer(ouverts, f, vus)
    if any(strcmp(vus, f))
        return
    end
    D = assurer(ouverts, f);
    if ~isequal(D.donnees, D.disque) || exist(f, 'file') ~= 2
        ecrireFichier(f, D);
        D.disque = D.donnees;
        ouverts(f) = D;
    end
    for c = sourcesDe(f, D)
        enregistrer(ouverts, c{1}, [vus, {f}]);
    end
end

function abandonner(ouverts, f, vus)
    if any(strcmp(vus, f))
        return
    end
    D = assurer(ouverts, f);
    D.donnees = D.disque;
    ouverts(f) = D;
    for c = sourcesDe(f, D)
        abandonner(ouverts, c{1}, [vus, {f}]);
    end
end

% --- ce que voit un dictionnaire : ses entrées, puis celles de ses sources ----

function D = assurer(ouverts, f)
    if isKey(ouverts, f)
        D = ouverts(f);
    else
        D = lireFichier(f);
        ouverts(f) = D; %#ok<NASGU>  la poignée Map garde le dictionnaire ouvert
        D = ouverts(f);
    end
end

function chemins = sourcesDe(f, D)
    chemins = {};
    dossier = fileparts(f);
    for k = 1:numel(D.donnees.sources)
        candidat = fullfile(dossier, D.donnees.sources{k});
        if exist(candidat, 'file') ~= 2
            candidat = cheminDe(D.donnees.sources{k}, true);
        end
        chemins{end + 1} = candidat; %#ok<AGROW>
    end
end

function [v, origine] = lireEntree(ouverts, f, s, nom, vus)
    v = [];
    origine = '';
    if any(strcmp(vus, f))
        return
    end
    D = assurer(ouverts, f);
    if isfield(D.donnees.sections.(s), nom)
        v = D.donnees.sections.(s).(nom);
        origine = f;
        return
    end
    for c = sourcesDe(f, D)
        [v, origine] = lireEntree(ouverts, c{1}, s, nom, [vus, {f}]);
        if ~isempty(origine)
            return
        end
    end
end

function noms = entreesVues(ouverts, f, s, vus)
    noms = {};
    if any(strcmp(vus, f))
        return
    end
    D = assurer(ouverts, f);
    noms = fieldnames(D.donnees.sections.(s)).';
    for c = sourcesDe(f, D)
        noms = [noms, setdiff(entreesVues(ouverts, c{1}, s, [vus, {f}]), noms, 'stable')]; %#ok<AGROW>
    end
end

function [noms, valeurs] = toutesVues(ouverts, f, s, vus)
    noms = entreesVues(ouverts, f, s, vus);
    valeurs = cell(size(noms));
    for k = 1:numel(noms)
        valeurs{k} = lireEntree(ouverts, f, s, noms{k}, {});
    end
end
