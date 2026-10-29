classdef Block < handle
%BLOCK Un bloc d'un modèle chargé, comme objet.
%   O = GET_PARAM(OBJET,'Object') le rend, le même objet à chaque fois.
%   O.Param lit un paramètre ou un réglage, comme GET_PARAM ; O.Param = V
%   le pose, comme SET_PARAM, et GET(O,'Param'), SET(O,'Param',V) de même.
%   O.Handle est sa poignée. Méthodes : GETFULLNAME, son chemin complet ;
%   GETPARENT, l'objet du système qui le contient ; GETCHILDREN, les
%   objets des blocs qu'il contient, pour un modèle ou un sous-système.
%
%   Exemple :
%      new_system('blocObjet');
%      add_block('built-in/Gain', 'blocObjet/g', 'Gain', '2');
%      o = get_param('blocObjet/g', 'Object');
%      o.Gain                             % '2'
%      o.Gain = '5';
%      get_param('blocObjet/g', 'Gain')   % '5'
%      o.getFullName()                    % 'blocObjet/g'
%      close_system('blocObjet', 0);
%
%   Voir aussi GET_PARAM, SIMULINK.BLOCKDIAGRAM, SIMULINK.PORT.
    properties (Hidden, SetAccess = private)
        Poignee = []
    end
    methods
        function o = Block(h)
            if nargin > 0
                o.Poignee = h;
            end
        end
        function varargout = subsref(o, s)
            varargout{1} = matlibre_sl_objet('lire', o, s);
        end
        function o = subsasgn(o, s, v)
            o = matlibre_sl_objet('ecrire', o, s, v);
        end
        function n = numArgumentsFromSubscript(o, s, contexte) %#ok<INUSD>
            n = 1;
        end
        function chemin = getFullName(o)
            chemin = getfullname(o.Poignee);
        end
        function p = getParent(o)
            p = [];
            parent = get_param(o.Poignee, 'Parent');
            if ~isempty(parent)
                p = get_param(parent, 'Object');
            end
        end
        function enfants = getChildren(o)
            enfants = [];
            if ~any(strcmp(get_param(o.Poignee, 'Type'), {'block', 'block_diagram'}))
                return
            end
            if strcmp(get_param(o.Poignee, 'Type'), 'block') && ...
               ~strcmp(get_param(o.Poignee, 'BlockType'), 'SubSystem')
                return
            end
            h = find_system(o.Poignee, 'SearchDepth', 1, 'Type', 'block');
            h = h(h ~= o.Poignee);
            liste = cell(1, numel(h));
            for k = 1:numel(h)
                liste{k} = get_param(h(k), 'Object');
            end
            if ~isempty(liste)
                enfants = [liste{:}];
            end
        end
        function v = get(o, nom)
            if nargin < 2
                v = get_param(o.Poignee, 'ObjectParameters');
            elseif strcmpi(char(nom), 'Handle')
                v = o.Poignee;
            else
                v = get_param(o.Poignee, nom);
            end
        end
        function set(o, varargin)
            set_param(o.Poignee, varargin{:});
        end
        function disp(o)
            for k = 1:numel(o)
                x = builtin('subsref', o, struct('type', '()', 'subs', {{k}}));
                h = builtin('subsref', x, struct('type', '.', 'subs', 'Poignee'));
                try
                    fprintf('  %s : %s\n', class(x), getfullname(h));
                catch
                    fprintf('  %s : poignee %g, qui ne designe plus rien\n', class(x), h);
                end
            end
            fprintf('\n');
        end
    end
end
