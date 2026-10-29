classdef Data < handle
%DATA Une donnée d'un diagramme Stateflow.
%   D = STATEFLOW.DATA(PARENT) crée une donnée. Scope : 'Local' (défaut),
%   'Input' — une entrée du bloc Chart, lue par son nom dans les
%   étiquettes —, 'Output' — une sortie —, 'Parameter' — la variable de
%   même nom, lue là où le bloc lit ses variables — ou 'Constant'.
%   DataType ('double', 'boolean', 'int8'...), Props.InitialValue, Port
%   (son rang parmi les entrées ou les sorties), Description ; Id, Path et
%   Chart en lecture seule.
%
%   Méthodes : FIND, DELETE, GET, SET ; VIEW et FITTOVIEW ne font rien.
%
%   Exemple :
%      sfnew('donneeEssai');
%      ch = find(sfroot, '-isa', 'Stateflow.Chart', 'Path', 'donneeEssai/Chart');
%      d = Stateflow.Data(ch);
%      d.Name = 'y'; d.Scope = 'Output';
%      d.Props.InitialValue = '3';
%      d.Port                                 % 1
%      close_system('donneeEssai', 0);
%
%   Voir aussi SFNEW, SFROOT, STATEFLOW.CHART, STATEFLOW.STATE, STATEFLOW.TRANSITION.
    properties (Hidden, SetAccess = private)
        Bloc = []
        Id_ = 0
    end
    methods
        function o = Data(parent, h, id)
            if nargin == 3 && ischar(parent) && strcmp(parent, 'matlibre__vue')
                o.Bloc = h;
                o.Id_ = id;
                return
            end
            if nargin < 1
                error('Stateflow:API:InvalidParent', ...
                      'STATEFLOW.Data(PARENT) : PARENT est un diagramme ou un etat.');
            end
            [h, id] = matlibre_sf_api('creer', parent, 'Stateflow.Data');
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
