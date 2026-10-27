function deleteContents(sousSysteme)
%SIMULINK.SUBSYSTEM.DELETECONTENTS Vide un sous-système de ses blocs et liens.
%   SIMULINK.SUBSYSTEM.DELETECONTENTS(SOUS) retire tous les blocs et liens
%   du sous-système — désigné par son chemin ou sa poignée — d'un modèle
%   chargé, sur place : il n'a plus de port, et les liens qui le
%   reliaient au système parent s'en vont avec ses ports.
%
%   Exemple :
%      new_system('dedans');
%      add_block('simulink/Ports & Subsystems/Subsystem', 'dedans/s');
%      Simulink.SubSystem.deleteContents('dedans/s');
%      find_system('dedans/s')                  % {'dedans/s'}
%      bdclose('dedans');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.DELETECONTENTS,
%   SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM.
    chemin = matlibre_sl_memoire('chemin', sousSysteme);
    [parent, feuille] = matlibre_sl_memoire('decouper', chemin);
    if isempty(parent)
        error('Simulink:Commands:DeleteContentsNotSubsystem', ...
              ['''%s'' est un modele : SIMULINK.BLOCKDIAGRAM.DELETECONTENTS le vide ; ' ...
               'SIMULINK.SUBSYSTEM.DELETECONTENTS vide un sous-systeme.'], chemin);
    end
    bloc = matlibre_sl_memoire('bloc', chemin);
    if ~strcmp(bloc.type, 'subsystem')
        error('Simulink:Commands:DeleteContentsNotSubsystem', ...
              '''%s'' n''est pas un sous-systeme : il n''a pas de contenu a vider.', chemin);
    end
    matlibre_sl_memoire('appliquer', chemin, @(s) matlibre_sl_schema('vider', s));
    matlibre_sl_memoire('appliquer', parent, @(P) matlibre_sl_schema('detacher', P, feuille));
end
