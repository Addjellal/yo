classdef State < handle
%STATE Un état d'un diagramme Stateflow.
%   S = STATEFLOW.STATE(PARENT) crée un état dans PARENT, un diagramme
%   (Stateflow.Chart) ou un état, dont il devient un sous-état.
%   Propriétés : Name ; LabelString, son étiquette — le nom sur la
%   première ligne, puis ses actions : « entry: y = 1; during: n = n + 1;
%   exit: ... » (en, du, ex), une action sans mot-clé valant à l'entrée ;
%   Decomposition, 'EXCLUSIVE_OR' ou 'PARALLEL_AND' pour ses sous-états ;
%   Position ; Description ; et, en lecture seule, Id, Type ('OR', 'AND'),
%   Path et Chart.
%
%   Méthodes : FIND, DELETE, GET, SET ; VIEW et FITTOVIEW ne font rien.
%
%   Exemple :
%      sfnew('etatEssai');
%      ch = find(sfroot, '-isa', 'Stateflow.Chart', 'Path', 'etatEssai/Chart');
%      s = Stateflow.State(ch);
%      s.LabelString = ['marche' newline 'entry: y = 1;'];
%      s.Name                                 % 'marche'
%      close_system('etatEssai', 0);
%
%   Voir aussi SFNEW, SFROOT, STATEFLOW.CHART, STATEFLOW.STATE, STATEFLOW.TRANSITION.
    properties (Hidden, SetAccess = private)
        Bloc = []
        Id_ = 0
    end
    methods
        function o = State(parent, h, id)
            if nargin == 3 && ischar(parent) && strcmp(parent, 'matlibre__vue')
                o.Bloc = h;
                o.Id_ = id;
                return
            end
            if nargin < 1
                error('Stateflow:API:InvalidParent', ...
                      'STATEFLOW.State(PARENT) : PARENT est un diagramme ou un etat.');
            end
            [h, id] = matlibre_sf_api('creer', parent, 'Stateflow.State');
            o.Bloc = h;
            o.Id_ = id;
            matlibre_sf_objet('memoriser', o);
        end
        function varargout = subsref(o, s)
            varargout{1} = matlibre_sf_objet('lire', o, s);
        end
        function o = subsasgn(o, s, v)
            o = matlibre_sf_objet('ecrire', o, s, v);
        end
        function n = numArgumentsFromSubscript(o, s, contexte) %#ok<INUSD>
            n = 1;
        end
        function v = find(o, varargin)
            v = matlibre_sf_objet('methode', 'find', o, varargin);
        end
        function delete(o)
            matlibre_sf_objet('methode', 'delete', o, {});
        end
        function v = get(o, varargin)
            v = matlibre_sf_objet('methode', 'get', o, varargin);
        end
        function set(o, varargin)
            matlibre_sf_objet('methode', 'set', o, varargin);
        end
        function v = getChildren(o)
            v = matlibre_sf_objet('methode', 'getChildren', o, {});
        end
        function r = eq(a, b)
            r = matlibre_sf_objet('egal', a, b);
        end
        function r = ne(a, b)
            r = ~matlibre_sf_objet('egal', a, b);
        end
        function view(o) %#ok<MANU>
        end
        function fitToView(o) %#ok<MANU>
        end
        function disp(o)
            matlibre_sf_objet('afficher', o);
        end
    end
end
