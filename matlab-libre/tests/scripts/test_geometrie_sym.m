% test_geometrie_sym.m — polygones et algèbre symbolique.
% Ce qui est vérifié : l'aire d'une figure dont on connaît la réponse, le
% produit d'une factorisation, la valeur d'une forme réécrite. Jamais une
% chaîne de caractères produite par le programme lui-même.
disp('--- geometrie et symbolique ---');

%% ---------------------------------------------------------- POLYSHAPE
% L'aire, le périmètre et le centre de gravité se vérifient sur des
% figures dont on connaît la réponse, et l'orientation ne doit rien y
% changer : la formule du lacet en prend la valeur absolue.
carre = polyshape([0 2 2 0], [0 0 2 2]);
assert(abs(area(carre) - 4) < 1e-12);
assert(abs(perimeter(carre) - 8) < 1e-12);
assert(max(abs(centroid(carre) - [1 1])) < 1e-12);
assert(numsides(carre) == 4);
assert(numboundaries(carre) == 1);
assert(numregions(carre) == 1);
assert(isequal(boundingbox(carre), [0 2; 0 2]));
% Le même carré parcouru dans l'autre sens a la même aire.
assert(abs(area(polyshape([0 0 2 2], [0 2 2 0])) - 4) < 1e-12);

% Un triangle : l'aire est la moitié de la base par la hauteur, et le
% centre de gravité le tiers du chemin depuis chaque côté.
triangle = polyshape([0 3 0], [0 0 3]);
assert(abs(area(triangle) - 4.5) < 1e-12);
assert(max(abs(centroid(triangle) - [1 1])) < 1e-12);

% Un L non convexe : l'aire ne suppose pas la convexité, et le centre de
% gravité tombe là où la matière est.
forme = polyshape([0 2 2 1 1 0], [0 0 1 1 2 2]);
assert(abs(area(forme) - 3) < 1e-12);
assert(isinterior(forme, 0.5, 0.5));
assert(~isinterior(forme, 1.5, 1.5));

% Un trou : le contour intérieur, parcouru en sens inverse, retranche son
% aire. C'est tout ce que l'orientation sert à dire.
perce = polyshape({[0 4 4 0], [1 1 3 3]}, {[0 0 4 4], [1 3 3 1]});
assert(numboundaries(perce) == 2);
assert(numregions(perce) == 1);
assert(sum(ishole(perce)) == 1);
assert(abs(area(perce) - (16 - 4)) < 1e-12);
% Le périmètre compte les deux bords : celui du dehors et celui du trou.
assert(abs(perimeter(perce) - (16 + 8)) < 1e-12);
% Un point dans le trou n'est pas dans la région.
assert(isinterior(perce, 0.5, 0.5));
assert(~isinterior(perce, 2, 2));
% Par symétrie, le centre de gravité reste au centre.
assert(max(abs(centroid(perce) - [2 2])) < 1e-12);
% HOLES rend le trou comme une région à part entière.
assert(abs(area(holes(perce)) - 4) < 1e-12);

% Deux morceaux séparés : deux régions, et l'aire s'ajoute.
deux = polyshape({[0 1 1 0], [3 4 4 3]}, {[0 0 1 1], [0 0 1 1]});
assert(numregions(deux) == 2);
assert(abs(area(deux) - 2) < 1e-12);
morceaux = regions(deux);
assert(numel(morceaux) == 2);
assert(abs(area(morceaux(1)) - 1) < 1e-12);

%% ------------------------------------------------ TRANSLATE, SCALE, ROTATE
% Déplacer ne change ni l'aire ni le périmètre ; le centre suit.
deplace = translate(carre, [10 -5]);
assert(abs(area(deplace) - area(carre)) < 1e-12);
assert(max(abs(centroid(deplace) - [11 -4])) < 1e-12);
% Dilater d'un facteur k multiplie l'aire par k^2 et le périmètre par k.
grand = scale(carre, 3);
assert(abs(area(grand) - 9 * area(carre)) < 1e-11);
assert(abs(perimeter(grand) - 3 * perimeter(carre)) < 1e-12);
% Tourner ne change rien du tout : c'est ce qui définit une isométrie.
tourne = rotate(carre, 37);
assert(abs(area(tourne) - area(carre)) < 1e-12);
assert(abs(perimeter(tourne) - perimeter(carre)) < 1e-12);
% Et tourner de 360 degrés ramène au point de départ.
assert(max(max(abs(rotate(carre, 360).Vertices - carre.Vertices))) < 1e-12);

