function h = allBlockDiagrams(genre)
%ALLBLOCKDIAGRAMS Les poignées des diagrammes chargés.
%   H = SIMULINK.ALLBLOCKDIAGRAMS rend la colonne des poignées des modèles,
%   bibliothèques et fichiers de sous-système chargés ;
%   SIMULINK.ALLBLOCKDIAGRAMS('model'), ('library') ou ('subsystem') ne
%   rend que ceux de ce genre (BlockDiagramType).
%
%   Exemple :
%      new_system('diagrammeA');
%      new_system('bibliothequeA', 'Library');
%      getfullname(Simulink.allBlockDiagrams('library'))   % 'bibliothequeA'
%      close_system('diagrammeA', 0);
%      close_system('bibliothequeA', 0);
%
%   Voir aussi FIND_SYSTEM, BDROOT, BDISLOADED.
    if nargin > 0
        if ~(ischar(genre) || (isstring(genre) && isscalar(genre))) || ...
           ~any(strcmpi(char(genre), {'model', 'library', 'subsystem'}))
            error('Simulink:Commands:InvalidBlockDiagramType', ...
                  ['SIMULINK.ALLBLOCKDIAGRAMS(GENRE) : GENRE vaut ''model'', ''library'' ou ' ...
                   '''subsystem''.']);
        end
        genre = lower(char(genre));
    else
        genre = '';
    end
    noms = matlibre_sl_ouverts('noms');
    h = zeros(0, 1);
    for k = 1:numel(noms)
        if isempty(genre) || strcmpi(get_param(noms{k}, 'BlockDiagramType'), genre)
            h(end + 1, 1) = get_param(noms{k}, 'Handle'); %#ok<AGROW>
        end
    end
end
