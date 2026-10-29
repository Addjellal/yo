function varargout = matlibre_sf_api(action, varargin)
%MATLIBRE_SF_API L'API de Stateflow sur les blocs Chart des modèles chargés.
%   Un bloc Chart posé par ADD_BLOCK('sflib/Chart',...) ou SFNEW range son
%   diagramme dans son paramètre Diagramme : ses états, transitions,
%   jonctions, données et événements, chacun avec son numéro (Id). Les
%   objets Stateflow.State, Stateflow.Transition, Stateflow.Junction,
%   Stateflow.Data, Stateflow.Event et Stateflow.Chart en sont des vues :
%   lire une de leurs propriétés la lit dans le bloc, la poser l'y écrit.
%   À la compilation, le diagramme devient la machine que fait tourner le
%   bloc Chart (voir SFCHART) : les données d'entrée sont ses entrées,
%   lues par leur nom dans les étiquettes, les données de sortie ses
%   sorties, les données locales, constantes et paramètres son contexte.
%
%   Actions : 'vide', 'lire', 'ecrire', 'objet', 'creer', 'propriete',
%   'poser', 'supprimer', 'trouver', 'machine', 'ports', 'proprietes'.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      sfnew('apiEssai');
%      ch = find(sfroot, '-isa', 'Stateflow.Chart', 'Path', 'apiEssai/Chart');
%      s = Stateflow.State(ch);
%      s.Name = 'A';
%      numel(matlibre_sf_api('lire', getSimulinkBlockHandle('apiEssai/Chart')).elements)  % 1
%      close_system('apiEssai', 0);
%
%   Voir aussi SFNEW, SFROOT, STATEFLOW.STATE, STATEFLOW.TRANSITION.
    switch action
        case 'vide'
            varargout{1} = jsonencode(vide());
        case 'lire'
            varargout{1} = lire(varargin{1});
        case 'ecrire'
            ecrire(varargin{1}, varargin{2});
        case 'objet'
            [h, id] = varargin{1:2};
            D = lire(h);
            if id == 0
                classe = 'Stateflow.Chart';
            else
                k = indice(D, id, h);
                classe = ['Stateflow.' D.elements(k).Classe];
            end
            varargout{1} = matlibre_sf_objet('obtenir', h, id, classe);
        case 'creer'
            [parent, classe] = varargin{1:2};
            [varargout{1}, varargout{2}] = creer(parent, classe);
        case 'propriete'
            [o, nom] = varargin{1:2};
            varargout{1} = propriete(o, nom);
        case 'poser'
            [o, nom, v] = varargin{1:3};
            poser(o, nom, v);
        case 'supprimer'
            supprimer(varargin{1});
        case 'trouver'
            [racine, args] = varargin{1:2};
            varargout{1} = trouver(racine, args);
        case 'machine'
            [p, chemin] = varargin{1:2};
            [varargout{1:4}] = machine(p, chemin);
        case 'ports'
            varargout{1} = ports(varargin{1});
        case 'proprietes'
            varargout{1} = proprietesDe(varargin{1});
        otherwise
            error('Stateflow:API:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

% --- la définition rangée dans le bloc -------------------------------------------

function D = vide()
    D = struct('elements', {elementsVides()}, 'prochain', 1, ...
               'chart', struct('Decomposition', 'EXCLUSIVE_OR', 'ActionLanguage', 'MATLAB', ...
                               'StateMachineType', 'Classic', 'ChartUpdate', 'INHERITED', ...
                               'ExecuteAtInitialization', false, 'Description', ''));
end

function E = elementsVides()
    E = struct('Id', {}, 'Classe', {}, 'Parent', {}, 'Name', {}, 'LabelString', {}, ...
               'Position', {}, 'Decomposition', {}, 'Source', {}, 'Destination', {}, ...
               'ExecutionOrder', {}, 'Type', {}, 'Scope', {}, 'DataType', {}, ...
               'InitialValue', {}, 'Port', {}, 'Trigger', {}, 'Description', {}, ...
               'SourceOClock', {}, 'DestinationOClock', {});
end

function e = elementNeuf(id, classe, parent)
    e = struct('Id', id, 'Classe', classe, 'Parent', parent, 'Name', '', 'LabelString', '', ...
               'Position', [], 'Decomposition', 'EXCLUSIVE_OR', 'Source', 0, 'Destination', 0, ...
               'ExecutionOrder', 0, 'Type', '', 'Scope', '', 'DataType', 'double', ...
               'InitialValue', '', 'Port', 0, 'Trigger', '', 'Description', '', ...
               'SourceOClock', 0, 'DestinationOClock', 0);
    switch classe
        case 'Junction'
            e.Type = 'CONNECTIVE';
        case 'Data'
            e.Scope = 'Local';
        case 'Event'
            e.Scope = 'Local';
            e.Trigger = 'Either';
        case 'State'
            e.Position = [0 0 90 60];
    end
end

function D = lire(h)
    texte = '';
    try
        texte = get_param(h, 'Diagramme');
    catch err
        if strcmp(err.identifier, 'Simulink:Commands:InvSimulinkObjHandle')
            error('Stateflow:API:DeletedObject', ...
                  'Le bloc Chart de cet objet n''existe plus : %s', err.message);
        end
        rethrow(err);
    end
    D = decoder(texte);
end

function D = decoder(texte)
    D = vide();
    if isempty(texte)
        return
    end
    lu = jsondecode(char(texte));
    if isfield(lu, 'chart') && isstruct(lu.chart)
        for champ = fieldnames(lu.chart).'
            D.chart.(champ{1}) = lu.chart.(champ{1});
        end
    end
    D.chart.ExecuteAtInitialization = logical(D.chart.ExecuteAtInitialization);
    D.prochain = lu.prochain;
    if isfield(lu, 'elements') && ~isempty(lu.elements)
        E = lu.elements;
        if iscell(E)
            E = [E{:}];
        end
        for k = 1:numel(E)
            e = elementNeuf(E(k).Id, E(k).Classe, E(k).Parent);
            for champ = fieldnames(E(k)).'
                e.(champ{1}) = E(k).(champ{1});
            end
            e.Position = reshape(double(e.Position), 1, []);
            D.elements(end + 1) = e;
        end
    end
end

function ecrire(h, D)
    set_param(h, 'Diagramme', jsonencode(D));
end

function k = indice(D, id, h)
    k = [];
    if ~isempty(D.elements)
        k = find([D.elements.Id] == id, 1);
    end
    if isempty(k)
        error('Stateflow:API:DeletedObject', ...
              'L''objet %d du diagramme ''%s'' n''existe plus.', id, getfullname(h));
    end
end

% --- les objets : leur bloc, leur numéro ----------------------------------------

function [h, id] = vue(o)
    h = builtin('subsref', o, struct('type', '.', 'subs', 'Bloc'));
    id = builtin('subsref', o, struct('type', '.', 'subs', 'Id_'));
end

function [h, id] = creer(parent, classe)
    if ~isobject(parent) || ~any(strcmp(class(parent), {'Stateflow.Chart', 'Stateflow.State'}))
        error('Stateflow:API:InvalidParent', ...
              ['Un objet %s se cree dans un diagramme (Stateflow.Chart) ou un etat ' ...
               '(Stateflow.State) ; pas dans %s.'], classe, class(parent));
    end
    [h, idParent] = vue(parent);
    D = lire(h);
    if idParent ~= 0
        indice(D, idParent, h);
    end
    id = D.prochain;
    D.prochain = id + 1;
    e = elementNeuf(id, strrep(classe, 'Stateflow.', ''), idParent);
    if strcmp(e.Classe, 'Data') || strcmp(e.Classe, 'Event')
        e.Name = nomLibre(D, e.Classe);
    end
    D.elements(end + 1) = e;
    ecrire(h, D);
end

% Un nom libre pour une donnée ou un événement neuf : data, data1...
function nom = nomLibre(D, classe)
    base = lower(classe);
    pris = {};
    if ~isempty(D.elements)
        pris = {D.elements.Name};
    end
    nom = base;
    k = 0;
    while any(strcmp(pris, nom))
        k = k + 1;
        nom = sprintf('%s%d', base, k);
    end
end

function supprimer(o)
    [h, id] = vue(o);
    D = lire(h);
    if id == 0
        error('Stateflow:API:InvalidDelete', ...
              'Un diagramme se supprime avec son bloc : DELETE_BLOCK.');
    end
    indice(D, id, h);
    % l'objet, ce qu'il contient, et les transitions qui le touchent
    retirer = id;
    change = true;
    while change
        change = false;
        for k = 1:numel(D.elements)
            e = D.elements(k);
            if ~any(retirer == e.Id) && (any(retirer == e.Parent) || ...
               (strcmp(e.Classe, 'Transition') && (any(retirer == e.Source) || ...
                                                   any(retirer == e.Destination))))
                retirer(end + 1) = e.Id; %#ok<AGROW>
                change = true;
            end
        end
    end
    D.elements = D.elements(~ismember([D.elements.Id], retirer));
    ecrire(h, D);
end

% Les propriétés de chaque classe, et celles qui ne se posent pas.
function [noms, lecture] = proprietesDe(classe)
    switch classe
        case 'Stateflow.Chart'
            noms = {'Id', 'Name', 'Path', 'Decomposition', 'ActionLanguage', ...
                    'StateMachineType', 'ChartUpdate', 'SampleTime', ...
                    'ExecuteAtInitialization', 'Description', 'Chart'};
            lecture = {'Id', 'Path', 'Chart'};
        case 'Stateflow.State'
            noms = {'Id', 'Name', 'LabelString', 'Position', 'Decomposition', 'Type', ...
                    'ExecutionOrder', 'Description', 'Path', 'Chart', 'IsSubchart'};
            lecture = {'Id', 'Type', 'Path', 'Chart'};
        case 'Stateflow.Transition'
            noms = {'Id', 'LabelString', 'Source', 'Destination', 'ExecutionOrder', ...
                    'SourceOClock', 'DestinationOClock', 'Description', 'Path', 'Chart'};
            lecture = {'Id', 'Path', 'Chart'};
        case 'Stateflow.Junction'
            noms = {'Id', 'Type', 'Position', 'Description', 'Path', 'Chart'};
            lecture = {'Id', 'Path', 'Chart'};
        case 'Stateflow.Data'
            noms = {'Id', 'Name', 'Scope', 'DataType', 'Props', 'Port', 'Description', ...
                    'Path', 'Chart'};
            lecture = {'Id', 'Path', 'Chart'};
        case 'Stateflow.Event'
            noms = {'Id', 'Name', 'Scope', 'Trigger', 'Port', 'Description', 'Path', 'Chart'};
            lecture = {'Id', 'Path', 'Chart'};
        otherwise
            noms = {};
            lecture = {};
    end
end

function nom = nomPropriete(o, nom)
    noms = proprietesDe(class(o));
    k = find(strcmpi(noms, char(nom)), 1);
    if isempty(k)
        error('Stateflow:API:UnknownProperty', ...
              'Un objet %s n''a pas de propriete ''%s'' ; il a : %s.', class(o), char(nom), ...
              strjoin(noms, ', '));
    end
    nom = noms{k};
end

function v = propriete(o, nom)
    nom = nomPropriete(o, nom);
    [h, id] = vue(o);
    D = lire(h);
    if strcmp(nom, 'Chart')
        v = matlibre_sf_api('objet', h, 0);
        return
    end
    if id == 0
        switch nom
            case 'Id'
                v = 0;
            case 'Name'
                v = get_param(h, 'Name');
            case 'Path'
                v = getfullname(h);
            case 'SampleTime'
                v = get_param(h, 'SampleTime');
                if isnumeric(v)
                    v = num2str(v);
                end
            otherwise
                v = D.chart.(nom);
        end
        return
    end
    k = indice(D, id, h);
    e = D.elements(k);
    switch nom
        case 'Path'
            v = cheminConteneur(D, e.Parent, h);
        case 'Source'
            v = objetOuVide(h, e.Source);
        case 'Destination'
            v = objetOuVide(h, e.Destination);
        case 'Props'
            v = struct('InitialValue', e.InitialValue, ...
                       'Range', struct('Minimum', '', 'Maximum', ''), ...
                       'Array', struct('Size', '-1'));
        case 'Type'
            if strcmp(e.Classe, 'State')
                v = 'OR';
                if strcmp(decompositionDe(D, e.Parent), 'PARALLEL_AND')
                    v = 'AND';
                end
            else
                v = e.Type;
            end
        case 'ExecutionOrder'
            v = rangDe(D, e);
        case 'Port'
            v = rangDe(D, e);
        case 'IsSubchart'
            v = false;
        otherwise
            v = e.(nom);
    end
end

function v = objetOuVide(h, id)
    v = [];
    if id ~= 0
        v = matlibre_sf_api('objet', h, id);
    end
end

function poser(o, nom, v)
    nom = nomPropriete(o, nom);
    [~, lecture] = proprietesDe(class(o));
    if any(strcmp(lecture, nom))
        error('Stateflow:API:ReadOnlyProperty', ...
              'La propriete %s d''un objet %s se lit, mais ne se pose pas.', nom, class(o));
    end
    [h, id] = vue(o);
    D = lire(h);
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if id == 0
        switch nom
            case 'Name'
                set_param(h, 'Name', v);
                return
            case 'SampleTime'
                set_param(h, 'SampleTime', v);
                return
            case 'Decomposition'
                D.chart.Decomposition = choix(nom, v, {'EXCLUSIVE_OR', 'PARALLEL_AND'});
            case 'ActionLanguage'
                D.chart.ActionLanguage = choix(nom, v, {'MATLAB', 'C'});
            case 'StateMachineType'
                D.chart.StateMachineType = choix(nom, v, {'Classic', 'Mealy', 'Moore'});
            case 'ChartUpdate'
                D.chart.ChartUpdate = choix(nom, v, {'INHERITED', 'DISCRETE', 'CONTINUOUS'});
            case 'ExecuteAtInitialization'
                if ~(islogical(v) || isnumeric(v)) || ~isscalar(v)
                    error('Stateflow:API:InvalidValue', ...
                          'ExecuteAtInitialization vaut true ou false.');
                end
                D.chart.ExecuteAtInitialization = logical(v);
            case 'Description'
                D.chart.Description = texte(nom, v);
        end
        ecrire(h, D);
        return
    end
    k = indice(D, id, h);
    e = D.elements(k);
    switch nom
        case 'Name'
            v = texte(nom, v);
            if ~isvarname(v)
                error('Stateflow:API:InvalidName', ...
                      '''%s'' n''est pas un nom : un %s se nomme comme une variable de MATLAB.', ...
                      v, lower(e.Classe));
            end
            if strcmp(e.Classe, 'State')
                [~, reste] = premiereLigne(e.LabelString);
                e.LabelString = v;
                if ~isempty(reste)
                    e.LabelString = [v newline reste];
                end
            end
            e.Name = v;
        case 'LabelString'
            v = texte(nom, v);
            e.LabelString = v;
            if strcmp(e.Classe, 'State')
                e.Name = premiereLigne(v);
            end
        case {'Source', 'Destination'}
            if isempty(v)
                e.(nom) = 0;
            else
                if ~isobject(v) || ~any(strcmp(class(v), {'Stateflow.State', 'Stateflow.Junction'}))
                    error('Stateflow:API:InvalidEndpoint', ...
                          ['La %s d''une transition est un etat (Stateflow.State) ou une ' ...
                           'jonction (Stateflow.Junction) ; pas %s.'], ...
                          lower(nom), class(v));
                end
                [hv, idv] = vue(v);
                if hv ~= h
                    error('Stateflow:API:InvalidEndpoint', ...
                          'Une transition relie deux objets d''un meme diagramme.');
                end
                indice(D, idv, h);
                e.(nom) = idv;
            end
        case 'Position'
            if ~isnumeric(v) && ~isstruct(v)
                error('Stateflow:API:InvalidValue', 'Position est un vecteur de nombres.');
            end
            if isstruct(v)
                if isfield(v, 'Center')
                    v = double(v.Center(:).');
                else
                    v = [];
                end
            end
            e.Position = double(v(:).');
        case 'Decomposition'
            e.Decomposition = choix(nom, v, {'EXCLUSIVE_OR', 'PARALLEL_AND'});
        case 'Type'
            e.Type = choix(nom, v, {'CONNECTIVE', 'HISTORY'});
        case 'Scope'
            if strcmp(e.Classe, 'Data')
                e.Scope = choix(nom, v, {'Local', 'Input', 'Output', 'Parameter', 'Constant'});
            else
                e.Scope = choix(nom, v, {'Local', 'Input', 'Output'});
            end
            e.Port = 0;
        case 'Trigger'
            e.Trigger = choix(nom, v, {'Either', 'Rising', 'Falling', 'Function call'});
        case 'DataType'
            v = texte(nom, v);
            types = {'double', 'single', 'boolean', 'int8', 'uint8', 'int16', 'uint16', ...
                     'int32', 'uint32'};
            if ~any(strcmp(v, types)) && ~strncmp(v, 'Inherit', 7)
                error('Stateflow:API:InvalidValue', ...
                      ['Le type d''une donnee est %s, ou ''Inherit: Same as Simulink'' ; ' ...
                       'pas ''%s''.'], strjoin(types, ', '), v);
            end
            e.DataType = v;
        case 'Props'
            if ~isstruct(v) || ~isfield(v, 'InitialValue')
                error('Stateflow:API:InvalidValue', ...
                      'Props est une structure qui porte InitialValue.');
            end
            e.InitialValue = valeurInitiale(v.InitialValue);
        case {'ExecutionOrder', 'Port', 'SourceOClock', 'DestinationOClock'}
            if ~isnumeric(v) || ~isscalar(v) || v < 0 || (~strncmp(nom, 'S', 1) && ...
                                                          ~strncmp(nom, 'D', 1) && v ~= round(v))
                error('Stateflow:API:InvalidValue', '%s est un nombre positif.', nom);
            end
            e.(nom) = double(v);
        case 'IsSubchart'
        otherwise
            e.(nom) = texte(nom, v);
    end
    D.elements(k) = e;
    ecrire(h, D);
end

function v = valeurInitiale(v)
    if isnumeric(v) || islogical(v)
        v = mat2str(double(v));
    end
    if ~ischar(v)
        error('Stateflow:API:InvalidValue', ...
              'InitialValue est un texte, ''0'', ou un nombre.');
    end
end

function v = texte(nom, v)
    if ~ischar(v) || size(v, 1) > 1
        error('Stateflow:API:InvalidValue', '%s est un texte.', nom);
    end
end

function v = choix(nom, v, admis)
    k = [];
    if ischar(v)
        k = find(strcmpi(v, admis), 1);
    end
    if isempty(k)
        error('Stateflow:API:InvalidValue', '%s vaut %s.', nom, strjoin(admis, ', '));
    end
    v = admis{k};
end

function [nom, reste] = premiereLigne(etiquette)
    etiquette = char(etiquette);
    fin = find(etiquette == newline | etiquette == '/', 1);
    if isempty(fin)
        nom = strtrim(etiquette);
        reste = '';
    else
        nom = strtrim(etiquette(1:fin - 1));
        reste = etiquette(fin + 1:end);
    end
end

function d = decompositionDe(D, idParent)
    if idParent == 0
        d = D.chart.Decomposition;
    else
        d = D.elements([D.elements.Id] == idParent).Decomposition;
    end
end

function c = cheminConteneur(D, idParent, h)
    noms = {};
    while idParent ~= 0
        e = D.elements([D.elements.Id] == idParent);
        noms = [{e.Name}, noms]; %#ok<AGROW>
        idParent = e.Parent;
    end
    c = strjoin([{getfullname(h)}, noms], '/');
end

% Le rang d'une transition parmi celles qui partent de sa source, ou d'une
% donnée parmi celles de sa portée : l'ordre posé d'abord, puis l'ordre
% de création.
function r = rangDe(D, e)
    switch e.Classe
        case 'Transition'
            freres = D.elements(strcmp({D.elements.Classe}, 'Transition') & ...
                                [D.elements.Source] == e.Source);
            if e.Source == 0
                freres = freres([freres.Parent] == e.Parent);
            end
            clefs = [freres.ExecutionOrder];
        case {'Data', 'Event'}
            freres = D.elements(strcmp({D.elements.Classe}, e.Classe) & ...
                                strcmp({D.elements.Scope}, e.Scope));
            if ~any(strcmp(e.Scope, {'Input', 'Output'}))
                r = 0;
                return
            end
            clefs = [freres.Port];
        otherwise
            r = 0;
            return
    end
    clefs(clefs == 0) = Inf;
    [~, ordre] = sortrows([clefs(:), [freres.Id]']);
    r = find([freres(ordre).Id] == e.Id, 1);
end

function E = ordonnes(E)
    if isempty(E)
        return
    end
    if any(strcmp(E(1).Classe, {'Data', 'Event'}))
        clefs = [E.Port];
    else
        clefs = [E.ExecutionOrder];
    end
    clefs(clefs == 0) = Inf;
    [~, ordre] = sortrows([clefs(:), [E.Id]']);
    E = E(ordre);
end

% --- la recherche -----------------------------------------------------------------

function trouves = trouver(racine, args)
    classe = '';
    profondeur = Inf;
    criteres = {};
    k = 1;
    while k <= numel(args)
        a = args{k};
        if ischar(a) && any(strcmpi(a, {'-isa', '-depth'})) && k == numel(args)
            error('Stateflow:API:InvalidFindArguments', ...
                  'FIND(OBJET,''%s'',VALEUR) : il manque la valeur de %s.', a, a);
        end
        if ischar(a) && strcmpi(a, '-isa')
            classe = char(args{k + 1});
            k = k + 2;
        elseif ischar(a) && strcmpi(a, '-depth')
            profondeur = double(args{k + 1});
            k = k + 2;
        elseif ischar(a) && k < numel(args)
            criteres(end + 1:end + 2) = args(k:k + 1); %#ok<AGROW>
            k = k + 2;
        else
            error('Stateflow:API:InvalidFindArguments', ...
                  ['FIND(OBJET,''-isa'',CLASSE,''Propriete'',VALEUR,...) : les criteres vont ' ...
                   'par paires.']);
        end
    end
    candidats = {};
    if ischar(racine) && strcmp(racine, 'racine')
        noms = matlibre_sl_ouverts('noms');
        for j = 1:numel(noms)
            candidats{end + 1} = get_param(noms{j}, 'Object'); %#ok<AGROW>
            candidats = [candidats, objetsDuSysteme(get_param(noms{j}, 'Handle'))]; %#ok<AGROW>
        end
    elseif isa(racine, 'Simulink.BlockDiagram') || isa(racine, 'Simulink.Block')
        candidats = [{racine}, objetsDuSysteme(racine.Handle)];
    else
        [h, id] = vue(racine);
        candidats = [{racine}, descendants(h, id, profondeur)];
    end
    trouves = [];
    liste = {};
    for j = 1:numel(candidats)
        o = candidats{j};
        if ~isempty(classe) && ~isa(o, classe)
            continue
        end
        garder = true;
        for q = 1:2:numel(criteres)
            try
                v = o.(criteres{q});
            catch
                garder = false;
                break
            end
            if ~isequal(v, criteres{q + 1})
                garder = false;
                break
            end
        end
        if garder
            liste{end + 1} = o; %#ok<AGROW>
        end
    end
    if ~isempty(liste)
        trouves = liste{1};
        for j = 2:numel(liste)
            if strcmp(class(liste{j}), class(trouves))
                trouves = [trouves, liste{j}]; %#ok<AGROW>
            else
                trouves = liste;   % des classes mêlées : une cellule
                return
            end
        end
    end
end

% Les diagrammes d'un modèle et ce qu'ils contiennent.
function liste = objetsDuSysteme(h)
    liste = {};
    blocs = find_system(h, 'BlockType', 'Chart');
    for j = 1:numel(blocs)
        if blocs(j) == h
            continue
        end
        if isempty(get_param(blocs(j), 'Diagramme'))
            continue   % une machine bâtie par SFCHART : sans objets
        end
        liste{end + 1} = matlibre_sf_api('objet', blocs(j), 0); %#ok<AGROW>
        liste = [liste, descendants(blocs(j), 0, Inf)]; %#ok<AGROW>
    end
end

function liste = descendants(h, id, profondeur)
    liste = {};
    if profondeur < 1
        return
    end
    D = lire(h);
    for k = 1:numel(D.elements)
        e = D.elements(k);
        if e.Parent == id
            liste{end + 1} = matlibre_sf_api('objet', h, e.Id); %#ok<AGROW>
            if strcmp(e.Classe, 'State')
                liste = [liste, descendants(h, e.Id, profondeur - 1)]; %#ok<AGROW>
            end
        end
    end
end

% --- les ports, et la machine du moteur --------------------------------------------

function n = ports(p)
    D = decoder(p.Diagramme);
    E = D.elements;
    if isempty(E)
        n = [0 0];
        return
    end
    donnees = strcmp({E.Classe}, 'Data');
    evenements = strcmp({E.Classe}, 'Event');
    portees = {E.Scope};
    n = [sum(donnees & strcmp(portees, 'Input')) + any(evenements & strcmp(portees, 'Input')), ...
         sum(donnees & strcmp(portees, 'Output')) + sum(evenements & strcmp(portees, 'Output'))];
end

function [m, contexte, sorties, entrees] = machine(p, chemin)
    D = decoder(p.Diagramme);
    E = D.elements;
    if isempty(E)
        E = elementsVides();
    end
    classes = {E.Classe};
    m = sfchart(chemin);
    % les données : les entrées et les sorties dans l'ordre de leurs ports,
    % le contexte de départ
    donnees = E(strcmp(classes, 'Data'));
    noms = {donnees.Name};
    for j = 1:numel(donnees)
        if isempty(noms{j})
            error('Stateflow:API:UnnamedData', ...
                  'Une donnee du diagramme ''%s'' n''a pas de nom.', chemin);
        end
        if sum(strcmp(noms, noms{j})) > 1
            error('Stateflow:API:DuplicateData', ...
                  'Le diagramme ''%s'' a deux donnees nommees ''%s''.', chemin, noms{j});
        end
    end
    entreesD = ordonnes(donnees(strcmp({donnees.Scope}, 'Input')));
    sortiesD = ordonnes(donnees(strcmp({donnees.Scope}, 'Output')));
    entrees = {entreesD.Name};
    sorties = {sortiesD.Name};
    contexte = struct();
    for j = 1:numel(donnees)
        d = donnees(j);
        switch d.Scope
            case 'Input'
                v = 0;
            case 'Parameter'
                [trouve, v] = matlibre_sl_espace('valeur', chemin, d.Name);
                if ~trouve
                    error('Stateflow:API:ParameterNotFound', ...
                          ['La donnee ''%s'' du diagramme ''%s'' est un parametre, et aucune ' ...
                           'variable ''%s'' ne la porte : ni l''espace du modele, ni son ' ...
                           'dictionnaire, ni l''espace de travail de base.'], d.Name, chemin, ...
                          d.Name);
                end
                if isa(v, 'Simulink.Parameter')
                    v = v.Value;
                end
            otherwise
                v = 0;
                if ~isempty(strtrim(d.InitialValue))
                    try
                        v = evalin('base', d.InitialValue);
                    catch err
                        error('Stateflow:API:InvalidInitialValue', ...
                              ['La valeur initiale ''%s'' de la donnee ''%s'' du diagramme ' ...
                               '''%s'' ne s''evalue pas : %s'], d.InitialValue, d.Name, chemin, ...
                              err.message);
                    end
                end
        end
        if ~strncmp(d.DataType, 'Inherit', 7) && ~strcmp(d.Scope, 'Input')
            if strcmp(d.DataType, 'boolean')
                v = logical(v);
            else
                v = cast(v, d.DataType);
            end
        end
        contexte.(d.Name) = v;
    end
    % les événements
    evenements = E(strcmp(classes, 'Event'));
    for j = 1:numel(evenements)
        ev = evenements(j);
        if strcmp(ev.Scope, 'Local')
            error('Stateflow:API:LocalEvent', ...
                  ['L''evenement ''%s'' du diagramme ''%s'' est local : seuls les evenements ' ...
                   'd''entree et de sortie sont pris en charge.'], ev.Name, chemin);
        end
    end
    for portee = {'Input', 'Output'}
        for ev = ordonnes(evenements(strcmp({evenements.Scope}, portee{1})))
            m = sfevent(m, ev.Name, portee{1}, ev.Trigger);
        end
    end
    % les états, de haut en bas
    etats = E(strcmp(classes, 'State'));
    if isempty(etats)
        error('Simulink:blocks:ChartNoState', 'Le diagramme ''%s'' n''a pas d''etat.', chemin);
    end
    complets = containers.Map('KeyType', 'double', 'ValueType', 'any');
    m = ajouterEtats(m, D, etats, 0, '', complets, chemin);
    if strcmp(D.chart.Decomposition, 'PARALLEL_AND')
        m = sfdecomposition(m, '', 'parallel');
    end
    % les jonctions
    jonctions = E(strcmp(classes, 'Junction'));
    nomsJ = containers.Map('KeyType', 'double', 'ValueType', 'any');
    for j = 1:numel(jonctions)
        J = jonctions(j);
        if strcmp(J.Type, 'HISTORY')
            if J.Parent == 0
                error('Stateflow:API:HistoryJunctionAtChartLevel', ...
                      ['La jonction d''historique %d du diagramme ''%s'' est au niveau du ' ...
                       'diagramme : elle se pose dans un etat.'], J.Id, chemin);
            end
            m = sfhistory(m, complets(J.Parent));
        else
            nomsJ(J.Id) = sprintf('jonction%d', J.Id);
            m = sfjunction(m, nomsJ(J.Id));
        end
    end
    % les transitions par défaut, puis les autres, dans leur ordre
    transitions = E(strcmp(classes, 'Transition'));
    for j = 1:numel(transitions)
        t = transitions(j);
        if t.Destination == 0
            error('Stateflow:API:DanglingTransition', ...
                  'La transition %d du diagramme ''%s'' n''a pas de destination.', t.Id, chemin);
        end
    end
    parDefaut = transitions([transitions.Source] == 0);
    conteneurs = unique([0, etats.Id]);
    for c = conteneurs
        enfants = etats([etats.Parent] == c);
        if isempty(enfants) || strcmp(decompositionDe(D, c), 'PARALLEL_AND')
            continue
        end
        idsEnfants = [enfants.Id];
        defauts = parDefaut(ismember([parDefaut.Destination], idsEnfants));
        if numel(defauts) > 1
            error('Stateflow:API:MultipleDefaultTransitions', ...
                  'Le diagramme ''%s'' a %d transitions par defaut vers les etats de %s.', ...
                  chemin, numel(defauts), nomConteneur(complets, c, chemin));
        end
        if isempty(defauts)
            if numel(enfants) > 1
                error('Stateflow:API:NoDefaultTransition', ...
                      ['Le diagramme ''%s'' n''a pas de transition par defaut vers les etats ' ...
                       'de %s : sans elle, on ne sait dans lequel entrer.'], chemin, ...
                      nomConteneur(complets, c, chemin));
            end
            m = sfdefault(m, complets(enfants(1).Id));
        else
            m = sfdefault(m, complets(defauts.Destination));
        end
    end
    autres = transitions([transitions.Source] ~= 0);
    sources = unique([autres.Source]);
    for s = sources
        for t = ordonnes(autres([autres.Source] == s))
            depuis = nomExtremite(t.Source, complets, nomsJ, chemin, t.Id);
            vers = nomExtremite(t.Destination, complets, nomsJ, chemin, t.Id);
            m = sftransition(m, depuis, vers, t.LabelString);
        end
    end
end

function m = ajouterEtats(m, D, etats, parent, prefixe, complets, chemin)
    enfants = etats([etats.Parent] == parent);
    noms = {enfants.Name};
    for j = 1:numel(enfants)
        e = enfants(j);
        if isempty(e.Name)
            error('Stateflow:API:UnnamedState', ...
                  'L''etat %d du diagramme ''%s'' n''a pas de nom.', e.Id, chemin);
        end
        if sum(strcmp(noms, e.Name)) > 1
            error('Stateflow:API:DuplicateStateName', ...
                  'Le diagramme ''%s'' a deux etats nommes ''%s'' au meme niveau.', chemin, ...
                  e.Name);
        end
        nom = e.Name;
        if ~isempty(prefixe)
            nom = [prefixe '.' e.Name];
        end
        complets(e.Id) = nom;
        [~, actions] = premiereLigne(e.LabelString);
        actions = strtrim(actions);
        if isempty(actions)
            m = sfstate(m, nom);
        elseif isempty(regexp(actions, '(^|[\s;,])(en|entry|du|during|ex|exit)\s*:', 'once'))
            m = sfstate(m, nom, ['en: ' actions]);   % une action sans mot-clé : à l'entrée
        else
            m = sfstate(m, nom, actions);
        end
        m = ajouterEtats(m, D, etats, e.Id, nom, complets, chemin);
        if strcmp(e.Decomposition, 'PARALLEL_AND')
            m = sfdecomposition(m, nom, 'parallel');
        end
    end
end

function n = nomExtremite(id, complets, nomsJ, chemin, idT)
    if isKey(complets, id)
        n = complets(id);
    elseif isKey(nomsJ, id)
        n = nomsJ(id);
    else
        error('Stateflow:API:InvalidEndpoint', ...
              ['La transition %d du diagramme ''%s'' touche un objet qui n''est ni un etat ' ...
               'ni une jonction de connexion.'], idT, chemin);
    end
end

function n = nomConteneur(complets, c, chemin)
    if c == 0
        n = ['''' chemin ''''];
    else
        n = ['''' complets(c) ''''];
    end
end
