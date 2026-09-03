% test_types.m — types de données : duration, calendarDuration, datetime,
% categorical, table, timetable, containers.Map et tableaux creux.
% Les valeurs de référence viennent de la documentation MathWorks ou d'un
% calcul indépendant (calendrier grégorien proleptique).
disp('--- types ---');

%% ---------------------------------------------------------------- duration
d = hours(2) + minutes(30);
assert(strcmp(class(d), 'duration'));
assert(seconds(d) == 9000);
assert(abs(hours(d) - 2.5) < 1e-12);
assert(minutes(d) == 150);
assert(strcmp(strtrim(char(d)), '2.5 hr'));      % format hérité de hours

e = duration(1, 15, 30);
assert(seconds(e) == 4530);
assert(strcmp(char(e), '01:15:30'));
assert(d > e);
assert(~(d < e));
assert(d ~= e);

% Millisecondes et formats d'horloge.
f = duration(0, 0, 1.5);
f.Format = 'hh:mm:ss.SSS';
assert(strcmp(char(f), '00:00:01.500'));
assert(milliseconds(f) == 1500);

% Tableau de durées : indexation, end, tri, somme.
v = seconds([60 120 180]);
assert(numel(v) == 3);
assert(seconds(v(2)) == 120);
assert(seconds(v(end)) == 180);
assert(seconds(sum(v)) == 360);
assert(isequal(seconds(sort(seconds([3 1 2]))), [1 2 3]));
assert(seconds(max(v)) == 180);
assert(seconds(abs(seconds(-5))) == 5);

% Arithmétique mixte.
assert(seconds(days(1)) == 86400);
assert(seconds(years(1)) == 31556952);           % 365,2425 jours
assert(hours(days(1)) == 24);
assert(seconds(seconds(10) * 3) == 30);
assert(seconds(10) / seconds(5) == 2);

%% -------------------------------------------------------- calendarDuration
cd1 = calmonths(3) + caldays(2);
assert(strcmp(class(cd1), 'calendarDuration'));
assert(calmonths(cd1) == 3);
assert(caldays(cd1) == 2);
assert(strcmp(strtrim(char(cd1)), '3mo 2d'));

cd2 = calyears(1) + calmonths(2) + caldays(3) + hours(4);
assert(calmonths(cd2) == 14);
assert(calyears(cd2) == 1);
assert(seconds(time(cd2)) == 14400);
assert(strcmp(strtrim(char(cd2)), '1y 2mo 3d 04:00:00'));
assert(calmonths(calmonths(3) * 2) == 6);
assert(calweeks(caldays(14)) == 2);

%% ---------------------------------------------------------------- datetime
t = datetime(2024, 2, 29, 13, 30, 0);
assert(strcmp(class(t), 'datetime'));
assert(year(t) == 2024 && month(t) == 2 && day(t) == 29);
assert(hour(t) == 13 && minute(t) == 30 && second(t) == 0);
assert(strcmp(char(t), '29-Feb-2024 13:30:00'));
assert(quarter(t) == 1);
assert(week(t) == 9);                            % semaine ISO 8601
assert(weekday(t) == 5);                         % jeudi
assert(~isweekend(t));
assert(strcmp(day(t, 'name'), 'Thursday'));

% Différence de dates : duration ; somme avec une durée de calendrier.
t2 = datetime(2024, 3, 1);
assert(seconds(t2 - t) == 37800);                % 10 h 30 min
assert(strcmp(char(t + caldays(1)), '01-Mar-2024 13:30:00'));
assert(strcmp(char(datetime(2024, 1, 31) + calmonths(1)), '29-Feb-2024'));

% Comparaisons, tri, extremums.
liste = [datetime(2024,1,3), datetime(2024,1,1), datetime(2024,1,2)];
assert(numel(liste) == 3);
trie = sort(liste);
assert(day(trie(1)) == 1 && day(trie(3)) == 3);
assert(day(max(liste)) == 3);
assert(day(min(liste)) == 1);

% Conversions documentées.
assert(datenum(datetime(2024, 1, 1)) == datenum(2024, 1, 1));
assert(posixtime(datetime(1970, 1, 1)) == 0);
assert(exceltime(datetime(1900, 1, 1)) == 2);
assert(abs(juliandate(datetime(2000, 1, 1, 12, 0, 0)) - 2451545) < 1e-6);

