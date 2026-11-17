function copyContentsToSubsystem(source, sousSysteme)
%SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM Copie un modèle dans un sous-système vide.
%   SIMULINK.BLOCKDIAGRAM.COPYCONTENTSTOSUBSYSTEM(MODELE,SOUSSYSTEME)
%   copie les blocs, les liens et les connexions physiques du modèle —
%   ouvert dans la session, ou donné par valeur — dans le sous-système,
%   désigné par son chemin ou sa poignée. Comme dans Simulink, le
%   sous-système ne contient ni bloc ni lien, et le modèle ne le contient
%   pas ; SIMULINK.SUBSYSTEM.DELETECONTENTS le vide d'abord. Les Inport et
%   les Outport du modèle deviennent les ports du sous-système, qu'ADD_LINE
%   peut alors câbler. La configuration du modèle ne suit pas.
%
%   Exemple :
%      bdclose('all');
%      new_system('source');
%      add_block('built-in/Inport', 'source/u');
%      add_block('built-in/Gain', 'source/g', 'Gain', '4');
%      add_block('built-in/Outport', 'source/y');
%      add_line('source', {'u/1', 'g/1'}, {'g/1', 'y/1'});
%      new_system('cible');
%      add_block('built-in/Subsystem', 'cible/S');
%      Simulink.BlockDiagram.copyContentsToSubsystem('source', 'cible/S');
%      get_param('cible/S/g', 'Gain')           % '4'
%      bdclose('all');
%
%   Voir aussi SIMULINK.SUBSYSTEM.COPYCONTENTSTOBLOCKDIAGRAM,
%   SIMULINK.SUBSYSTEM.DELETECONTENTS.
    if isstruct(source)
        source = matlibre_sl_modele(source);
        nomSource = char(source.nom);
    else
        [nomSource, cheminSource, genre] = matlibre_sl_nomme('systeme', source);
        if ~strcmp(genre, 'modele') || ~isempty(cheminSource)
            error('Simulink:BlockDiagram:CopyContentsSourceNotBlockDiagram', ...
                  ['copyContentsToSubsystem copie un modele, designe par son nom sans chemin ' ...
                   'ni extension.']);
        end
        source = matlibre_sl_nomme('modele', nomSource);
    end
    [racine, chemin, genre] = matlibre_sl_nomme('systeme', sousSysteme);
    if ~strcmp(genre, 'bloc') || isempty(chemin)
        error('Simulink:SubSystem:NotASubsystem', ...
              'copyContentsToSubsystem copie dans un sous-systeme, designe par son chemin.');
    end
    if strcmp(racine, nomSource)
        error('Simulink:BlockDiagram:CopyContentsSourceContainsTarget', ...
              ['Le modele ''%s'' contient le sous-systeme ''%s/%s'' : il ne se copie pas ' ...
               'dedans.'], nomSource, racine, chemin);
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
    systeme = matlibre_sl_restructurer('remplir', ctx.systeme, feuille, source, ou);
    matlibre_sl_restructurer('fermer', ctx, systeme);
end
