% test_texte_es.m — chaînes, formatage et fichiers.
disp('--- texte et entrees-sorties ---');

assert(strcmp(upper('abc'), 'ABC'));
assert(strcmp(lower('ABC'), 'abc'));
assert(strcmp(strtrim('  x  '), 'x'));
assert(strcmp(strcat('a', 'b', 'c'), 'abc'));
assert(strcmp(strrep('abcabc', 'b', 'X'), 'aXcaXc'));
assert(isequal(strfind('abcabc', 'bc'), [2 5]));
assert(strcmp(strjoin({'a', 'b', 'c'}, '-'), 'a-b-c'));
morceaux = strsplit('a,b,c', ',');
assert(numel(morceaux) == 3 && strcmp(morceaux{2}, 'b'));
[jeton, reste] = strtok('un deux trois');
assert(strcmp(jeton, 'un'));
assert(strcmp(strtrim(reste), 'deux trois'));
assert(contains('bonjour', 'jour'));
assert(startsWith('bonjour', 'bon'));
assert(endsWith('bonjour', 'jour'));
assert(strlength('abcd') == 4);
assert(strcmp(blanks(3), '   '));
assert(strcmp(fliplr('abc'), 'cba'));

% Comparaisons vectorisées.
r = strcmp({'a', 'b'}, 'a');
assert(r(1) && ~r(2));
assert(strcmpi('ABC', 'abc'));
assert(strncmp('abcdef', 'abcxxx', 3));

% Expressions régulières.
assert(isequal(regexp('a1b22c', '\d+'), [2 4]));
correspondances = regexp('a1b22c', '\d+', 'match');
assert(numel(correspondances) == 2 && strcmp(correspondances{2}, '22'));
assert(strcmp(regexprep('abc', 'b', 'X'), 'aXc'));
assert(strcmp(regexprep('2024-01-02', '(\d+)-(\d+)-(\d+)', '$3/$2/$1'), '02/01/2024'));

% Formatage.
assert(strcmp(sprintf('%d', 42), '42'));
assert(strcmp(sprintf('%5.2f', pi), ' 3.14'));
assert(strcmp(sprintf('%s=%d', 'x', 3), 'x=3'));
assert(strcmp(sprintf('%e', 1000), '1.000000e+03'));
assert(strcmp(sprintf('%-5d|', 1), '1    |'));
assert(strcmp(sprintf('%03d', 7), '007'));
assert(strcmp(sprintf('%x', 255), 'ff'));
assert(strcmp(sprintf('%%'), '%'));
assert(strcmp(sprintf('%d,', [1 2 3]), '1,2,3,'));
assert(strcmp(num2str(42), '42'));
assert(strcmp(mat2str([1 2; 3 4]), '[1 2;3 4]'));
assert(str2double('2.5') == 2.5);
assert(isnan(str2double('abc')));
assert(isequal(str2num('[1 2 3]'), [1 2 3]));

% Conversions de type.
assert(double('A') == 65);
assert(strcmp(char(65), 'A'));
assert(isstring(string('x')));
assert(iscellstr({'a', 'b'}));

% Fichiers.
nom = [tempname() '.txt'];
fid = fopen(nom, 'w');
fprintf(fid, 'ligne un\nligne deux\n');
fclose(fid);
contenu = fileread(nom);
assert(~isempty(strfind(contenu, 'ligne deux')));
fid = fopen(nom, 'r');
premiere = fgetl(fid);
fclose(fid);
assert(strcmp(premiere, 'ligne un'));
delete(nom);

% Fichier délimité.
nomCsv = [tempname() '.csv'];
dlmwrite(nomCsv, [1 2; 3 4], ',');
relu = dlmread(nomCsv, ',');
assert(isequal(relu, [1 2; 3 4]));
delete(nomCsv);

%% ------------------------------------------------------------- sscanf
% Conversions, littéraux, largeurs de champ, suppression et taille imposée.
assert(isequal(sscanf('1 2 3', '%f'), [1;2;3]));
assert(sscanf('12', '%d') == 12);
assert(abs(sscanf('1.5e3', '%f') - 1500) < 1e-12);
assert(isequal(sscanf('[1 2 3]', '[%f %f %f]'), [1;2;3]));
assert(sscanf('a=5', 'a=%d') == 5);
assert(isequal(sscanf('1,2,3', '%f,'), [1;2;3]));
assert(strcmp(sscanf('abc', '%s'), 'abc'));
assert(strcmp(sscanf('ab', '%c'), 'ab'));
assert(sscanf('ff', '%x') == 255);
assert(sscanf('17', '%o') == 15);
% Le troisième argument limite la lecture, ou range en matrice, colonne
% par colonne comme partout dans MATLAB.
assert(isequal(sscanf('1 2 3 4', '%f', 2), [1;2]));
assert(isequal(sscanf('1 2 3 4', '%f', [2 2]), [1 3; 2 4]));
assert(isequal(sscanf('1234', '%2d'), [12;34]));
assert(isequal(sscanf('1 2 3 4', '%*f %f'), [2;4]));
assert(isempty(sscanf('', '%f')));
% La lecture s'arrête au premier champ qui ne correspond pas, et rend la
% position atteinte.
[valeursLues, compteLu, ~, positionLue] = sscanf('1 2 x', '%f');
assert(isequal(valeursLues, [1;2]) && compteLu == 2 && positionLue == 5);

