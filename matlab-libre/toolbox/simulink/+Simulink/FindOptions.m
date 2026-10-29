classdef FindOptions
%FINDOPTIONS Les options d'une recherche de blocs.
%   F = SIMULINK.FINDOPTIONS crée les options par défaut ;
%   SIMULINK.FINDOPTIONS('SearchDepth',1,...) en règle par paires. Elles
%   valent pour SIMULINK.FINDBLOCKS et SIMULINK.FINDBLOCKSOFTYPE :
%      CaseSensitive        true : les valeurs se comparent avec la casse
%      FollowLinks          true : descend dans les blocs liés à une
%                           bibliothèque
%      IncludeCommented     true : les blocs commentés comptent
%      LookUnderMasks       'all' (défaut), 'none', 'graphical' ou
%                           'functional'
%      RegExp               false ; true : les valeurs sont des
%                           expressions régulières
%      SearchDepth          -1 : toutes les profondeurs ; 1 : le système
%                           seul, sans ce qu'il contient
%      Variants             'AllVariants', ou 'ActiveVariants'...
%
%   Exemple :
%      f = Simulink.FindOptions('SearchDepth', 1);
%      f.SearchDepth                      % 1
%      f.LookUnderMasks                   % 'all'
%
%   Voir aussi SIMULINK.FINDBLOCKS, SIMULINK.FINDBLOCKSOFTYPE, FIND_SYSTEM.
    properties
        CaseSensitive = true
        FollowLinks = true
        IncludeCommented = true
        LookUnderMasks = 'all'
        RegExp = false
        SearchDepth = -1
        Variants = 'AllVariants'
        LookInsideSubsystemReference = true
        MatchFilter = []
    end
    methods
        function f = FindOptions(varargin)
            if mod(numel(varargin), 2) ~= 0
                error('Simulink:Commands:FindOptionsArguments', ...
                      'SIMULINK.FINDOPTIONS(''Option'',VALEUR,...) : les options vont par paires.');
            end
            noms = properties(f);
            for k = 1:2:numel(varargin)
                j = find(strcmpi(noms, char(varargin{k})), 1);
                if isempty(j)
                    error('Simulink:Commands:FindOptionsUnknown', ...
                          'Simulink.FindOptions n''a pas d''option ''%s'' : %s.', ...
                          char(varargin{k}), strjoin(noms.', ', '));
                end
                f.(noms{j}) = varargin{k + 1};
            end
        end
        function f = set.SearchDepth(f, v)
            if ~isnumeric(v) || ~isscalar(v) || v ~= round(v) || (v < 1 && v ~= -1)
                error('Simulink:Commands:FindOptionsInvalid', ...
                      'SearchDepth est un entier positif, ou -1 pour toutes les profondeurs.');
            end
            f.SearchDepth = double(v);
        end
        function f = set.LookUnderMasks(f, v)
            choix = {'all', 'none', 'graphical', 'functional'};
            k = [];
            if ischar(v) || (isstring(v) && isscalar(v))
                k = find(strcmpi(char(v), choix), 1);
            end
            if isempty(k)
                error('Simulink:Commands:FindOptionsInvalid', ...
                      'LookUnderMasks vaut ''all'', ''none'', ''graphical'' ou ''functional''.');
            end
            f.LookUnderMasks = choix{k};
        end
        function f = set.CaseSensitive(f, v)
            f.CaseSensitive = logique(v, 'CaseSensitive');
        end
        function f = set.FollowLinks(f, v)
            f.FollowLinks = logique(v, 'FollowLinks');
        end
        function f = set.IncludeCommented(f, v)
            f.IncludeCommented = logique(v, 'IncludeCommented');
        end
        function f = set.RegExp(f, v)
            f.RegExp = logique(v, 'RegExp');
        end
    end
end

function v = logique(v, nom)
    if ~(islogical(v) || isnumeric(v)) || ~isscalar(v)
        error('Simulink:Commands:FindOptionsInvalid', '%s vaut true ou false.', nom);
    end
    v = logical(v);
end