%% -------------------------------------------- OPERATIONS BOOLEENNES
% Deux carrés qui se chevauchent d'un carré unité. Les quatre opérations
% se vérifient l'une par l'autre : l'union vaut la somme moins
% l'intersection, et la différence symétrique l'union moins l'intersection.
a = polyshape([0 2 2 0], [0 0 2 2]);
b = polyshape([1 3 3 1], [1 1 3 3]);
assert(abs(area(intersect(a, b)) - 1) < 1e-9);
assert(abs(area(union(a, b)) - 7) < 1e-9);
assert(abs(area(subtract(a, b)) - 3) < 1e-9);
assert(abs(area(subtract(b, a)) - 3) < 1e-9);
assert(abs(area(xor(a, b)) - 6) < 1e-9);
assert(abs(area(union(a, b)) - (area(a) + area(b) - area(intersect(a, b)))) < 1e-9);
assert(overlaps(a, b));

% Deux carrés disjoints : rien en commun, et l'union garde les deux.
c = polyshape([10 11 11 10], [10 10 11 11]);
assert(area(intersect(a, c)) < 1e-12);
assert(abs(area(union(a, c)) - (area(a) + area(c))) < 1e-9);
assert(abs(area(subtract(a, c)) - area(a)) < 1e-9);
assert(~overlaps(a, c));

% Un carré dans un autre : l'intersection est le petit, l'union le grand,
% et la différence un carré percé.
grandCarre = polyshape([0 10 10 0], [0 0 10 10]);
petit = polyshape([4 6 6 4], [4 4 6 6]);
assert(abs(area(intersect(grandCarre, petit)) - 4) < 1e-9);
assert(abs(area(union(grandCarre, petit)) - 100) < 1e-9);
troue = subtract(grandCarre, petit);
assert(abs(area(troue) - 96) < 1e-9);
assert(numboundaries(troue) == 2);
assert(~isinterior(troue, 5, 5));
assert(isinterior(troue, 1, 1));

% Un cas non convexe : un L et un carré. L'aire du résultat se calcule à
% la main, et c'est elle qui juge.
enL = polyshape([0 3 3 1 1 0], [0 0 1 1 3 3]);
assert(abs(area(enL) - 5) < 1e-12);
bande = polyshape([0 3 3 0], [0 0 1 1]);
% Les deux figures partagent deux arêtes entières : c'est le cas
% dégénéré, résolu en déplaçant l'une d'un cheveu. Le résultat est donc
% juste à ce déplacement près, non à la précision machine.
assert(abs(area(intersect(enL, bande)) - 3) < 1e-8);
assert(abs(area(subtract(enL, bande)) - 2) < 1e-8);

% Une région vide se combine sans erreur.
vide = polyshape();
assert(area(vide) == 0);
assert(abs(area(union(a, vide)) - area(a)) < 1e-9);
assert(area(intersect(a, vide)) < 1e-12);
assert(abs(area(subtract(a, vide)) - area(a)) < 1e-9);

% Deux carrés qui partagent exactement une arête : l'aire de la réunion
% est celle des deux, et rien ne leur est commun.
colles = polyshape([2 4 4 2], [0 0 2 2]);
assert(abs(area(union(a, colles)) - 8) < 1e-8);
assert(area(intersect(a, colles)) < 1e-8);

%% --------------------------------------- ADDBOUNDARY, RMBOUNDARY, CONVHULL
ajoute = addboundary(polyshape([0 1 1 0], [0 0 1 1]), [3 4 4 3], [0 0 1 1]);
assert(numboundaries(ajoute) == 2);
assert(abs(area(ajoute) - 2) < 1e-12);
assert(numboundaries(rmboundary(ajoute, 2)) == 1);
% L'enveloppe convexe d'un L est un triangle rectangle, dont l'aire est
% plus grande que celle du L.
enveloppe = convhull(enL);
assert(area(enveloppe) > area(enL));
assert(abs(area(enveloppe) - area(polyshape([0 3 3 1 0], [0 0 1 3 3]))) < 1e-9);