%% ------------------------------------- char empile, comme sous MATLAB
% « char(S1,S2,...) » et « char(C) » empilent une ligne par texte,
% completee d'espaces jusqu'a la plus longue.
empile = char('un', 'deux');
assert(isequal(size(empile), [2 4]));
assert(strcmp(empile(1,:), 'un  '));
assert(strcmp(strtrim(empile(2,:)), 'deux'));
listeEmpile = cellstr(empile);
assert(numel(listeEmpile) == 2);
assert(strcmp(listeEmpile{2}, 'deux'));
% Un seul argument : la conversion ordinaire, inchangee.
assert(strcmp(char(72), 'H'));
assert(strcmp(char([72 105]), 'Hi'));
assert(isequal(size(char('abc')), [1 3]));
% Une cellule s'empile aussi.
assert(isequal(size(char({'a', 'bbb'})), [2 3]));

% newline vaut char(10).
assert(double(newline) == 10);
assert(numel(strsplit(['a' newline 'b'], newline)) == 2);

%% ------------------------------------------------------- affichage
% MatLibre montre par defaut tous les chiffres que la valeur porte : pi
% s'ecrit en entier, et non arrondi a quatre decimales.
assert(strcmp(strtrim(evalc('disp(pi)')), '3.141592653589793'));
% Un single n'en porte que sept : au-dela on ecrirait le bruit de sa
% conversion, pas la valeur. MATLAB s'arrete a sept lui aussi.
assert(strcmp(strtrim(evalc('disp(single(pi))')), '3.1415927'));
assert(strcmp(strtrim(evalc('disp(single(1/3))')), '0.3333333'));
assert(strcmp(class(float(pi)), 'single'));
assert(float(pi) == single(pi));
% « format short » rend l'affichage de MATLAB par defaut, « format »
% seul revient au reglage de depart.
format short
assert(strcmp(strtrim(evalc('disp(pi)')), '3.1416'));
assert(strcmp(strtrim(evalc('disp(single(pi))')), '3.1416'));
format long
assert(strcmp(strtrim(evalc('disp(pi)')), '3.141592653589793'));
format short
format
assert(strcmp(strtrim(evalc('disp(pi)')), '3.141592653589793'));
% Les formes exponentielles suivent la meme regle de chiffres.
format longE
assert(strcmp(strtrim(evalc('disp(single(pi))')), '3.1415927e+00'));
assert(strcmp(strtrim(evalc('disp(pi)')), '3.141592653589793e+00'));
format
% Un tableau de singles n'aligne pas plus de chiffres qu'il n'en porte.
ligneSingle = strtrim(evalc('disp(single([pi 1/3]))'));
assert(~isempty(strfind(ligneSingle, '3.1415927')));
assert(isempty(strfind(ligneSingle, '3.14159274')));

