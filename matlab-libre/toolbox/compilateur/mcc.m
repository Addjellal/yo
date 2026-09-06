function chemin = mcc(script, sortie)
%MCC Fabrique un lanceur pour un script.
%   CHEMIN = MCC('script.m','programme') écrit un lanceur qui appelle
%   l'interpréteur MatLibre sur le script, avec le chemin des toolboxes
%   déjà réglé. Sans nom de sortie, le lanceur prend celui du script.
%
%   C'est l'équivalent libre du « MATLAB Runtime » : le programme produit
%   a besoin de l'interpréteur, comme un programme compilé par mcc a
%   besoin du runtime. Rien ici ne devient un binaire autonome, et le
%   prétendre serait mentir.
%
%   Le lanceur nomme l'interpréteur par son chemin complet, celui de
%   l'interpréteur qui a produit le lanceur : écrire « exec matlibre »
%   supposerait qu'il soit dans le PATH de la machine cible, ce qui n'est
%   vrai qu'après installation.
%
%   Sous Windows, le lanceur est un fichier de commandes .bat ; ailleurs,
%   un script shell rendu exécutable.
%
%   Exemple :
%      mcc('analyse.m', 'analyse')
%      system('./analyse')
%
%   Voir aussi DEPLOYTOOL, MATLABROOT.
    if nargin < 2
        [~, nom] = fileparts(script);
        sortie = nom;
    end
    racine = matlabroot();
    interpreteur = matlibre_executable();
    complet = script;
    if ~matlibre_cheminAbsolu(script)
        complet = fullfile(pwd(), script);
    end
    if ispc
        if ~endsWith(lower(sortie), '.bat')
            sortie = [sortie '.bat'];
        end
        identifiant = fopen(sortie, 'w');
        fprintf(identifiant, '@echo off\r\n');
        fprintf(identifiant, 'rem Lanceur produit par mcc (MatLibre)\r\n');
        fprintf(identifiant, 'set "MATLIBRE_TOOLBOX=%s"\r\n', racine);
        fprintf(identifiant, '"%s" "%s" %%*\r\n', interpreteur, complet);
        fclose(identifiant);
    else
        identifiant = fopen(sortie, 'w');
        fprintf(identifiant, '#!/bin/sh\n');
        fprintf(identifiant, '# Lanceur produit par mcc (MatLibre)\n');
        fprintf(identifiant, 'MATLIBRE_TOOLBOX="%s"\n', racine);
        fprintf(identifiant, 'export MATLIBRE_TOOLBOX\n');
        fprintf(identifiant, 'exec "%s" "%s" "$@"\n', interpreteur, complet);
        fclose(identifiant);
        system(sprintf('chmod +x "%s"', sortie));
    end
    if matlibre_cheminAbsolu(sortie)
        chemin = sortie;
    else
        chemin = fullfile(pwd(), sortie);
    end
end