%% ------------------------------------------------ COLLECT et HORNER
% Regrouper n'est pas simplifier : on développe, puis on rassemble ce qui
% porte la même puissance. Le résultat est une forme canonique, donc deux
% écritures d'un même polynôme y deviennent identiques.
syms x
assert(strcmp(char(collect((x + 1)^2)), char(collect(x^2 + 2*x + 1))));
assert(strcmp(char(collect(x*(x + 2) - x^2)), '2*x'));
assert(strcmp(char(collect((x - 1)*(x + 1))), 'x^2 - 1'));
% Ce qui est canonique se compare : deux expressions égales le montrent.
assert(strcmp(char(collect((x + 2)^3)), char(collect(x^3 + 6*x^2 + 12*x + 8))));

% HORNER emboîte les puissances. La forme change, la valeur non : c'est
% ce qu'on peut vérifier sans rien connaître de l'écriture produite.
polynome = x^3 + 2*x^2 + 3*x + 4;
emboite = horner(polynome);
for essai = [-2 -0.5 0 1 3.7]
    assert(abs(double(subs(emboite, x, essai)) - ...
               double(subs(polynome, x, essai))) < 1e-12);
end
% Et la forme est bien emboîtée : elle ne porte plus de puissance.
assert(isempty(strfind(char(emboite), '^')));

%% ------------------------------------------------------------ FACTOR
% Le produit des facteurs vaut toujours l'expression de départ : c'est ce
% qu'une factorisation promet, et c'est vérifiable sans connaître les
% facteurs.
for expression = {x^2 - 1, x^2 - 3*x + 2, 2*x^2 - 6*x + 4, x^3 - x, ...
                  x^2 + 2*x + 1, 6*x^2 - 5*x + 1}
    f = expression{1};
    decompose = factor(f);
    for essai = [-3 -1 0 0.5 2 7]
        assert(abs(double(subs(decompose, x, essai)) - ...
                   double(subs(f, x, essai))) < 1e-9);
    end
end
% Les racines rationnelles sont trouvées exactement : x^2 - 3x + 2 a pour
% racines 1 et 2, et la factorisation doit les montrer.
assert(abs(double(subs(factor(x^2 - 3*x + 2), x, 1))) < 1e-12);
assert(abs(double(subs(factor(x^2 - 3*x + 2), x, 2))) < 1e-12);
% Un polynôme sans racine rationnelle est rendu tel quel : le dire vaut
% mieux que prétendre avoir fini.
irreductible = factor(x^2 + 1);
assert(abs(double(subs(irreductible, x, 3)) - 10) < 1e-12);

% Le théorème des racines rationnelles trouve ce qui existe et rien
% d'autre : 6x^2 - 5x + 1 a pour racines 1/2 et 1/3, que seul un quotient
% de diviseurs peut donner.
racines = matlibre_sym_racines_rationnelles([6 -5 1]);
assert(numel(racines) == 2);
assert(abs(min(racines) - 1/3) < 1e-12);
assert(abs(max(racines) - 1/2) < 1e-12);
% Un polynôme sans racine rationnelle n'en rend aucune.
assert(isempty(matlibre_sym_racines_rationnelles([1 0 1])));
assert(isempty(matlibre_sym_racines_rationnelles([1 0 0 0 1])));
% Les multiplicités sont rendues autant de fois qu'elles comptent.
assert(isequal(matlibre_sym_racines_rationnelles([1 -2 1]), [1 1]));

%% ----------------------------------------------------------- NUMDEN
[n1, d1] = numden(sym(1) / x);
assert(abs(double(subs(n1, x, 5)) - 1) < 1e-12);
assert(abs(double(subs(d1, x, 5)) - 5) < 1e-12);
% Une somme de fractions se met au même dénominateur : le quotient rendu
% doit valoir l'expression de départ partout.
expression = 1/x + 1/(x + 1);
[n2, d2] = numden(expression);
for essai = [0.5 2 3.3 -4]
    attendu = 1/essai + 1/(essai + 1);
    assert(abs(double(subs(n2, x, essai)) / double(subs(d2, x, essai)) - attendu) < 1e-9);
