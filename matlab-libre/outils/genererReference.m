% genererReference.m — fabrique la référence des fonctions.
%
% Le script parcourt la table des fonctions natives et les fichiers .m des
% toolboxes, en extrait le bloc d'aide de tête, et écrit un fichier
% Markdown par groupe dans documentation/reference/.
%
% Usage :  matlibre outils/genererReference.m
%
% Il est écrit dans le langage qu'il documente : c'est le meilleur test de
% bout en bout dont on dispose.

racine = pwd();
dossierSortie = fullfile(racine, 'documentation', 'reference');
mkdir(dossierSortie);

% ------------------------------------------------------------ fonctions natives
table = matlibre_fonctions();
n = size(table, 1);
groupes = {};
for k = 1:n
    g = table{k, 2};
    if ~any(strcmp(groupes, g))
        groupes{end+1} = g;
    end
end
groupes = sort(groupes);

titres = struct();
titres.base = 'Tableaux, tailles et classes';
titres.math = 'Mathematiques elementaires';
titres.tableaux = 'Reductions et manipulations';
titres.texte = 'Chaines de caracteres';
titres.structures = 'Cellules et structures';
titres.fonctionnel = 'Fonctions de fonctions';
titres.es = 'Entrees, sorties et formatage';
titres.algebre = 'Algebre lineaire';
titres.statistiques = 'Statistiques';
titres.signal = 'Signal et Fourier';
titres.polynomes = 'Polynomes et interpolation';
titres.optimisation = 'Optimisation et equations differentielles';
titres.temps = 'Temps et dates';
titres.systeme = 'Systeme, chemin et aide';
titres.graphique = 'Graphique';
titres.tests = 'Assertions et tests';

nombreNatives = 0;
for g = 1:numel(groupes)
    groupe = groupes{g};
    fichier = fullfile(dossierSortie, ['natif-' groupe '.md']);
    fid = fopen(fichier, 'w');
    if isfield(titres, groupe)
        fprintf(fid, '# %s\n\n', titres.(groupe));
    else
        fprintf(fid, '# %s\n\n', groupe);
    end
    fprintf(fid, 'Fonctions natives du groupe `%s`.\n\n', groupe);
    for k = 1:n
        if ~strcmp(table{k, 2}, groupe)
            continue;
        end
        nom = table{k, 1};
        aide = help(nom);
        fprintf(fid, '## `%s`\n\n', nom);
        fprintf(fid, '```\n%s\n```\n\n', strtrim(aide));
        nombreNatives = nombreNatives + 1;
    end
    fclose(fid);
    fprintf('%-14s %s\n', groupe, fichier);
end

% ------------------------------------------------------------------ toolboxes
dossierToolbox = fullfile(racine, 'toolbox');
entrees = dir(dossierToolbox);
nomsToolbox = {};
for k = 1:numel(entrees)
    if entrees(k).isdir && ~strcmp(entrees(k).name, '.') && ~strcmp(entrees(k).name, '..')
        nomsToolbox{end+1} = entrees(k).name;
    end
end
nomsToolbox = sort(nomsToolbox);

nombreM = 0;
lignesIndex = {};
for t = 1:numel(nomsToolbox)
    nom = nomsToolbox{t};
    dossier = fullfile(dossierToolbox, nom);
    fichiers = dir(fullfile(dossier, '*.m'));
    fichier = fullfile(dossierSortie, ['toolbox-' nom '.md']);
    fid = fopen(fichier, 'w');
    fprintf(fid, '# Toolbox `%s`\n\n', nom);
    cheminContents = fullfile(dossier, 'Contents.m');
    if exist(cheminContents, 'file')
        contenu = fileread(cheminContents);
        fprintf(fid, '```\n%s```\n\n', contenu);
    end
    compte = 0;
    for k = 1:numel(fichiers)
        nomFichier = fichiers(k).name;
        if strcmp(nomFichier, 'Contents.m')
            continue;
        end
        base = nomFichier(1:end-2);
        aide = aideDeFichier(fullfile(dossier, nomFichier));
        fprintf(fid, '## `%s`\n\n', base);
        if isempty(strtrim(aide))
            fprintf(fid, '_Pas de bloc d''aide._\n\n');
        else
            fprintf(fid, '```\n%s\n```\n\n', strtrim(aide));
        end
        compte = compte + 1;
        nombreM = nombreM + 1;
    end
    fclose(fid);
    lignesIndex{end+1} = sprintf('| [`%s`](reference/toolbox-%s.md) | %d |', nom, nom, compte);
    fprintf('%-24s %d fonctions\n', nom, compte);
end

% --------------------------------------------------------------------- index
fid = fopen(fullfile(racine, 'documentation', 'reference.md'), 'w');
fprintf(fid, '# Reference des fonctions\n\n');
fprintf(fid, 'Genere par `outils/genererReference.m`. Ne pas modifier a la main.\n\n');
fprintf(fid, '## Fonctions natives\n\n');
fprintf(fid, '%d fonctions ecrites en C++, reparties en %d groupes.\n\n', ...
        nombreNatives, numel(groupes));
fprintf(fid, '| Groupe | Fichier |\n|---|---|\n');
for g = 1:numel(groupes)
    fprintf(fid, '| %s | [natif-%s.md](reference/natif-%s.md) |\n', ...
            groupes{g}, groupes{g}, groupes{g});
end
fprintf(fid, '\n## Toolboxes\n\n');
fprintf(fid, '%d fonctions ecrites dans le langage, reparties en %d toolboxes.\n\n', ...
        nombreM, numel(nomsToolbox));
fprintf(fid, '| Toolbox | Fonctions |\n|---|---|\n');
for k = 1:numel(lignesIndex)
    fprintf(fid, '%s\n', lignesIndex{k});
end
fclose(fid);

fprintf('\n%d fonctions natives, %d fonctions de toolbox.\n', nombreNatives, nombreM);

% ------------------------------------------------------------------ fonctions

function aide = aideDeFichier(chemin)
%AIDEDEFICHIER Bloc de commentaires qui suit la ligne « function ».
    texte = fileread(chemin);
    lignes = strsplit(texte, sprintf('\n'));
    aide = '';
    commence = false;
    for k = 1:numel(lignes)
        ligne = strtrim(lignes{k});
        if isempty(ligne)
            if commence
                break;
            end
            continue;
        end
        if ~commence && (strncmp(ligne, 'function', 8) || strncmp(ligne, 'classdef', 8))
            commence = true;
            continue;
        end
        if commence
            if ~isempty(ligne) && ligne(1) == '%'
                contenu = ligne(2:end);
                if ~isempty(contenu) && contenu(1) == ' '
                    contenu = contenu(2:end);
                end
                aide = [aide contenu sprintf('\n')];
            else
                break;
            end
        end
    end
end
