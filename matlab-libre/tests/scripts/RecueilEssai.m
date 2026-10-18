classdef RecueilEssai
%RECUEILESSAI Une classe d'essai qui surcharge SUBSREF et dit, par
%   numArgumentsFromSubscript, combien de valeurs rend une chaîne lue là
%   où une liste est attendue.
    properties
        Contenu = struct()
        Contextes = {}
    end
    methods
        function obj = RecueilEssai(contenu)
            obj.Contenu = contenu;
        end
        function varargout = subsref(obj, s)
            v = obj.Contenu.(s(1).subs);
            if numel(s) == 1
                varargout{1} = v;
            else
                [varargout{1:max(1, nargout)}] = subsref(v, s(2:end));
            end
        end
        function n = numArgumentsFromSubscript(obj, s, contexte)
            assert(isa(contexte, 'matlab.indexing.IndexingContext') && ...
                   contexte == matlab.indexing.IndexingContext.Expression, ...
                   'le contexte d''une liste est Expression');
            n = 1;
            if numel(s) == 2 && strcmp(s(2).type, '.')
                n = numel(obj.Contenu.(s(1).subs));
            end
        end
    end
end