end
% Une expression sans division a pour dénominateur un.
[~, d3] = numden(x^2 + 1);
assert(double(d3) == 1);
% Une puissance négative renverse la fraction.
[n4, d4] = numden(x^(-2));
assert(double(subs(n4, x, 3)) == 1);
assert(abs(double(subs(d4, x, 3)) - 9) < 1e-12);

%% --------------------------------------------------------- CHILDREN
enfants = children(x + 1);
assert(numel(enfants) == 2);
assert(strcmp(char(enfants{1}), 'x'));
assert(double(enfants{2}) == 1);
% Un nombre et une variable se rendent eux-mêmes : ils n'ont pas
% d'opérateur de tête.
assert(numel(children(x)) == 1);
assert(strcmp(char(children(x){1}), 'x'));
assert(double(children(sym(7)){1}) == 7);
% Une fonction rend son argument.
assert(strcmp(char(children(sin(x)){1}), 'x'));

%% --------------------------------------------------------- VPASOLVE
% VPASOLVE résout ce que SOLVE ne sait pas : x = cos(x) n'a pas de
% solution en forme close, mais elle existe et vaut 0.739085...
pointFixe = double(vpasolve(cos(x) - x, x, 1));
assert(abs(pointFixe - 0.7390851332151607) < 1e-9);
assert(abs(cos(pointFixe) - pointFixe) < 1e-12);
% Sur un polynôme, il rend toutes les racines, exactement celles de ROOTS.
deuxRacines = vpasolve(x^2 - 2, x);
valeurs = sort([double(deuxRacines{1}), double(deuxRacines{2})]);
assert(max(abs(valeurs - [-sqrt(2) sqrt(2)])) < 1e-12);
% Le point de départ choisit la racine quand il y en a plusieurs.
assert(abs(double(vpasolve(x^2 - 4, x, 1.5)) - 2) < 1e-9);
assert(abs(double(vpasolve(x^2 - 4, x, -1.5)) + 2) < 1e-9);
% Une équation transcendante balayée sans point de départ trouve ses
% racines : sin annule en 0, pi, -pi, 2pi...
racinesSin = vpasolve(sin(x), x);
assert(iscell(racinesSin));
trouvees = sort(cellfun(@double, racinesSin));
assert(any(abs(trouvees) < 1e-9));
assert(any(abs(trouvees - pi) < 1e-6));

%% ------------------------------------------ PARTFRAC, ISOLATE, REWRITE
% Une décomposition en éléments simples ne change pas la fonction : c'est
% la seule chose à vérifier, et elle se vérifie en quelques points.
for expression = {1/(x^2 - 3*x + 2), 1/(x*(x + 1)), (x + 1)/(x^2 + 3*x + 2), ...
                  1/(x - 1)^2, (x^2 + 1)/(x^2 - 1)}
    decomposee = partfrac(expression{1});
    for essai = [3 5 7.5 -4]
        assert(abs(double(subs(decomposee, x, essai)) - ...
                   double(subs(expression{1}, x, essai))) < 1e-8);
    end
end
% La forme obtenue est bien une somme de termes simples : chaque
% dénominateur ne porte plus qu'une racine.
assert(~isempty(strfind(char(partfrac(1/(x^2 - 3*x + 2))), 'x - 1')));
assert(~isempty(strfind(char(partfrac(1/(x^2 - 3*x + 2))), 'x - 2')));
% Une expression sans dénominateur en x se rend telle quelle.
assert(abs(double(subs(partfrac(x + 1), x, 3)) - 4) < 1e-12);

% ISOLATE défait les opérations une à une. La solution rendue doit annuler
% l'équation de départ : c'est ce qui la définit.
for cas = {2*x + 3, x^2 - 4, 3*x, x/2 - 1, sqrt(x) - 3, exp(x) - 5, 5 - x, 10/x - 2}
    resolue = isolate(cas{1}, x);
    % LHS et RHS ouvrent l'équation : à gauche l'inconnue seule, à droite
    % sa valeur. Sans eux il faudrait descendre dans l'arbre à la main.
    assert(strcmp(char(lhs(resolue)), 'x'));
    valeur = double(rhs(resolue));
    assert(abs(double(subs(cas{1}, x, valeur))) < 1e-9);
