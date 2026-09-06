%% Base de données : une table, des lignes, des requêtes
% Une table nomme ses colonnes et empile ses lignes. Tout le reste — la
% sélection, la mise à jour, la suppression, le regroupement — s'exprime
% par un prédicat sur une ligne.
%
% Voir aussi DBTABLE, DBINSERT, DBSELECT, DBUPDATE, DBDELETE,
% DBGROUPSUM, DBSAVE, DBLOAD.

fprintf('=== Base de donnees ===\n');

%% 1. Créer une table et y insérer
t = dbTable({'nom', 'service', 'salaire', 'anciennete'});
donnees = { ...
    {'Dupont',  'etudes',    45000, 5}, ...
    {'Martin',  'etudes',    52000, 9}, ...
    {'Bernard', 'ventes',    38000, 2}, ...
    {'Petit',   'ventes',    41000, 6}, ...
    {'Durand',  'production', 35000, 12}, ...
    {'Leroy',   'production', 47000, 3}};
for k = 1:numel(donnees)
    t = dbInsert(t, donnees{k});
end
fprintf('\nTable de %d colonnes, %d lignes :\n', ...
        numel(t.colonnes), numel(t.lignes));
fprintf('  colonnes : %s\n', strjoin(t.colonnes, ', '));
assert(numel(t.lignes) == 6, 'six lignes inserees');
assert(numel(t.colonnes) == 4, 'quatre colonnes');

% Une ligne de la mauvaise largeur est refusée : c'est le seul contrôle
% de forme, et il vaut mieux qu'il soit strict.
refuse = false;
try
    dbInsert(t, {'Trop', 'court'});
catch
    refuse = true;
end
fprintf('  une ligne trop courte est refusee : %d\n', refuse);
assert(refuse, 'la largeur de ligne est verifiee');

%% 2. Sélectionner
% Un prédicat sur la ligne : la colonne se lit par son rang, la table
% n'ayant pas de nommage à l'intérieur du prédicat.
etudes = dbSelect(t, @(l) strcmp(l{2}, 'etudes'));
fprintf('\nSelection du service « etudes » : %d lignes\n', numel(etudes));
for k = 1:numel(etudes)
    fprintf('  %-8s %6d euros\n', etudes{k}{1}, etudes{k}{3});
end
assert(numel(etudes) == 2, 'deux personnes aux etudes');

% Sans prédicat, toute la table.
assert(numel(dbSelect(t)) == numel(t.lignes), 'sans predicat, tout sort');
% Un prédicat toujours faux ne rend rien — et c'est bien une liste vide,
% non une erreur.
assert(isempty(dbSelect(t, @(l) false)), 'aucune ligne ne peut sortir');

% Les prédicats se composent : c'est le « et » du langage de requête.
hauts = dbSelect(t, @(l) l{3} > 40000 && l{4} > 4);
fprintf('  salaire > 40000 et anciennete > 4 : %d lignes\n', numel(hauts));
noms = cellfun(@(l) l{1}, hauts, 'UniformOutput', false);
fprintf('  soit %s\n', strjoin(noms, ', '));
assert(numel(hauts) == 3, 'Dupont, Martin et Petit');
assert(all(ismember({'Dupont', 'Martin', 'Petit'}, noms)), 'et ce sont bien eux');
% Le « et » se resserre : ajouter une condition ne peut que retirer des
% lignes, jamais en ajouter.
plusStrict = dbSelect(t, @(l) l{3} > 40000 && l{4} > 4 && ~strcmp(l{2}, 'ventes'));
assert(numel(plusStrict) <= numel(hauts), 'une condition de plus ne peut qu''en retirer');
fprintf('  en excluant les ventes : %d lignes\n', numel(plusStrict));

%% 3. Mettre à jour, supprimer
% Une augmentation générale sur un service.
t2 = dbUpdate(t, @(l) strcmp(l{2}, 'ventes'), 'salaire', 45000);
apres = dbSelect(t2, @(l) strcmp(l{2}, 'ventes'));
fprintf('\nApres augmentation du service « ventes » :\n');
for k = 1:numel(apres)
    fprintf('  %-8s %6d euros\n', apres{k}{1}, apres{k}{3});
