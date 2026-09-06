% audit.m — état des lieux mesuré de MatLibre.
%
% Le script ne juge rien sur parole : il compte. Pour chaque boîte à
% outils il mesure la couverture par rapport à la liste de référence, la
% part de fonctions documentées au-delà d'une ligne, celles qui portent un
% exemple dans leur aide, celles que les tests ou les exemples exercent, et
% celles qui restent orphelines.
%
% Il écrit documentation/audit.md.
%
% Usage :  matlibre outils/audit.m
disp('--- audit ---');

racine = pwd();
dossierToolbox = fullfile(racine, 'toolbox');
boites = dir(dossierToolbox);
boites = boites([boites.isdir] & ~startsWith({boites.name}, '.'));
noms = sort({boites.name});

% Tout ce que les tests et les exemples nomment, en un seul texte : on y
% cherchera chaque fonction. Grossier, mais sans faux négatif.
corpus = '';
for dossier = {fullfile(racine, 'tests', 'scripts'), ...
               fullfile(racine, 'exemples'), ...
               fullfile(racine, 'exemples', 'toolboxes')}
    fichiers = dir(fullfile(dossier{1}, '*.m'));
    for k = 1:numel(fichiers)
        corpus = [corpus, ' ', fileread(fullfile(fichiers(k).folder, fichiers(k).name))]; %#ok<AGROW>
    end
end
% Les tests C++ nomment aussi des fonctions.
fichiersCpp = dir(fullfile(racine, 'tests', '*.cpp'));
for k = 1:numel(fichiersCpp)
    corpus = [corpus, ' ', fileread(fullfile(fichiersCpp(k).folder, fichiersCpp(k).name))]; %#ok<AGROW>
end

lignes = {};
lignes{end+1} = '# Audit';
lignes{end+1} = '';
lignes{end+1} = 'Fichier produit par `outils/audit.m` ; ne pas le corriger à la main.';
lignes{end+1} = '';
lignes{end+1} = ['Pour chaque boîte à outils : le nombre de fonctions publiques, ' ...
                 'la part dont l''aide dépasse une ligne, la part qui porte un ' ...
                 'exemple, et la part qu''un test ou un exemple exerce.'];
lignes{end+1} = '';
lignes{end+1} = '| boîte à outils | fonctions | documentées | avec exemple | exercées |';
lignes{end+1} = '|---|---:|---:|---:|---:|';

totalFonctions = 0;
totalDocumentees = 0;
totalExemples = 0;
totalExercees = 0;
maigres = {};
sansExemple = {};
orphelines = {};

for b = 1:numel(noms)
    nom = noms{b};
    if strcmp(nom, 'aide')
        continue
    end
    fichiers = dir(fullfile(dossierToolbox, nom, '*.m'));
    nFonctions = 0;
    nDocumentees = 0;
    nExemples = 0;
    nExercees = 0;
    for k = 1:numel(fichiers)
        base = fichiers(k).name(1:end-2);
        if strcmp(base, 'Contents') || startsWith(base, 'matlibre_')
            continue
        end
        nFonctions = nFonctions + 1;
        texte = fileread(fullfile(fichiers(k).folder, fichiers(k).name));
        aide = blocAide(texte);
        if numel(aide) > 1
            nDocumentees = nDocumentees + 1;
        else
            maigres{end+1} = [nom '/' base];   %#ok<AGROW>
        end
        if any(contains(lower(aide), 'exemple'))
            nExemples = nExemples + 1;
        else
            sansExemple{end+1} = [nom '/' base];   %#ok<AGROW>
        end
        if contains(corpus, base)
            nExercees = nExercees + 1;
        else
            orphelines{end+1} = [nom '/' base];   %#ok<AGROW>
        end
    end
    if nFonctions == 0
        continue
    end
    lignes{end+1} = sprintf('| %s | %d | %.0f %% | %.0f %% | %.0f %% |', ...
                            nom, nFonctions, ...
                            100 * nDocumentees / nFonctions, ...
                            100 * nExemples / nFonctions, ...
                            100 * nExercees / nFonctions);   %#ok<AGROW>
    fprintf('  %-26s %4d fonctions, %3.0f %% documentees, %3.0f %% avec exemple, %3.0f %% exercees\n', ...
            nom, nFonctions, 100 * nDocumentees / nFonctions, ...
            100 * nExemples / nFonctions, 100 * nExercees / nFonctions);
    totalFonctions = totalFonctions + nFonctions;
    totalDocumentees = totalDocumentees + nDocumentees;
    totalExemples = totalExemples + nExemples;
    totalExercees = totalExercees + nExercees;