end
% Les deux refusent ce qui n'est pas une équation.
refuseMembre = false;
try
    rhs(x + 1);
catch
    refuseMembre = true;
end
assert(refuseMembre);
% Une inconnue qui paraît deux fois ne se défait pas : ISOLATE le dit.
refuseIsolate = false;
try
    isolate(x^2 + x, x);
catch
    refuseIsolate = true;
end
assert(refuseIsolate);

% REWRITE change la forme, jamais la valeur.
reecritures = {sin(x), 'exp'; cos(x), 'exp'; tan(x), 'exp'; sinh(x), 'exp'; ...
               tanh(x), 'exp'; tan(x), 'sincos'; sin(x), 'tan'; cos(x), 'tan'; ...
               atan(x), 'log'};
for k = 1:size(reecritures, 1)
    reecrite = rewrite(reecritures{k, 1}, reecritures{k, 2});
    for essai = [0.3 0.7 1.2]
        assert(abs(double(subs(reecritures{k, 1}, x, essai)) - ...
                   double(subs(reecrite, x, essai))) < 1e-12);
    end
end
% Et la réécriture a bien eu lieu : la fonction visée y paraît.
assert(~isempty(strfind(char(rewrite(sin(x), 'exp')), 'exp')));
assert(~isempty(strfind(char(rewrite(tan(x), 'sincos')), 'sin')));
% Une cible inconnue est refusée.
refuseCible = false;
try
    rewrite(sin(x), 'inconnu');
catch
    refuseCible = true;
end
assert(refuseCible);

%% ------------- les fonctions élémentaires manquantes du calcul symbolique
% Leurs dérivées doivent coïncider avec une différence finie : c'est ce
% qui prouve la règle de dérivation sans la recopier d'une table.
for fonction = {sinh(x), cosh(x), tanh(x), asin(x), acos(x), atan(x), ...
                log2(x), log10(x)}
    derivee = diff(fonction{1});
    point = 0.4;
    pas = 1e-6;
    approchee = (double(subs(fonction{1}, x, point + pas)) - ...
                 double(subs(fonction{1}, x, point - pas))) / (2 * pas);
    assert(abs(approchee - double(subs(derivee, x, point))) < 1e-8);
end
% Et leur évaluation numérique est celle des fonctions ordinaires.
assert(abs(double(subs(sinh(x), x, 1)) - sinh(1)) < 1e-14);
assert(abs(double(subs(atan(x), x, 2)) - atan(2)) < 1e-14);
assert(abs(double(subs(log10(x), x, 100)) - 2) < 1e-14);

%% ---------------- l'écriture symbolique se lit sans parenthèses inutiles
% Une somme dont le second terme est négatif s'écrit comme une
% soustraction, y compris quand ce terme est un quotient.
assert(strcmp(char(x + sym(-3)), 'x - 3'));
assert(~isempty(strfind(char(partfrac(1/(x^2 - 3*x + 2))), ' - ')));
assert(isempty(strfind(char(partfrac(1/(x^2 - 3*x + 2))), '+ -')));
% Retrancher un terme négatif, c'est ajouter : « x - -1 » ne s'écrit pas.
assert(strcmp(char(x - sym(-1)), 'x + 1'));
% Mais les parenthèses qui portent un sens restent : sans elles, « x/-1 »
% et « x^-1 » se reliraient de travers.
assert(~isempty(strfind(char(x / sym(-1)), '(-1)')));
assert(~isempty(strfind(char(x ^ sym(-1)), '(-1)')));
% Un facteur -1 s'écrit comme un signe, non comme un produit.
assert(strcmp(char(-x), '-x'));
assert(strcmp(char((-x) / sym('y')), '-x/y'));
assert(isempty(strfind(char(-x * sym('y')), '-1*')));
% Deux facteurs de même base font une puissance, et le quotient se
% retranche : c'est ce qui empêche une expression de gonfler.
assert(strcmp(char(x * x), 'x^2'));
assert(strcmp(char(x ^ 2 * x ^ 3), 'x^5'));
assert(strcmp(char(x / x), '1'));
assert(strcmp(char(x - x), '0'));
assert(strcmp(char((x + 1) * (x + 1)), '(x + 1)^2'));
% Le développement continue de rendre la forme etendue.
assert(strcmp(char(expand((x + 1) ^ 2)), 'x^2 + 2*x + 1'));
assert(strcmp(char((x + 1) * 2), '(x + 1)*2'));

