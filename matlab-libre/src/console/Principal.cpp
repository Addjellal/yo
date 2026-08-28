// Principal.cpp — point d'entrée de l'exécutable « matlibre ».
//
//   matlibre                    interpréteur interactif
//   matlibre script.m [args]    exécute un script
//   matlibre -e "expr"          évalue une expression
//   matlibre --test dossier     exécute les tests d'un dossier
#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "matlibre/Affichage.h"
#include "matlibre/Analyseur.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Console.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Atelier.h"
#include "matlibre/Version.h"

namespace fs = std::filesystem;
using namespace matlibre;

namespace {

std::string racineInstallation(const char* argv0) {
    std::error_code ec;
    fs::path exe = fs::weakly_canonical(fs::path(argv0), ec);
    fs::path dossier = exe.parent_path();
    // Arborescence installée : <prefixe>/bin/matlibre et <prefixe>/share/matlibre
    for (fs::path p : {dossier / ".." / "share" / "matlibre", dossier / ".." / "toolbox",
                       dossier / "toolbox"}) {
        std::error_code e2;
        if (fs::is_directory(p, e2)) return fs::weakly_canonical(p, e2).string();
    }
    const char* env = std::getenv("MATLIBRE_TOOLBOX");
    if (env) return env;
    return std::string();
}

void chargerToolboxes(Interpreteur& it, const std::string& racine) {
    if (racine.empty()) return;
    it.definirRacineToolbox(racine);
    std::error_code ec;
    std::vector<std::string> dossiers;
    for (const auto& e : fs::directory_iterator(racine, ec))
        if (e.is_directory()) dossiers.push_back(e.path().string());
    std::sort(dossiers.begin(), dossiers.end());
    for (auto rit = dossiers.rbegin(); rit != dossiers.rend(); ++rit)
        it.ajouterChemin(*rit, true);
    it.ajouterChemin(racine, true);
}

// Console du débogueur : appelée quand l'exécution s'arrête sur un point
// d'arrêt. On lit des commandes jusqu'à ce que l'utilisateur reprenne.
void consoleDebogueur(Interpreteur& it, const std::string& fichier, int ligne) {
    std::cout << "\nArret dans " << (fichier.empty() ? "<console>" : fichier) << " ligne "
              << ligne << ".\n";
    // Montre la ligne concernée quand le fichier est lisible.
    std::ifstream f(fichier);
    if (f) {
        std::string texte;
        for (int k = 1; k <= ligne && std::getline(f, texte); ++k)
            if (k == ligne) std::cout << ligne << "  " << texte << "\n";
    }
    std::string commande;
    for (;;) {
        std::cout << "K>> " << std::flush;
        if (!std::getline(std::cin, commande)) {
            it.debogueur.action = ActionDebogueur::Continuer;
            return;
        }
        std::string mot = commande;
        while (!mot.empty() && (mot.back() == ' ' || mot.back() == '\t')) mot.pop_back();
        if (mot == "dbcont" || mot == "return") {
            it.debogueur.action = ActionDebogueur::Continuer;
            return;
        }
        if (mot == "dbstep" || mot == "dbstep in" || mot == "dbstep out" || mot == "dbquit") {
            try {
                it.executerTexte(mot, "<debogueur>");
            } catch (const ErreurMatlab& e) {
                std::cerr << "Error: " << e.message << "\n";
            }
            return;
        }
        if (mot.empty()) continue;
        try {
            it.executerTexte(mot, "<debogueur>");
        } catch (const ErreurMatlab& e) {
            std::cerr << "Error: " << e.message << "\n";
        }
    }
}

int executerFluxInteractif(Interpreteur& it) {
    it.modeInteractif = true;
    std::string tampon;
    std::string ligne;
    std::cout << "MatLibre " << MATLIBRE_VERSION
              << " — clone libre du langage MATLAB.\n"
                 "« ide » ouvre l'atelier : editeur de scripts, figures, debogueur, "
                 "schemas-blocs.\n"
                 "« help » pour l'aide, « exit » pour quitter.\n\n";
    for (;;) {
        std::cout << (tampon.empty() ? ">> " : "... ") << std::flush;
        if (!std::getline(std::cin, ligne)) break;
        tampon += ligne + "\n";
        // Continuation explicite.
        std::string sansBlanc = ligne;
        while (!sansBlanc.empty() && (sansBlanc.back() == ' ' || sansBlanc.back() == '\t'))
            sansBlanc.pop_back();
        if (sansBlanc.size() >= 3 && sansBlanc.substr(sansBlanc.size() - 3) == "...") continue;
        try {
            it.executerTexte(tampon, "<console>");
            tampon.clear();
        } catch (const ErreurMatlab& e) {
            // Un bloc incomplet (if/for/function) attend la suite.
            if (e.identifiant == "MATLAB:parseError" &&
                (e.message.find("Expected 'end'") != std::string::npos ||
                 e.message.find("Unexpected end of statement") != std::string::npos)) {
                continue;
            }
            std::cerr << "Error: " << e.message << "\n";
            tampon.clear();
        } catch (const DemandeSortie& s) {
            return s.code;
        } catch (const RuptureBoucle&) {
            tampon.clear();
        } catch (const ContinuerBoucle&) {
            tampon.clear();
        } catch (const RetourFonction&) {
            tampon.clear();
        }
    }
    std::cout << "\n";
    return 0;
}

}  // namespace

