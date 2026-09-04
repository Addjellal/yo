% test_langage.m — sémantique du langage : contrôle, portées, types.
%
% Comme dans MATLAB depuis R2016b, les fonctions locales d'un script sont
% écrites à la fin du fichier.
disp('--- langage ---');

% Affectations et opérateurs composés.
a = 1;
a += 2;
assert(a == 3);
a *= 4;
assert(a == 12);

% Comparaisons et court-circuit.
assert(true && ~false);
assert(1 > 0 || effetDeBord());

% if / elseif / else.
assert(strcmp(classer(-1), 'negatif'));
assert(strcmp(classer(0), 'nul'));
assert(strcmp(classer(2), 'positif'));

% Boucles, break et continue.
somme = 0;
for k = 1:10
    if mod(k, 2) == 0
        continue;
    end
    if k > 7
        break;
    end
    somme = somme + k;
end
assert(somme == 1 + 3 + 5 + 7);

% while avec condition composée.
n = 0;
x = 100;
while x > 1 && n < 50
    x = x / 2;
    n = n + 1;
end
assert(n == 7);

% switch avec cellule de cas.
assert(strcmp(jour(6), 'week-end'));
assert(strcmp(jour(1), 'lundi'));
assert(strcmp(jour(3), 'semaine'));

% Récursion.
assert(fact(6) == 720);

% varargin, nargin, nargout.
[a1, a2] = compte(1, 2, 3);
assert(a1 == 3 && a2 == 6);
assert(combien(1) == 1);
assert(combien(1, 2) == 2);

% Fermetures.
g = fabriquerCompteur(10);
assert(g(5) == 15);

% Poignées dans une cellule.
operations = {@(x) x + 1, @(x) x * 2, @sqrt};
assert(operations{1}(1) == 2);
assert(operations{2}(3) == 6);
assert(abs(operations{3}(9) - 3) < 1e-12);

% Structures et tableaux de structures.
s.nom = 'essai';
s.valeur = 42;
assert(isfield(s, 'nom'));
assert(numel(fieldnames(s)) == 2);
s = rmfield(s, 'nom');
assert(~isfield(s, 'nom'));
t(1).x = 1;
t(2).x = 2;
assert(numel(t) == 2);
assert(t(2).x == 2);

% Champ dynamique.
u = struct();
champ = 'dyn';
u.(champ) = 5;
assert(u.dyn == 5);

% Cellules imbriquées.
c = {1, {2, 3}, 'quatre'};
assert(numel(c) == 3);
assert(iscell(c{2}));
assert(c{2}{2} == 3);
[p, q] = c{1:2};
assert(p == 1);

% cellfun et arrayfun.
assert(isequal(cellfun(@numel, {'a', 'bb', 'ccc'}), [1 2 3]));
assert(isequal(arrayfun(@(v) v^2, 1:3), [1 4 9]));
r = cellfun(@(v) v * 2, {1, 2}, 'UniformOutput', false);
assert(r{2} == 4);

% Erreurs et identifiants.
leve = false;
try
    error('MonModule:monErreur', 'valeur %d refusee', 7);
catch e
    leve = strcmp(e.identifier, 'MonModule:monErreur');
    assert(~isempty(strfind(e.message, '7')));
end
assert(leve);

% global et persistent.
global compteurGlobal
compteurGlobal = 0;
incrementer();
incrementer();
assert(compteurGlobal == 2);
appels();
assert(appels() == 2);

% Types entiers et logiques.
assert(int8(200) == 127);
assert(uint8(-5) == 0);
assert(isa(single(1), 'single'));
assert(islogical(true));
assert(class(1) == 'double');
assert(int32(7) / int32(2) == 4);

% Nombres complexes.
z = 3 + 4i;
assert(abs(z) == 5);
assert(real(z) == 3 && imag(z) == 4);
assert(conj(z) == 3 - 4i);
assert(abs(sqrt(-4) - 2i) < 1e-12);

