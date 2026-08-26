// Tests.cpp — assertions et exécution des suites de tests.
#include <algorithm>
#include <cmath>
#include <filesystem>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace fs = std::filesystem;

namespace matlibre {

std::string formatMatlab(const std::string& format, const std::vector<Valeur>& args,
                         std::size_t debut);

namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

// Écart maximal entre deux tableaux, en valeur absolue.
double ecartMaximal(const Valeur& a, const Valeur& b) {
    if (a.nelem() != b.nelem()) return INFINITY;
    double m = 0;
    for (std::size_t k = 0; k < a.nelem(); ++k) {
        double x = a.re.empty() ? 0 : a.re[k];
        double y = b.re.empty() ? 0 : b.re[k];
        if (std::isnan(x) && std::isnan(y)) continue;
        m = std::max(m, std::fabs(x - y));
        double xi = a.im.empty() ? 0 : a.im[k];
        double yi = b.im.empty() ? 0 : b.im[k];
        m = std::max(m, std::fabs(xi - yi));
    }
    return m;
}

bool memesTextes(const Valeur& a, const Valeur& b) {
    return (a.estTexte() || a.estChaine()) && (b.estTexte() || b.estChaine()) &&
           a.versTexte() == b.versTexte();
}

FONCTION(fnAssert) {
    INUTILISE
    exigerArguments(args, 1, 0, "assert");
    // Forme MATLAB : assert(condition, message, ...)
    if (args.size() == 1 || (args.size() >= 2 && (args[1].estTexte() || args[1].estChaine()) &&
                             !(args[0].estTexte() || args[0].estChaine()))) {
        if (args[0].vrai()) return {};
        std::string message = args.size() > 1 ? formatMatlab(args[1].versTexte(), args, 2)
                                              : "Assertion failed.";
        erreur("MATLAB:assertion:failed", message);
    }
    // Forme Octave : assert(observe, attendu [, tolerance])
    const Valeur& observe = args[0];
    const Valeur& attendu = args[1];
    double tolerance = args.size() > 2 ? args[2].scal() : 0.0;
    if (memesTextes(observe, attendu)) return {};
    if (observe.classe == Classe::Cellule || observe.estStructure()) {
        std::vector<Valeur> a = {observe, attendu};
        auto egal = it.appeler("isequal", a, 1);
        if (!egal.empty() && egal[0].vrai()) return {};
        erreur("MATLAB:assertion:failed", "Assertion failed: values differ.");
    }
    if (!memeDims(observe.dims, attendu.dims) && observe.nelem() != attendu.nelem())
        erreur("MATLAB:assertion:failed",
               formater("Assertion failed: sizes differ (%s vs %s).",
                        texteDims(observe.dims).c_str(), texteDims(attendu.dims).c_str()));
    double ecart = ecartMaximal(observe, attendu);
    double limite = std::fabs(tolerance);
    if (tolerance < 0) {
        double echelle = 0;
        for (std::size_t k = 0; k < attendu.nelem(); ++k)
            echelle = std::max(echelle, std::fabs(attendu.re[k]));
        limite = std::fabs(tolerance) * std::max(echelle, 1e-300);
    }
    if (ecart <= limite) return {};
    erreur("MATLAB:assertion:failed",
           formater("Assertion failed: maximum difference %g exceeds tolerance %g.", ecart,
                    limite));
}

FONCTION(fnAssertEqual) {
    INUTILISE
    exigerArguments(args, 2, 3, "assertEqual");
    std::vector<Valeur> a = {args[0], args[1]};
    auto egal = it.appeler("isequal", a, 1);
    if (!egal.empty() && egal[0].vrai()) return {};
    erreur("MATLAB:assertion:failed",
           args.size() > 2 ? args[2].versTexte() : "assertEqual failed: values are not equal.");
}

FONCTION(fnAssertPresque) {
    INUTILISE
    exigerArguments(args, 2, 3, "assertAlmostEqual");
    double tolerance = args.size() > 2 ? args[2].scal() : 1e-10;
    double ecart = ecartMaximal(args[0], args[1]);
    if (ecart <= tolerance) return {};
    erreur("MATLAB:assertion:failed",
           formater("assertAlmostEqual failed: difference %g exceeds %g.", ecart, tolerance));
}

FONCTION(fnAssertErreur) {
    INUTILISE
    exigerArguments(args, 1, 2, "assertError");
    std::string identifiantAttendu = args.size() > 1 ? args[1].versTexte() : "";
    std::vector<Valeur> aucun;
    try {
        it.appelerValeur(args[0], aucun, 0);
    } catch (const ErreurMatlab& e) {
        if (identifiantAttendu.empty() || e.identifiant == identifiantAttendu) return {};
        erreur("MATLAB:assertion:failed",
               "assertError: expected identifier '" + identifiantAttendu + "', got '" +
                   e.identifiant + "'.");
    }
    erreur("MATLAB:assertion:failed", "assertError: no error was raised.");
}

FONCTION(fnFail) {
    INUTILISE
    erreur("MATLAB:assertion:failed",
           args.empty() ? "Test failed." : args[0].versTexte());
}

// runtests(dossier) : exécute tous les fichiers « test_*.m » ou « *_test.m ».
FONCTION(fnRuntests) {
    INUTILISE
    std::string cible = args.empty() ? "." : args[0].versTexte();
    std::vector<std::string> fichiers;
    std::error_code ec;
    // Le dossier testé rejoint le chemin de recherche : les tests y
    // rangent leurs fonctions et classes d'appui.
    if (fs::is_directory(cible, ec)) it.ajouterChemin(cible, true);
    else it.ajouterChemin(fs::path(cible).parent_path().string(), true);
    if (fs::is_directory(cible, ec)) {
        for (const auto& e : fs::directory_iterator(cible, ec)) {
            if (!e.is_regular_file()) continue;
            std::string nom = e.path().filename().string();
            if (nom.size() < 3 || nom.substr(nom.size() - 2) != ".m") continue;
            if (nom.rfind("test_", 0) == 0 || nom.find("_test.m") != std::string::npos)
                fichiers.push_back(e.path().string());
        }
    } else {
        fichiers.push_back(cible);
    }
    std::sort(fichiers.begin(), fichiers.end());
    int reussis = 0, echoues = 0;
    std::vector<std::string> messages;
    for (const auto& f : fichiers) {
        std::string nom = fs::path(f).stem().string();
        try {
            it.executerFichier(f);
            ++reussis;
            it.sortie() << formater("  ok    %s\n", nom.c_str());
        } catch (const ErreurMatlab& e) {
            ++echoues;
            it.sortie() << formater("  ECHEC %s : %s\n", nom.c_str(), e.message.c_str());
            messages.push_back(nom + " : " + e.message);
        }
    }
    it.sortie() << formater("\n%d test(s) reussi(s), %d en echec.\n", reussis, echoues);
    if (nargout > 0) {
        Valeur r = Valeur::structureVide();
        r.poserChamp("Passed", Valeur::scalaire(reussis));
        r.poserChamp("Failed", Valeur::scalaire(echoues));
        Valeur c = Valeur::celluleDims({(int)messages.size(), 1});
        for (std::size_t k = 0; k < messages.size(); ++k)
            c.cellules[k] = Valeur::texte(messages[k]);
        r.poserChamp("Messages", c);
        return {r};
    }
    if (echoues > 0) {
        DemandeSortie s;
        s.code = 1;
        throw s;
    }
    return {};
}

}  // namespace

void enregistrerTests(Interpreteur& it) {
    it.enregistrer("assert", fnAssert, "tests",
                   "assert  Verifie une condition, ou compare deux valeurs a une "
                   "tolerance pres.");
    it.enregistrer("assertEqual", fnAssertEqual, "tests", "assertEqual  Egalite exacte.");
    it.enregistrer("assertAlmostEqual", fnAssertPresque, "tests",
                   "assertAlmostEqual  Egalite a une tolerance pres.");
    it.enregistrer("assertElementsAlmostEqual", fnAssertPresque, "tests",
                   "assertElementsAlmostEqual  Egalite element par element.");
    it.enregistrer("assertError", fnAssertErreur, "tests",
                   "assertError  Verifie qu'une fonction leve une erreur.");
    it.enregistrer("fail", fnFail, "tests", "fail  Fait echouer un test.");
    it.enregistrer("runtests", fnRuntests, "tests",
                   "runtests  Execute les fichiers de test d'un dossier.");
}

}  // namespace matlibre
