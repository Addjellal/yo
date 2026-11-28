classdef FindOptions
%SIMULINK.FINDOPTIONS Les options d'une recherche de blocs.
%   O = SIMULINK.FINDOPTIONS('Option',VALEUR,...) — ou, comme dans MATLAB
%   récent, SIMULINK.FINDOPTIONS(Option=VALEUR,...) — décrit comment
%   SIMULINK.FINDBLOCKS et SIMULINK.FINDBLOCKSOFTYPE cherchent :
%     CaseSensitive      vrai : la casse compte dans les valeurs comparées
%     IncludeCommented   vrai : les blocs mis en commentaire sont rendus
%     RegExp             faux : les valeurs sont des textes, non des
%                        expressions régulières
%     SearchDepth        -1 : tous les niveaux ; 1 : le système seul
%     SearchUnderMasks   "all" : on entre sous tous les masques ("none",
%                        "graphical", "functional")
%     SearchInsideLibraryLinks  faux : on n'entre pas dans les blocs liés
%                        à une bibliothèque
%     MatchFilter        une fonction qui reçoit la poignée de chaque bloc
%                        trouvé, et rend vrai pour le garder
%   Les noms d'avant R2024 sont admis : LookUnderMasks pour
%   SearchUnderMasks, FollowLinks pour SearchInsideLibraryLinks,
%   LookInsideSubsystemReference pour SearchInsideSubsystemReferences.
%
%   Ce que MatLibre ne parcourt pas est dit, non tu :
%   SearchInsideSubsystemReferences (vrai par défaut) est accepté, mais les
%   références de sous-système ne sont pas parcourues ;
%   SearchInsideModelReferences n'admet que faux, son défaut, et Variants
%   que "AllVariants", son défaut — les variantes sont toutes parcourues.
%   LoadFullyIfNeeded est accepté : les modèles de la session sont
%   toujours chargés en entier.
%
%   Exemple :
%      o = Simulink.FindOptions('SearchDepth', 1, 'RegExp', true);
%      o.SearchDepth                            % 1
%      o = Simulink.FindOptions('LookUnderMasks', 'none');
%      o.SearchUnderMasks                       % 'none'
%
%   Voir aussi SIMULINK.FINDBLOCKS, SIMULINK.FINDBLOCKSOFTYPE, FIND_SYSTEM.
    properties
        CaseSensitive = true
        IncludeCommented = true
        LoadFullyIfNeeded = true
        MatchFilter = []
        RegExp = false
        SearchDepth = -1
        SearchInsideLibraryLinks = false
        SearchInsideModelReferences = false
        SearchInsideSubsystemReferences = true
        SearchUnderMasks = 'all'
        Variants = 'AllVariants'
    end
    properties (Dependent, Hidden)
        % les noms d'avant R2024, toujours admis
        FollowLinks
        LookUnderMasks
        LookInsideSubsystemReference
    end
    methods
        function obj = FindOptions(varargin)
            if mod(numel(varargin), 2) ~= 0
                error('Simulink:FindOptions:Pairs', ...
                      'Simulink.FindOptions options must be name-value pairs.');
            end
            noms = [properties(obj); {'FollowLinks'; 'LookUnderMasks'; ...
                                     'LookInsideSubsystemReference'}];
            for k = 1:2:numel(varargin)
                i = find(strcmpi(char(varargin{k}), noms), 1);
                if isempty(i)
                    error('Simulink:FindOptions:UnknownOption', ...
                          'Simulink.FindOptions has no option ''%s''. Valid options: %s.', ...
                          char(varargin{k}), strjoin(properties(obj).', ', '));
                end
                obj.(noms{i}) = varargin{k + 1};
            end
        end
        function v = get.FollowLinks(obj)
            v = obj.SearchInsideLibraryLinks;
        end
        function obj = set.FollowLinks(obj, v)
            obj.SearchInsideLibraryLinks = v;
        end
        function v = get.LookUnderMasks(obj)
            v = obj.SearchUnderMasks;
        end
        function obj = set.LookUnderMasks(obj, v)
            obj.SearchUnderMasks = v;
        end
        function v = get.LookInsideSubsystemReference(obj)
            v = obj.SearchInsideSubsystemReferences;
        end
        function obj = set.LookInsideSubsystemReference(obj, v)
            obj.SearchInsideSubsystemReferences = v;
        end
        function obj = set.SearchUnderMasks(obj, v)
            obj.SearchUnderMasks = matlibre_sl_parametre('choix', v, 'SearchUnderMasks', ...
                {'all', 'none', 'graphical', 'functional'});
        end
        function obj = set.SearchInsideModelReferences(obj, v)
            if logique(v)
                error('Simulink:FindOptions:NotSupported', ...
                      ['SearchInsideModelReferences: MatLibre does not search referenced ' ...
                       'models. Search the referenced model itself.']);
            end
            obj.SearchInsideModelReferences = false;
        end
        function obj = set.Variants(obj, v)
            v = matlibre_sl_parametre('choix', v, 'Variants', ...
                {'AllVariants', 'ActiveVariants', 'ActivePlusCodeVariants'});
            if ~strcmp(v, 'AllVariants')
                error('Simulink:FindOptions:NotSupported', ...
                      ['Variants: MatLibre searches all variants; ''%s'' is ' ...
                       'not supported.'], v);
            end
            obj.Variants = v;
        end
        function obj = set.MatchFilter(obj, f)
            if ~(isempty(f) || isa(f, 'function_handle'))
                error('Simulink:FindOptions:InvalidMatchFilter', ...
                      ['MatchFilter must be a function that takes a handle and returns true or ' ...
                       'false.']);
            end
            obj.MatchFilter = f;
        end
        function arguments = enArguments(obj)
            % les mêmes options, comme FIND_SYSTEM les attend
            surOff = {'off', 'on'};
            arguments = {'CaseSensitive', surOff{1 + logique(obj.CaseSensitive)}, ...
                         'FollowLinks', surOff{1 + logique(obj.SearchInsideLibraryLinks)}, ...
                         'IncludeCommented', surOff{1 + logique(obj.IncludeCommented)}, ...
                         'LookUnderMasks', char(obj.SearchUnderMasks), ...
                         'RegExp', surOff{1 + logique(obj.RegExp)}};
            if obj.SearchDepth >= 0
                arguments = [arguments, {'SearchDepth', obj.SearchDepth}];
            end
        end
    end
end

% Vrai ou faux, écrit comme un booléen, un nombre, ou 'on' / 'true'.
function oui = logique(v)
    if ischar(v) || (isstring(v) && isscalar(v))
        oui = any(strcmpi(char(v), {'on', 'true'}));
    else
        oui = logical(v);
    end
end
