function varargout = matlibre_sf_objet(action, varargin)
%MATLIBRE_SF_OBJET L'indexation des objets Stateflow, et leur identité.
%   O = MATLIBRE_SF_OBJET('obtenir',H,ID,CLASSE) rend l'objet ID du
%   diagramme du bloc H, le même à chaque fois ;
%   MATLIBRE_SF_OBJET('memoriser',O) retient un objet qui vient d'être
%   créé. V = MATLIBRE_SF_OBJET('lire',O,S) et
%   O = MATLIBRE_SF_OBJET('ecrire',O,S,V) font O.Prop, O.Prop = V et les
%   appels de méthode O.find(...), O.delete()...
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      sfnew('objetSf');
%      ch = find(sfroot, '-isa', 'Stateflow.Chart', 'Path', 'objetSf/Chart');
%      s = Stateflow.State(ch);
%      s == find(ch, '-isa', 'Stateflow.State')   % true
%      close_system('objetSf', 0);
%
%   Voir aussi MATLIBRE_SF_API, SFROOT.
    persistent objets
    if isempty(objets)
        objets = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    switch action
        case 'obtenir'
            [h, id, classe] = varargin{1:3};
            clef = sprintf('%.17g|%d', h, id);
            if isKey(objets, clef) && strcmp(class(objets(clef)), classe)
                varargout{1} = objets(clef);
                return
            end
            o = feval(classe, 'matlibre__vue', h, id);
            objets(clef) = o;
            varargout{1} = o;
        case 'memoriser'
            o = varargin{1};
            [h, id] = vue(o);
            objets(sprintf('%.17g|%d', h, id)) = o;
        case 'lire'
            [o, s] = varargin{1:2};
            varargout{1} = lire(o, s);
        case 'ecrire'
            [o, s, v] = varargin{1:3};
            if strcmp(s(1).type, '()') && numel(s) == 1
                varargout{1} = builtin('subsasgn', o, s, v);
                return
            end
            if ~strcmp(s(1).type, '.') || numel(o) ~= 1
                error('Stateflow:API:InvalidAssignment', ...
                      'Un objet Stateflow se regle par ses proprietes : o.Prop = valeur.');
            end
            if numel(s) > 1
                actuel = matlibre_sf_api('propriete', o, s(1).subs);
                v = subsasgn(actuel, s(2:end), v);
            end
            matlibre_sf_api('poser', o, s(1).subs, v);
            varargout{1} = o;
        case 'egal'
            % deux objets sont égaux quand ils désignent le même élément du
            % même diagramme
            [a, b] = varargin{1:2};
            ca = clefs(a);
            cb = clefs(b);
            if numel(ca) == 1
                ca = repmat(ca, size(cb));
            elseif numel(cb) == 1
                cb = repmat(cb, size(ca));
            end
            if ~isequal(size(ca), size(cb))
                error('MATLAB:dimagree', 'Les deux operandes de == n''ont pas la meme taille.');
            end
            varargout{1} = reshape(strcmp(ca, cb), size(ca));
        case 'methode'
            [nom, o, arguments] = varargin{1:3};
            varargout{1} = methode(nom, o, arguments);
        case 'afficher'
            o = varargin{1};
            for k = 1:numel(o)
                x = builtin('subsref', o, struct('type', '()', 'subs', {{k}}));
                try
                    nom = '';
                    if any(strcmp(class(x), {'Stateflow.State', 'Stateflow.Data', ...
                                             'Stateflow.Event', 'Stateflow.Chart'}))
                        nom = [' ''' matlibre_sf_api('propriete', x, 'Name') ''''];
                    elseif strcmp(class(x), 'Stateflow.Transition')
                        nom = [' ''' matlibre_sf_api('propriete', x, 'LabelString') ''''];
                    end
                    fprintf('  %s%s, dans %s\n', class(x), nom, ...
                            matlibre_sf_api('propriete', x, 'Path'));
                catch
                    fprintf('  %s, qui n''existe plus\n', class(x));
                end
            end
            fprintf('\n');
        otherwise
            error('Stateflow:API:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

function c = clefs(o)
    if ~isobject(o) || ~strncmp(class(o), 'Stateflow.', 10) || strcmp(class(o), 'Stateflow.Root')
        c = repmat({''}, size(o));
        if isempty(o)
            c = {};
        end
        return
    end
    c = cell(size(o));
    for k = 1:numel(o)
        x = builtin('subsref', o, struct('type', '()', 'subs', {{k}}));
        [h, id] = vue(x);
        c{k} = sprintf('%s|%.17g|%d', class(x), h, id);
    end
end

function [h, id] = vue(o)
    h = builtin('subsref', o, struct('type', '.', 'subs', 'Bloc'));
    id = builtin('subsref', o, struct('type', '.', 'subs', 'Id_'));
end

function v = lire(o, s)
    switch s(1).type
        case '()'
            v = builtin('subsref', o, s(1));
            reste = s(2:end);
        case '.'
            if numel(o) ~= 1
                error('Stateflow:API:ObjectArrayIndexing', ...
                      'Un tableau d''objets se lit element par element : o(k).%s.', s(1).subs);
            end
            nom = s(1).subs;
            reste = s(2:end);
            methodes = {'find', 'delete', 'get', 'set', 'view', 'fitToView', 'dialog', ...
                        'getChildren'};
            k = find(strcmpi(methodes, nom), 1);
            if isempty(k)
                v = matlibre_sf_api('propriete', o, nom);
            else
                arguments = {};
                if ~isempty(reste) && strcmp(reste(1).type, '()')
                    arguments = reste(1).subs;
                    reste = reste(2:end);
                end
                v = methode(methodes{k}, o, arguments);
            end
        otherwise
            error('MATLAB:cellRefFromNonCell', ...
                  'Brace indexing is not supported for variables of this type.');
    end
    if ~isempty(reste)
        v = subsref(v, reste);
    end
end

function v = methode(nom, o, arguments)
    v = [];
    switch nom
        case 'find'
            v = matlibre_sf_api('trouver', o, arguments);
        case 'delete'
            matlibre_sf_api('supprimer', o);
        case 'get'
            if isempty(arguments)
                noms = matlibre_sf_api('proprietes', class(o));
                v = struct();
                for k = 1:numel(noms)
                    v.(noms{k}) = matlibre_sf_api('propriete', o, noms{k});
                end
            else
                v = matlibre_sf_api('propriete', o, arguments{1});
            end
        case 'set'
            if mod(numel(arguments), 2) ~= 0
                error('Stateflow:API:InvalidAssignment', ...
                      'SET(O,''Prop'',VALEUR,...) : les proprietes vont par paires.');
            end
            for k = 1:2:numel(arguments)
                matlibre_sf_api('poser', o, arguments{k}, arguments{k + 1});
            end
        case 'getChildren'
            v = matlibre_sf_api('trouver', o, {'-depth', 1});
            if isequal(v, o)
                v = [];
            elseif ~iscell(v) && numel(v) > 0 && v(1) == o
                v = v(2:end);
            elseif iscell(v)
                v = v(2:end);
            end
        otherwise
            % view, fitToView, dialog : ce que l'éditeur graphique montre
    end
end
