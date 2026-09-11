% test_parquet.m — le format Parquet : écriture, lecture, aller-retour.
% Ce qui définit la lecture et l'écriture est qu'elles s'annulent : la
% table relue porte les mêmes valeurs et les mêmes classes. Et comme le
% format est public, un fichier écrit ailleurs doit se lire ici — c'est
% ce que vérifie le fichier de référence, produit par une autre
% implémentation.
disp('--- parquet ---');

dossier = tempdir;
fichier = fullfile(dossier, 'matlibre_essai.parquet');

%% ------------------------------------------------------- LE PROTOCOLE
% Les entiers de longueur variable et le codage en zigzag sont ce sur
% quoi tout le reste repose.
assert(isequal(double(matlibre_thrift_varint(0)), 0));
assert(isequal(double(matlibre_thrift_varint(1)), 1));
assert(isequal(double(matlibre_thrift_varint(127)), 127));
assert(isequal(double(matlibre_thrift_varint(128)), [128 1]));
assert(isequal(double(matlibre_thrift_varint(300)), [172 2]));
assert(matlibre_thrift_zigzag(0) == 0);
assert(matlibre_thrift_zigzag(-1) == 1);
assert(matlibre_thrift_zigzag(1) == 2);
assert(matlibre_thrift_zigzag(-2) == 3);
for n = [-1000 -7 -1 0 1 7 1000 123456]
    assert(matlibre_thrift_dezigzag(matlibre_thrift_zigzag(n)) == n);
end

% Une structure écrite se relit à l'identique, champ par champ.
octets = matlibre_thrift_structure({{1, 5, matlibre_thrift_varint(matlibre_thrift_zigzag(7))}, ...
                                    {3, 6, matlibre_thrift_varint(matlibre_thrift_zigzag(-9))}, ...
                                    {4, 8, [matlibre_thrift_varint(3), uint8('abc')]}});
relue = matlibre_thrift_lire(octets, 1);
assert(relue.c1 == 7);
assert(relue.c3 == -9);
assert(strcmp(char(relue.c4), 'abc'));
assert(~isfield(relue, 'c2'));

% Une liste aussi, et au-delà de quatorze éléments son compte passe en
% varint : c'est la frontière où le format change de forme.
elements = cell(1, 20);
for k = 1:20
    elements{k} = matlibre_thrift_varint(matlibre_thrift_zigzag(k));
end
avecListe = matlibre_thrift_structure({{1, 9, matlibre_thrift_liste(5, elements)}});
relue = matlibre_thrift_lire(avecListe, 1);
assert(numel(relue.c1) == 20);
assert(relue.c1{20} == 20);

%% ---------------------------------------------------- L'ALLER-RETOUR
T = table([1; 2; 3], ["a"; "bb"; "ccc"], [true; false; true], int8([-1; 2; -3]), ...
          'VariableNames', {'n', 'nom', 'vrai', 'petit'});
parquetwrite(fichier, T);

% Le fichier porte la marque du format à ses deux bouts.
identifiant = fopen(fichier, 'r');
brut = uint8(fread(identifiant))';
fclose(identifiant);
assert(strcmp(char(brut(1:4)), 'PAR1'));
assert(strcmp(char(brut(end-3:end)), 'PAR1'));

R = parquetread(fichier);
assert(isequal(R.Properties.VariableNames, T.Properties.VariableNames));
assert(isequal(R.n, T.n));
assert(isequal(R.nom, T.nom));
assert(isequal(R.vrai, T.vrai));
assert(isequal(R.petit, T.petit));
% Les classes reviennent telles quelles : sans le type converti, un int8
% reviendrait int32, car Parquet n'a pas de type physique plus étroit.
assert(strcmp(class(R.petit), 'int8'));
assert(strcmp(class(R.vrai), 'logical'));
assert(isstring(R.nom));

% Le renseignement se lit sans ouvrir une seule colonne.
info = parquetinfo(fichier);
assert(info.NumRows == 3);
assert(info.NumRowGroups == 1);
assert(isequal(info.VariableNames, {'n', 'nom', 'vrai', 'petit'}));
assert(isequal(info.VariableTypes, {'double', 'string', 'logical', 'int8'}));
assert(strcmp(info.CreatedBy, 'MatLibre'));

% Ne lire qu'une colonne est l'intérêt d'un format en colonnes.
choisie = parquetread(fichier, 'SelectedVariableNames', {'nom'});
assert(isequal(choisie.Properties.VariableNames, {'nom'}));
assert(height(choisie) == 3);
assert(isequal(choisie.nom, T.nom));