%% --------------------------------------------------------- SYMMATRIX
% Une matrice symbolique se manipule comme un tout : « A*B + A » reste
% « A*B + A », et c'est SYMMATRIX2SYM qui descend aux coefficients.
A = symmatrix('A', [2 2]);
B = symmatrix('B', [2 2]);
assert(strcmp(char(A * B + A), 'A*B + A'));
assert(strcmp(char(A'), ['A' char(39)]));
assert(strcmp(char(inv(A)), 'inv(A)'));
assert(strcmp(char(det(A)), 'det(A)'));
assert(isequal(size(A * B), [2 2]));
assert(isequal(size(symmatrix('C', [2 3]) * symmatrix('D', [3 4])), [2 4]));
assert(numel(A) == 4);

% Le developpement nomme les elements A1_1, A1_2, ... et suit l'algebre
% matricielle : le produit devient une somme de produits.
S = symmatrix2sym(A);
assert(strcmp(char(S(1, 1)), 'A1_1'));
assert(strcmp(char(S(2, 1)), 'A2_1'));
carre = symmatrix2sym(A * A);
assert(strcmp(char(carre(1, 1)), 'A1_1^2 + A1_2*A2_1'));
assert(strcmp(char(carre(1, 2)), 'A1_1*A1_2 + A1_2*A2_2'));

% Le determinant et la trace se developpent a la main connue.
assert(strcmp(char(symmatrix2sym(det(A))), 'A1_1*A2_2 - A1_2*A2_1'));
assert(strcmp(char(symmatrix2sym(trace(A))), 'A1_1 + A2_2'));

% L'inverse est un quotient de determinants : aucun pivot n'est suppose
% non nul, ce qui est la seule facon d'inverser sans connaitre les
% valeurs. On le verifie sur la propriete : A*inv(A) vaut l'identite.
produit = symmatrix2sym(A * inv(A));
noms = {'A1_1', 'A1_2', 'A2_1', 'A2_2'};
valeurs = {2, 1, 3, 4};
for i = 1:2
    for j = 1:2
        attendu = double(i == j);
        obtenu = symeval(matlibre_sym_arbre(produit(i, j)), noms, valeurs);
        assert(abs(obtenu - attendu) < 1e-12);
    end
end

% Une puissance entiere se ramene a des produits, et la puissance zero a
% l'identite.
puissance = symmatrix2sym(A ^ 2);
assert(strcmp(char(puissance(1, 1)), 'A1_1^2 + A1_2*A2_1'));
identite = symmatrix2sym(A ^ 0);
assert(strcmp(char(identite(1, 1)), '1') && strcmp(char(identite(1, 2)), '0'));

% Une constante matricielle se calcule vraiment.
C = symmatrix([1 2; 3 4]);
assert(strcmp(char(C), '[1, 2; 3, 4]'));
produitC = symmatrix2sym(C * C);
assert(strcmp(char(produitC(1, 1)), '7'));

% Kronecker multiplie les tailles.
K = symmatrix2sym(kron(symmatrix('P', [1 2]), symmatrix('Q', [2 1])));
assert(isequal(size(K), [2 2]));
assert(strcmp(char(K(2, 2)), 'P1_2*Q2_1'));

% Les tailles sont verifiees a la construction, la ou l'erreur est encore
% lisible.
refuseSomme = false;
try
    symmatrix('A', [2 3]) + symmatrix('B', [3 2]);
catch err
    refuseSomme = strcmp(err.identifier, 'symbolic:symmatrix:Dimensions');
end
assert(refuseSomme);
refuseProduit = false;
try
    symmatrix('A', [2 3]) * symmatrix('B', [2 3]);
catch err
    refuseProduit = strcmp(err.identifier, 'symbolic:symmatrix:Dimensions');
end
assert(refuseProduit);
refuseCarree = false;
try
    det(symmatrix('A', [2 3]));
catch err
    refuseCarree = strcmp(err.identifier, 'symbolic:symmatrix:Carree');
end
assert(refuseCarree);

disp('geometrie et symbolique : toutes les verifications passent');
