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

disp('texte et entrees-sorties : toutes les verifications passent');
