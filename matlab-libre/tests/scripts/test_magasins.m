% test_magasins.m — magasins de données : lecture par morceaux.
% Ce qui définit un magasin est la boucle qu'il permet d'écrire :
% « tant qu'il reste, lire le suivant ». Elle doit se terminer, ne rien
% sauter, ne rien compter deux fois.
disp('--- magasins ---');

dossier = tempdir;

%% ----------------------------------------------- TABULARTEXTDATASTORE
fichier = fullfile(dossier, 'matlibre_magasin.csv');
writelines(["a,b"; "1,2"; "3,4"; "5,6"; "7,8"; "9,10"], fichier);

ds = tabularTextDatastore(fichier, 'ReadSize', 2);
assert(numel(ds.Files) == 1);
assert(isequal(ds.VariableNames, {'a', 'b'}));

% La boucle usuelle : tout doit sortir, une fois chacun.
morceaux = 0;
lignes = 0;
while hasdata(ds)
    bloc = read(ds);
    morceaux = morceaux + 1;
    lignes = lignes + height(bloc);
end
assert(lignes == 5);                    % cinq lignes de donnees
assert(morceaux == 3);                  % 2 + 2 + 1
assert(~hasdata(ds));
% Lire au-dela de la fin est une erreur : c'est HASDATA qui dit quand
% s'arreter, et rendre un morceau vide laisserait la boucle tourner.
refuseLecture = false;
try
    read(ds);
catch
    refuseLecture = true;
end
assert(refuseLecture);

% Le magasin se copie par reference : READ l'a fait avancer sans qu'on le
% reaffecte. Un objet qui se copierait par valeur ferait tourner la
% boucle sans fin.
reset(ds);
assert(hasdata(ds));
premier = read(ds);
assert(height(premier) == 2);
assert(hasdata(ds));

% READALL rend tout, PREVIEW montre sans avancer.
reset(ds);
assert(height(readall(ds)) == 5);
avant = hasdata(ds);
apercu = preview(ds);
assert(height(apercu) <= 8);
assert(hasdata(ds) == avant);           % PREVIEW n'a pas avance
assert(numpartitions(ds) == 3);

% La somme des morceaux vaut le tout : rien ne se perd au decoupage.
reset(ds);
recolte = [];
while hasdata(ds)
    bloc = read(ds);
    recolte = [recolte; bloc.a];
end
assert(isequal(sort(recolte), sort(readall(ds).a)));
delete(fichier);

%% ------------------------------------------------------ ARRAYDATASTORE
donnees = [1 2; 3 4; 5 6];
da = arrayDatastore(donnees, 'ReadSize', 2);
assert(isequal(read(da), [1 2; 3 4]));
assert(hasdata(da));
assert(isequal(read(da), [5 6]));
assert(~hasdata(da));
reset(da);
assert(isequal(readall(da), donnees));
assert(numpartitions(da) == 2);
% Le parcours peut suivre l'autre dimension.
dc = arrayDatastore([1 2 3; 4 5 6], 'IterationDimension', 2, 'ReadSize', 2);
assert(isequal(read(dc), [1 2; 4 5]));
assert(isequal(read(dc), [3; 6]));
% Et la reunion des morceaux redonne le tableau.
dr = arrayDatastore(donnees, 'ReadSize', 1);
reunion = [];
while hasdata(dr)
    reunion = [reunion; read(dr)];
end
assert(isequal(reunion, donnees));

%% ------------------------------------------------------ IMAGEDATASTORE
dossierImages = fullfile(dossier, 'matlibre_images');
if exist(dossierImages, 'dir') ~= 7
    mkdir(dossierImages);
end
imwrite(uint8(magic(4) * 15), fullfile(dossierImages, 'a.pgm'));
imwrite(uint8(magic(4) * 10), fullfile(dossierImages, 'b.pgm'));

di = imageDatastore(dossierImages);
assert(numel(di.Files) == 2);
compte = 0;
while hasdata(di)
    [image, infos] = read(di);
    assert(isequal(size(image), [4 4]));
    assert(isfield(infos, 'Filename'));
    compte = compte + 1;
end
assert(compte == 2);
reset(di);
assert(numel(readall(di)) == 2);
assert(isequal(size(preview(di)), [4 4]));
% Les fichiers d'un dossier sortent en ordre alphabetique : sans cela le
% contenu du magasin dependrait du systeme de fichiers.
assert(~isempty(strfind(di.Files{1}, 'a.pgm')));

% Les etiquettes disent si le jeu est equilibre.
de = imageDatastore(dossierImages, 'Labels', {'chat', 'chien'});
resume = countEachLabel(de);
assert(height(resume) == 2);
assert(all(resume.Count == 1));

%% ------------------------------------------------------------ DATASTORE
% Le genre se devine a l'extension, et 'Type' l'impose.
fichierCsv = fullfile(dossier, 'matlibre_devine.csv');
writelines(["a,b"; "1,2"], fichierCsv);
assert(strcmp(class(datastore(fichierCsv)), 'tabularTextDatastore'));
assert(strcmp(class(datastore(dossierImages)), 'imageDatastore'));
assert(strcmp(class(datastore(fichierCsv, 'Type', 'tabulartext')), ...
              'tabularTextDatastore'));
% Un type inconnu est refuse.
refuseType = false;
try
    datastore(fichierCsv, 'Type', 'inexistant');
catch
    refuseType = true;
end
assert(refuseType);
% Un chemin sans fichier lisible aussi.
refuseChemin = false;
try
    tabularTextDatastore(fullfile(dossier, 'matlibre_absent_xyz.csv'));
catch
    refuseChemin = true;
end
assert(refuseChemin);

delete(fichierCsv);
delete(fullfile(dossierImages, 'a.pgm'));
delete(fullfile(dossierImages, 'b.pgm'));

disp('magasins : toutes les verifications passent');
