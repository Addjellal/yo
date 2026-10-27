function createSubsystem(blocs, varargin)
%SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM Réunit des blocs en un sous-système.
%   SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM(BLOCS) remplace les blocs BLOCS
%   — leurs chemins ou leurs poignées, d'un même système d'un modèle
%   chargé — par un sous-système qui les contient : une entrée par signal
%   qui y arrive du dehors, une sortie par signal qui en part, les liens
%   du dehors reliés à ses ports ; la simulation n'en change pas.
%   SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM(BLOCS,'Name',NOM) nomme le
%   sous-système, 'Subsystem' sinon, un nom libre étant choisi s'il est
%   pris.
%
%   Exemple :
%      new_system('aGrouper');
%      add_block('built-in/Constant', 'aGrouper/c', 'Value', '2');
%      add_block('built-in/Gain', 'aGrouper/k', 'Gain', '3');
%      add_block('built-in/Outport', 'aGrouper/y');
%      add_line('aGrouper', 'c/1', 'k/1');
%      add_line('aGrouper', 'k/1', 'y/1');
%      Simulink.BlockDiagram.createSubsystem({'aGrouper/k'}, 'Name', 'gain');
%      get_param('aGrouper/gain', 'Ports')      % [1 1 0 0 0 0 0 0]
%      bdclose('aGrouper');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM,
%   SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM.
    nom = 'Subsystem';
    if mod(numel(varargin), 2) ~= 0
        error('Simulink:Commands:CreateSubsystemArguments', ...
              'CREATESUBSYSTEM(BLOCS, ''Name'', NOM) : l''option va par paire.');
    end
    for k = 1:2:numel(varargin)
        if ~strcmpi(char(varargin{k}), 'Name')
            error('Simulink:Commands:CreateSubsystemArguments', ...
                  'CREATESUBSYSTEM n''a que l''option ''Name''.');
        end
        nom = char(varargin{k + 1});
    end
    if isnumeric(blocs)
        blocs = num2cell(blocs);
    elseif ischar(blocs) || isstring(blocs)
        blocs = cellstr(blocs);
    end
    if isempty(blocs)
        error('Simulink:Commands:CreateSubsystemArguments', ...
              'CREATESUBSYSTEM reunit au moins un bloc.');
    end
    chemins = cellfun(@(b) matlibre_sl_memoire('chemin', b), blocs, 'UniformOutput', false);
    parents = cell(size(chemins));
    feuilles = cell(size(chemins));
    for k = 1:numel(chemins)
        matlibre_sl_memoire('genre', chemins{k});   % refuse un chemin qui ne mène à rien
        [parents{k}, feuilles{k}] = matlibre_sl_memoire('decouper', chemins{k});
        if isempty(parents{k})
            error('Simulink:Commands:CreateSubsystemArguments', ...
                  '''%s'' est un modele : CREATESUBSYSTEM reunit des blocs.', chemins{k});
        end
    end
    if numel(unique(parents)) > 1
        error('Simulink:Commands:CreateSubsystemDifferentSystems', ...
              ['Les blocs a reunir sont dans des systemes differents (%s) : un ' ...
               'sous-systeme reunit des blocs d''un meme systeme.'], strjoin(unique(parents), ', '));
    end
    matlibre_sl_memoire('appliquer', parents{1}, ...
                        @(P) matlibre_sl_schema('grouper', P, feuilles, nom, parents{1}));
end
