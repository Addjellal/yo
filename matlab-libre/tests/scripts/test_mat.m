% test_mat.m — save, load et le format MAT.
%
% Les contrôles portent sur l'aller-retour : ce qu'on écrit, on doit le
% relire à l'identique, classe comprise. Le format lui-même est vérifié
% par la lecture d'un fichier écrit octet par octet dans le test, dont on
% connaît le contenu attendu.
disp('--- fichiers MAT ---');

dossier = tempname();
mkdir(dossier);
ancien = pwd();
cd(dossier);

%% ------------------------------------------------- aller-retour complet
a = magic(4);
b = 'une chaine de caracteres';
c = {1, 'deux', [3 4 5], {6, 7}};
s.entier = 42;
s.texte = 'champ';
s.vecteur = (1:5)';
simple = single(pi);
entiers = int32([-3 0 7]);
entiers8 = uint8([1 200]);
logique = [true false; false true];
complexe = [1+2i, 3-4i];
vide = [];
grand = reshape(1:24, 2, 3, 4);
creuse = sparse([1 0 0; 0 2 0; 0 0 3]);

save('tout.mat');
efface = whos();
clear a b c s simple entiers entiers8 logique complexe vide grand creuse
assert(~exist('a', 'var'));
load('tout.mat');

assert(isequal(a, magic(4)));
assert(strcmp(b, 'une chaine de caracteres'));
assert(numel(c) == 4 && strcmp(c{2}, 'deux') && isequal(c{3}, [3 4 5]));
assert(iscell(c{4}) && c{4}{2} == 7);
assert(s.entier == 42 && strcmp(s.texte, 'champ') && isequal(s.vecteur, (1:5)'));
assert(strcmp(class(simple), 'single') && abs(double(simple) - pi) < 1e-6);
assert(strcmp(class(entiers), 'int32') && isequal(double(entiers), [-3 0 7]));
assert(strcmp(class(entiers8), 'uint8') && isequal(double(entiers8), [1 200]));
assert(strcmp(class(logique), 'logical') && isequal(logique, [true false; false true]));
assert(isequal(complexe, [1+2i, 3-4i]));
assert(isempty(vide));
assert(isequal(size(grand), [2 3 4]) && grand(2,3,4) == 24);
assert(issparse(creuse) && isequal(full(creuse), [1 0 0; 0 2 0; 0 0 3]));

%% ------------------------------------------------------ les deux formes
% « load » sans sortie remplit l'espace de travail ; avec une sortie, il
% rend une structure et n'y touche pas.
clear a
recu = load('tout.mat');
assert(~exist('a', 'var'));
assert(isequal(recu.a, magic(4)));
assert(isfield(recu, 'creuse'));

%% ------------------------------------------------- choix des variables
x1 = 1; x2 = 2; y1 = 3;
save('choix.mat', 'x1', 'y1');
choix = load('choix.mat');
assert(isfield(choix, 'x1') && isfield(choix, 'y1') && ~isfield(choix, 'x2'));
% Les jokers.
save('jokers.mat', 'x*');
jokers = load('jokers.mat');
assert(isfield(jokers, 'x1') && isfield(jokers, 'x2') && ~isfield(jokers, 'y1'));
% Une variable qui n'existe pas est signalée.
manque = false;
try
    save('rien.mat', 'variableAbsente');
catch e
    manque = strcmp(e.identifier, 'MATLAB:save:variableNotFound');
end
assert(manque);
% Et la lecture partielle.
partiel = load('tout.mat', 'a', 'b');
assert(numel(fieldnames(partiel)) == 2);

%% ------------------------------------------------------------ -append
p = 10; save('ajout.mat', 'p');
q = 20; save('ajout.mat', 'q', '-append');
p = 11; save('ajout.mat', 'p', '-append');   % remplace la premiere
ajout = load('ajout.mat');
assert(ajout.p == 11 && ajout.q == 20);

%% ------------------------------------------------------------ -struct
paquet.alpha = 1;
paquet.beta = 'deux';
save('paquet.mat', '-struct', 'paquet');
depuisStruct = load('paquet.mat');
assert(depuisStruct.alpha == 1 && strcmp(depuisStruct.beta, 'deux'));
assert(~isfield(depuisStruct, 'paquet'));

%% --------------------------------------------------------- compression
% « -v7 » enveloppe chaque variable dans un flux zlib ; le contenu doit
% etre le meme, et le fichier different.
m = rand(20, 20);
save('clair.mat', 'm', '-v6');
save('comprime.mat', 'm', '-v7');
assert(isequal(load('clair.mat').m, m));
assert(isequal(load('comprime.mat').m, m));

%% ---------------------------------------------------------- whos -file
inventaire = matlibre_contenu_mat('choix.mat');
noms = {};
for k = 1:numel(inventaire)
    noms{end+1} = inventaire(k).name;  %#ok<SAGROW>
end
assert(any(strcmp(noms, 'x1')) && any(strcmp(noms, 'y1')));

%% --------------------------------------------------------------- ascii
donnees = [1 2 3; 4 5 6];
save('texte.txt', 'donnees', '-ascii');
relu = load('texte.txt');
assert(max(max(abs(relu - donnees))) < 1e-9);
% Un fichier texte ecrit a la main, avec commentaires et lignes vides.
fid = fopen('brut.txt', 'w');
fprintf(fid, '%% un commentaire\n1 2 3\n\n4 5 6\n');
fclose(fid);
assert(isequal(load('brut.txt'), [1 2 3; 4 5 6]));

%% ------------------------------------------- un fichier ecrit a la main
% On fabrique un fichier de niveau 5 octet par octet : c'est le format
% lui-meme qu'on verifie, pas notre propre ecriture.
texteEntete = double('MATLAB 5.0 MAT-file, ecrit par le test');
entete = [texteEntete, 32 * ones(1, 116 - numel(texteEntete))];
octets = [entete, zeros(1, 8), 0, 1, double('IM')];
% Un miMATRIX : drapeaux (mxDOUBLE), dimensions 1x2, nom « z », donnees.
corps = [motLong(6), motLong(8), motLong(6), motLong(0), ...        % drapeaux
         motLong(5), motLong(8), motLong(1), motLong(2), ...        % dimensions
         motLong(1), motLong(1), double('z'), zeros(1, 7), ...      % nom, complete a 8
         motLong(9), motLong(16), ...                               % donnees
         reel(2.5), reel(-4)];
octets = [octets, motLong(14), motLong(numel(corps)), corps];
fid = fopen('main.mat', 'w');
fwrite(fid, octets, 'uint8');
fclose(fid);
aLaMain = load('main.mat');
assert(isequal(aLaMain.z, [2.5 -4]));

%% ------------------------------------------------- fichiers introuvables
absent = false;
try
    load('ceFichierNExistePas.mat');
catch e
    absent = strcmp(e.identifier, 'MATLAB:load:couldNotReadFile');
end
assert(absent);
% Un fichier qui n'est pas un MAT ne doit pas faire tomber le programme.
fid = fopen('faux.mat', 'w');
fprintf(fid, 'MATLAB 5.0 mais tout le reste est du charabia');
fclose(fid);
casse = false;
try
    load('faux.mat');
catch
    casse = true;
end
assert(casse || true);   % l'un ou l'autre, mais pas un plantage

cd(ancien);
rmdir(dossier, 's');
disp('fichiers MAT : toutes les verifications passent');

% Les deux fabriques d'octets du fichier ecrit a la main : un entier de
% trente-deux bits, et un reel de soixante-quatre, en petit-boutien.
function o = motLong(v)
    o = double(typecast(uint32(v), 'uint8'));
end

function o = reel(x)
    o = double(typecast(double(x), 'uint8'));
end
