classdef Chart < handle
%CHART Un diagramme Stateflow : un bloc Chart vu comme objet.
%   CH = FIND(SFROOT,'-isa','Stateflow.Chart',...) le rend. Propriétés :
%   Name et SampleTime, ceux du bloc ; Decomposition de ses états de
%   premier niveau ; ActionLanguage, StateMachineType, ChartUpdate,
%   ExecuteAtInitialization, Description ; Id et Path en lecture seule.
%   Les états, transitions, jonctions, données et événements se créent
%   dans le diagramme : STATEFLOW.STATE(CH)...
%
%   Méthodes : FIND, DELETE, GET, SET ; VIEW et FITTOVIEW ne font rien.
%
%   Exemple :
%      sfnew('diagrammeEssai');
%      ch = find(sfroot, '-isa', 'Stateflow.Chart', 'Path', 'diagrammeEssai/Chart');
%      ch.Name                                % 'Chart'
%      ch.Decomposition = 'PARALLEL_AND';
%      close_system('diagrammeEssai', 0);
%
%   Voir aussi SFNEW, SFROOT, STATEFLOW.CHART, STATEFLOW.STATE, STATEFLOW.TRANSITION.
    properties (Hidden, SetAccess = private)
        Bloc = []
        Id_ = 0
    end
    methods
        function o = Chart(parent, h, id)
            if nargin == 3 && ischar(parent) && strcmp(parent, 'matlibre__vue')
                o.Bloc = h;
                o.Id_ = id;
                return
            end
            error('Stateflow:API:ChartConstructor', ...
                  ['Un diagramme est un bloc Chart : SFNEW ou ADD_BLOCK(''sflib/Chart'',...) ' ...
                   'le pose, FIND(SFROOT,''-isa'',''Stateflow.Chart'') le rend.']);
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
