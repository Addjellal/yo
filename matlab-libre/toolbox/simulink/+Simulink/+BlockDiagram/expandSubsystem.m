function expandSubsystem(sousSysteme)
%SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM Remplace un sous-système par son contenu.
%   SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM(SOUS) déplie le sous-système
%   virtuel SOUS — son chemin ou sa poignée, dans un modèle chargé — : ses
%   blocs viennent dans le système qui le contient, sous un nom libre, et
%   ce qui entrait par ses Inport ou sortait par ses Outport se relie
%   directement ; la simulation n'en change pas. Un sous-système masqué, à
%   variantes, atomique, conditionnel, itéré, lié à une bibliothèque ou
%   qui porte des connexions physiques est refusé.
%
%   Exemple :
%      new_system('aDeplier');
%      add_block('built-in/Constant', 'aDeplier/c', 'Value', '2');
%      add_block('simulink/Ports & Subsystems/Subsystem', 'aDeplier/s');
%      add_block('built-in/Outport', 'aDeplier/y');
%      add_line('aDeplier', 'c/1', 's/1');
%      add_line('aDeplier', 's/1', 'y/1');
%      Simulink.BlockDiagram.expandSubsystem('aDeplier/s');
%      find_system('aDeplier', 'SearchDepth', 1)   % plus de sous-système
%      bdclose('aDeplier');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM,
%   SIMULINK.SUBSYSTEM.DELETECONTENTS.
    chemin = matlibre_sl_memoire('chemin', sousSysteme);
    [parent, feuille] = matlibre_sl_memoire('decouper', chemin);
    if isempty(parent)
        error('Simulink:Commands:ExpandSubsystemNotSubsystem', ...
              '''%s'' est un modele : on deplie un sous-systeme.', chemin);
    end
    matlibre_sl_memoire('appliquer', parent, ...
                        @(P) matlibre_sl_schema('deplier', P, feuille, chemin));
end
