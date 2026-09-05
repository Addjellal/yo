%% test_exemples.m — les exemples par boîte à outils doivent tourner.
%
% Chaque fichier de exemples/toolboxes traite un cas d'école et vérifie
% lui-même ses résultats. Les faire tourner sous les tests garantit deux
% choses : que la boîte à outils fait ce que l'exemple annonce, et que
% l'exemple reste un modèle valide à copier.
%
% Chaque exemple tourne dans l'espace de travail d'une fonction, non dans
% celui du test : un script exécuté par RUN écrit dans l'espace de son
% appelant, et les variables des exemples écraseraient celles du test.
disp('--- exemples ---');

racine = fileparts(fileparts(fileparts(mfilename('fullpath'))));
dossier = fullfile(racine, 'exemples', 'toolboxes');
listeFichiers = dir(fullfile(dossier, '*.m'));
assert(~isempty(listeFichiers), 'aucun exemple trouve dans exemples/toolboxes');
nomsExemples = sort({listeFichiers.name});

for indiceExemple = 1:numel(nomsExemples)
    nomCourant = nomsExemples{indiceExemple};
    lancerUnExemple(fullfile(dossier, nomCourant), nomCourant);
end

fprintf('%d exemples de boites a outils executes\n', numel(nomsExemples));
disp('exemples : toutes les verifications passent');

function lancerUnExemple(chemin, nom)
%LANCERUNEXEMPLE Exécution isolée d'un exemple.
%   La sortie n'intéresse pas le test : seul compte qu'il aille jusqu'au
%   bout sans qu'une de ses vérifications cède, et qu'il le dise.
    sortie = evalc('run(chemin)');
    assert(contains(sortie, 'Toutes les verifications passent'), ...
           sprintf('%s ne conclut pas', nom));
    fprintf('  %-24s ok\n', nom);
end
