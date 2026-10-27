function copyContentsToSubsystem(modele, sousSysteme)
%SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM Recopie un modèle dans un sous-système.
%   SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM(MODELE,SOUS) recopie les
%   blocs et les liens du modèle MODELE — chargé, ou tenu dans une
%   variable — dans le sous-système vide SOUS d'un modèle chargé : ses
%   Inport et ses Outport deviennent les ports du sous-système. Un
%   sous-système qui n'est pas vide est refusé.
%
%   Exemple :
%      new_system('source');
%      add_block('built-in/Inport', 'source/u');
%      add_block('built-in/Gain', 'source/k', 'Gain', '4');
%      add_block('built-in/Outport', 'source/y');
%      add_line('source', 'u/1', 'k/1');
%      add_line('source', 'k/1', 'y/1');
%      new_system('cible');
%      add_block('built-in/Subsystem', 'cible/s');
%      Simulink.BlockDiagram.copyContentsToSubsystem('source', 'cible/s');
%      get_param('cible/s/k', 'Gain')           % '4'
%      bdclose('source'); bdclose('cible');
%
%   Voir aussi SIMULINK.SUBSYSTEM.DELETECONTENTS,
%   SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM.
    if isstruct(modele)
        source = modele;
    else
        source = matlibre_sl_memoire('systeme', matlibre_sl_memoire('chemin', modele));
    end
    chemin = matlibre_sl_memoire('chemin', sousSysteme);
    bloc = struct('type', '');
    if ~isempty(matlibre_sl_memoire('decouper', chemin))
        bloc = matlibre_sl_memoire('bloc', chemin);
    end
    if ~strcmp(bloc.type, 'subsystem')
        error('Simulink:Commands:CopyContentsNotSubsystem', ...
              '''%s'' n''est pas un sous-systeme : on y recopie un modele.', chemin);
    end
    matlibre_sl_memoire('appliquer', chemin, @(s) matlibre_sl_schema('remplir', s, source));
end