% Lecture de texte et format d'entrée.
assert(year(datetime('2024-05-17')) == 2024);
u = datetime('17/05/2024', 'InputFormat', 'dd/MM/uuuu');
assert(month(u) == 5 && day(u) == 17);

% dateshift et between.
assert(strcmp(char(dateshift(t, 'start', 'month')), '01-Feb-2024 00:00:00'));
assert(strcmp(char(dateshift(t, 'start', 'year')),  '01-Jan-2024 00:00:00'));
ecart = between(datetime(2024,1,31), datetime(2024,3,1));
assert(calmonths(ecart) == 1 && caldays(ecart) == 1);

% Valeur manquante.
assert(isnat(NaT));
assert(~isnat(t));
assert(isdatetime(t) && ~isdatetime(1));

%% ------------------------------------------------------------- categorical
c = categorical({'petit', 'grand', 'petit'});
assert(iscategorical(c));
assert(isequal(categories(c), {'grand'; 'petit'}));
assert(isequal(countcats(c), [1 2]));
assert(isequal(double(c), [2 1 2]));
assert(isequal(cellstr(c), {'petit', 'grand', 'petit'}));
assert(iscategory(c, 'grand'));
assert(~iscategory(c, 'moyen'));
assert(sum(c == 'petit') == 2);

% Catégories ordonnées : les comparaisons deviennent licites.
o = categorical({'bas', 'haut', 'moyen'}, {'bas', 'moyen', 'haut'}, {}, 'Ordinal', true);
assert(isordinal(o));
assert(o(1) < o(2));
assert(o(3) < o(2));
assert(isequal(cellstr(sort(o)), {'bas', 'moyen', 'haut'}));

% Manipulation de l'ensemble des catégories.
c2 = addcats(c, {'moyen'});
assert(numel(categories(c2)) == 3);
c3 = removecats(c2, {'moyen'});
assert(numel(categories(c3)) == 2);
c4 = renamecats(c, {'grand', 'petit'}, {'G', 'P'});
assert(isequal(categories(c4), {'G'; 'P'}));
c5 = mergecats(c, {'petit', 'grand'}, 'tous');
assert(numel(categories(c5)) == 1);
assert(countcats(c5) == 3);

% Valeur hors de l'ensemble : indéfinie.
c6 = categorical({'a', 'z'}, {'a'});
assert(isequal(isundefined(c6), [false true]));

%% -------------------------------------------------------------------- table
t1 = table([1; 2; 3], {'a'; 'b'; 'c'}, 'VariableNames', {'n', 'lettre'});
assert(istable(t1));
assert(height(t1) == 3 && width(t1) == 2);
assert(isequal(size(t1), [3 2]));
assert(isequal(t1.n, [1; 2; 3]));
assert(isequal(t1.Properties.VariableNames, {'n', 'lettre'}));

% Sous-table et extraction par accolades.
sous = t1(2:3, :);
assert(height(sous) == 2);
assert(isequal(sous.n, [2; 3]));
assert(t1{1, 1} == 1);
assert(isequal(t1{:, 'n'}, [1; 2; 3]));

% Ajout, suppression et renommage de variables.
t1.carre = t1.n .^ 2;
assert(isequal(t1.carre, [1; 4; 9]));
t2 = removevars(t1, 'carre');
assert(width(t2) == 2);
t3 = renamevars(t2, 'n', 'nombre');
assert(isequal(t3.Properties.VariableNames, {'nombre', 'lettre'}));
t4 = addvars(t2, [10; 20; 30], 'NewVariableNames', {'poids'});
assert(isequal(t4.poids, [10; 20; 30]));

% Tri, tête et queue.
t5 = sortrows(t1, 'n', 'descend');
assert(isequal(t5.n, [3; 2; 1]));
assert(height(head(t1, 2)) == 2);
assert(isequal(tail(t1, 1).n, 3));

% Conversions.
m = array2table([1 2; 3 4]);
assert(isequal(m.Properties.VariableNames, {'A1', 'A2'}));
assert(isequal(table2array(m), [1 2; 3 4]));
cellules = cell2table({1, 'a'; 2, 'b'}, 'VariableNames', {'n', 's'});
assert(isequal(cellules.n, [1; 2]));
assert(isequal(table2cell(cellules), {1, 'a'; 2, 'b'}));
clear s
s(1).a = 1; s(1).b = 'x'; s(2).a = 2; s(2).b = 'y';
ts = struct2table(s);
assert(isequal(ts.Properties.VariableNames, {'a', 'b'}));
assert(isequal(ts.a, [1; 2]));
assert(isequal(ts.b, {'x'; 'y'}));

