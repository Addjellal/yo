function h = matlibre_sl_chercher(systeme, type, args)
%MATLIBRE_SL_CHERCHER La recherche de SIMULINK.FINDBLOCKS, par FIND_SYSTEM.
%   H = MATLIBRE_SL_CHERCHER(SYSTEME,TYPE,ARGS) rend les poignées des blocs
%   de SYSTEME — chemin, poignée, ou cellule de chemins — qui répondent
%   aux critères ARGS ('Param', VALEUR, ... et, en dernier, un
%   Simulink.FindOptions), de BlockType TYPE s'il n'est pas vide. Le
%   système lui-même n'en est pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      new_system('chercherEssai');
%      add_block('built-in/Gain', 'chercherEssai/g');
%      h = matlibre_sl_chercher('chercherEssai', 'Gain', {});
%      getfullname(h)                     % 'chercherEssai/g'
%      close_system('chercherEssai', 0);
%
%   Voir aussi SIMULINK.FINDBLOCKS, SIMULINK.FINDBLOCKSOFTYPE.
    options = Simulink.FindOptions;
    if ~isempty(args) && isa(args{end}, 'Simulink.FindOptions')
        options = args{end};
        args(end) = [];
    end
    if mod(numel(args), 2) ~= 0
        error('Simulink:Commands:FindBlocksArguments', ...
              'Les criteres de la recherche vont par paires : un parametre, une valeur.');
    end
    for k = 1:2:numel(args)
        if ~(ischar(args{k}) || (isstring(args{k}) && isscalar(args{k})))
            error('Simulink:Commands:FindBlocksArguments', ...
                  'Un critere de la recherche se nomme par un texte, ''BlockType''.');
        end
    end
    if isstring(systeme)
        systeme = cellstr(systeme);
    end
    if ischar(systeme)
        systeme = {systeme};
    end
    if isnumeric(systeme)
        systeme = num2cell(systeme(:).');
    end
    if ~iscell(systeme)
        error('Simulink:Commands:InvalidSystem', ...
              'Le systeme de la recherche est un chemin, une poignee, ou une cellule de chemins.');
    end
    profondeur = {};
    if options.SearchDepth > 0
        profondeur = {'SearchDepth', options.SearchDepth};
    end
    criteres = [args, {'Type', 'block'}];
    if ~isempty(type)
        criteres = [criteres, {'BlockType', type}];
    end
    onOff = {'off', 'on'};
    h = zeros(0, 1);
    if isempty(systeme)
        return
    end
    h = find_system(systeme, 'FindAll', 'on', profondeur{:}, ...
                    'LookUnderMasks', options.LookUnderMasks, ...
                    'FollowLinks', onOff{1 + options.FollowLinks}, ...
                    'CaseSensitive', onOff{1 + options.CaseSensitive}, ...
                    'RegExp', onOff{1 + options.RegExp}, criteres{:});
    % le système lui-même, quand c'est un sous-système, n'en est pas
    propres = zeros(1, numel(systeme));
    for k = 1:numel(systeme)
        propres(k) = matlibre_sl_memoire('poignee', matlibre_sl_memoire('chemin', systeme{k}));
    end
    h = h(~ismember(h, propres));
    h = h(:);
end
