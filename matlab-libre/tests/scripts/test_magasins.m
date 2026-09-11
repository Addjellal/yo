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

%% --------------------------------------------------- COMBINE, TRANSFORM
% Apparier deux magasins : chaque lecture prend un morceau de chacun, et
% les deux avancent du meme pas. C'est la seule chose que COMBINE
% garantisse et que deux lectures separees ne garantiraient pas.
a = arrayDatastore([1; 2; 3]);
b = arrayDatastore([10; 20; 30]);
c = combine(a, b);
assert(numel(c.UnderlyingDatastores) == 2);
assert(numpartitions(c) == 3);
paire = read(c);
assert(iscell(paire) && numel(paire) == 2);
assert(paire{1} == 1 && paire{2} == 10);
paire = read(c);
assert(paire{1} == 2 && paire{2} == 20);

% La boucle se termine, ne saute rien, ne compte rien deux fois.
reset(c);
gauche = [];
droite = [];
while hasdata(c)
    p = read(c);
    gauche(end + 1, 1) = p{1};
    droite(end + 1, 1) = p{2};
end
assert(isequal(gauche, [1; 2; 3]));
assert(isequal(droite, [10; 20; 30]));

% L'apercu ne consomme rien : apres lui, la lecture repart du debut.
reset(c);
apercu = preview(c);
assert(isequal(apercu{1}, [1; 2; 3]));
assert(isequal(apercu{2}, [10; 20; 30]));
p = read(c);
assert(p{1} == 1);
reset(c);
entier = readall(c);
assert(isequal(entier{1}, [1; 2; 3]));
assert(isequal(entier{2}, [10; 20; 30]));

% Le plus court decide : appariez 2 et 3, il y a 2 paires, pas 3. Une
% quatrieme lecture n'invente pas de paire boiteuse, elle refuse.
court = combine(arrayDatastore([1; 2]), arrayDatastore([10; 20; 30]));
assert(numpartitions(court) == 2);
n = 0;
while hasdata(court)
    read(court);
    n = n + 1;
end
assert(n == 2);
refuseFin = false;
try
    read(court);
catch
    refuseFin = true;
end
assert(refuseFin);

% Apparier un seul magasin n'a pas de sens.
refuseSeul = false;
try
    combine(arrayDatastore([1; 2]));
catch
    refuseSeul = true;
end
assert(refuseSeul);

% TRANSFORM : la fonction s'applique a chaque morceau lu.
d = transform(arrayDatastore([1; 2; 3]), @(x) x * 10);
assert(numel(d.UnderlyingDatastores) == 1);
assert(numel(d.Transforms) == 1);
assert(numpartitions(d) == 3);
assert(read(d) == 10);
assert(read(d) == 20);
reset(d);
vus = [];
while hasdata(d)
    vus(end + 1, 1) = read(d);
end
assert(isequal(vus, [10; 20; 30]));
assert(isequal(readall(d), [10; 20; 30]));
assert(isequal(preview(d), [10; 20; 30]));

% Morceau par morceau, et non sur le jeu entier : le dernier morceau est
% plus court que les autres, et la fonction le voit tel quel.
g = transform(arrayDatastore([1; 2; 3; 4; 5], 'ReadSize', 2), @(x) numel(x));
assert(read(g) == 2);
assert(read(g) == 2);
assert(read(g) == 1);

% Paresseuse : decrire la transformation n'evalue rien. Une fonction qui
% echoue ne se manifeste donc qu'a la lecture, pas a la construction.
f = transform(arrayDatastore([1; 2]), @(x) error('MATLAB:essai:tard', 'trop tard'));
tardif = false;
try
    read(f);
catch err
    tardif = strcmp(err.identifier, 'MATLAB:essai:tard');
end
assert(tardif);

% Sur un magasin de fichier, c'est aussi morceau par morceau.
fichierTr = fullfile(dossier, 'matlibre_transforme.csv');
writelines(["a,b"; "1,2"; "3,4"; "5,6"; "7,8"; "9,10"], fichierTr);
tt = transform(tabularTextDatastore(fichierTr, 'ReadSize', 2), @(t) height(t));
assert(read(tt) == 2);
assert(read(tt) == 2);
assert(read(tt) == 1);
delete(fichierTr);

% Les deux se composent : on apparie un magasin transforme et un autre.
h = combine(transform(arrayDatastore([1; 2]), @(x) x * 100), ...
            arrayDatastore([7; 8]));
p = read(h);
assert(p{1} == 100 && p{2} == 7);

% Transformer par autre chose qu'une fonction est refuse.
refuseF = false;
try
    transform(arrayDatastore([1; 2]), 'pasUneFonction');
catch
    refuseF = true;
end
assert(refuseF);

delete(fichierCsv);
delete(fullfile(dossierImages, 'a.pgm'));
delete(fullfile(dossierImages, 'b.pgm'));

disp('magasins : toutes les verifications passent');
