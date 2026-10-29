classdef Junction < handle
%JUNCTION Une jonction d'un diagramme Stateflow.
%   J = STATEFLOW.JUNCTION(PARENT) crée une jonction de connexion
%   (Type 'CONNECTIVE'), où des transitions se rejoignent et se séparent ;
%   Type 'HISTORY', posée dans un état, lui donne un historique. Position,
%   Description ; Id, Path et Chart en lecture seule.
%
%   Méthodes : FIND, DELETE, GET, SET ; VIEW et FITTOVIEW ne font rien.
%
%   Exemple :
%      sfnew('jonctionEssai');
%      ch = find(sfroot, '-isa', 'Stateflow.Chart', 'Path', 'jonctionEssai/Chart');
%      j = Stateflow.Junction(ch);
%      j.Type                                 % 'CONNECTIVE'
%      close_system('jonctionEssai', 0);
%
%   Voir aussi SFNEW, SFROOT, STATEFLOW.CHART, STATEFLOW.STATE, STATEFLOW.TRANSITION.
    properties (Hidden, SetAccess = private)
        Bloc = []
        Id_ = 0
    end
    methods
        function o = Junction(parent, h, id)
            if nargin == 3 && ischar(parent) && strcmp(parent, 'matlibre__vue')
                o.Bloc = h;
                o.Id_ = id;
                return
            end
            if nargin < 1
                error('Stateflow:API:InvalidParent', ...
                      'STATEFLOW.Junction(PARENT) : PARENT est un diagramme ou un etat.');
            end
            [h, id] = matlibre_sf_api('creer', parent, 'Stateflow.Junction');
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
