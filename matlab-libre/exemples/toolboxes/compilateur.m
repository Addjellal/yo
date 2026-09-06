%% Compilateur : distribuer un programme
% « Compiler » un script MATLAB n'a jamais voulu dire en faire un binaire
% autonome : cela veut dire l'empaqueter avec de quoi l'exécuter. MCC
% produit un lanceur, et le lanceur appelle l'interpréteur.
%
% Voir aussi MCC, DEPLOYTOOL.

fprintf('=== Compilateur : empaqueter un programme ===\n');

%% 1. Fabriquer un lanceur
dossier = tempname();
mkdir(dossier);
script = fullfile(dossier, 'bonjour.m');
identifiant = fopen(script, 'w');
fprintf(identifiant, 'fprintf(''resultat : %%g\\n'', 6 * 7);\n');
fclose(identifiant);

lanceur = mcc(script, fullfile(dossier, 'bonjour'));
fprintf('\nLanceur produit :\n  %s\n', lanceur);
assert(exist(lanceur, 'file') == 2, 'le lanceur est ecrit');
contenu = fileread(lanceur);
fprintf('  %d octets, %d lignes\n', numel(contenu), ...
        numel(strsplit(strtrim(contenu), sprintf('\n'))));
assert(contains(contenu, 'matlibre'), 'il appelle l''interpreteur');
assert(contains(contenu, 'bonjour.m'), 'sur le script demande');

%% 2. Le lanceur fonctionne
% C'est la seule vérification qui compte : l'exécuter et regarder ce
% qu'il écrit.
if isunix
    system(sprintf('chmod +x "%s"', lanceur));
    [statut, sortie] = system(sprintf('"%s"', lanceur));
    fprintf('\nExecution du lanceur :\n');
    fprintf('  code de retour %d\n', statut);
    fprintf('  sortie : %s\n', strtrim(sortie));
    assert(statut == 0, 'le lanceur s''execute sans erreur');
    assert(contains(sortie, '42'), 'et le script fait ce qu''il doit');
end

%% 3. Le nom du programme
% Sans nom de sortie, le lanceur prend celui du script : c'est la
% convention de MCC, et elle évite d'avoir à le répéter.
script2 = fullfile(dossier, 'calcule.m');
identifiant = fopen(script2, 'w');
fprintf(identifiant, 'disp(sum(1:100));\n');
fclose(identifiant);
ancien = cd(dossier);
lanceur2 = mcc('calcule.m');
fprintf('\nSans nom de sortie : %s\n', lanceur2);
assert(contains(lanceur2, 'calcule'), 'le lanceur prend le nom du script');
assert(exist(lanceur2, 'file') == 2, 'et il est bien ecrit');
cd(ancien);

%% 4. Ce que le paquet contient vraiment
% DEPLOYTOOL le décrit sans détour : le programme n'est pas autonome. Le
% dire est plus utile que de laisser croire le contraire — un programme
% qu'on distribue sans son interpréteur ne démarre pas.
description = deploytool(script);
fprintf('\nDescription du paquet :\n');
fprintf('  script       : %s\n', description.script);
fprintf('  interpreteur : %s\n', description.interpreteur);
fprintf('  toolboxes    : %s\n', description.toolboxes);
fprintf('  remarque     : %s\n', description.remarque);
assert(strcmp(description.script, script), 'le script est celui qu''on a donne');
assert(~isempty(description.interpreteur), 'l''interpreteur est nomme');
assert(exist(description.toolboxes, 'dir') == 7, ...
       'le dossier des toolboxes existe reellement');
assert(contains(lower(description.remarque), 'autonome'), ...
       'et la remarque dit franchement ce qu''il en est');

%% 5. Le parallèle avec le MATLAB Runtime
% MATLAB distribue un programme compilé avec son « runtime », un
% ensemble de bibliothèques qu'il faut installer sur la machine cible.
% Ici, la dépendance est l'interpréteur et le dossier des toolboxes :
% c'est la même chose, dite plus simplement.
fprintf('\nCe qu''il faut sur la machine cible :\n');
fprintf('  l''interpreteur « %s »\n', description.interpreteur);
fprintf('  et le dossier des toolboxes, %d boites a outils\n', ...
        numel(dir(fullfile(description.toolboxes, '*'))) - 2);
boites = dir(description.toolboxes);
boites = boites([boites.isdir] & ~startsWith({boites.name}, '.'));
fprintf('  soit %d dossiers, dont %s...\n', numel(boites), ...
        strjoin({boites(1:min(4, numel(boites))).name}, ', '));
assert(numel(boites) > 10, 'le dossier des toolboxes est bien peuple');

fprintf('\nToutes les verifications passent.\n');
