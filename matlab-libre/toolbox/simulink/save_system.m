function fichier = save_system(modele, fichier)
%SAVE_SYSTEM Enregistre un modèle dans un fichier .m qui le rebâtit.
%   SAVE_SYSTEM(MODELE) écrit MODELE.nom.m dans le dossier courant.
%   SAVE_SYSTEM(MODELE,FICHIER) choisit le nom du fichier ; l'extension
%   .m est ajoutée si elle manque. La fonction rend le chemin écrit.
%
%   Le fichier produit est un programme : une fonction sans argument qui
%   appelle NEW_SYSTEM, ADD_BLOCK et ADD_LINE, et rend le modèle.
%   LOAD_SYSTEM le relit, et SIM l'accepte par son nom. C'est un format
%   qui se lit, se compare et se range dans un dépôt — ce que le .slx de
%   MathWorks, binaire et non documenté, ne permet pas.
%
%   Les valeurs de paramètres sont réécrites par MAT2STR pour les
%   nombres et entre apostrophes pour le texte : ce qu'on relit est ce
%   qu'on avait, à la représentation près.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'constant', 'c', 'Value', 2);
%      m = add_block(m, 'gain', 'g', 'Gain', 3);
%      m = add_line(m, 'c', 'g');
%      chemin = save_system(m, [tempname() '.m']);
%      relu = load_system(chemin);
%      get_param(relu, 'g', 'Gain')             % 3
%      delete(chemin);
%
%   Voir aussi LOAD_SYSTEM, NEW_SYSTEM, ADD_BLOCK, ADD_LINE, CLOSE_SYSTEM.
    if ~isstruct(modele) || ~isfield(modele, 'blocs')
        error('Simulink:Commands:InvalidModel', ...
              'SAVE_SYSTEM attend un modele bati par NEW_SYSTEM.');
    end
    if nargin < 2
        fichier = [modele.nom '.m'];
    end
    fichier = char(fichier);
    if numel(fichier) < 2 || ~strcmp(fichier(end-1:end), '.m')
        fichier = [fichier '.m'];
    end
    [~, base] = fileparts(fichier);
    identifiant = regexprep(base, '[^A-Za-z0-9_]', '_');
    if isempty(identifiant) || ~isletter(identifiant(1))
        identifiant = ['modele_' identifiant];
    end

    lignes = {};
    lignes{end+1} = sprintf('function m = %s()', identifiant);
    lignes{end+1} = sprintf('%%%s Modele Simulink ecrit par SAVE_SYSTEM.', ...
                            upper(identifiant));
    lignes{end+1} = '%   Le fichier se relit par LOAD_SYSTEM, et SIM l''accepte par son nom.';
    lignes{end+1} = '%';
    lignes{end+1} = '%   Exemple :';
    lignes{end+1} = sprintf('%%      m = %s();', identifiant);
    lignes{end+1} = '%      numel(m.blocs) > 0';
    lignes{end+1} = '%';
    lignes{end+1} = '%   Voir aussi LOAD_SYSTEM, SAVE_SYSTEM, SIM.';
    lignes{end+1} = sprintf('    m = new_system(%s);', citer(modele.nom));
    for k = 1:numel(modele.blocs)
        bloc = modele.blocs{k};
        morceaux = {sprintf('    m = add_block(m, %s, %s', ...
                            citer(bloc.type), citer(bloc.nom))};
        champs = fieldnames(bloc.parametres);
        for j = 1:numel(champs)
            morceaux{end+1} = sprintf(', %s, %s', citer(champs{j}), ...
                                      ecrireValeur(bloc.parametres.(champs{j}), ...
                                                   bloc.nom, champs{j}));   %#ok<AGROW>
        end
        morceaux{end+1} = ');';   %#ok<AGROW>
        lignes{end+1} = [morceaux{:}];   %#ok<AGROW>
    end
    if isfield(modele, 'parametres')
        champs = fieldnames(modele.parametres);
        for j = 1:numel(champs)
            lignes{end+1} = sprintf('    m = add_param(m, %s, %s);', ...
                                    citer(champs{j}), ...
                                    ecrireValeur(modele.parametres.(champs{j}), ...
                                                 modele.nom, champs{j}));   %#ok<AGROW>
        end
    end
    for l = 1:size(modele.liens, 1)
        lignes{end+1} = sprintf('    m = add_line(m, %s, %s, %d);', ...
                                citer(modele.blocs{modele.liens(l, 1)}.nom), ...
                                citer(modele.blocs{modele.liens(l, 2)}.nom), ...
                                modele.liens(l, 3));   %#ok<AGROW>
    end
    lignes{end+1} = 'end';

    identifiantFichier = fopen(fichier, 'w');
    if identifiantFichier < 0
        error('Simulink:Commands:SaveFailed', ...
              'Impossible d''ecrire ''%s''.', fichier);
    end
    for k = 1:numel(lignes)
        fprintf(identifiantFichier, '%s\n', lignes{k});
    end
    fclose(identifiantFichier);
end

function texte = citer(valeur)
    texte = ['''' strrep(char(valeur), '''', '''''') ''''];
end

% Une valeur de paramètre se réécrit telle qu'un programme la relira.
% Ce qui n'a pas de telle écriture est refusé en nommant le bloc, plutôt
% qu'écrit de travers.
function texte = ecrireValeur(valeur, nomBloc, nomParametre)
    if ischar(valeur) || isstring(valeur)
        texte = citer(valeur);
    elseif islogical(valeur)
        if isscalar(valeur)
            texte = 'true';
            if ~valeur
                texte = 'false';
            end
        else
            texte = mat2str(valeur);
        end
    elseif isnumeric(valeur)
        texte = mat2str(valeur, 17);
    else
        error('Simulink:Commands:SaveUnsupported', ...
              ['Le parametre ''%s'' du bloc ''%s'' est de classe ''%s'' : ' ...
               'SAVE_SYSTEM ne sait ecrire que des nombres, des booleens et ' ...
               'du texte.'], nomParametre, nomBloc, class(valeur));
    end
end