end

lignes{end+1} = sprintf('| **ensemble** | **%d** | **%.0f %%** | **%.0f %%** | **%.0f %%** |', ...
                        totalFonctions, ...
                        100 * totalDocumentees / totalFonctions, ...
                        100 * totalExemples / totalFonctions, ...
                        100 * totalExercees / totalFonctions);
lignes{end+1} = '';

lignes{end+1} = '## Ce qui reste à faire';
lignes{end+1} = '';
lignes{end+1} = sprintf(['%d fonctions n''ont qu''une ligne d''aide. Une ligne dit ce ' ...
                         'que fait la fonction, non comment elle se comporte aux ' ...
                         'bords ni ce qu''elle refuse.'], numel(maigres));
lignes{end+1} = '';
lignes = [lignes, enColonnes(maigres)];
lignes{end+1} = '';
lignes{end+1} = sprintf('%d fonctions ne portent pas d''exemple dans leur aide.', ...
                        numel(sansExemple));
lignes{end+1} = '';
lignes = [lignes, enColonnes(sansExemple)];
lignes{end+1} = '';
lignes{end+1} = sprintf(['%d fonctions ne sont nommées par aucun test ni aucun ' ...
                         'exemple : rien ne prouve qu''elles marchent.'], ...
                        numel(orphelines));
lignes{end+1} = '';
lignes = [lignes, enColonnes(orphelines)];
lignes{end+1} = '';

chemin = fullfile(racine, 'documentation', 'audit.md');
identifiant = fopen(chemin, 'w');
for k = 1:numel(lignes)
    fprintf(identifiant, '%s\n', lignes{k});
end
fclose(identifiant);
fprintf('\n  %d fonctions publiques\n', totalFonctions);
fprintf('  %d a l''aide d''une seule ligne\n', numel(maigres));
fprintf('  %d sans exemple\n', numel(sansExemple));
fprintf('  %d sans test ni exemple\n', numel(orphelines));
fprintf('  ecrit : %s\n', chemin);

function aide = blocAide(texte)
% Le bloc de commentaires qui suit la ligne « function » ou « classdef ».
    lignes = strsplit(texte, sprintf('\n'));
    aide = {};
    commence = false;
    for k = 1:numel(lignes)
        ligne = strtrim(lignes{k});
        if ~commence
            if startsWith(ligne, 'function') || startsWith(ligne, 'classdef')
                commence = true;
            end
            continue
        end
        if isempty(ligne)
            continue
        end
        if ligne(1) ~= '%'
            break
        end
        aide{end+1} = ligne;   %#ok<AGROW>
    end
end

function blocs = enColonnes(liste)
% La liste en lignes de quatre, pour qu'elle se lise.
    blocs = {};
    if isempty(liste)
        blocs{end+1} = '*Aucune.*';
        return
    end
    liste = sort(liste);
    for k = 1:4:numel(liste)
        fin = min(k + 3, numel(liste));
        morceaux = liste(k:fin);
        for j = 1:numel(morceaux)
            morceaux{j} = ['`' morceaux{j} '`'];
        end
        blocs{end+1} = strjoin(morceaux, ', ');   %#ok<AGROW>
    end
end
