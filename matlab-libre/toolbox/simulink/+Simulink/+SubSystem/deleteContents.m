function deleteContents(sousSysteme)
%SIMULINK.SUBSYSTEM.DELETECONTENTS Retire tous les blocs et les liens d'un sous-système.
%   SIMULINK.SUBSYSTEM.DELETECONTENTS(SOUSSYSTEME) vide le sous-système,
%   désigné par son chemin ou sa poignée dans un modèle de la session : ses
%   blocs, ses liens, ses connexions physiques. Ses Inport et ses Outport
%   partant avec le reste, il n'a plus de port : les liens qui le
%   reliaient au système qui le contient disparaissent aussi — Simulink
%   les laisse pendre, il n'y a pas ici de lien qui pende. Son masque et
%   ses réglages demeurent. Un sous-système lié à une bibliothèque est
%   refusé : son contenu est celui de la bibliothèque.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('simulink/Ports & Subsystems/Subsystem', 'essai/S');
%      Simulink.SubSystem.deleteContents('essai/S');
%      find_system('essai/S')                   % {'essai/S'} : vide
%      bdclose('all');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.DELETECONTENTS,
%   SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM.
    [racine, chemin, genre] = matlibre_sl_nomme('systeme', sousSysteme);
    if ~strcmp(genre, 'bloc') || isempty(chemin)
        error('Simulink:SubSystem:NotASubsystem', ...
              ['Simulink.SubSystem.deleteContents empties a subsystem, given by its ' ...
               'path; Simulink.BlockDiagram.deleteContents empties a model.']);
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
    systeme = matlibre_sl_restructurer('viderSousSysteme', ctx.systeme, feuille, ou);
    matlibre_sl_restructurer('fermer', ctx, systeme);
end