%% ------------------- affectation multiple dans une liste separee
% Une cible qui designe plusieurs elements consomme autant de sorties :
% c'est l'idiome [c{:}] = deal(...) de MATLAB.
c = cell(1, 3);
[c{:}] = deal(1, 2, 3);
assert(isequal(c, {1, 2, 3}));
d = cell(1, 2);
[d{:}] = size(zeros(2, 3));
assert(isequal(d, {2, 3}));
e = cell(1, 3);
[e{1:2}] = deal(4, 5);
assert(isequal(e{1}, 4) && isequal(e{2}, 5) && isempty(e{3}));
f = cell(1, 3);
[f{[1 3]}] = deal(7, 8);
assert(isequal(f{1}, 7) && isempty(f{2}) && isequal(f{3}, 8));
% Sur un tableau de structures, le champ se remplit element par element.
s = struct('a', {[] []});
[s.a] = deal(7, 8);
assert(s(1).a == 7 && s(2).a == 8);
% Un champ absent est cree.
t = struct('x', {1 2});
[t.y] = deal(10, 20);
assert(t(1).y == 10 && t(2).y == 20);
% Les cibles simples n'ont pas change de comportement.
[g, h] = deal(1, 2);
assert(g == 1 && h == 2);
cc = {0 0};
cc{end} = 5;
assert(isequal(cc, {0, 5}));
cc{end+1} = 6;
assert(numel(cc) == 3 && cc{3} == 6);

%% --------------------------------------------- syntaxe commande
% MATLAB accepte « f arg1 arg2 » pour n'importe quelle fonction, pas pour
% une liste choisie : c'est ainsi que s'ecrivent « cvx_begin sdp » ou
% « hold on ». La regle est syntaxique, sauf que le nom ne doit pas etre
% une variable — « x -1 » soustrait quand x en est une.
assert(strcmp(evalc('disp bonjour'), sprintf('bonjour\n')));

xCmd = 10;
assert(xCmd -1 == 9);          % xCmd est une variable : soustraction
assert(xCmd - 1 == 9);
assert(xCmd-1 == 9);

% Un nom qui n'est pas une variable prend ses arguments comme du texte.
% La syntaxe commande n'existe qu'en instruction seule : « r = f arg » est
% une erreur de syntaxe en MATLAB aussi.
assert(strcmp(commandeDEssai('un', 'deux'), 'un|deux'));
sortieCmd = evalc('commandeDEssai trois quatre');
assert(~isempty(strfind(sortieCmd, 'trois|quatre')));
% L'apostrophe groupe : « f 'un texte' » ne fait qu'un argument.
sortieCmd = evalc('commandeDEssai ''un texte'' seul');
assert(~isempty(strfind(sortieCmd, 'un texte|seul')));
% Un operateur colle au mot en fait partie.
sortieCmd = evalc('commandeDEssai -verbose');
assert(~isempty(strfind(sortieCmd, '-verbose')));

% Un mot-cle en argument reste un mot : « dbstop if error » est une
% commande, pas un « if ». Le premier jeton, lui, ne peut pas etre un
% mot-cle, donc « if x > 1 » reste un vrai if.
sortieCmd = evalc('commandeDEssai if error');
assert(~isempty(strfind(sortieCmd, 'if|error')));
xGarde = 3;
if xGarde > 1
    assert(true);
end
for kGarde = 1:2
end
assert(kGarde == 2);

%% ------------------------------------------ « for » sur un intervalle
% MATLAB parcourt un intervalle sans le construire : « for k = 1:1e9 »
% n'alloue rien. Ici, construire le vecteur demandait seize gigaoctets,
% et le programme se faisait tuer avant d'entrer dans la boucle.
compte = 0;
for k = 1:2000000000
    compte = compte + 1;
    if compte >= 1000
        break
    end
end
assert(compte == 1000);

% Le parcours reste celui de MATLAB, dans tous les cas de figure.
sommeCroissante = 0;
for k = 1:10, sommeCroissante = sommeCroissante + k; end
assert(sommeCroissante == 55);
sommePas = 0;
for k = 10:-2:1, sommePas = sommePas + k; end
assert(sommePas == 30);
sommeFractionnaire = 0;
for k = 0:0.25:1, sommeFractionnaire = sommeFractionnaire + k; end
assert(abs(sommeFractionnaire - 2.5) < 1e-12);
toursVides = 0;
for k = 1:0, toursVides = toursVides + 1; end
assert(toursVides == 0);
sommeContinue = 0;
for k = 1:10
    if mod(k, 2) == 0
        continue
    end
    sommeContinue = sommeContinue + k;
end
assert(sommeContinue == 25);
% La variable de boucle garde sa derniere valeur, et reste un double.
for kFinal = 1:5, end
assert(kFinal == 5);
assert(strcmp(class(kFinal), 'double'));
% Une boucle sur une matrice parcourt toujours ses colonnes.
colonnes = 0;
for colonne = magic(3)
    assert(isequal(size(colonne), [3 1]));
    colonnes = colonnes + 1;
