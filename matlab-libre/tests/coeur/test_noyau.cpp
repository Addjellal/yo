// test_noyau.cpp — tests unitaires du cœur, sans dépendance externe.
//
// Un test est une fonction qui lève une exception si quelque chose cloche.
// Le programme rend un code non nul dès qu'un test échoue, ce qui suffit à
// ctest.
#include <cctype>
#include <cmath>
#include <cstdio>
#include <functional>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include "matlibre/Affichage.h"
#include "matlibre/AlgebreLineaire.h"
#include "matlibre/Analyseur.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Console.h"
#include "matlibre/EditionLigne.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Lexeur.h"
#include "matlibre/Operations.h"

using namespace matlibre;

namespace {

int echecs = 0;
int total = 0;

void verifier(bool condition, const std::string& description) {
    ++total;
    if (!condition) {
        ++echecs;
        std::cout << "  ECHEC : " << description << "\n";
    }
}

void verifierProche(double obtenu, double attendu, const std::string& description,
                    double tolerance = 1e-9) {
    ++total;
    if (!(std::fabs(obtenu - attendu) <= tolerance)) {
        ++echecs;
        std::cout << "  ECHEC : " << description << " (obtenu " << obtenu << ", attendu "
                  << attendu << ")\n";
    }
}

// Évalue une expression et rend la variable demandée.
Valeur executer(const std::string& code, const std::string& variable) {
    Interpreteur it;
    it.installerBibliotheque();
    std::ostringstream poubelle;
    it.definirSortie(&poubelle);
    it.executerTexte(code, "<test>");
    return it.lireVariable(variable);
}

std::string sortieDe(const std::string& code) {
    Interpreteur it;
    it.installerBibliotheque();
    std::ostringstream tampon;
    it.definirSortie(&tampon);
    it.executerTexte(code, "<test>");
    return tampon.str();
}

void testLexeur() {
    Lexeur l("x = 1 + 2; % commentaire\ny = 'abc';");
    auto jetons = l.analyser();
    verifier(jetons.size() > 8, "le lexeur produit des jetons");
    verifier(jetons[0].genre == Genre::Ident && jetons[0].texte == "x",
             "premier jeton : identificateur x");
    bool trouveLitteral = false;
    for (const auto& j : jetons)
        if (j.genre == Genre::Litteral && j.texte == "abc") trouveLitteral = true;
    verifier(trouveLitteral, "la chaine 'abc' est reconnue");

    // L'apostrophe transpose apres une valeur.
    Lexeur l2("A'");
    auto j2 = l2.analyser();
    verifier(j2[1].genre == Genre::Operateur && j2[1].texte == "'",
             "l'apostrophe apres un identificateur transpose");
}

void testAnalyseur() {
    NoeudPtr bloc = compilerBloc("if x > 1\n  y = 2;\nelse\n  y = 3;\nend", "<test>");
    verifier(bloc->enfants.size() == 1, "un seul noeud pour un if complet");
    verifier(bloc->enfants[0]->type == TypeN::Si, "le noeud est un « si »");
    verifier(bloc->enfants[0]->drapeau, "la branche « else » est signalee");

    UniteCompilee u = compiler("function y = f(x)\n y = x + 1;\nend", "<test>");
    verifier(u.fonctions.size() == 1, "une fonction est reconnue");
    verifier(u.fonctions[0]->nom == "f", "le nom de la fonction est lu");
    verifier(u.fonctions[0]->entrees.size() == 1, "un argument d'entree");
    verifier(u.fonctions[0]->sorties.size() == 1, "une sortie");
}

void testArithmetique() {
    verifierProche(executer("a = 2 + 3 * 4;", "a").scal(), 14, "priorite du produit");
    verifierProche(executer("a = 2 ^ 3 ^ 2;", "a").scal(), 64, "puissance associative a gauche");
    verifierProche(executer("a = -2 ^ 2;", "a").scal(), -4, "unaire moins de priorite inferieure");
    verifierProche(executer("a = 2 ^ -1;", "a").scal(), 0.5, "exposant negatif");
    verifierProche(executer("a = mod(-1, 3);", "a").scal(), 2, "mod suit le signe du diviseur");
    verifierProche(executer("a = rem(-1, 3);", "a").scal(), -1, "rem suit le signe du dividende");
    verifier(executer("a = int8(200);", "a").scal() == 127, "saturation des entiers");
    verifier(executer("a = 1:5;", "a").nelem() == 5, "plage entiere");
    verifier(executer("a = [1 -2];", "a").nelem() == 2, "espace separateur dans les crochets");
    verifier(executer("a = [1 - 2];", "a").nelem() == 1, "espaces des deux cotes : soustraction");
}

void testIndexation() {
    verifierProche(executer("A = [1 2; 3 4]; a = A(2,1);", "a").scal(), 3, "indexation 2-D");
    verifierProche(executer("A = [1 2 3 4]; a = A(end);", "a").scal(), 4, "mot-cle end");
    verifierProche(executer("A = [1 2 3 4]; A(2) = []; a = numel(A);", "a").scal(), 3,
                   "suppression par indexation");
    verifierProche(executer("A = zeros(2); A(3,3) = 1; a = numel(A);", "a").scal(), 9,
                   "croissance automatique");
    verifierProche(executer("A = [1 2 3]; a = sum(A(A > 1));", "a").scal(), 5,
                   "indexation logique");
    verifierProche(executer("c = {1, 'deux'}; a = numel(c);", "a").scal(), 2, "cellule");
    verifier(executer("s.a.b = 3; a = s.a.b;", "a").scal() == 3, "champs imbriques");
}

void testFonctions() {
    verifierProche(executer("f = @(x) x^2; a = f(3);", "a").scal(), 9, "fonction anonyme");
    verifierProche(executer("k = 5; f = @(x) x + k; k = 0; a = f(1);", "a").scal(), 6,
                   "capture par valeur");
    verifierProche(executer("a = 0; for k = 1:4, a = a + k; end", "a").scal(), 10,
                   "boucle for");
    verifierProche(executer("a = 0; k = 0; while k < 3, k = k + 1; a = a + k; end", "a").scal(),
                   6, "boucle while");
    verifierProche(executer("a = 0; try, error('x:y','boum'); catch e, a = 1; end", "a").scal(),
                   1, "try / catch");
    verifier(executer("try, error('x:y','boum'); catch e, id = e.identifier; end", "id")
                 .versTexte() == "x:y",
             "identifiant d'erreur conserve");
    verifierProche(executer("s = 0; switch 2, case 1, s = 10; case 2, s = 20; end", "s").scal(),
                   20, "switch");
}

void testAlgebre() {
    Valeur A = executer("A = [4 1; 1 3];", "A");
    verifierProche(determinantMatrice(A).scal(), 11, "determinant");
    Valeur inverse = inverseMatrice(A);
    Valeur produit = produitMatrice(A, inverse);
    verifierProche(produit.re[0], 1, "A * inv(A) = I (coin superieur gauche)");
    verifierProche(produit.re[1], 0, "A * inv(A) = I (hors diagonale)", 1e-12);
    Valeur valeurs;
    valeursPropres(A, valeurs, nullptr);
    verifierProche(valeurs.re[0] + valeurs.re[1], 7, "trace = somme des valeurs propres");
    Valeur q, r;
    factorisationQR(A, q, r, false);
    Valeur reconstruit = produitMatrice(q, r);
    verifierProche(reconstruit.re[0], 4, "Q * R restitue A");
    verifierProche(normeMatrice(executer("v = [3 4];", "v"), Valeur::vide()).scal(), 5,
                   "norme euclidienne");
}

void testTexte() {
    verifier(executer("a = upper('abc');", "a").versTexte() == "ABC", "upper");
    verifier(executer("a = sprintf('%5.2f', pi);", "a").versTexte() == " 3.14", "sprintf");
    verifier(executer("a = sprintf('%d-%d ', [1 2 3 4]);", "a").versTexte() == "1-2 3-4 ",
             "sprintf recycle le format");
    verifier(executer("a = strrep('abcabc','b','X');", "a").versTexte() == "aXcaXc", "strrep");
    verifier(executer("a = strjoin({'a','b'}, '-');", "a").versTexte() == "a-b", "strjoin");
    verifier(executer("a = num2str(3.14159, 4);", "a").versTexte() == "3.142", "num2str");
    verifierProche(executer("a = str2double('2.5');", "a").scal(), 2.5, "str2double");
}

void testAffichage() {
    verifier(sortieDe("x = 5") == "x = 5\n\n", "affichage d'un scalaire");
    std::string sortie = sortieDe("disp([1 2])");
    verifier(sortie.find("1") != std::string::npos && sortie.find("2") != std::string::npos,
             "disp d'un vecteur");
    // les en-têtes et les formes de la fenêtre de commande de MATLAB
    const std::string x = "\xC3\x97";
    verifier(sortieDe("C = {1, 'deux'; [1 2 3], {2}}") ==
                 "C =\n\n  2" + x + "2 cell array\n\n    {[    1]}    {'deux'  }\n"
                 "    {[1 2 3]}    {1" + x + "1 cell}\n\n",
             "une cellule : nombres a droite dans leurs crochets, textes a gauche");
    verifier(sortieDe("D = {'Carrot'; 'Egg'}") ==
                 "D =\n\n  2" + x + "1 cell array\n\n    {'Carrot'}\n    {'Egg'   }\n\n",
             "les cases d'une colonne a la meme largeur");
    verifier(sortieDe("disp({1, 'a'})") == "    {[1]}    {'a'}\n", "disp d'une cellule, sans en-tete");
    verifier(sortieDe("E = cell(1, 0)") == "E =\n\n  1" + x + "0 empty cell array\n\n",
             "une cellule vide");
    verifier(sortieDe("s.a = 1; s.beta = 'x'; s") ==
                 "s =\n\n  struct with fields:\n\n       a: 1\n    beta: 'x'\n\n",
             "une structure : l'en-tete, les noms cales a droite");
    verifier(sortieDe("s.c = {'a', 'bb'}; s.t = struct('u', 1); s.w = zeros(3); disp(s)") ==
                 "    c: {'a'  'bb'}\n    t: [1" + x + "1 struct]\n    w: [3" + x +
                 "3 double]\n",
             "les champs resumes, et disp sans en-tete");
    verifier(sortieDe("q = struct()") == "q =\n\n  struct with no fields.\n\n",
             "une structure sans champ");
    verifier(sortieDe("t = struct('a', {1, 2})") ==
                 "t =\n\n  1" + x + "2 struct array with fields:\n\n    a\n\n",
             "un tableau de structures");
    verifier(sortieDe("u = uint8(7)") == "u =\n\n  uint8\n\n   7\n\n",
             "un entier dit sa classe");
    verifier(sortieDe("v = true") == "v =\n\n  logical\n\n   1\n\n",
             "un logique dit sa classe");
    verifier(sortieDe("disp(true)") == "   1\n", "disp d'un logique");
    verifier(sortieDe("a = int8([1 2 3])") ==
                 "a =\n\n  1" + x + "3 int8 row vector\n\n   1   2   3\n\n",
             "un vecteur d'entiers, serre");
    verifier(sortieDe("c = [true; false]") ==
                 "c =\n\n  2" + x + "1 logical array\n\n   1\n   0\n\n",
             "un tableau logique");
    verifier(sortieDe("d = ['abc'; 'def']") ==
                 "d =\n\n  2" + x + "3 char array\n\n    'abc'\n    'def'\n\n",
             "une matrice de caracteres");
    verifier(sortieDe("e = [\"a\" \"bb\"; \"ccc\" \"d\"]") ==
                 "e =\n\n  2" + x + "2 string array\n\n    \"a\"      \"bb\"\n"
                 "    \"ccc\"    \"d\"\n\n",
             "un tableau de chaines, en colonnes");
    verifier(sortieDe("z = zeros(0, 3)") == "z =\n\n  0" + x + "3 empty double matrix\n\n",
             "un tableau vide dit ses dimensions");
    verifier(sortieDe("w = []") == "w = []\n\n", "[] tient sur une ligne");
    verifier(sortieDe("M = containers.Map({'a', 'b'}, {1, 2})") ==
                 "M =\n\n  Map with properties:\n\n        Count: 2\n      KeyType: char\n"
                 "    ValueType: any\n\n",
             "une carte montre ses proprietes, pas son identifiant");
    sortie = sortieDe("x = ones(2, 2, 2)");
    verifier(sortie.rfind("x(:,:,1) =\n\n", 0) == 0 && sortie.find("x(:,:,2) =") != std::string::npos,
             "les pages d'un tableau a trois dimensions portent le nom de la variable");
    sortie = sortieDe("F = cell(1, 1, 2)");
    verifier(sortie.find("  1" + x + "1" + x + "2 cell array") != std::string::npos &&
                 sortie.find("F(:,:,2) =") != std::string::npos,
             "une cellule a trois dimensions, page par page");
    verifier(sortieDe("format compact\nC = {1, 'a'}") ==
                 "C =\n  1" + x + "2 cell array\n    {[1]}    {'a'}\n",
             "format compact : sans lignes blanches");
}

void testSignal() {
    Valeur y = executer("y = fft([1 2 3 4]);", "y");
    verifierProche(y.re[0], 10, "fft : composante continue");
    verifierProche(y.re[1], -2, "fft : partie reelle du premier harmonique");
    verifierProche(y.im[1], 2, "fft : partie imaginaire du premier harmonique");
    Valeur z = executer("z = real(ifft(fft([1 2 3 4 5])));", "z");
    verifierProche(z.re[4], 5, "ifft(fft(x)) = x pour une longueur impaire");
}

void testErreurs() {
    bool leve = false;
    try {
        executer("a = inconnue_xyz();", "a");
    } catch (const ErreurMatlab& e) {
        leve = e.identifiant == "MATLAB:UndefinedFunction";
    }
    verifier(leve, "fonction inconnue : identifiant MATLAB:UndefinedFunction");

    leve = false;
    try {
        executer("A = [1 2]; a = A(5);", "a");
    } catch (const ErreurMatlab& e) {
        leve = e.identifiant == "MATLAB:badsubscript";
    }
    verifier(leve, "indice hors bornes : identifiant MATLAB:badsubscript");

    leve = false;
    try {
        executer("a = [1 2] * [3 4];", "a");
    } catch (const ErreurMatlab& e) {
        leve = e.identifiant == "MATLAB:innerdim";
    }
    verifier(leve, "dimensions incompatibles : identifiant MATLAB:innerdim");
}

// « Did you mean: » : le nom connu le plus proche, et la commande
// corrigée que la console propose.
void testSuggestion() {
    Interpreteur it;
    it.installerBibliotheque();
    std::ostringstream poubelle;
    it.definirSortie(&poubelle);
    it.executerTexte("maVariable = 3;", "<test>");
    verifier(it.nomProche("plott") == "plot", "plott -> plot (une lettre de trop), non plot3");
    verifier(it.nomProche("lenght") == "length", "lenght -> length (transposition)");
    verifier(it.nomProche("dsip") == "disp", "dsip -> disp (transposition, nom court)");
    verifier(it.nomProche("mavariable") == "maVariable", "la casse seule : distance nulle");
    verifier(it.nomProche("maVariabel") == "maVariable", "une variable se propose aussi");
    verifier(it.nomProche("zzqqxxww").empty(), "rien d'assez proche : aucune proposition");
    verifier(it.nomProche("x").empty(), "un nom d'une lettre : aucune proposition");

    // La commande corrigée remplace le nom fautif, et lui seul : ni le
    // texte entre apostrophes, ni le champ qui porte le même nom.
    auto correction = [&](const std::string& commande) {
        try {
            it.executerTexte(commande, "<console>");
        } catch (const ErreurMatlab& e) {
            return it.correctionCommande(e, commande + "\n");
        }
        return std::string("(pas d'erreur)");
    };
    verifier(correction("dispp('dispp')") == "disp('dispp')",
             "le texte entre apostrophes est laissé");
    verifier(correction("s.plott = 1; y = plott(2);") == "s.plott = 1; y = plot(2);",
             "le champ homonyme est laissé");
    verifier(correction("y = maVariabel + 1;") == "y = maVariable + 1;",
             "une variable mal tapée est corrigée");
    verifier(correction("eval('dispp(1)')").empty(),
             "le nom fautif n'est pas dans la commande : rien à proposer");
    verifier(correction("y = [1 2] * [3 4];").empty(),
             "une erreur qui n'est pas un nom inconnu : rien à proposer");
    verifier(correction("qqzzxxw(1)").empty(), "aucun nom proche : rien à proposer");

    // Le message reste celui de MATLAB : la proposition n'y entre pas.
    try {
        it.executerTexte("plott(1)", "<console>");
    } catch (const ErreurMatlab& e) {
        verifier(e.message == "Unrecognized function or variable 'plott'.",
                 "le message d'erreur ne porte pas la proposition");
        verifier(e.nomInconnu == "plott", "l'erreur garde le nom inconnu");
    }
}

// L'édition de la ligne de commande, sans terminal : les octets que
// produisent les touches, puis ce que l'éditeur en fait.
std::vector<Evenement> decoder(const std::string& octets) {
    DecodeurTouches d;
    std::vector<Evenement> v;
    for (unsigned char c : octets) d.pousser(c, v);
    Evenement e;
    if (d.vider(e)) v.push_back(e);
    return v;
}

// Tape OCTETS dans un éditeur neuf et rend la ligne obtenue.
std::string taper(EditeurLigne& ed, const std::string& octets) {
    for (const Evenement& e : decoder(octets)) ed.traiter(e);
    return ed.ligne();
}

void testEditionLigne() {
    auto touches = [](const std::string& octets) {
        std::vector<Touche> t;
        for (const Evenement& e : decoder(octets)) t.push_back(e.touche);
        return t;
    };
    verifier(touches("\x1b[A\x1b[B\x1b[C\x1b[D") ==
                 std::vector<Touche>{Touche::Haut, Touche::Bas, Touche::Droite, Touche::Gauche},
             "les flèches en CSI");
    verifier(touches("\x1bOH\x1bOF\x1b[1~\x1b[4~\x1b[3~") ==
                 std::vector<Touche>{Touche::Debut, Touche::Fin, Touche::Debut, Touche::Fin,
                                     Touche::Supprimer},
             "Début, Fin et Suppr sous leurs diverses formes");
    verifier(touches("\x1b[1;5C\x1b[1;5D") ==
                 std::vector<Touche>{Touche::MotDroite, Touche::MotGauche},
             "Ctrl-flèche va par mot");
    verifier(touches("\x1b") == std::vector<Touche>{Touche::Echap},
             "un ESC sans suite est la touche Échap");
    verifier(touches("\x1by") == std::vector<Touche>{Touche::Echap, Touche::Texte},
             "Échap suivi aussitôt d'une lettre : la lettre n'est pas perdue");
    verifier(touches("a\r\nb\n") == std::vector<Touche>{Touche::Texte, Touche::Entree,
                                                         Touche::Ignoree, Touche::Texte,
                                                         Touche::Entree},
             "« \\r\\n » ne valide qu'une fois, « \\n » seul valide");
    const auto e = decoder("\xc3\xa9");
    verifier(e.size() == 1 && e[0].touche == Touche::Texte && e[0].texte == "\xc3\xa9",
             "un caractère UTF-8 de deux octets est une seule touche");
    verifier(touches("\x7f\x03\x04\t\r") ==
                 std::vector<Touche>{Touche::RetourArriere, Touche::Interrompre,
                                     Touche::FinFichier, Touche::Tabulation, Touche::Entree},
             "les touches de contrôle");

    EditeurLigne ed;
    ed.commencer(">> ");
    verifier(taper(ed, "x = 41\x7f" "2") == "x = 42", "retour arrière puis frappe");
    ed.commencer(">> ");
    // « été » : le curseur recule de deux caractères, non de deux octets.
    verifier(taper(ed, "'\xc3\xa9t\xc3\xa9'\x1b[D\x1b[D" "X") == "'\xc3\xa9tX\xc3\xa9'",
             "le curseur se déplace par caractère, accents compris");
    ed.commencer(">> ");
    verifier(taper(ed, "abc\x7f\x7f\x7f\x7f") == "", "retour arrière en début de ligne : rien");
    ed.commencer(">> ");
    verifier(taper(ed, "a = bb + ccc\x17") == "a = bb + ", "Ctrl-W coupe le mot précédent");
    ed.commencer(">> ");
    verifier(taper(ed, "abcdef\x1b[D\x1b[D\x0b") == "abcd", "Ctrl-K coupe jusqu'au bout");
    ed.commencer(">> ");
    verifier(taper(ed, "abcdef\x1b[D\x1b[D\x15") == "ef", "Ctrl-U coupe jusqu'au début");
    ed.commencer(">> ");
    verifier(taper(ed, "abc\x01X\x05Y") == "XabcY", "Ctrl-A et Ctrl-E");
    ed.commencer(">> ");
    verifier(taper(ed, "abc\x1b") == "", "Échap efface la ligne, comme dans MATLAB");
    ed.commencer(">> ", "plot(1:3)");
    verifier(ed.ligne() == "plot(1:3)" && ed.curseur() == 9,
             "une ligne qui commence pré-remplie, le curseur au bout");
    ed.commencer(">> ");
    verifier(ed.traiter(decoder("\x04")[0]) == EditeurLigne::Issue::Fin,
             "Ctrl-D sur une ligne vide : fin de la session");
    ed.commencer(">> ");
    verifier(ed.traiter(decoder("\x03")[0]) == EditeurLigne::Issue::Abandonner,
             "Ctrl-C abandonne la ligne");

    // L'historique, filtré par ce qu'on a tapé, comme dans MATLAB.
    ed.definirHistorique({"plot(1:3)", "x = 1", "plot(4:6)", "y = 2", "y = 2"});
    verifier(ed.historique().size() == 4, "deux lignes identiques de suite n'en font qu'une");
    ed.commencer(">> ");
    verifier(taper(ed, "\x1b[A") == "y = 2", "↑ sur une ligne vide : la dernière commande");
    verifier(taper(ed, "\x1b[A") == "plot(4:6)", "↑ encore : la précédente");
    ed.commencer(">> ");
    verifier(taper(ed, "pl\x1b[A") == "plot(4:6)", "« pl » puis ↑ : le dernier plot");
    verifier(taper(ed, "\x1b[A") == "plot(1:3)", "↑ encore : le plot d'avant, x = 1 sauté");
    verifier(taper(ed, "\x1b[A") == "plot(1:3)", "rien de plus ancien : la ligne reste");
    verifier(taper(ed, "\x1b[B\x1b[B") == "pl", "↓ jusqu'en bas : ce qu'on avait tapé revient");
    ed.ajouterHistorique("   ");
    verifier(ed.historique().size() == 4, "une ligne blanche n'entre pas dans l'historique");

    // La complétion : aussi loin que les choix s'accordent, puis les choix.
    ed.definirCompleteur([](const std::string& l, std::size_t c, std::size_t& debut) {
        debut = c;
        while (debut > 0 && std::isalpha((unsigned char)l[debut - 1])) --debut;
        const std::string mot = l.substr(debut, c - debut);
        std::vector<std::string> v;
        for (const char* n : {"cumsum", "cumprod", "cummax", "linspace"})
            if (std::string(n).compare(0, mot.size(), mot) == 0) v.push_back(n);
        return v;
    });
    ed.commencer(">> ");
    verifier(taper(ed, "y = lin\t") == "y = linspace", "un seul choix : complété");
    ed.commencer(">> ");
    verifier(taper(ed, "cu\t") == "cum", "plusieurs : leur préfixe commun");
    verifier(ed.prendreChoix().empty(), "le préfixe a avancé : rien à montrer encore");
    taper(ed, "\t");
    verifier(ed.prendreChoix().size() == 3, "Tab sans rien à ajouter : les trois choix");

    // Le rendu : une ligne plus large que le terminal défile autour du
    // curseur au lieu de déborder.
    ed.commencer(">> ");
    taper(ed, std::string(100, 'a') + "\x01" + "\x1b[C\x1b[C");
    const std::string r = ed.rendu(40);
    verifier(r.find(std::string(36, 'a')) != std::string::npos &&
                 r.find(std::string(37, 'a')) == std::string::npos,
             "ligne de 100 caractères sur 40 colonnes : 36 montrés");
    verifier(r.find("\x1b[5C") != std::string::npos, "le curseur au troisième caractère");
}

}  // namespace

int main() {
    matlibre::ConsoleUtf8 console;
    struct Cas {
        const char* nom;
        void (*fonction)();
    };
    const Cas cas[] = {
        {"lexeur", testLexeur},         {"analyseur", testAnalyseur},
        {"arithmetique", testArithmetique}, {"indexation", testIndexation},
        {"fonctions", testFonctions},   {"algebre", testAlgebre},
        {"texte", testTexte},           {"affichage", testAffichage},
        {"signal", testSignal},         {"erreurs", testErreurs},
        {"suggestion", testSuggestion}, {"edition de ligne", testEditionLigne},
    };
    for (const auto& c : cas) {
        std::cout << "[" << c.nom << "]\n";
        try {
            c.fonction();
        } catch (const ErreurMatlab& e) {
            ++echecs;
            std::cout << "  EXCEPTION : " << e.message << "\n";
        } catch (const std::exception& e) {
            ++echecs;
            std::cout << "  EXCEPTION : " << e.what() << "\n";
        }
    }
    std::cout << "\n" << (total - echecs) << " / " << total << " verifications passees\n";
    return echecs == 0 ? 0 : 1;
}
