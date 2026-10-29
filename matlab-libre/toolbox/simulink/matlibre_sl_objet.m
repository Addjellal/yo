function varargout = matlibre_sl_objet(action, varargin)
%MATLIBRE_SL_OBJET Les objets de bloc, de modèle, de ligne et de port.
%   O = MATLIBRE_SL_OBJET('obtenir',H) rend l'objet de la poignée H — un
%   Simulink.Block, Simulink.BlockDiagram, Simulink.Line ou Simulink.Port
%   —, le même à chaque fois pour une même poignée, comme dans Simulink.
%
%   V = MATLIBRE_SL_OBJET('lire',O,S) et O = MATLIBRE_SL_OBJET('ecrire',O,S,V)
%   font l'indexation de ces objets : O.Param se lit par GET_PARAM,
%   O.Param = V se pose par SET_PARAM, O.getFullName() et les autres
%   méthodes s'appellent.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      new_system('objetEssai');
%      add_block('built-in/Gain', 'objetEssai/g');
%      o = matlibre_sl_objet('obtenir', getSimulinkBlockHandle('objetEssai/g'));
%      o.Gain                             % '1'
%      close_system('objetEssai', 0);
%
%   Voir aussi GET_PARAM, SIMULINK.BLOCK.
    persistent objets
    if isempty(objets)
        objets = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    switch action
        case 'obtenir'
            h = varargin{1};
            [~, genre] = matlibre_sl_memoire('objet', h);
            switch genre
                case 'bloc'
                    classe = 'Simulink.Block';
                case 'modele'
                    classe = 'Simulink.BlockDiagram';
                case 'ligne'
                    classe = 'Simulink.Line';
                otherwise
                    classe = 'Simulink.Port';
            end
            clef = sprintf('%.17g', h);
            if isKey(objets, clef)
                o = objets(clef);
                if strcmp(class(o), classe)
                    varargout{1} = o;
                    return
                end
            end
            o = feval(classe, h);
            objets(clef) = o;
            varargout{1} = o;
        case 'lire'
            [o, s] = varargin{1:2};
            varargout{1} = lire(o, s);
        case 'ecrire'
            [o, s, v] = varargin{1:3};
            if strcmp(s(1).type, '()') && numel(s) == 1
                % un tableau d'objets : o(k) = autre
                varargout{1} = builtin('subsasgn', o, s, v);
                return
            end
            ecrire(o, s, v);
            varargout{1} = o;
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

function v = lire(o, s)
    switch s(1).type
        case '()'
            v = builtin('subsref', o, s(1));
            reste = s(2:end);
        case '.'
            if numel(o) ~= 1
                error('Simulink:Commands:ObjectArrayIndexing', ...
                      'Un tableau d''objets se lit element par element : o(k).%s.', s(1).subs);
            end
            nom = s(1).subs;
            reste = s(2:end);
            methodes = {'getFullName', 'getParent', 'getChildren', 'get', 'set'};
            k = find(strcmpi(methodes, nom), 1);
            if ~isempty(k)
                arguments = {};
                if ~isempty(reste) && strcmp(reste(1).type, '()')
                    arguments = reste(1).subs;
                    reste = reste(2:end);
                end
                v = feval(methodes{k}, o, arguments{:});
            elseif strcmpi(nom, 'Handle')
                v = poignee(o);
            else
                v = get_param(poignee(o), nom);
            end
        otherwise
            error('MATLAB:cellRefFromNonCell', ...
                  'Brace indexing is not supported for variables of this type.');
    end
    if ~isempty(reste)
        v = subsref(v, reste);
    end
end

function ecrire(o, s, v)
    if ~strcmp(s(1).type, '.') || numel(o) ~= 1
        error('Simulink:Commands:ObjectAssignment', ...
              'Un objet de Simulink se regle par ses proprietes : o.Param = valeur.');
    end
    nom = s(1).subs;
    if strcmpi(nom, 'Handle')
        error('Simulink:Commands:SetParamReadOnly', ...
              'La propriete Handle d''un objet de Simulink se lit, mais ne se regle pas.');
    end
    if numel(s) > 1
        actuel = get_param(poignee(o), nom);
        v = subsasgn(actuel, s(2:end), v);
    end
    set_param(poignee(o), nom, v);
end

function h = poignee(o)
    h = builtin('subsref', o, struct('type', '.', 'subs', 'Poignee'));
end
