function copyContentsToBlockDiagram(sousSysteme, cible)
%SIMULINK.SUBSYSTEM.COPYCONTENTSTOBLOCKDIAGRAM Copie un sous-système dans un modèle vide.
%   SIMULINK.SUBSYSTEM.COPYCONTENTSTOBLOCKDIAGRAM(SOUSSYSTEME,MODELE)
%   copie les blocs, les liens et les connexions physiques du sous-système
%   — son chemin ou sa poignée — dans le modèle de la session nommé MODELE.
%   Comme dans Simulink, le modèle ne contient ni bloc ni lien ;
%   SIMULINK.BLOCKDIAGRAM.DELETECONTENTS le vide d'abord. Le reste du
%   modèle — sa configuration, son espace de travail — demeure, et le
%   sous-système n'est pas touché. Ses Inport et ses Outport deviennent
%   ceux du modèle : le modèle se simule ou se linéarise seul.
%
%   Exemple :
%      bdclose('all');
%      new_system('grand');
%      add_block('simulink/Ports & Subsystems/Subsystem', 'grand/S');
%      new_system('seul');
%      Simulink.SubSystem.copyContentsToBlockDiagram('grand/S', 'seul');
%      get_param('seul', 'Blocks')              % In1, Out1
%      bdclose('all');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM,
%   SIMULINK.BLOCKDIAGRAM.DELETECONTENTS.
    [racine, chemin, genre] = matlibre_sl_nomme('systeme', sousSysteme);
    if ~strcmp(genre, 'bloc') || isempty(chemin)
        error('Simulink:SubSystem:NotASubsystem', ...
              'copyContentsToBlockDiagram copies a subsystem, given by its path.');
    end
    barre = find(chemin == '/', 1, 'last');
    parent = '';
    feuille = chemin;
    if ~isempty(barre)
        parent = chemin(1:barre - 1);
        feuille = chemin(barre + 1:end);
    end
    ctxSource = matlibre_sl_restructurer('ouvrir', racine, parent);
    ou = racine;
    if ~isempty(parent)
        ou = [racine '/' parent];
    end
    c = matlibre_sl_restructurer('contenu', ctxSource.systeme, feuille, ou);
    [nomCible, cheminCible, genreCible] = matlibre_sl_nomme('systeme', cible);
    if ~strcmp(genreCible, 'modele') || ~isempty(cheminCible)
        error('Simulink:SubSystem:CopyContentsTargetNotBlockDiagram', ...
              ['copyContentsToBlockDiagram copies into a model, given by its name without ' ...
               'path or extension.']);
    end
    ctx = matlibre_sl_restructurer('ouvrir', nomCible, '');
    if ~isempty(ctx.systeme.blocs) || ~isempty(matlibre_sl_liens(ctx.systeme))
        error('Simulink:SubSystem:CopyContentsTargetNotEmpty', ...
              ['Model ''%s'' already contains blocks or lines: the target must be ' ...
               'empty. Simulink.BlockDiagram.deleteContents empties it.'], nomCible);
    end
    systeme = ctx.systeme;
    systeme.blocs = c.blocs;
    systeme.liens = matlibre_sl_liens(c);
    if isfield(c, 'connexions') && ~isempty(c.connexions)
        systeme.connexions = c.connexions;
    end
    matlibre_sl_restructurer('fermer', ctx, systeme);
end
