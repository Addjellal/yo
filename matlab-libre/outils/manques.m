% manques.m — ce qui manque à MatLibre pour coller à MATLAB.
%
% Le script compare l'inventaire des fonctions de MatLibre — natives et
% fichiers .m des toolboxes — aux listes de noms rangées dans
% documentation/reference-matlab/. Chaque liste est un fichier texte, un
% nom par ligne ou séparés par des espaces, « # » commençant un
% commentaire.
%
% Il écrit documentation/manques.md : par domaine, ce qui est présent, ce
% qui manque, et la proportion. Les listes de référence ne prétendent pas
% être exhaustives ; elles couvrent ce qu'un utilisateur rencontre.
%
% Usage :  matlibre outils/manques.m
disp('--- manques ---');

racine = pwd();
dossierListes = fullfile(racine, 'documentation', 'reference-matlab');
listes = dir(fullfile(dossierListes, '*.txt'));
if isempty(listes)
    error('manques:AucuneListe', 'Aucune liste de reference dans %s.', dossierListes);
end

sortie = {};
sortie{end+1} = '# Ce qui manque';
sortie{end+1} = '';
sortie{end+1} = ['Comparaison de l''inventaire de MatLibre aux listes de ' ...
                 '`documentation/reference-matlab/`.'];
sortie{end+1} = 'Fichier produit par `outils/manques.m` ; ne pas le corriger à la main.';
sortie{end+1} = '';
sortie{end+1} = '| domaine | présentes | manquantes | couverture |';
sortie{end+1} = '|---|---:|---:|---:|';

detail = {};
totalPresentes = 0;
totalManquantes = 0;
for k = 1:numel(listes)
    domaine = listes(k).name(1:end-4);
    noms = lireListe(fullfile(dossierListes, listes(k).name));
    presentes = {};
    manquantes = {};
    for j = 1:numel(noms)
        if exist(noms{j}) ~= 0     %#ok<EXIST>
            presentes{end+1} = noms{j};   %#ok<SAGROW>
        else
            manquantes{end+1} = noms{j};  %#ok<SAGROW>
        end
    end
    total = numel(noms);
    part = 100 * numel(presentes) / max(total, 1);
    sortie{end+1} = sprintf('| %s | %d | %d | %.0f %% |', ...
                            domaine, numel(presentes), numel(manquantes), part);   %#ok<SAGROW>
    totalPresentes = totalPresentes + numel(presentes);
    totalManquantes = totalManquantes + numel(manquantes);
    detail{end+1} = struct('domaine', domaine, 'manquantes', {manquantes});   %#ok<SAGROW>
    fprintf('  %-24s %3d presentes, %3d manquantes\n', domaine, ...
            numel(presentes), numel(manquantes));
end
part = 100 * totalPresentes / max(totalPresentes + totalManquantes, 1);
sortie{end+1} = sprintf('| **ensemble** | **%d** | **%d** | **%.0f %%** |', ...
                        totalPresentes, totalManquantes, part);
sortie{end+1} = '';

for k = 1:numel(detail)
    if isempty(detail{k}.manquantes)
        continue
    end
    sortie{end+1} = ['## ' detail{k}.domaine];   %#ok<SAGROW>
    sortie{end+1} = '';                          %#ok<SAGROW>
    ligne = '';
    noms = detail{k}.manquantes;
    for j = 1:numel(noms)
        if isempty(ligne)
            ligne = ['`' noms{j} '`'];
        else
            ligne = [ligne ', `' noms{j} '`'];   %#ok<AGROW>
        end
        if numel(ligne) > 70
            sortie{end+1} = ligne;               %#ok<SAGROW>
            ligne = '';
        end
    end
    if ~isempty(ligne)
        sortie{end+1} = ligne;                   %#ok<SAGROW>
    end
    sortie{end+1} = '';                          %#ok<SAGROW>
end

% La partie écrite à la main — les manques qui ne sont pas des noms de
% fonctions — est reprise telle quelle à la fin.
horsFonctions = fullfile(dossierListes, 'hors-fonctions.md');
if exist(horsFonctions, 'file')
    sortie{end+1} = fileread(horsFonctions);
end

fichier = fullfile(racine, 'documentation', 'manques.md');
filewrite(fichier, strjoin(sortie, sprintf('\n')));
fprintf('  ecrit : %s\n', fichier);
fprintf('  %d presentes, %d manquantes (%.0f %% de couverture)\n', ...
        totalPresentes, totalManquantes, part);

function noms = lireListe(chemin)
%LIRELISTE Les noms d'un fichier de reference, commentaires retires.
    texte = fileread(chemin);
    lignes = strsplit(texte, sprintf('\n'));
    noms = {};
    for k = 1:numel(lignes)
        ligne = strtrim(lignes{k});
        if isempty(ligne) || ligne(1) == '#'
            continue
        end
        for morceau = strsplit(ligne)
            mot = strtrim(morceau{1});
            if ~isempty(mot)
                noms{end+1} = mot;   %#ok<AGROW>
            end
        end
    end
end
