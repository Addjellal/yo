function expandSubsystem(sousSysteme, varargin)
%SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM Remplace un sous-système par son contenu.
%   SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM(SOUSSYSTEME) déplie le
%   sous-système — son chemin ou sa poignée, dans un modèle de la session
%   — dans le système qui le contient : ses blocs y passent, ses Inport et
%   ses Outport disparaissent, et chaque signal qui arrivait sur une
%   entrée du sous-système va droit aux blocs que l'Inport alimentait, ce
%   qui alimentait un Outport va droit aux blocs que la sortie alimentait.
%   Le calcul ne change pas.
%
%   Comme dans Simulink : seul un sous-système virtuel se déplie — ni
%   masqué, ni lié à une bibliothèque, ni mis en commentaire ; ni
%   atomique, ni conditionnel, ni à variantes —, les priorités posées
%   dedans (Priority) sont retirées, et les chemins des blocs changent :
%   'modele/S/gain' devient 'modele/gain'. Un bloc qui prendrait le nom
%   d'un bloc du système prend le rang libre suivant ('gain1'). Les blocs
%   déplacés n'ont plus de Position : la mise en place les range.
%
%   SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM(SOUSSYSTEME,'CreateArea',V), V
%   'on' (le défaut) ou 'off' : dans Simulink, une aire entoure le contenu
%   déplié. Les annotations n'existent pas ici : aucune aire n'est tracée.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('built-in/Constant', 'essai/c', 'Value', '2');
%      add_block('simulink/Ports & Subsystems/Subsystem', 'essai/S');
%      add_block('built-in/Outport', 'essai/y');
%      add_line('essai', {'c/1', 'S/1'}, {'S/1', 'y/1'});
%      Simulink.BlockDiagram.expandSubsystem('essai/S');
%      find_system('essai')                     % essai, c, y
%      bdclose('all');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM, FIND_SYSTEM.
    if mod(numel(varargin), 2) ~= 0
        error('Simulink:BlockDiagram:ExpandSubsystemArguments', ...
              'Les options d''expandSubsystem vont par paires : un nom, une valeur.');
    end
    for k = 1:2:numel(varargin)
        if ~strcmpi(char(varargin{k}), 'CreateArea')
            error('Simulink:BlockDiagram:ExpandSubsystemArguments', ...
                  'expandSubsystem n''a pas d''option ''%s'' : sa seule option est CreateArea.', ...
                  char(varargin{k}));
        end
        v = varargin{k + 1};
        if ~((ischar(v) || (isstring(v) && isscalar(v))) && any(strcmpi(char(v), {'on', 'off'})))
            error('Simulink:BlockDiagram:ExpandSubsystemArguments', ...
                  'CreateArea vaut ''on'' ou ''off''.');
        end
    end
    [racine, chemin, genre] = matlibre_sl_nomme('systeme', sousSysteme);
    if ~strcmp(genre, 'bloc') || isempty(chemin)
        error('Simulink:BlockDiagram:ExpandSubsystemNotSubsystem', ...
              'expandSubsystem deplie un sous-systeme, designe par son chemin ou sa poignee.');
    end
    barre = find(chemin == '/', 1, 'last');
    parent = '';
    feuille = chemin;
    if ~isempty(barre)
        parent = chemin(1:barre - 1);
        feuille = chemin(barre + 1:end);
    end
    ctx = matlibre_sl_restructurer('ouvrir', racine, parent);
    ou = racine;
    if ~isempty(parent)
        ou = [racine '/' parent];
    end
    systeme = matlibre_sl_restructurer('deplier', ctx.systeme, feuille, ou);
    matlibre_sl_restructurer('fermer', ctx, systeme);
end