%% ------------------------------------------- readmatrix et writematrix
% Ce qu'on ecrit, on doit le relire a l'identique — c'est le seul controle
% qui vaille pour un format de fichier.
fichierCsv = [tempname() '.csv'];
writematrix(magic(4), fichierCsv);
assert(isequal(readmatrix(fichierCsv), magic(4)));
% Les nombres a virgule survivent aussi, et NaN et Inf gardent leur nom.
donnees = [1.5 -2.25; NaN Inf];
writematrix(donnees, fichierCsv);
relu = readmatrix(fichierCsv);
assert(isnan(relu(2, 1)) && isinf(relu(2, 2)));
assert(abs(relu(1, 1) - 1.5) < 1e-15 && abs(relu(1, 2) + 2.25) < 1e-15);
% Un separateur impose.
writematrix([1 2; 3 4], fichierCsv, 'Delimiter', 'semi');
texteBrut = fileread(fichierCsv);
assert(~isempty(strfind(texteBrut, '1;2')));
assert(isequal(readmatrix(fichierCsv), [1 2; 3 4]));
% Une ligne d'en-tete est reconnue toute seule ; « Range » commence ou
% l'on veut.
fid = fopen(fichierCsv, 'w');
fprintf(fid, 'temps;mesure\n0;1.5\n1;2.5\n2;3.5\n');
fclose(fid);
assert(isequal(readmatrix(fichierCsv), [0 1.5; 1 2.5; 2 3.5]));
assert(isequal(readmatrix(fichierCsv, 'Range', 'B2'), [2.5; 3.5]));
avecEnTete = readmatrix(fichierCsv, 'NumHeaderLines', 0, 'Delimiter', ';');
assert(isequal(size(avecEnTete), [4 2]));
assert(all(isnan(avecEnTete(1, :))));      % la ligne de titres n'a pas de nombre
assert(isequal(avecEnTete(2:end, :), [0 1.5; 1 2.5; 2 3.5]));
% Une tabulation, devinee elle aussi.
fid = fopen(fichierCsv, 'w');
fprintf(fid, '1\t2\t3\n4\t5\t6\n');
fclose(fid);
assert(isequal(readmatrix(fichierCsv), [1 2 3; 4 5 6]));
delete(fichierCsv);

