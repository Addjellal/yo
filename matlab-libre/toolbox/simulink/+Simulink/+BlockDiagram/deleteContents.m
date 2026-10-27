function varargout = deleteContents(modele)
%SIMULINK.BLOCKDIAGRAM.DELETECONTENTS Vide un modèle de ses blocs et liens.
%   SIMULINK.BLOCKDIAGRAM.DELETECONTENTS(MODELE) retire tous les blocs et
%   les liens du modèle chargé — désigné par son nom ou sa poignée —, sur
%   place ; ses réglages restent. M = SIMULINK.BLOCKDIAGRAM.DELETECONTENTS(M)
%   rend vidé un modèle tenu dans une variable.
%
%   Exemple :
%      new_system('aVider');
%      add_block('built-in/Gain', 'aVider/k');
%      Simulink.BlockDiagram.deleteContents('aVider');
%      find_system('aVider')                    % {'aVider'}
%      bdclose('aVider');
%
%   Voir aussi SIMULINK.SUBSYSTEM.DELETECONTENTS,
%   SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM.
    if isstruct(modele)
        varargout{1} = matlibre_sl_schema('vider', modele);
        return
    end
    chemin = matlibre_sl_memoire('chemin', modele);
    if ~strcmp(matlibre_sl_memoire('genre', chemin), 'modele')
        error('Simulink:Commands:DeleteContentsNotBlockDiagram', ...
              ['''%s'' est un bloc : SIMULINK.SUBSYSTEM.DELETECONTENTS vide un sous-systeme ; ' ...
               'SIMULINK.BLOCKDIAGRAM.DELETECONTENTS vide un modele.'], chemin);
    end
    matlibre_sl_memoire('appliquer', chemin, @(s) matlibre_sl_schema('vider', s));
end