end
assert(all(cellfun(@(l) l{3} == 45000, apres)), 'les deux sont au meme salaire');
% Le reste n'a pas bougé : une mise à jour ne touche que ce qu'on lui dit.
avantEtudes = dbSelect(t, @(l) strcmp(l{2}, 'etudes'));
apresEtudes = dbSelect(t2, @(l) strcmp(l{2}, 'etudes'));
assert(isequal(avantEtudes, apresEtudes), 'les autres services sont intacts');
% Et la table d'origine non plus : les tables sont des valeurs, non des
% références. C'est ce qui rend une requête sans effet de bord.
avantVentes = dbSelect(t, @(l) strcmp(l{2}, 'ventes'));
assert(~all(cellfun(@(l) l{3} == 45000, avantVentes)), ...
       'la table d''origine n''a pas change');
fprintf('  la table d''origine garde ses %d et %d euros aux ventes\n', ...
        avantVentes{1}{3}, avantVentes{2}{3});

t3 = dbDelete(t, @(l) l{4} < 4);
fprintf('  suppression des anciennetes < 4 ans : %d lignes restantes\n', ...
        numel(t3.lignes));
assert(numel(t3.lignes) == 4, 'deux lignes supprimees');
assert(all(cellfun(@(l) l{4} >= 4, t3.lignes)), 'et il ne reste que les bonnes');
% Supprimer ce qui n'existe pas ne fait rien.
assert(numel(dbDelete(t, @(l) false).lignes) == numel(t.lignes), ...
       'un predicat toujours faux ne supprime rien');

%% 4. Regrouper
% La somme par service : c'est le « GROUP BY » de tout langage de requête.
[cles, sommes] = dbGroupSum(t, 'service', 'salaire');
fprintf('\nMasse salariale par service :\n');
for k = 1:numel(cles)
    fprintf('  %-12s %7d euros\n', cles{k}, sommes(k));
end
assert(numel(cles) == 3, 'trois services');
% Le total des groupes est le total général : c'est la propriété qui
% valide tout regroupement.
totalGeneral = sum(cellfun(@(l) l{3}, t.lignes));
fprintf('  total des groupes %d, total general %d\n', sum(sommes), totalGeneral);
assert(sum(sommes) == totalGeneral, 'les groupes partitionnent la table');
% Et chaque groupe vaut bien la somme de ses lignes.
for k = 1:numel(cles)
    lignes = dbSelect(t, @(l) strcmp(l{2}, cles{k}));
    assert(sommes(k) == sum(cellfun(@(l) l{3}, lignes)), ...
           'chaque somme de groupe est exacte');
end

%% 5. Écrire et relire
% Le tour complet : sauver la table, la relire, et vérifier qu'on retrouve
% ce qu'on avait — c'est la seule épreuve qui vaille pour une écriture.
fichier = [tempname() '.csv'];
dbSave(t, fichier);
relue = dbLoad(fichier);
fprintf('\nEcriture puis relecture :\n');
fprintf('  %d colonnes, %d lignes relues\n', ...
        numel(relue.colonnes), numel(relue.lignes));
assert(isequal(relue.colonnes, t.colonnes), 'les colonnes reviennent');
assert(numel(relue.lignes) == numel(t.lignes), 'et toutes les lignes');
% Les nombres reviennent en nombres, non en chaînes.
premiere = relue.lignes{1};
fprintf('  premiere ligne : %s, %s, %g, %g\n', ...
        premiere{1}, premiere{2}, premiere{3}, premiere{4});
assert(ischar(premiere{1}), 'le nom reste une chaine');
assert(isnumeric(premiere{3}) && premiere{3} == 45000, ...
       'le salaire revient en nombre');
% Un regroupement sur la table relue donne le même résultat : c'est la
% vérification de bout en bout.
[clesRelues, sommesRelues] = dbGroupSum(relue, 'service', 'salaire');
assert(isequal(clesRelues, cles) && isequal(sommesRelues, sommes), ...
       'la table relue se comporte comme l''originale');
fprintf('  les memes sommes par service apres relecture\n');
delete(fichier);

%% 6. Une table vide reste une table
% Le cas limite qu'on oublie toujours de traiter.
vide = dbTable({'a', 'b'});
fprintf('\nTable vide :\n');
fprintf('  %d lignes, selection : %d, groupement : %d cles\n', ...
        numel(vide.lignes), numel(dbSelect(vide, @(l) true)), ...
        numel(dbGroupSum(vide, 'a', 'b')));
assert(isempty(dbSelect(vide, @(l) true)), 'rien a selectionner');
assert(isempty(dbGroupSum(vide, 'a', 'b')), 'rien a grouper');
assert(numel(dbDelete(vide, @(l) true).lignes) == 0, 'rien a supprimer');
vide = dbInsert(vide, {1, 2});
assert(numel(vide.lignes) == 1, 'et elle se remplit normalement');

fprintf('\nToutes les verifications passent.\n');