end
assert(colonnes == 3);

%% ---------------------------------------------------- eval avec sortie
% MATLAB : « eval(texte) » execute ; « x = eval(texte) » evalue une
% expression et rend sa valeur, jusqu'a nargout valeurs.
assert(eval('1+1') == 2);
assert(isequal(eval('[1 2 3]'), [1 2 3]));
[lignesEval, colonnesEval] = eval('size(magic(3))');
assert(lignesEval == 3 && colonnesEval == 3);
assert(eval('zzzInconnu', '42') == 42);
% Les variables temporaires de eval ne restent pas dans l'espace de travail.
assert(exist('matlibre__eval1__', 'var') == 0);

% evalin evalue DANS l'espace vise, avec ou sans sortie : sans cela,
% « evalin('base','x') » lisait la portee courante.
assert(essaiEvalin() == 6);

% Un evalc dans un evalc ne laisse rien echapper vers la console : le plus
% interne rend son texte au plus externe, qui le capture aussi.
sortieImbriquee = evalc('interne = evalc(''disp(42)''); disp([''vu : '' strtrim(interne)])');
assert(~isempty(strfind(sortieImbriquee, 'vu : 42')));

%% ------------------------------------------- « return » dans un script
% MATLAB : « return force le retour du controle au programme appelant
% avant la fin du script ou de la fonction ». Un script s'arrete donc sur
% « return » — et rien de plus : ni la fonction qui l'a lance, ni, dans une
% interface, la boucle d'evenements que l'exception traverserait.
clear marqueRetour
scriptQuiRend;                      % appele par son nom
assert(exist('marqueRetour', 'var') == 1);
assert(marqueRetour == 1);          % la ligne d'apres n'a pas tourne

clear marqueRetour
run('scriptQuiRend');               % appele par « run »
assert(marqueRetour == 1);

% Lance depuis une fonction, le script rend la main a la fonction, qui
% continue : c'est le sens de « programme appelant ».
assert(lanceurDeScript(true) == 42);
assert(lanceurDeScript(false) == 42);

% Ce qui ne porte pas de nombre ne se convertit pas. Convertir une
% structure, un objet ou une poignee rendait une valeur numerique sans
% donnees, dont la premiere lecture sortait du tableau — le programme
% tombait.
for aConvertir = {struct('a', 1), @sin, {1, 2}}
    refuse = false;
    try
        double(aConvertir{1});                          %#ok<VUNUS>
    catch e
        refuse = strcmp(e.identifier, 'MATLAB:invalidConversion');
    end
    assert(refuse);
end
refuse = false;
try
    int32(struct('a', 1));                              %#ok<VUNUS>
catch e
    refuse = strcmp(e.identifier, 'MATLAB:invalidConversion') && ...
             ~isempty(strfind(e.message, 'int32'));
end
assert(refuse);

% « err.stack » nomme les cadres traverses, du plus profond au plus haut,
% avec leur ligne : c'est ce que MATLAB imprime sous le message.
try
    profondEnErreur();
catch e
    assert(numel(e.stack) >= 2);
    assert(~isempty(strfind(e.stack(1).name, 'plusProfondEncore')));
    assert(e.stack(1).line > 0);
    assert(~isempty(strfind(e.stack(2).name, 'profondEnErreur')));
    assert(e.stack(2).line > e.stack(1).line - 100);
end

% « (a)(b) » : une multiplication oubliee. MATLAB le refuse a l'analyse ;
% on rendait « Index in position 1 is invalid », qui ne designe rien.
refuse = false;
try
    eval('x = (1+2)(3+4);');
catch e
    refuse = strcmp(e.identifier, 'MATLAB:parseError') && ...
             ~isempty(strfind(e.message, 'missing multiplication operator'));
