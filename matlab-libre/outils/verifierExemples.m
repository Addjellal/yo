function verifierExemples(varargin)
%VERIFIEREXEMPLES Les exemples d'aide d'un dossier doivent tourner.
%
% Le pendant, au moment d'ecrire, du controle que test_aide.m fait sur les
% dossiers deja complets. On lui donne un ou plusieurs dossiers de
% toolbox ; il dit lesquelles de leurs fonctions n'ont pas d'exemple, et
% lesquels de leurs exemples se cassent.
%
% Un exemple faux est pire que pas d'exemple : l'utilisateur le recopie et
% se demande ce qu'il a mal fait. C'est pourquoi la liste des dossiers
% verifies par test_aide.m ne s'allonge qu'apres etre passee ici.
%
% Usage :  matlibre -e "addpath outils; verifierExemples signal"
%          matlibre -e "addpath outils; verifierExemples"   % tout
%
% Nommer les dossiers evite d'attendre les deux mille autres fonctions
% quand on travaille sur une seule boite a outils.
    disp('--- exemples ---');

    racine = fullfile(fileparts(fileparts(mfilename('fullpath'))), 'toolbox');
    if isempty(varargin)
        entrees = dir(racine);
        entrees = entrees([entrees.isdir] & ~startsWith({entrees.name}, '.'));
        demandes = sort({entrees.name});
        demandes = demandes(~strcmp(demandes, 'aide'));
    else
        demandes = {};
        for k = 1:numel(varargin)
            demandes = [demandes, cellstr(varargin{k})];   %#ok<AGROW>
        end
    end

% Les exemples ecrivent parfois : on travaille dans un bac a sable.
    avant = pwd();
    bac = tempname();
    mkdir(bac);

    total = 0;
    sansExemple = {};
    casses = {};
    for kd = 1:numel(demandes)
    dossier = fullfile(racine, demandes{kd});
    if ~isfolder(dossier)
        fprintf('  %s : dossier inconnu\n', demandes{kd});
        continue
    end
    fichiers = dir(fullfile(dossier, '*.m'));
    nSans = 0;
    nCasses = 0;
    nOk = 0;
    for kf = 1:numel(fichiers)
        nom = fichiers(kf).name(1:end-2);
        if strcmp(nom, 'Contents') || strncmp(nom, 'matlibre_', 9)
            continue
        end
        total = total + 1;
        fiche = matlibre_aide_structuree(nom);
        if isempty(fiche.Exemples)
            sansExemple{end+1} = [demandes{kd} '/' nom];   %#ok<SAGROW>
            nSans = nSans + 1;
            continue
        end
        cd(bac);
        message = essayerBloc(strjoin(fiche.Exemples, sprintf('\n')));
        cd(avant);
        if isempty(message)
            nOk = nOk + 1;
        else
            casses{end+1} = sprintf('%s/%s : %s', demandes{kd}, nom, message);   %#ok<SAGROW>
            nCasses = nCasses + 1;
        end
    end
    fprintf('  %-26s %3d exemples passent, %3d casses, %3d sans exemple\n', ...
            demandes{kd}, nOk, nCasses, nSans);
    end

    cd(avant);
    rmdir(bac, 's');

    for k = 1:numel(casses)
    fprintf('  casse : %s\n', casses{k});
    end
    fprintf('\n  %d fonctions examinees, %d sans exemple, %d exemples casses\n', ...
        total, numel(sansExemple), numel(casses));

end

% Chaque bloc s'execute dans une portee a lui : sans cela les variables
% d'un exemple survivraient au suivant, et un exemple casse passerait
% pour bon parce qu'un autre a defini ce qui lui manque.
function message = essayerBloc(bloc)
    message = '';
    try
        evalc(bloc);
    catch e
        message = e.message;
    end
    try
        close all
    catch
    end
end
