classdef CasierEssai
%CASIERESSAI Une classe d'essai qui surcharge SUBSREF pour les accolades :
%   C{K} rend sa K-ième case, et END y vaut le nombre de cases. Elle sert
%   à éprouver « end » au bout d'une chaîne qui traverse un tel objet.
    properties
        Cases = {}
    end
    methods
        function obj = CasierEssai(cases)
            obj.Cases = cases;
        end
        function varargout = subsref(obj, s)
            switch s(1).type
                case '{}'
                    v = obj.Cases{s(1).subs{1}};
                case '()'
                    v = CasierEssai(obj.Cases(s(1).subs{1}));
                otherwise
                    v = obj.(s(1).subs);
            end
            if numel(s) == 1
                varargout{1} = v;
            else
                [varargout{1:max(1, nargout)}] = subsref(v, s(2:end));
            end
        end
        function n = end(obj, ~, ~)
            n = numel(obj.Cases);
        end
    end
end