end
assert(refuse);
% Ce qui reste licite le reste.
assert((1 + 2) * 3 == 9);
assert(isequal(([1 2 3])', [1; 2; 3]));

% Aucune fonction native ne doit tomber sur un argument qui n'a pas la
% forme attendue. Une cellule, une structure, une poignee ou un tableau de
% chaines ne portent aucun nombre : « nelem » y compte des elements que le
% tableau de reels n'a pas, et les parcourir sortait de la memoire — le
% programme tombait, parfois plus loin, a l'affichage. Une erreur MATLAB
% est la bonne reponse ; un plantage n'en est jamais une.
%
% On ne peut pas eprouver ici les 617 fonctions — un plantage tuerait le
% test lui-meme — mais on couvre celles ou le defaut se logeait, et les
% deux familles de garde qui les protegent.
hostiles = {struct(), @sin, {1, 2}, "", [], 'abc'};
aEprouver = {'acos', 'asin', 'angle', 'conj', 'roots', 'expm', 'rot90', ...
             'fliplr', 'flipud', 'flip', 'ctranspose', 'sort', 'sortrows', ...
             'num2str', 'mat2str', 'string', 'isletter', 'isspace', 'isdigit', ...
             'fftshift', 'ifftshift', 'zeros', 'ones', 'randi', 'speye', ...
             'histcounts', 'prctile', 'quantile', 'cumtrapz', 'nchoosek'};
for k = 1:numel(aEprouver)
    for j = 1:numel(hostiles)
        try
            feval(aEprouver{k}, hostiles{j});
        catch
            % Une erreur est le comportement voulu.
        end
    end
end
% Les arguments de taille et de dimension, eux aussi.
mauvaisesTailles = {{1, 2}, struct(), @sin, NaN, Inf, -1};
for j = 1:numel(mauvaisesTailles)
    for nom = {'zeros', 'ones', 'speye', 'size', 'reshape', 'permute', 'circshift'}
        try
            feval(nom{1}, 1, mauvaisesTailles{j});
        catch
        end
    end
end
% Une dimension negative indexait avant le tableau et corrompait le tas.
for nom = {'sum', 'all', 'any', 'prod', 'cumsum', 'cumprod', 'mean'}
    coupe = false;
    try
        feval(nom{1}, [1 2 3], -1);
    catch e
        coupe = ~isempty(strfind(e.message, 'Dimension argument'));
    end
    assert(coupe);
end
% Et ce qui doit marcher marche toujours.
assert(isequal(sort({'b', 'a'}), {'a', 'b'}));
assert(isequal(size(zeros(3, 7)), [3 7]));
assert(isequal(permute(ones(2, 3), [2 1]), ones(3, 2)));
assert(isletter('a') && ~isletter('1'));
assert(~isletter(NaN));       % isalpha(INT_MIN) lisait hors de sa table

%% ------------------------------------------------------------ inputname
% Le nom de la variable passee en argument, quand c'en etait une.
maDonnee = [1 2 3];
assert(strcmp(nomRecu(maDonnee), 'maDonnee'));
assert(isempty(nomRecu([4 5 6])));
assert(isempty(nomRecu(maDonnee + 1)));

%% ------------------------------------------------ evalin efface aussi
% « evalin('caller','clear x') » doit effacer x chez l'appelant : une
% fusion des variables ecrites ne suffit pas, il faut reporter la table
% entiere.
aEffacer = 1;
aGarder = 2;
effaceChezLAppelant('aEffacer');
assert(exist('aEffacer', 'var') == 0);
assert(exist('aGarder', 'var') ~= 0);

%% --------------------------------- les arguments hostiles, deuxieme passe
% Une fonction qui parcourt « re » d'une valeur qui n'en a pas — une
% cellule, une structure, une poignee — lit hors du tableau et fait tomber
% le programme. Le passage automatique en avait ferme deux cent
% vingt-six ; en voici seize de plus, trouves par le meme moyen. Une
% erreur MATLAB est le bon comportement, jamais un plantage.
hostiles = {{1, 2}, struct(), struct('a', 1), @sin};
fonctions = {'trace', 'triu', 'tril', 'trapz', 'vander', ...
             'toeplitz', 'sub2ind', 'upsample', 'randsample', ...
             'sparse', 'xlim', 'ylim'};
for kf = 1:numel(fonctions)
    for kh = 1:numel(hostiles)
        leve = false;
        try
            switch fonctions{kf}
                case {'sub2ind', 'upsample', 'randsample'}
                    feval(fonctions{kf}, hostiles{kh}, 1);
                case 'sparse'
                    feval(fonctions{kf}, hostiles{kh}, 1, 1);
                otherwise
                    feval(fonctions{kf}, hostiles{kh});
            end
        catch
            leve = true;
        end
        assert(leve, sprintf('%s aurait du refuser l''argument %d', fonctions{kf}, kh));
    end
end
% « unique » accepte une cellule de chaines — c'est son usage courant —
% et refuse ce qui n'a pas d'elements a comparer.
assert(numel(unique({'b', 'a', 'b'})) == 2);
for hostile = {struct(), @sin}
    refuse = false;
    try
        unique(hostile{1});
    catch
        refuse = true;
    end
    assert(refuse);
end

% « transpose », lui, doit accepter une cellule — la transposer est
% legitime — et refuser ce qui n'a pas de forme de tableau.
assert(isequal(size(transpose({1, 2})), [2 1]));
for hostile = {struct(), @sin}
    refuse = false;
    try
        transpose(hostile{1});
    catch
        refuse = true;
    end
    assert(refuse);
end

% Melanger une cellule et des nombres dans une operation d'ensemble est
% refuse : le resultat aurait des elements des deux, et l'un des deux n'a
% rien a offrir a l'autre.
for nom = {'union', 'intersect', 'setdiff'}
    melange = false;
    try
        feval(nom{1}, {1, 2}, 1);
    catch
        melange = true;
    end
    assert(melange);
end
% Ce qui doit marcher marche toujours.
assert(isequal(union([1 2], [2 3]), [1 2 3]));
assert(isequal(intersect([1 2 3], [2 3 4]), [2 3]));
assert(isequal(setdiff([1 2 3], [2]), [1 3]));
assert(numel(union({'a', 'c'}, {'b'})) == 3);
assert(trace([1 2; 3 4]) == 5);
assert(isequal(triu([1 2; 3 4]), [1 2; 0 4]));

% Une structure copiee ne partage pas ses champs : ecrire dans une copie
% ne touche pas les autres. Les champs sont partages tant que personne
% n'y ecrit, ce qui economise la copie ; c'est l'ecriture qui doit
% detacher. Sans cela, « repmat({s}, 1, 3) » rendait trois cases qui
% pointaient les memes champs.
modele = struct('valeur', 0);
cases = repmat({modele}, 1, 3);
for k = 1:3
    cases{k}.valeur = 10 * k;
end
assert(isequal([cases{1}.valeur, cases{2}.valeur, cases{3}.valeur], [10 20 30]));
% Meme chose avec un indice explicite dans la chaine d'affectation.
cases = repmat({modele}, 1, 3);
for k = 1:3
    cases{k}(1).valeur = k;
end
assert(isequal([cases{1}.valeur, cases{2}.valeur, cases{3}.valeur], [1 2 3]));
% Et dans un tableau de structures.
tableau = repmat(modele, 1, 3);
for k = 1:3
    tableau(k).valeur = k * k;
end
assert(isequal([tableau.valeur], [1 4 9]));
% Une structure rangee dans un champ d'une autre est aussi une copie.
englobante.a = modele;
englobante.b = englobante.a;
englobante.a.valeur = 5;
assert(englobante.b.valeur == 0);

disp('langage : toutes les verifications passent');

function nom = nomRecu(~)
    nom = inputname(1);
end

function effaceChezLAppelant(nom)
    evalin('caller', ['clear ' nom]);
end

% --------------------------------------------------------------- fonctions

function r = essaiEvalin()
%ESSAIEVALIN assignin ecrit dans la base, evalin l'y relit — sans sortie
%   comme avec, et depuis l'interieur d'un evalc.
    code = sprintf('assignin(''base'',''venuDeLaBase'',6);\nevalin(''base'',''venuDeLaBase'')');
    texte = evalc(code);
    assert(~isempty(strfind(texte, '6')));
    evalin('base', 'creeeParEvalin = 6;');
    r = evalin('base', 'creeeParEvalin');
end

function r = effetDeBord()
    r = true;
end

function nom = classer(x)
    if x < 0
        nom = 'negatif';
    elseif x == 0
        nom = 'nul';
    else
        nom = 'positif';
    end
end

function r = jour(n)
    switch n
        case {6, 7}
            r = 'week-end';
        case 1
            r = 'lundi';
        otherwise
            r = 'semaine';
    end
end

function y = fact(n)
    if n <= 1
        y = 1;
    else
        y = n * fact(n - 1);
    end
end

function varargout = compte(varargin)
    for k = 1:nargout
        varargout{k} = numel(varargin) * k;
    end
end

function n = combien(a, b, c)
    n = nargin;
end

function f = fabriquerCompteur(depart)
    f = @(x) x + depart;
end

function incrementer()
    global compteurGlobal
    compteurGlobal = compteurGlobal + 1;
end

function n = appels()
    persistent nombre
    if isempty(nombre)
        nombre = 0;
    end
    nombre = nombre + 1;
    n = nombre;
end

function profondEnErreur()
    plusProfondEncore();
end

function plusProfondEncore()
    error('Essai:profond', 'au fond');
end
