% analyse-de-texte.m — Text Analytics Toolbox, cas d'école.
%
%   matlibre exemples/toolboxes/analyse-de-texte.m
%
% Le cas : un petit corpus, et la question de savoir de quoi parle chaque
% document. La chaîne est toujours la même — découper, nettoyer, compter,
% pondérer — et c'est la pondération qui fait tout le travail.

fprintf('=== Analyse de texte : decouper, nettoyer, compter, ponderer ===\n\n');

%% 1. Découper
% Un texte devient une liste de mots. Ce qui semble trivial ne l'est pas :
% la ponctuation, la casse et les apostrophes décident du résultat.
texte = 'Le chat dort. Le chien court vite ! Le chat et le chien dorment.';
mots = tokenizedDocument(texte);
fprintf('Texte : %s\n', texte);
fprintf('  %d mots : %s\n', numel(mots), strjoin(mots, ' | '));
assert(numel(mots) >= 12);
% La ponctuation a disparu.
assert(~any(contains(mots, '.')) && ~any(contains(mots, '!')));

% Découper en phrases est un autre problème : le point termine une
% phrase, sauf quand il abrège.
phrases = splitSentences(texte);
fprintf('  %d phrases\n', numel(phrases));
assert(numel(phrases) == 3);
assert(contains(phrases{1}, 'chat'));

%% 2. Normaliser
% Mettre en minuscules et ramener les variantes à une forme commune :
% sans cela « Le » et « le » comptent pour deux mots différents.
normalises = normalizeWords(mots);
fprintf('\nApres normalisation : %s\n', strjoin(normalises, ' | '));
assert(all(strcmp(normalises, lower(normalises))), 'tout est en minuscules');
% « Le » et « le » sont maintenant le meme mot.
assert(sum(strcmp(normalises, 'le')) >= 3);

%% 3. Ôter les mots vides
% Les mots les plus fréquents d'une langue — articles, prépositions — ne
% disent rien du sujet. Les ôter réduit le vocabulaire de moitié sans
% rien perdre.
motsVides = {'le', 'la', 'les', 'et', 'de', 'du', 'un', 'une'};
utiles = removeStopWords(normalises, motsVides);
fprintf('\nApres retrait des mots vides : %s\n', strjoin(utiles, ' | '));
fprintf('  %d mots -> %d mots\n', numel(normalises), numel(utiles));
assert(numel(utiles) < numel(normalises));
assert(~any(strcmp(utiles, 'le')), 'les mots vides ont disparu');
assert(any(strcmp(utiles, 'chat')), 'les mots pleins sont restes');

%% 4. Compter
% Le vocabulaire et les effectifs. C'est la représentation la plus simple
% d'un document : un sac de mots, où l'ordre est perdu.
[motsUniques, effectifsMots] = wordFrequency(utiles);
fprintf('\nFrequences :\n');
[~, ordre] = sort(effectifsMots, 'descend');
for k = 1:min(4, numel(ordre))
    fprintf('  %-10s %d\n', motsUniques{ordre(k)}, effectifsMots(ordre(k)));
end
assert(sum(effectifsMots) == numel(utiles), ...
       'la somme des effectifs vaut le nombre de mots');
assert(numel(motsUniques) == numel(unique(motsUniques)));

%% 5. Le sac de mots d'un corpus
% Plusieurs documents, un vocabulaire commun, une matrice d'effectifs.
documents = {tokenizedDocument('le chat dort sur le tapis'), ...
             tokenizedDocument('le chien court dans le jardin'), ...
             tokenizedDocument('le chat et le chien dorment')};
[effectifs, vocabulaire] = bagOfWords(documents);
fprintf('\nSac de mots : %d documents, %d mots de vocabulaire\n', ...
        size(effectifs, 1), numel(vocabulaire));
assert(size(effectifs, 1) == 3);
assert(size(effectifs, 2) == numel(vocabulaire));
% Chaque ligne compte les mots d'un document.
for k = 1:3
    assert(sum(effectifs(k, :)) == numel(documents{k}), ...
           'chaque ligne totalise les mots de son document');
end
% Un mot present dans un seul document n'apparait que sur sa ligne.
indiceTapis = find(strcmp(vocabulaire, 'tapis'), 1);
assert(~isempty(indiceTapis));
assert(effectifs(1, indiceTapis) == 1);
assert(sum(effectifs(:, indiceTapis)) == 1, ...
       '« tapis » n''apparait que dans le premier document');

%% 6. La pondération TF-IDF
% Un mot présent partout ne distingue rien ; un mot rare, si. TF-IDF
% multiplie la fréquence dans le document par l'inverse du nombre de
% documents qui le contiennent. C'est la pondération qui rend le sac de
% mots utilisable.
poids = tfidf(effectifs);
fprintf('\nPonderation TF-IDF :\n');
fprintf('  matrice %dx%d\n', size(poids, 1), size(poids, 2));
assert(isequal(size(poids), size(effectifs)));
% « le » est dans les trois documents : son poids est nul, puisqu'il ne
% distingue rien.
indiceLe = find(strcmp(vocabulaire, 'le'), 1);
fprintf('  poids de « le »    (dans 3 documents sur 3) : %.6f\n', ...
        max(poids(:, indiceLe)));
assert(max(abs(poids(:, indiceLe))) < 1e-12, ...
       'un mot present partout ne pese rien');
% « tapis » n'est que dans un : son poids est le plus fort.
fprintf('  poids de « tapis » (dans 1 document sur 3) : %.6f\n', ...
        max(poids(:, indiceTapis)));
assert(max(poids(:, indiceTapis)) > 0, 'un mot rare pese');
% Le poids est nul partout ou le mot est absent.
absent = effectifs == 0;
assert(max(abs(poids(absent))) < 1e-12);

%% 7. La distance d'édition
% Combien de corrections séparent deux mots. C'est la mesure de base de
% la correction orthographique et de la recherche approchée.
paires = {{'chat', 'chats'}, {'chien', 'chine'}, {'jardin', 'jardin'}, ...
          {'court', 'cours'}};
fprintf('\nDistance d''edition :\n');
for k = 1:numel(paires)
    d = editDistance(paires{k}{1}, paires{k}{2});
    fprintf('  %-8s / %-8s : %d\n', paires{k}{1}, paires{k}{2}, d);
end
% Un mot est a distance nulle de lui-meme.
assert(editDistance('jardin', 'jardin') == 0);
% Ajouter une lettre coute un.
assert(editDistance('chat', 'chats') == 1);
% Elle est symetrique : corriger dans un sens ou dans l'autre coute
% pareil.
assert(editDistance('chien', 'chine') == editDistance('chine', 'chien'));
% Et elle respecte l'inegalite triangulaire : c'est une vraie distance.
a = 'chat'; b = 'chien'; c = 'chine';
assert(editDistance(a, c) <= editDistance(a, b) + editDistance(b, c), ...
       'l''inegalite triangulaire doit tenir');
% Elle ne depasse jamais la longueur du plus long mot.
assert(editDistance('a', 'abcde') == 4);

fprintf('\nToutes les verifications passent.\n');
