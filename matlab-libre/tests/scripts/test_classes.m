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

disp('classes : toutes les verifications passent');
