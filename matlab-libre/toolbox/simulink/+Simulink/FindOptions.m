classdef FindOptions
%SIMULINK.FINDOPTIONS Les options d'une recherche de blocs.
%   O = SIMULINK.FINDOPTIONS('Option',VALEUR,...) décrit comment
%   SIMULINK.FINDBLOCKS et SIMULINK.FINDBLOCKSOFTYPE cherchent :
%     CaseSensitive   vrai : la casse compte dans les valeurs comparées
%     FollowLinks     faux : on n'entre pas dans les blocs liés à une
%                     bibliothèque
%     LookUnderMasks  'all' : on entre sous tous les masques ('none',
%                     'graphical', 'functional')
%     RegExp          faux : les valeurs sont des textes, non des
%                     expressions régulières
%     SearchDepth     -1 : tous les niveaux ; 1 : le système seul
%     IncludeCommented  vrai
%
%   Exemple :
%      o = Simulink.FindOptions('SearchDepth', 1, 'RegExp', true);
%      o.SearchDepth                            % 1
%
%   Voir aussi SIMULINK.FINDBLOCKS, SIMULINK.FINDBLOCKSOFTYPE, FIND_SYSTEM.
    properties
        CaseSensitive = true
        FollowLinks = false
        IncludeCommented = true
        LookUnderMasks = 'all'
        RegExp = false
        SearchDepth = -1
    end
    methods
        function obj = FindOptions(varargin)
            if mod(numel(varargin), 2) ~= 0
                error('Simulink:FindOptions:Pairs', ...
                      'Simulink.FindOptions : les options vont par paires, un nom et une valeur.');
            end
            noms = properties(obj);
            for k = 1:2:numel(varargin)
                i = find(strcmpi(char(varargin{k}), noms), 1);
                if isempty(i)
                    error('Simulink:FindOptions:UnknownOption', ...
                          'Simulink.FindOptions n''a pas d''option ''%s''. Ses options : %s.', ...
                          char(varargin{k}), strjoin(noms(:).', ', '));
                end
                obj.(noms{i}) = varargin{k + 1};
            end
        end
        function arguments = enArguments(obj)
            % les mêmes options, comme FIND_SYSTEM les attend
            surOff = {'off', 'on'};
            arguments = {'CaseSensitive', surOff{1 + logical(obj.CaseSensitive)}, ...
                         'FollowLinks', surOff{1 + logical(obj.FollowLinks)}, ...
                         'IncludeCommented', surOff{1 + logical(obj.IncludeCommented)}, ...
                         'LookUnderMasks', char(obj.LookUnderMasks), ...
                         'RegExp', surOff{1 + logical(obj.RegExp)}};
            if obj.SearchDepth >= 0
                arguments = [arguments, {'SearchDepth', obj.SearchDepth}];
            end
        end
    end
end
