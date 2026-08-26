% verifierDoublons.m — refuse deux fichiers .m de même nom.
%
% Le chemin de recherche masque le second : deux implémentations du même
% nom, c'est une divergence silencieuse. Ce contrôle tourne avec les tests.
disp('--- doublons ---');
racine = getenv('MATLIBRE_TOOLBOX');
if isempty(racine)
    racine = 'toolbox';
end
dossiers = dir(racine);
noms = {};
ou = {};
for k = 1:numel(dossiers)
    if ~dossiers(k).isdir || dossiers(k).name(1) == '.'
        continue
    end
    chemin = fullfile(racine, dossiers(k).name);
    fichiers = dir(fullfile(chemin, '*.m'));
    for j = 1:numel(fichiers)
        nom = fichiers(j).name;
        if strcmp(nom, 'Contents.m')
            continue
        end
        noms{end + 1} = nom;                       %#ok<SAGROW>
        ou{end + 1} = fullfile(chemin, nom);       %#ok<SAGROW>
    end
end
doublons = {};
for k = 1:numel(noms)
    for j = k + 1:numel(noms)
        if strcmp(noms{k}, noms{j})
            doublons{end + 1} = sprintf('%s :\n    %s\n    %s', noms{k}, ou{k}, ou{j}); %#ok<SAGROW>
        end
    end
end
% Un fichier .m qui porte le nom d'une fonction native la masque : le C++
% devient inatteignable, et les deux implementations divergent en silence.
masques = {};
for k = 1:numel(noms)
    base = noms{k}(1:end - 2);
    if exist(base, 'builtin') == 5
        masques{end + 1} = sprintf('%s masque la fonction native du meme nom :\n    %s', ...
                                   base, ou{k});                       %#ok<SAGROW>
    end
end
if ~isempty(masques)
    for k = 1:numel(masques)
        fprintf('MASQUAGE %s\n', masques{k});
    end
    error('matlibre:masquage', '%d fichier(s) masquent une fonction native.', numel(masques));
end
if isempty(doublons)
    fprintf('doublons : aucun, sur %d fichiers ; aucun masquage du natif\n', numel(noms));
else
    for k = 1:numel(doublons)
        fprintf('DOUBLON %s\n', doublons{k});
    end
    error('matlibre:doublons', '%d nom(s) de fonction en double.', numel(doublons));
end
