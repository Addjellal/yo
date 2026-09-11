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

% Une classe qui definit « subsasgn » decide de ses affectations, y
% compris quand l'objet est range dans une cellule ou une structure.
% Auparavant l'affectation cherchait une propriete du meme nom et
% n'ecrivait rien.
t = table({'a'}, {[1 2]}, 'VariableNames', {'Nom', 'Valeur'});
paquet = repmat({t}, 1, 2);
paquet{1}.Valeur = {[9 9]};
assert(isequal(paquet{1}.Valeur{1}, [9 9]));
assert(isequal(paquet{2}.Valeur{1}, [1 2]));
enveloppe.contenu = t;
enveloppe.contenu.Valeur = {[7 7]};
assert(isequal(enveloppe.contenu.Valeur{1}, [7 7]));
assert(isequal(t.Valeur{1}, [1 2]));


% Une poignee vers un nom natif doit atteindre la methode de la classe,
% comme l'atteindrait un appel direct. Sans cela « cellfun(@double, ...) »
% appelait le natif, qui ne sait pas convertir un objet.
syms xPoignee
valeurSymbolique = sym(3);
assert(double(valeurSymbolique) == 3);
poigneeDouble = @double;
assert(poigneeDouble(valeurSymbolique) == 3);
poigneeChar = @char;
assert(strcmp(poigneeChar(valeurSymbolique), '3'));
assert(feval('double', valeurSymbolique) == 3);
% Et a travers CELLFUN et ARRAYFUN, qui est l'usage courant.
lot = {sym(1), sym(2), sym(4)};
assert(isequal(cellfun(@double, lot), [1 2 4]));
assert(isequal(cellfun(@char, lot, 'UniformOutput', false), {'1', '2', '4'}));
% Un objet sans la methode demandee laisse le natif faire son travail.
assert(poigneeDouble(int8(7)) == 7);
assert(poigneeDouble([1 2 3]) == [1 2 3]);
disp('poignees vers les methodes : ok');

%% --------------------------------------------------------- HERITAGE
% Une derivee recoit de son parent ses proprietes et ses methodes ; ce
% qu'elle redefinit l'emporte, et ISA la reconnait des deux classes.
d = FormeDerivee(3, 5);
assert(d.cote == 3);                       % la propriete du parent, posee
assert(d.hauteur == 5);                    % la sienne
assert(strcmp(d.nomDeBase, 'base'));       % avec sa valeur par defaut
assert(aire(d) == 9);                      % methode heritee
assert(perimetre(d) == 12);                % heritee aussi
assert(volume(d) == 45);                   % la sienne, qui appelle l'heritee
assert(strcmp(quiSuisJe(d), 'derivee'));   % la redefinition l'emporte
assert(strcmp(quiSuisJe(FormeDeBase(1)), 'base'));

% ISA remonte la chaine : un objet est de la classe de chacun de ses
% ancetres, c'est tout le propos de l'heritage.
assert(isa(d, 'FormeDerivee'));
assert(isa(d, 'FormeDeBase'));
assert(~isa(d, 'double'));
assert(~isa(FormeDeBase(1), 'FormeDerivee'));
assert(strcmp(class(d), 'FormeDerivee'));
assert(any(strcmp(superclasses(d), 'FormeDeBase')));
assert(any(strcmp(superclasses('FormeDerivee'), 'FormeDeBase')));
assert(isempty(superclasses('FormeDeBase')));

% Le constructeur du parent, appele sans argument, laisse les valeurs par
% defaut : « obj@Parent(...) » construit la part de parent, rien de plus.
sansArgument = FormeDerivee(7);
assert(sansArgument.cote == 7 && sansArgument.hauteur == 2);

% Le constructeur du parent ne s'herite pas : appeler FormeDerivee ne doit
% pas construire un FormeDeBase.
assert(strcmp(class(FormeDerivee(1)), 'FormeDerivee'));
% Une classe a poignee compte « handle » parmi ses ancetres, ce qui est
% la facon de savoir qu'elle se copie par reference.
f = memoize(@(x) x);
assert(isa(f, 'handle'));
assert(any(strcmp(superclasses(f), 'handle')));

%% ------------------------------------------ CLEARALLMEMOIZEDCACHES
% Une fonction memoisee retient ses resultats ; vider le cache les lui
% fait oublier. C'est necessaire quand ce dont elle depend change sans
% que ses arguments changent.
compteur = 0;
compter = memoize(@(x) x + 1);
compter(1);
compter(1);
avant = stats(compter);
assert(avant.CacheHits == 1);           % le second appel a ete retrouve
assert(avant.CacheOccupancyPercent > 0);
clearAllMemoizedCaches();
apres = stats(compter);
assert(apres.CacheOccupancyPercent == 0);
% Apres vidage, le meme appel est recalcule, non retrouve.
compter(1);
recalcul = stats(compter);
assert(recalcul.CacheHits == avant.CacheHits);
(compteur);   %#ok<VUNUS>

%% ------------------- ce qu'une classe declare se relit
% PROPERTIES existait seul de sa famille : METHODS, EVENTS et ENUMERATION
% manquaient, et le bloc « enumeration » etait analyse puis jete — ses
% membres se lisaient, et rien n'en restait.
assert(isequal(sort(methods('CouleurEssai')'), {'CouleurEssai', 'doubler'}));
assert(isequal(events('CouleurEssai')', {'Change', 'Efface'}));
assert(isequal(enumeration('CouleurEssai')', {'Rouge', 'Vert', 'Bleu'}));
assert(isequal(properties('CouleurEssai')', {'code'}));
% Un objet repond comme sa classe.
assert(isequal(methods(CouleurEssai(1)), methods('CouleurEssai')));
% Une classe native n'a rien de declare : le dire vaut mieux qu'une erreur.
assert(isempty(methods('double')));

% METACLASS reunit tout en une structure.
description = metaclass(CouleurEssai(1));
assert(strcmp(description.Name, 'CouleurEssai'));
assert(numel(description.PropertyList) == 1);
assert(numel(description.MethodList) == 2);
assert(numel(description.EventList) == 2);
assert(numel(description.EnumerationMemberList) == 3);
assert(isempty(description.SuperclassList));
% Et elle voit l'heritage.
assert(isequal(metaclass(FormeDerivee(1)).SuperclassList', {'FormeDeBase'}));
assert(metaclass(memoize(@(x) x)).HandleCompatible);
disp('reflexion : ok');

disp('heritage : ok');

disp('classes : toutes les verifications passent');