%% -------------------------------------------------- display et inputname
% « display(x) » ecrit « x = ... » quand on lui passe une variable, et le
% texte seul quand on lui passe une expression. C'est « inputname » qui
% fait la difference.
maVariable = 3;
sortie = evalc('display(maVariable)');
assert(~isempty(strfind(sortie, 'maVariable =')));
sortie = evalc('display(''un message'')');
assert(~isempty(strfind(sortie, 'un message')));
assert(isempty(strfind(sortie, 'ans =')));
assert(isempty(strfind(sortie, '''')));

%% ----------------------------------------------------------------- split
% split rend du texte de la meme espece que celui qu'on lui donne : des
% cellules pour un caractere, des chaines pour une chaine.
morceaux = split('a,b,c', ',');
assert(iscell(morceaux) && numel(morceaux) == 3 && strcmp(morceaux{2}, 'b'));
assert(isstring(split(string('a,b'), ',')));
grille = split(string({'a-b'; 'c-d'}), '-');
assert(isequal(size(grille), [2 2]));
assert(strcmp(char(grille(2, 1)), 'c'));
[bouts, seps] = split('a1b2c', {'1', '2'});
assert(numel(bouts) == 3 && strcmp(bouts{3}, 'c'));
assert(numel(seps) == 2 && strcmp(seps{1}, '1'));
% Sans separateur, ce sont les espaces qui coupent.
assert(numel(split('a b c')) == 3);
assert(numel(splitlines(sprintf('un\ndeux\ntrois'))) == 3);
% Les trois fins de ligne se valent.
assert(numel(splitlines(sprintf('un\r\ndeux'))) == 2);

%% ------------------------------------------------------------------ JSON
donnees = jsondecode('{"nom":"a","valeurs":[1,2,3]}');
assert(strcmp(donnees.nom, 'a'));
assert(isequal(donnees.valeurs(:)', [1 2 3]));
assert(isequal(jsondecode('[[1,2],[3,4]]'), [1 2; 3 4]));
assert(iscell(jsondecode('[1,"a"]')));
assert(jsondecode('true'));
assert(isempty(jsondecode('null')));
assert(strcmp(jsonencode(struct('a', 1, 'b', 'deux')), '{"a":1,"b":"deux"}'));
assert(strcmp(jsonencode([1 2; 3 4]), '[[1,2],[3,4]]'));
assert(strcmp(jsonencode({1, 'a', true}), '[1,"a",true]'));
% Le tour complet ne perd rien.
tourJson = jsondecode(jsonencode(struct('x', [1 2 3], 't', 'oui')));
assert(isequal(tourJson.x(:)', [1 2 3]) && strcmp(tourJson.t, 'oui'));
% Un texte qui n'est pas du JSON est refuse, en le disant.
jsonRefuse = false;
try
    jsondecode('{"a":}');
catch
    jsonRefuse = true;
end
assert(jsonRefuse);

%% ------------------------------------------ lecture et ecriture de cases
bac = tempdir();
fCases = fullfile(bac, 'matlibre_cases.csv');
writecell({'nom', 'valeur'; 'a', 1; 'b', 2.5}, fCases);
cases = readcell(fCases);
assert(isequal(size(cases), [3 2]));
assert(strcmp(cases{2, 1}, 'a') && cases{3, 2} == 2.5);
[colonneA, colonneB] = readvars(fCases);
assert(numel(colonneA) == 2 && colonneB(2) == 2.5);

% importdata reconnait le fichier a son extension et a sa forme.
apportees = importdata(fCases);
assert(isequal(apportees.data, [1; 2.5]));
assert(strcmp(apportees.colheaders{2}, 'valeur'));
fNombres = fullfile(bac, 'matlibre_nombres.csv');
writematrix([1 2; 3 4], fNombres);
assert(isequal(importdata(fNombres), [1 2; 3 4]));
fMat = fullfile(bac, 'matlibre_apport.mat');
valeurRangee = 7;
save(fMat, 'valeurRangee');
assert(importdata(fMat).valeurRangee == 7);
delete(fCases); delete(fNombres); delete(fMat);

%% --------------------------------------------------------------- matfile
fLent = fullfile(bac, 'matlibre_matfile.mat');
if isfile(fLent)
    delete(fLent);
end
depot = matfile(fLent, 'Writable', true);
depot.x = magic(4);
depot.y = 'coucou';
assert(isequal(depot.x, magic(4)));
assert(isequal(depot.x(1, :), [16 2 3 13]));
% Une ecriture partielle ne detruit ni le reste de la matrice ni les
% autres variables du fichier.
depot.x(1, 1) = 99;
assert(depot.x(1, 1) == 99 && depot.x(2, 2) == 11);
assert(strcmp(depot.y, 'coucou'));
assert(numel(who(depot)) == 2);
% Sans « Writable », le fichier est en lecture seule.
lecture = matfile(fLent);
assert(~lecture.Properties.Writable);
matfileRefuse = false;
try
    lecture.z = 1;
catch
    matfileRefuse = true;
end
assert(matfileRefuse);
delete(fLent);

%% ---------------------------------------------------------------- fscanf
fLu = fullfile(bac, 'matlibre_fscanf.txt');
fid = fopen(fLu, 'w');
fprintf(fid, '1 2 3 4 5 6');
fclose(fid);
fid = fopen(fLu, 'r');
assert(isequal(fscanf(fid, '%d')', [1 2 3 4 5 6]));
fclose(fid);
% La lecture s'arrete ou on le demande, et reprend la ou elle s'etait
% arretee : c'est ce qui distingue fscanf de sscanf.
fid = fopen(fLu, 'r');
premiers = fscanf(fid, '%d', 3);
suivants = fscanf(fid, '%d');
fclose(fid);
assert(isequal(premiers(:)', [1 2 3]));
assert(isequal(suivants(:)', [4 5 6]));
fid = fopen(fLu, 'r');
grilleLue = fscanf(fid, '%d', [2 3]);
fclose(fid);
assert(isequal(grilleLue, [1 3 5; 2 4 6]));
delete(fLu);

%% -------------------------------------------------------- chemins et dir
% genpath descend dans les sous-dossiers et laisse de cote ceux que
% MATLAB reserve.
chemins = genpath(fullfile(matlabroot(), 'aide'));
assert(~isempty(strfind(chemins, 'aide')));
assert(chemins(end) == pathsep());
inventaire = what(fullfile(matlabroot(), 'matlab'));
assert(numel(inventaire.m) > 100);
% fileattrib decrit un fichier existant et refuse ce qui n'existe pas.
fAttribut = fullfile(bac, 'matlibre_attribut.txt');
fid = fopen(fAttribut, 'w');
fclose(fid);
[trouve, ~, attributs] = fileattrib(fAttribut);
assert(trouve && attributs.UserRead == 1 && attributs.directory == 0);
delete(fAttribut);
assert(~fileattrib(fullfile(bac, 'matlibre_absent_xyz.txt')));

%% ------------------------------------------------------------- calendrier
assert(eomday(2024, 2) == 29);
assert(eomday(2023, 2) == 28);
assert(eomday(2024, 4) == 30);
fevrier = calendar(2024, 2);
assert(isequal(size(fevrier), [6 7]));
assert(fevrier(1, 5) == 1);          % le 1er fevrier 2024 est un jeudi
assert(max(fevrier(:)) == 29);
assert(weeknum(datenum(2024, 1, 8)) == 2);
assert(yyyymmdd(datetime(2024, 2, 3)) == 20240203);
assert(months('31-mar-2024', '30-apr-2024') == 1);
assert(months(datenum(2024, 1, 15), datenum(2024, 3, 14)) == 1);
% datestr ecrit « 31-Mar-2024 » : datenum doit savoir le relire.
assert(datenum('31-Mar-2024') == datenum(2024, 3, 31));
assert(strcmp(datestr(datenum('31-Mar-2024 13:45:00')), '31-Mar-2024 13:45:00'));

disp('texte et entrees-sorties : toutes les verifications passent');
