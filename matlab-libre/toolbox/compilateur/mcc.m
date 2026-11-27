function chemin = mcc(varargin)
%MCC Fabrique un lanceur autonome pour un programme MATLAB.
%   MCC -m PROGRAMME.m fabrique, comme MATLAB Compiler, une application
%   autonome nommée d'après PROGRAMME, dans le dossier courant. Options de
%   MATLAB reconnues :
%      -m            application autonome (la seule cible)
%      -o NOM        nom de l'application
%      -d DOSSIER    dossier où l'écrire
%      -a CHEMIN     fichier ou dossier joint : son dossier va au chemin
%      -v            dit ce qui est produit
%   Les autres options (-W, -T, -R, -e...) sont refusées en le disant.
%   CHEMIN = MCC('programme.m','sortie'), forme historique de MatLibre,
%   reste admise.
%
%   L'application est un lanceur qui appelle l'interpréteur MatLibre sur
%   le programme, chemin des toolboxes réglé : c'est l'équivalent libre du
%   MATLAB Runtime, dont un programme compilé par mcc a besoin. Rien ici
%   ne devient un binaire autonome, et le prétendre serait mentir. Comme
%   dans MATLAB, les arguments de la ligne de commande arrivent en texte
%   à la fonction principale : « ./prog 21 » appelle prog('21'), et
%   ISDEPLOYED y vaut vrai.
%
%   MCC n'écrit jamais sur un fichier .m : une sortie qui en porterait le
%   nom est refusée, ce qui protège le programme lui-même.
%
%   Sous Windows, le lanceur est un fichier de commandes .bat ; ailleurs,
%   un script shell rendu exécutable.
%
%   Exemple :
%      dossier = tempname(); mkdir(dossier);
%      f = fopen(fullfile(dossier, 'double.m'), 'w');
%      fprintf(f, 'function double(n)\n  disp(2 * str2double(n));\nend\n');
%      fclose(f);
%      lanceur = mcc('-m', fullfile(dossier, 'double.m'), '-d', dossier);
%      if isunix, [~, sortie] = system([lanceur ' 21']); end   % 42
%
%   Voir aussi DEPLOYTOOL, MATLABROOT, ISDEPLOYED.
    [programme, sortie, dossier, joints, bavard] = lireOptions(varargin);
    if ~matlibre_cheminAbsolu(programme)
        programme = fullfile(pwd(), programme);
    end
    if exist(programme, 'file') ~= 2
        error('compiler:mcc:Programme', 'Program ''%s'' does not exist.', programme);
    end
    [~, nom] = fileparts(programme);
    if isempty(sortie)
        sortie = nom;
    end
    if isempty(dossier)
        dossier = pwd();
    end
    if ~matlibre_cheminAbsolu(sortie)
        sortie = fullfile(dossier, sortie);
    end
    if ispc && ~endsWith(lower(sortie), '.bat')
        sortie = [sortie '.bat'];
    end
    if endsWith(lower(sortie), '.m') || strcmp(sortie, programme)
        error('compiler:mcc:Ecrasement', ...
              'MCC does not write over a .m file: ''%s'' would be overwritten.', sortie);
    end
    chemins = {};
    for k = 1:numel(joints)
        joint = joints{k};
        if ~matlibre_cheminAbsolu(joint)
            joint = fullfile(pwd(), joint);
        end
        if exist(joint, 'dir') ~= 7
            joint = fileparts(joint);
        end
        chemins{end + 1} = joint; %#ok<AGROW>
    end
    racine = matlabroot();
    interpreteur = matlibre_executable();
    if ispc
        options = strjoin(cellfun(@(c) sprintf('--path "%s" ', c), chemins, ...
                                  'UniformOutput', false), '');
        identifiant = fopen(sortie, 'w');
        fprintf(identifiant, '@echo off\r\n');
        fprintf(identifiant, 'rem Lanceur produit par mcc (MatLibre)\r\n');
        fprintf(identifiant, 'set "MATLIBRE_TOOLBOX=%s"\r\n', racine);
        fprintf(identifiant, 'set "MATLIBRE_DEPLOYE=1"\r\n');
        fprintf(identifiant, '"%s" %s"%s" %%*\r\n', interpreteur, options, programme);
        fclose(identifiant);
    else
        options = strjoin(cellfun(@(c) sprintf('--path "%s" ', c), chemins, ...
                                  'UniformOutput', false), '');
        identifiant = fopen(sortie, 'w');
        fprintf(identifiant, '#!/bin/sh\n');
        fprintf(identifiant, '# Lanceur produit par mcc (MatLibre)\n');
        fprintf(identifiant, 'MATLIBRE_TOOLBOX="%s"\n', racine);
        fprintf(identifiant, 'MATLIBRE_DEPLOYE=1\n');
        fprintf(identifiant, 'export MATLIBRE_TOOLBOX MATLIBRE_DEPLOYE\n');
        fprintf(identifiant, 'exec "%s" %s"%s" "$@"\n', interpreteur, options, programme);
        fclose(identifiant);
        system(sprintf('chmod +x "%s"', sortie));
    end
    if bavard
        fprintf('mcc : %s -> %s\n', programme, sortie);
    end
    chemin = sortie;
end

function [programme, sortie, dossier, joints, bavard] = lireOptions(arguments)
    programme = '';
    sortie = '';
    dossier = '';
    joints = {};
    bavard = false;
    arguments = cellfun(@char, arguments, 'UniformOutput', false);
    if numel(arguments) >= 1 && ~startsWith(arguments{1}, '-')
        % forme historique : mcc('programme.m', 'sortie')
        programme = arguments{1};
        if numel(arguments) >= 2
            sortie = arguments{2};
        end
        if numel(arguments) > 2
            error('compiler:mcc:Arguments', 'Forme historique : mcc(''programme.m'', ''sortie'').');
        end
        return
    end
    k = 1;
    while k <= numel(arguments)
        option = arguments{k};
        switch option
            case '-m'
            case '-v'
                bavard = true;
            case {'-o', '-d', '-a'}
                if k == numel(arguments)
                    error('compiler:mcc:Option', 'Option %s requires a value.', option);
                end
                valeur = arguments{k + 1};
                k = k + 1;
                if strcmp(option, '-o')
                    sortie = valeur;
                elseif strcmp(option, '-d')
                    dossier = valeur;
                else
                    joints{end + 1} = valeur; %#ok<AGROW>
                end
            otherwise
                if startsWith(option, '-')
                    error('compiler:mcc:Option', ...
                          'MatLibre does not support mcc option %s (-m, -o, -d, -a, -v).', option);
                end
                if ~isempty(programme)
                    error('compiler:mcc:Programmes', ...
                          'MatLibre compiles one program at a time (%s, then %s).', ...
                          programme, option);
                end
                programme = option;
        end
        k = k + 1;
    end
    if isempty(programme)
        error('compiler:mcc:Programme', 'MCC requires a program: mcc -m program.m.');
    end
end