% Toutes les largeurs d'entiers font l'aller-retour, et les flottants
% simples aussi.
large = table(int16([-300; 300]), uint16([1; 65535]), int32([-70000; 70000]), ...
              uint32([0; 4000000000]), int64([-5e12; 5e12]), single([1.5; -2.5]), ...
              'VariableNames', {'a', 'b', 'c', 'd', 'e', 'f'});
fichierLarge = fullfile(dossier, 'matlibre_large.parquet');
parquetwrite(fichierLarge, large);
relu = parquetread(fichierLarge);
for nom = large.Properties.VariableNames
    assert(isequal(relu.(nom{1}), large.(nom{1})));
    assert(strcmp(class(relu.(nom{1})), class(large.(nom{1}))));
end
delete(fichierLarge);

% Une table vide de lignes garde ses colonnes et leurs classes.
vide = table(zeros(0, 1), strings(0, 1), 'VariableNames', {'x', 'y'});
fichierVide = fullfile(dossier, 'matlibre_vide.parquet');
parquetwrite(fichierVide, vide);
relu = parquetread(fichierVide);
assert(height(relu) == 0);
assert(isequal(relu.Properties.VariableNames, {'x', 'y'}));
delete(fichierVide);

% Le texte non ASCII survit : les octets UTF-8 sont écrits tels quels.
accents = table(["éclair"; "naïve"; ""], 'VariableNames', {'mot'});
fichierAccents = fullfile(dossier, 'matlibre_accents.parquet');
parquetwrite(fichierAccents, accents);
assert(isequal(parquetread(fichierAccents).mot, accents.mot));
delete(fichierAccents);

%% ------------------------------------------- UN FICHIER ECRIT AILLEURS
% Le format est public : un fichier produit par une autre implémentation
% doit se lire ici. Sans cette vérification, l'aller-retour ne prouverait
% que la cohérence de MatLibre avec lui-même.
reference = fullfile(fileparts(mfilename('fullpath')), '..', 'donnees', ...
                     'reference.parquet');
assert(isfile(reference));
infoRef = parquetinfo(reference);
assert(infoRef.NumRows == 4);
assert(~isempty(strfind(infoRef.CreatedBy, 'parquet-cpp')));
ref = parquetread(reference);
assert(isequal(ref.Properties.VariableNames, {'mesure', 'compte', 'nom', 'vrai'}));
assert(isequal(ref.mesure, [1.5; -2.25; 0; 1e10]));
assert(isequal(ref.compte, int32([7; -8; 9; 10])));
assert(strcmp(class(ref.compte), 'int32'));
assert(isequal(ref.nom, ["alpha"; "bêta"; ""; "delta"]));
assert(isequal(ref.vrai, [true; true; false; true]));

%% ------------------------------------------------------------ LES REFUS
% Ce qui n'est pas lu est refusé par sa raison, non par un silence.
refuseTable = false;
try
    parquetwrite(fichier, [1 2 3]);
catch err
    refuseTable = strcmp(err.identifier, 'MATLAB:parquet:TableAttendue');
end
assert(refuseTable);

refuseClasse = false;
try
    parquetwrite(fichier, table({struct('a', 1); struct('a', 2)}));
catch err
    refuseClasse = strcmp(err.identifier, 'MATLAB:parquet:TypeNonSupporte');
end
assert(refuseClasse);

refuseMarque = false;
mauvais = fullfile(dossier, 'matlibre_pas_parquet.bin');
identifiant = fopen(mauvais, 'w');
fwrite(identifiant, uint8(1:64), 'uint8');
fclose(identifiant);
try
    parquetread(mauvais);
catch err
    refuseMarque = strcmp(err.identifier, 'MATLAB:parquet:FichierInvalide');
end
assert(refuseMarque);
delete(mauvais);

refuseOption = false;
try
    parquetread(fichier, 'Inconnue', 1);
catch err
    refuseOption = strcmp(err.identifier, 'MATLAB:parquet:OptionInconnue');
end
assert(refuseOption);

%% -------------------------------------------- NIVEAUX DE DEFINITION
% Le codage hybride dit où sont les trous : une série répète une valeur,
% des groupes tassés en portent huit par octet.
assert(isequal(matlibre_parquet_niveaux(uint8([8 1]), 1, 4)', [1 1 1 1]));
assert(isequal(matlibre_parquet_niveaux(uint8([3 11]), 1, 8)', [1 1 0 1 0 0 0 0]));

delete(fichier);

disp('parquet : toutes les verifications passent');