% Concaténation verticale.
t6 = [t2; t2];
assert(height(t6) == 6);

% Calculs groupés et jointures.
g = table([1; 2; 3], {'x'; 'y'; 'x'}, 'VariableNames', {'v', 'g'});
r = groupsummary(g, 'g', 'sum', 'v');
assert(height(r) == 2);
assert(isequal(r.GroupCount, [2; 1]));
assert(isequal(r.sum_v, [4; 2]));

ja = table([1; 2], {'a'; 'b'}, 'VariableNames', {'k', 'n'});
jb = table([2; 1], [20; 10], 'VariableNames', {'k', 'm'});
jj = innerjoin(ja, jb);
assert(height(jj) == 2);
assert(isequal(jj.m, [10; 20]));

% varfun sur des colonnes numériques.
vf = varfun(@sum, t2(:, 'n'));
assert(vf.sum_n == 6);

% Lecture et écriture d'un fichier délimité.
chemin = [tempdir 'matlibre_test_table.csv'];
writetable(t2, chemin);
relu = readtable(chemin);
assert(isequal(relu.Properties.VariableNames, {'n', 'lettre'}));
assert(isequal(relu.n, [1; 2; 3]));
delete(chemin);

%% --------------------------------------------------------------- timetable
temps = datetime(2024, 1, 1) + caldays(0:2)';
tt = timetable(temps, [10; 20; 30], 'VariableNames', {'mesure'});
assert(istimetable(tt));
assert(height(tt) == 3 && width(tt) == 1);
assert(isequal(tt.mesure, [10; 20; 30]));
assert(isregular(tt));
assert(numel(tt.Properties.RowTimes) == 3);

tt2 = tt(2:3, :);
assert(height(tt2) == 2);
assert(isequal(tt2.mesure, [20; 30]));

% Aller-retour avec table.
plate = timetable2table(tt);
assert(istable(plate));
assert(width(plate) == 2);
retour = table2timetable(plate);
assert(istimetable(retour));
assert(isequal(retour.mesure, [10; 20; 30]));

% Ré-échantillonnage linéaire sur un sous-ensemble d'instants.
re = retime(tt, datetime(2024, 1, 1) + caldays([0; 2]), 'linear');
assert(isequal(re.mesure, [10; 30]));

%% ------------------------------------------------------------ containers.Map
carte = containers.Map({'un', 'deux'}, {1, 2});
assert(carte.Count == 2);
assert(carte('un') == 1);
carte('trois') = 3;
assert(carte.Count == 3);
assert(isKey(carte, 'trois'));
copie = carte;                       % sémantique de poignée
copie('quatre') = 4;
assert(carte.Count == 4);
remove(carte, 'quatre');
assert(carte.Count == 3);

%% ------------------------------------------------------------------- creux
A = sparse([1 3], [2 3], [5 7], 3, 3);
assert(issparse(A));
assert(nnz(A) == 2);
assert(A(1, 2) == 5);
assert(isequal(full(A), [0 5 0; 0 0 0; 0 0 7]));
assert(~issparse(full(A)));
B = speye(3);
assert(nnz(B) == 3);
assert(isequal(full(B * A), full(A)));

%% ------------------------------------------------- structures : champ ajouté
clear q
q(1).a = 1;
q(1).b = 2;                          % ajout d'un champ par indexation
assert(isequal(fieldnames(q), {'a'; 'b'}));
clear w
w(1).a = 1; w(2).a = 2; w(2).b = 'y';
assert(isequal(fieldnames(w), {'a'; 'b'}));
assert(isempty(w(1).b));

%% ------------------------------------------------------------ matlab.lang
assert(strcmp(matlab.lang.makeValidName('mon nom'), 'mon_nom'));
assert(strcmp(matlab.lang.makeValidName('2eme'), 'x2eme'));
assert(isequal(matlab.lang.makeUniqueStrings({'a', 'a'}), {'a', 'a_1'}));
assert(isvarname('abc'));
assert(~isvarname('2a'));

