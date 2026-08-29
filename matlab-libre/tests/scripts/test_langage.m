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

disp('langage : toutes les verifications passent');

% --------------------------------------------------------------- fonctions

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
