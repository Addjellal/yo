% majComptes.m — remet à jour les nombres de fonctions cités par la doc.
%
% Les comptes traînent dans plusieurs fichiers ; les recopier à la main,
% c'est se tromper. Ce script les relit du dépôt et réécrit les chiffres
% en place, sans toucher au reste du texte.
%
% Usage :  matlibre outils/majComptes.m
disp('--- comptes ---');

racine = pwd();
natives = size(matlibre_fonctions(), 1);

entrees = dir(fullfile(racine, 'toolbox'));
noms = {};
comptes = [];
for k = 1:numel(entrees)
    if ~entrees(k).isdir || entrees(k).name(1) == '.'
        continue
    end
    fichiers = dir(fullfile(racine, 'toolbox', entrees(k).name, '*.m'));
    n = 0;
    for j = 1:numel(fichiers)
        if ~strcmp(fichiers(j).name, 'Contents.m')
            n = n + 1;
        end
    end
    noms{end + 1} = entrees(k).name;      %#ok<SAGROW>
    comptes(end + 1) = n;                 %#ok<SAGROW>
end
[noms, ordre] = sort(noms);
comptes = comptes(ordre);
total = sum(comptes);
modules = numel(noms);

fprintf('%d fonctions natives, %d fonctions de toolbox, %d modules\n', ...
        natives, total, modules);

% ------------------------------------ la colonne de documentation/toolboxes.md
chemin = fullfile(racine, 'documentation', 'toolboxes.md');
lignes = strsplit(fileread(chemin), sprintf('\n'));
change = 0;
for k = 1:numel(lignes)
    for t = 1:numel(noms)
        debut = ['| `' noms{t} '` |'];
        if strncmp(lignes{k}, debut, numel(debut))
            morceaux = strsplit(lignes{k}, '|');
            ancien = strtrim(morceaux{4});
            neuf = sprintf('%d', comptes(t));
            if ~strcmp(ancien, neuf)
                morceaux{4} = [' ' neuf ' '];
                lignes{k} = strjoin(morceaux, '|');
                change = change + 1;
                fprintf('  %-24s %s -> %s\n', noms{t}, ancien, neuf);
            end
        end
    end
end
ecrireLignes(chemin, lignes);

% ------------------------- les comptes cités en toutes lettres dans le texte
% « La Signal Processing Toolbox compte 163 fonctions » : ces phrases
% vieillissent aussi. On les relie au dossier correspondant.
citations = {
    'signal',               'La Signal Processing Toolbox compte %d fonctions'
    'images',               'L''Image Processing Toolbox en compte %d'
    'statistiques',         'La Statistics and Machine Learning Toolbox en compte %d'
    'automatique',          'La Control System Toolbox en compte\n   %d'
    'ondelettes',           'La Wavelet Toolbox en compte %d'
    'apprentissage-profond', 'La Deep Learning Toolbox compte %d'
    };
cheminCouverture = fullfile(racine, 'documentation', 'couverture.md');
texteCouverture = fileread(cheminCouverture);
for k = 1:size(citations, 1)
    indice = find(strcmp(noms, citations{k, 1}), 1);
    if isempty(indice)
        continue
    end
    motif = strrep(citations{k, 2}, '%d', '\d+');
    remplacement = sprintf(strrep(citations{k, 2}, '%%', '%%%%'), comptes(indice));
    texteCouverture = regexprep(texteCouverture, motif, remplacement);
end
fid = fopen(cheminCouverture, 'w');
fprintf(fid, '%s', texteCouverture);
fclose(fid);

% ------------------------------------------------- les totaux, partout où ils sont
fichiers = {fullfile(racine, 'README.md'), ...
            fullfile(racine, 'documentation', 'couverture.md'), ...
            fullfile(racine, 'documentation', 'architecture.md'), ...
            fullfile(racine, 'documentation', 'developpeur.md'), ...
            fullfile(racine, 'documentation', 'toolboxes.md')};
motifs = {'\d+ fonctions natives', sprintf('%d fonctions natives', natives)
          '\d+ fonctions de toolbox', sprintf('%d fonctions de toolbox', total)
          'fonctions natives — \d+,', sprintf('fonctions natives — %d,', natives)
          'réparties en \*\*\d+ modules\*\*', sprintf('réparties en **%d modules**', modules)
          'réparties en \d+ modules', sprintf('réparties en %d modules', modules)
          'les \d+ modules et leur', sprintf('les %d modules et leur', modules)};
for f = 1:numel(fichiers)
    texte = fileread(fichiers{f});
    avant = texte;
    for m = 1:size(motifs, 1)
        texte = regexprep(texte, motifs{m, 1}, motifs{m, 2});
    end
    if ~strcmp(texte, avant)
        fid = fopen(fichiers{f}, 'w');
        fprintf(fid, '%s', texte);
        fclose(fid);
        fprintf('  mis a jour : %s\n', fichiers{f});
    end
end

fprintf('comptes : %d ligne(s) de tableau corrigee(s)\n', change);

function ecrireLignes(chemin, lignes)
    fid = fopen(chemin, 'w');
    for k = 1:numel(lignes)
        if k < numel(lignes)
            fprintf(fid, '%s\n', lignes{k});
        else
            fprintf(fid, '%s', lignes{k});
        end
    end
    fclose(fid);
end