%% ------------------------------------------- remise en forme des tables
% stack empile plusieurs variables en une, avec une colonne indicatrice.
tableLarge = table([1; 2], [10; 20], [100; 200], 'VariableNames', {'a', 'b', 'c'});
[tableHaute, indicesSources] = stack(tableLarge, {'b', 'c'});
assert(height(tableHaute) == 4 && width(tableHaute) == 3);
assert(isequal(tableHaute.Properties.VariableNames, {'a', 'Indicator', 'Value'}));
assert(isequal(tableHaute.Value', [10 100 20 200]));
assert(isequal(indicesSources', [1 1 2 2]));
assert(isequal(tableHaute.a', [1 1 2 2]));
% Les noms sont réglables, et unstack refait la table de départ.
tableNommee = stack(tableLarge, {'b', 'c'}, ...
                    'NewDataVariableName', 'valeur', 'IndexVariableName', 'quoi');
tableRefaite = unstack(tableNommee, 'valeur', 'quoi');
assert(height(tableRefaite) == 2);
assert(isequal(tableRefaite.Properties.VariableNames, {'a', 'b', 'c'}));
assert(isequal(tableRefaite.b', [10 20]) && isequal(tableRefaite.c', [100 200]));
% unstack seul, sur une table déjà haute.
tableEmpilee = table([1; 1; 2; 2], {'b'; 'c'; 'b'; 'c'}, [10; 100; 20; 200], ...
                     'VariableNames', {'g', 'quoi', 'v'});
tableEtalee = unstack(tableEmpilee, 'v', 'quoi');
assert(height(tableEtalee) == 2);
assert(isequal(tableEtalee.b', [10 20]));
% Deux valeurs dans la même case : il faut une fonction d'agrégation.
tableDouble = table([1; 1], {'b'; 'b'}, [10; 20], 'VariableNames', {'g', 'quoi', 'v'});
erreurAttrapee = false;
try
    unstack(tableDouble, 'v', 'quoi');
catch
    erreurAttrapee = true;
end
assert(erreurAttrapee);
assert(unstack(tableDouble, 'v', 'quoi', 'AggregationFunction', @sum).b == 30);
% rows2vars transpose.
tableTransposee = rows2vars(table([1; 2], [3; 4], 'VariableNames', {'a', 'b'}));
assert(isequal(tableTransposee.Properties.VariableNames, ...
               {'OriginalVariableNames', 'Var1', 'Var2'}));
assert(isequal(tableTransposee.Var1', [1 3]));
% mergevars réunit, splitvars sépare.
tableFusionnee = mergevars(tableLarge, {'a', 'b'});
assert(isequal(size(tableFusionnee.a), [2 2]));
assert(isequal(tableFusionnee.Properties.VariableNames, {'a', 'c'}));
tableSeparee = splitvars(tableFusionnee);
assert(isequal(tableSeparee.Properties.VariableNames, {'a_1', 'a_2', 'c'}));
assert(isequal(splitvars(table([1 2; 3 4], 'VariableNames', {'ab'})).Properties.VariableNames, ...
               {'ab_1', 'ab_2'}));

%% ---------------------------------------------- sélecteurs d'indexation
% timerange choisit des lignes par période, avec les quatre bornes.
tableTemporelle = timetable(seconds([1; 2; 3; 4]), (10:10:40)');
assert(isequal(tableTemporelle(timerange(seconds(2), seconds(4)), :).Var1', [20 30]));
assert(isequal(tableTemporelle(timerange(seconds(2), seconds(4), 'closed'), :).Var1', [20 30 40]));
assert(isequal(tableTemporelle(timerange(seconds(2), seconds(4), 'open'), :).Var1', 30));
assert(isequal(tableTemporelle(timerange(seconds(2), seconds(4), 'openleft'), :).Var1', [30 40]));
% withtol retrouve un instant à une tolérance près.
assert(isequal(tableTemporelle(withtol(seconds(2.05), seconds(0.1)), :).Var1', 20));
assert(isequal(tableTemporelle(withtol(seconds([1.02; 3.05]), seconds(0.1)), :).Var1', [10 30]));
assert(height(tableTemporelle(withtol(seconds(2.5), seconds(0.1)), :)) == 0);
% vartype choisit des variables par type.
tableMelangee = table([1; 2], {'a'; 'b'}, true(2, 1), ...
                      'VariableNames', {'n', 'lettre', 'vrai'});
assert(isequal(tableMelangee(:, vartype('numeric')).Properties.VariableNames, {'n'}));
assert(isequal(tableMelangee(:, vartype('cellstr')).Properties.VariableNames, {'lettre'}));
assert(isequal(tableMelangee(:, vartype('logical')).Properties.VariableNames, {'vrai'}));
assert(width(timetable(seconds([1; 2]), [1; 2], {'a'; 'b'})(:, vartype('numeric'))) == 1);

%% --------------------------------------------------- fuseaux horaires
% Décalage d'hiver et d'été, sur les deux hémisphères.
assert(hours(tzoffset(datetime(2020, 1, 15, 'TimeZone', 'Europe/Paris'))) == 1);
assert(hours(tzoffset(datetime(2020, 7, 15, 'TimeZone', 'Europe/Paris'))) == 2);
assert(~isdst(datetime(2020, 1, 15, 'TimeZone', 'Europe/Paris')));
assert(isdst(datetime(2020, 7, 15, 'TimeZone', 'Europe/Paris')));
assert(hours(tzoffset(datetime(2020, 1, 15, 'TimeZone', 'America/New_York'))) == -5);
assert(hours(tzoffset(datetime(2020, 7, 15, 'TimeZone', 'America/New_York'))) == -4);
assert(hours(tzoffset(datetime(2020, 1, 15, 'TimeZone', 'Australia/Sydney'))) == 11);
assert(hours(tzoffset(datetime(2020, 7, 15, 'TimeZone', 'Australia/Sydney'))) == 10);
assert(hours(tzoffset(datetime(2020, 1, 1, 'TimeZone', 'Asia/Kolkata'))) == 5.5);
% Les bascules de 2020, à la minute : 8 mars aux États-Unis, 29 mars en
% Europe. L'heure qui se répète à l'automne compte pour l'heure d'été,
% comme dans MATLAB.
assert(~isdst(datetime(2020, 3, 8, 1, 59, 0, 'TimeZone', 'America/New_York')));
assert(isdst(datetime(2020, 3, 8, 2, 0, 0, 'TimeZone', 'America/New_York')));
assert(isdst(datetime(2020, 11, 1, 1, 59, 0, 'TimeZone', 'America/New_York')));
assert(~isdst(datetime(2020, 11, 1, 2, 0, 0, 'TimeZone', 'America/New_York')));
assert(~isdst(datetime(2020, 3, 29, 1, 59, 0, 'TimeZone', 'Europe/Paris')));
assert(isdst(datetime(2020, 3, 29, 2, 0, 0, 'TimeZone', 'Europe/Paris')));
assert(isdst(datetime(2020, 10, 25, 2, 59, 0, 'TimeZone', 'Europe/Paris')));
assert(~isdst(datetime(2020, 10, 25, 3, 0, 0, 'TimeZone', 'Europe/Paris')));
% Changer de fuseau décrit le même instant dans une autre heure locale.
dateParis = datetime(2020, 1, 15, 12, 0, 0, 'TimeZone', 'Europe/Paris');
dateUTC = dateParis;
dateUTC.TimeZone = 'UTC';
assert(hour(dateUTC) == 11 && minute(dateUTC) == 0 && second(dateUTC) == 0);
dateNewYork = dateParis;
dateNewYork.TimeZone = 'America/New_York';
assert(hour(dateNewYork) == 6 && minute(dateNewYork) == 0);
dateEte = datetime(2020, 7, 15, 12, 0, 0, 'TimeZone', 'Europe/Paris');
dateTokyo = dateEte;
dateTokyo.TimeZone = 'Asia/Tokyo';
assert(hour(dateTokyo) == 19 && minute(dateTokyo) == 0 && second(dateTokyo) == 0);
% Un décalage fixe est accepté, avec ses minutes.
dateFixe = datetime(2020, 1, 1, 12, 0, 0, 'TimeZone', '+05:30');
assert(hours(tzoffset(dateFixe)) == 5.5);
dateFixe.TimeZone = 'UTC';
assert(hour(dateFixe) == 6 && minute(dateFixe) == 30);
% La table des fuseaux se consulte, et un nom inconnu est refusé.
assert(height(timezones('Europe')) >= 20);
assert(isequal(timezones.Properties.VariableNames, {'Name', 'UTCOffset', 'DSTRule'}));
erreurFuseau = false;
try
    datetime(2020, 1, 1, 'TimeZone', 'Mars/Olympus');
catch
    erreurFuseau = true;
end
assert(erreurFuseau);

%% ------------------------------------------------------ valeurs manquantes
% ismissing reconnait le manquant propre a chaque type : NaN pour un
% nombre, la chaine vide pour du texte.
assert(isequal(ismissing([1 NaN 3]), [false true false]));
assert(isequal(ismissing([1 2 -99], -99), [false false true]));
assert(isequal(ismissing({'a', '', 'c'}), [false true false]));
assert(isequal(ismissing(string({'a', '', 'c'})), [false true false]));
assert(isequal(ismissing({'a', 'x', 'c'}, {'x'}), [false true false]));

% rmmissing retire les valeurs d'un vecteur, les lignes d'une matrice.
assert(isequal(rmmissing([1 NaN 3]), [1 3]));
assert(isequal(rmmissing([1 NaN; 2 3]), [2 3]));
assert(isequal(rmmissing([1 NaN; 2 3], 2), [1; 2]));
[sansNaN, marque] = rmmissing([1 NaN 3]);
assert(isequal(sansNaN, [1 3]) && isequal(marque(:)', [false true false]));

% standardizeMissing traduit un code d'absence en vrai manquant, ce qui
% permet ensuite a rmmissing de faire son travail.
assert(isequaln(standardizeMissing([1 2 -99], -99), [1 2 NaN]));
propre = standardizeMissing({'a', 'N/A'}, {'N/A'});
assert(isempty(propre{2}));

% Sur une table, le manquant se cherche variable par variable.
tManque = table([1; NaN; 3], {'a'; 'b'; ''}, 'VariableNames', {'x', 'y'});
assert(isequal(size(ismissing(tManque)), [3 2]));
assert(height(rmmissing(tManque)) == 1);

%% ------------------------------------------------- groupes et agregation
[groupes, noms] = findgroups({'b', 'a', 'b'});
assert(isequal(groupes, [2 1 2]));
assert(strcmp(noms{1}, 'a') && strcmp(noms{2}, 'b'));
% Deux classements croises donnent un groupe par couple.
assert(isequal(findgroups([1 1 2], {'x', 'y', 'x'}), [1 2 3]));
% Un manquant n'appartient a aucun groupe.
assert(isnan(sum(findgroups([3 NaN 1]) .* [0 1 0])));

assert(isequal(splitapply(@sum, [1 2 3 4], [1 1 2 2]), [3; 7]));
assert(isequal(splitapply(@(v) [min(v) max(v)], [1 5 2 8], [1 1 2 2]), [1 5; 2 8]));
[moyennes, ecarts] = splitapply(@(v) deal(mean(v), std(v)), [1 3 10 20], [1 1 2 2]);
assert(isequal(moyennes, [2; 15]));
assert(abs(ecarts(1) - sqrt(2)) < 1e-12);

%% ------------------------------------------------------- tableau croise
tCroise = table({'a'; 'a'; 'b'}, [1; 2; 1], [10; 20; 30], ...
                'VariableNames', {'g', 'c', 'v'});
croise = pivot(tCroise, 'Rows', 'g', 'Columns', 'c', ...
               'DataVariable', 'v', 'Method', 'sum');
assert(height(croise) == 2 && width(croise) == 3);
assert(croise.x1(1) == 10 && croise.x2(1) == 20);
% Sans variable de donnees, pivot compte les lignes.
comptes = pivot(tCroise, 'Rows', 'g', 'Columns', 'c');
assert(comptes.x1(2) == 1 && comptes.x2(2) == 0);

%% --------------------------------------------------------------- X.empty
% La seule methode statique que MATLAB donne a toute classe.
assert(isequal(size(double.empty), [0 0]));
assert(isequal(size(double.empty(0, 3)), [0 3]));
assert(strcmp(class(cell.empty(0, 2)), 'cell'));
assert(strcmp(class(int8.empty), 'int8'));
assert(isempty(duration.empty));
videRefuse = false;
try
    double.empty(2, 3);
catch
    videRefuse = true;
end
assert(videRefuse);

disp('types : toutes les verifications passent');
