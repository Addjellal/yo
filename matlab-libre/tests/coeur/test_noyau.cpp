// test_noyau.cpp — tests unitaires du cœur, sans dépendance externe.
//
// Un test est une fonction qui lève une exception si quelque chose cloche.
// Le programme rend un code non nul dès qu'un test échoue, ce qui suffit à
// ctest.
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
