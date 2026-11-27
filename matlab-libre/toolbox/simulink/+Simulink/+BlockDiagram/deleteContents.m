function modele = deleteContents(systeme)
%SIMULINK.BLOCKDIAGRAM.DELETECONTENTS Retire tous les blocs et les liens d'un modèle.
%   SIMULINK.BLOCKDIAGRAM.DELETECONTENTS(MODELE) vide le modèle de la
%   session désigné par son nom ou sa poignée : ses blocs, ses liens et ses
%   connexions physiques. Le reste demeure — la configuration, l'espace de
%   travail du modèle, ses rappels.
%
%   MODELE = SIMULINK.BLOCKDIAGRAM.DELETECONTENTS(MODELE) vide un modèle
%   par valeur, et le rend.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('built-in/Gain', 'essai/g');
%      set_param('essai', 'StopTime', '5');
%      Simulink.BlockDiagram.deleteContents('essai');
%      isempty(get_param('essai', 'Blocks'))    % vrai
%      get_param('essai', 'StopTime')           % '5' : la configuration reste
%      bdclose('all');
%
%   Voir aussi SIMULINK.SUBSYSTEM.DELETECONTENTS,
%   SIMULINK.SUBSYSTEM.COPYCONTENTSTOBLOCKDIAGRAM.
    if isstruct(systeme)
        modele = matlibre_sl_restructurer('vider', matlibre_sl_modele(systeme));
        return
    end
    [racine, chemin, genre] = matlibre_sl_nomme('systeme', systeme);
    if ~strcmp(genre, 'modele') || ~isempty(chemin)
        error('Simulink:BlockDiagram:DeleteContentsNotBlockDiagram', ...
              ['Simulink.BlockDiagram.deleteContents empties a model, given by its name; ' ...
               'Simulink.SubSystem.deleteContents empties a subsystem.']);
    end
    ctx = matlibre_sl_restructurer('ouvrir', racine, '');
    matlibre_sl_restructurer('fermer', ctx, matlibre_sl_restructurer('vider', ctx.systeme));
    clear modele
end