int main(int argc, char** argv) {
    // Avant tout affichage : la console de Windows doit lire de l'UTF-8.
    ConsoleUtf8 console;
    std::vector<std::string> arguments(argv + 1, argv + argc);
    Interpreteur it;
    it.installerBibliotheque();
    chargerToolboxes(it, racineInstallation(argv[0]));
    it.ajouterChemin(fs::current_path().string(), true);
    it.crochetArret = consoleDebogueur;

    try {
        if (arguments.empty()) return executerFluxInteractif(it);
        if (arguments[0] == "--version" || arguments[0] == "-v") {
            std::cout << "MatLibre " << MATLIBRE_VERSION << "\n";
            return 0;
        }
        if (arguments[0] == "--help" || arguments[0] == "-h") {
            std::cout << "Usage : matlibre [options] [script.m [arguments]]\n"
                      << "  -e, --eval EXPR    evalue EXPR puis quitte\n"
                      << "  -q, --quiet        pas de banniere\n"
                      << "  --path DOSSIER     ajoute DOSSIER au chemin de recherche\n"
                      << "  --test DOSSIER     execute les fichiers de test du dossier\n"
                      << "  --ide [PORT]       ouvre l'atelier dans le navigateur\n"
                      << "  --ide-sans-navigateur [PORT]  atelier sans ouvrir le navigateur\n"
                      << "  -v, --version      affiche la version\n";
            return 0;
        }
        if (arguments[0] == "--ide" || arguments[0] == "--ide-sans-navigateur") {
            int port = 842;
            if (arguments.size() > 1) {
                int demande = std::atoi(arguments[1].c_str());
                if (demande > 0) port = demande;
            }
            std::string racineToolbox = racineInstallation(argv[0]);
            if (!racineToolbox.empty())
#ifdef _WIN32
                _putenv_s("MATLIBRE_TOOLBOX", racineToolbox.c_str());
#else
                setenv("MATLIBRE_TOOLBOX", racineToolbox.c_str(), 0);
#endif
            return lancerAtelier(port, trouverRacineWeb(argv[0]),
                                 arguments[0] == "--ide");
        }
        std::size_t k = 0;
        while (k < arguments.size() && arguments[k].rfind("--path", 0) == 0) {
            if (k + 1 >= arguments.size()) break;
            it.ajouterChemin(arguments[k + 1], true);
            k += 2;
        }
        if (k < arguments.size() && (arguments[k] == "-e" || arguments[k] == "--eval")) {
            if (k + 1 >= arguments.size()) {
                std::cerr << "matlibre: option -e sans expression\n";
                return 2;
            }
            it.executerTexte(arguments[k + 1], "<eval>");
            return 0;
        }
        if (k < arguments.size() && arguments[k] == "--test") {
            std::string dossier = (k + 1 < arguments.size()) ? arguments[k + 1] : "tests";
            std::vector<Valeur> a = {Valeur::texte(dossier)};
            auto r = it.appeler("runtests", a, 1);
            if (!r.empty() && !r[0].vrai()) return 1;
            return 0;
        }
        if (k < arguments.size()) {
            // Les arguments restants sont visibles par « argv » dans le script.
            std::vector<Valeur> reste;
            for (std::size_t j = k + 1; j < arguments.size(); ++j)
                reste.push_back(Valeur::texte(arguments[j]));
            it.ecrireVariable("argv", Valeur::celluleLigne(reste));
            fs::path fichier(arguments[k]);
            it.ajouterChemin(fichier.parent_path().empty()
                                 ? fs::current_path().string()
                                 : fichier.parent_path().string(),
                             true);
            it.executerFichier(arguments[k]);
            return 0;
        }
        return executerFluxInteractif(it);
    } catch (const DemandeSortie& s) {
        return s.code;
    } catch (const ErreurMatlab& e) {
        std::cerr << "Error: " << e.message << "\n";
        return 1;
    } catch (const std::exception& e) {
        std::cerr << "Erreur interne : " << e.what() << "\n";
        return 3;
    }
}
