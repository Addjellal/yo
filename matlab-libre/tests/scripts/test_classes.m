% test_classes.m — classes, méthodes et surcharge d'opérateurs.
disp('--- classes ---');

c = Compteur(5);
assert(strcmp(class(c), 'Compteur'));
assert(isobject(c));
assert(c.valeur == 5);
assert(c.pas == 1);

% Méthode appelée sur l'objet, puis en notation fonctionnelle.
c = c.incrementer();
assert(c.valeur == 6);
c = incrementer(c);
assert(c.valeur == 7);

% Sémantique de valeur : l'original n'est pas modifié.
d = c;
d = d.incrementer();
assert(c.valeur == 7 && d.valeur == 8);

% Surcharge d'opérateur.
e = c + d;
assert(strcmp(class(e), 'Compteur'));
assert(e.valeur == 15);

% Méthode rendant autre chose qu'un objet.
assert(strcmp(versTexte(e), 'Compteur(15)'));
assert(strcmp(e.versTexte(), 'Compteur(15)'));

% Constructeur sans argument : les valeurs par défaut s'appliquent.
f = Compteur();
assert(f.valeur == 0);

% Modification directe d'une propriété.
f.valeur = 42;
assert(f.valeur == 42);

% « help » et « doc » lisent aussi le bloc d'aide d'une classe : il est
% sous « classdef » comme celui d'une fonction est sous « function ».
% « help tf » repondait « 'tf' not found » des que tf est devenue une
% classe.
for nomClasse = {'tf', 'ss', 'duration'}
    fiche = matlibre_aide_structuree(nomClasse{1});
    assert(strcmp(fiche.Source, 'classe'));
    assert(~isempty(fiche.Resume));
    assert(~isempty(fiche.Fichier));
end
% Et les sections y sont decoupees, « Exemple : » compris — l'espace
% avant le deux-points empechait de reconnaitre l'en-tete.
ficheTf = matlibre_aide_structuree('tf');
assert(numel(ficheTf.Exemples) >= 2);
assert(any(strcmp(ficheTf.VoirAussi, 'zpk')));

%% -------------------------------------------------- classes a reference
% « classdef X < handle » : l'objet partage son etat avec ses copies.
% Sans cela, une methode qui ecrit dans l'objet travaillait sur une copie
% et son effet se perdait au retour.
compteurPartage = CompteurAReference();
compteurPartage.incrementer();
compteurPartage.incrementer();
assert(compteurPartage.n == 2);
autreVue = compteurPartage;
autreVue.incrementer();
assert(compteurPartage.n == 3);      % la meme chose, vue deux fois

%% -------------------------------------------------------- inputParser
analyseur = inputParser;
addRequired(analyseur, 'x', @isnumeric);
addParameter(analyseur, 'Ordre', 2, @(v) v > 0);
addParameter(analyseur, 'Nom', 'a');
addSwitch(analyseur, 'Vite');
parse(analyseur, 3, 'Ordre', 5, 'Vite');
assert(analyseur.Results.x == 3);
assert(analyseur.Results.Ordre == 5);
assert(strcmp(analyseur.Results.Nom, 'a'));
assert(analyseur.Results.Vite);
assert(isequal(analyseur.UsingDefaults, {'Nom'}));

% Un argument facultatif prend sa valeur par defaut quand il manque.
facultatif = inputParser;
addOptional(facultatif, 'n', 10);
parse(facultatif);
assert(facultatif.Results.n == 10);

% Un prefixe non ambigu suffit a nommer un parametre, comme dans MATLAB.
partiel = inputParser;
addParameter(partiel, 'Longueur', 1);
parse(partiel, 'Long', 7);
assert(partiel.Results.Longueur == 7);

% Ce qui n'est pas declare est refuse, sauf si l'on garde les inconnus.
refuse = false;
strict = inputParser;
addParameter(strict, 'a', 1);
try
    parse(strict, 'zz', 2);
catch
    refuse = true;
end
assert(refuse);
tolerant = inputParser;
addParameter(tolerant, 'a', 1);
tolerant.KeepUnmatched = true;
parse(tolerant, 'b', 2);
assert(tolerant.Unmatched.b == 2);

% Le validateur a le dernier mot.
valide = false;
controle = inputParser;
addParameter(controle, 'a', 1, @(v) v > 0);
try
    parse(controle, 'a', -1);
catch
    valide = true;
end
assert(valide);

%% ------------------------------------------------------------- memoize
carre = memoize(@(x) x ^ 2);
assert(carre(3) == 9);
assert(carre(3) == 9);
assert(carre(4) == 16);
compte = stats(carre);
assert(compte.TotalCalls == 3 && compte.CacheHits == 1);
clearCache(carre);
assert(stats(carre).CacheOccupancyPercent == 0);
% Desactive, il recalcule sans rien retenir.
carre.Enabled = false;
assert(carre(5) == 25);
% Plusieurs sorties passent par le cache elles aussi.
deuxSorties = memoize(@(a, b) deal(a + b, a * b));
[somme1, produit1] = deuxSorties(2, 3);
[somme2, produit2] = deuxSorties(2, 3);
assert(somme1 == 5 && produit1 == 6);
assert(somme2 == 5 && produit2 == 6);

%% ------------------------------------------------------------ subsasgn
% L'affectation indexee ecrite comme une donnee : c'est ce dont a besoin
% la methode subsasgn d'une classe pour poursuivre la chaine.
assert(isequal(subsasgn([1 2 3], substruct('()', {2}), 9), [1 9 3]));
structureEcrite = subsasgn(struct('a', struct('b', 1)), ...
                           substruct('.', 'a', '.', 'c'), 5);
assert(structureEcrite.a.c == 5 && structureEcrite.a.b == 1);
celluleEcrite = subsasgn({1, 2}, substruct('{}', {1}), 'x');
assert(strcmp(celluleEcrite{1}, 'x'));

%% -------------------------------------------------------------- builtin
% builtin court-circuite la surcharge : c'est la native qui repond.
assert(isequal(builtin('size', ones(2, 3)), [2 3]));
assert(builtin(@max, [1 5 2]) == 5);
natifRefuse = false;
try
    builtin('repelem', [1 2], 2);
catch
    natifRefuse = true;
end
assert(natifRefuse);

disp('classes : toutes les verifications passent');
