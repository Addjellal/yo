// Principal.cpp — point d'entrée de l'exécutable « matlibre ».
//
//   matlibre                    interpréteur interactif
//   matlibre script.m [args]    exécute un script
//   matlibre -e "expr"          évalue une expression
//   matlibre --test dossier     exécute les tests d'un dossier
#include <algorithm>
#include <atomic>
#include <cctype>
#include <csignal>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#ifdef _WIN32
#include <io.h>
#else
#include <unistd.h>
#endif
#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

#include "matlibre/Affichage.h"
#include "matlibre/Analyseur.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Console.h"
#include "matlibre/EditionLigne.h"
#include "matlibre/Erreur.h"
#include "matlibre/Installation.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Version.h"

namespace fs = std::filesystem;
using namespace matlibre;

namespace {

// Le lecteur de la session interactive : l'éditeur de ligne, l'historique.
// Le débogueur s'en sert aussi, pour que « K>> » se tape comme « >> ».
LecteurLignes* lecteurConsole = nullptr;

// Lit une commande : par le lecteur de la session s'il y en a un, sinon
// ligne à ligne. Rend faux en fin de fichier.
bool lireCommande(const std::string& invite, std::string& commande) {
    if (lecteurConsole) {
        for (;;) {
            const auto r = lecteurConsole->lire(invite, commande);
            if (r == LecteurLignes::Resultat::FinFichier) return false;
            if (r == LecteurLignes::Resultat::Ligne) {
                lecteurConsole->retenir(commande);
                return true;
            }
        }
    }
    std::cout << invite << std::flush;
    return static_cast<bool>(std::getline(std::cin, commande));
}

// --- complétion de la ligne de commande (Tab) ---

bool caractereDeNom(char c) {
    return std::isalnum((unsigned char)c) || c == '_' || c == '.';
}

// Vrai quand le curseur est dans un texte entre apostrophes ou guillemets ;
// DEBUT reçoit alors le premier caractère du texte. Une apostrophe qui suit
// un nom, un nombre ou une parenthèse fermante est une transposition.
bool dansUnTexte(const std::string& ligne, std::size_t curseur, std::size_t& debut) {
    char ouvert = 0;
    for (std::size_t i = 0; i < curseur; ++i) {
        const char c = ligne[i];
        if (ouvert) {
            if (c == ouvert) {
                if (i + 1 < curseur && ligne[i + 1] == ouvert) ++i;   // '' ou ""
                else ouvert = 0;
            }
            continue;
        }
        if (c == '"') {
            ouvert = c;
            debut = i + 1;
        } else if (c == '\'') {
            std::size_t j = i;
            while (j > 0 && ligne[j - 1] == ' ') --j;
            const char avant = j > 0 ? ligne[j - 1] : ' ';
            const bool transposition = j == i && (std::isalnum((unsigned char)avant) ||
                                                  avant == '_' || avant == ')' || avant == ']' ||
                                                  avant == '}' || avant == '.' || avant == '\'');
            if (!transposition) {
                ouvert = c;
                debut = i + 1;
            }
        }
    }
    return ouvert != 0;
}

std::vector<std::string> completerFichier(const std::string& prefixe) {
    std::vector<std::string> trouves;
    const std::size_t coupe = prefixe.find_last_of("/\\");
    const std::string debutChemin = coupe == std::string::npos ? "" : prefixe.substr(0, coupe + 1);
    const std::string base = coupe == std::string::npos ? prefixe : prefixe.substr(coupe + 1);
    std::error_code ec;
    const fs::path dossier = debutChemin.empty() ? fs::current_path(ec) : fs::path(debutChemin);
    for (fs::directory_iterator d(dossier, ec), fin; !ec && d != fin; d.increment(ec)) {
        const std::string nom = d->path().filename().string();
        if (nom.compare(0, base.size(), base) != 0) continue;
        if (base.empty() && !nom.empty() && nom[0] == '.') continue;
        std::error_code ec2;
        trouves.push_back(debutChemin + nom + (d->is_directory(ec2) ? "/" : ""));
    }
    return trouves;
}

// Les noms qui commencent par le mot qui finit au curseur : variables,
// fonctions natives et fichiers du chemin, mots-clés ; après « s. », les
// champs de la structure s ; dans un texte, ou en argument de cd, load,
// run..., les fichiers. Comme MATLAB, la casse est ignorée quand rien ne
// correspond exactement.
std::vector<std::string> completer(const Interpreteur& it, const std::string& ligne,
                                   std::size_t curseur, std::size_t& debut) {
    std::size_t debutTexte = 0;
    if (dansUnTexte(ligne, curseur, debutTexte)) {
        debut = debutTexte;
        return completerFichier(ligne.substr(debutTexte, curseur - debutTexte));
    }
    // La forme commande : « cd dos », « load don ».
    static const char* commandesFichier[] = {"cd", "load", "run", "edit", "type", "open",
                                             "dir", "ls", "delete", "mkdir", "rmdir",
                                             "addpath", "save", "what"};
    const std::size_t premier = ligne.find_first_not_of(' ');
    if (premier != std::string::npos) {
        const std::size_t finMot = ligne.find(' ', premier);
        if (finMot != std::string::npos && finMot < curseur) {
            const std::string commande = ligne.substr(premier, finMot - premier);
            for (const char* c : commandesFichier) {
                if (commande != c) continue;
                std::size_t d = ligne.rfind(' ', curseur - 1);
                debut = d == std::string::npos ? curseur : d + 1;
                return completerFichier(ligne.substr(debut, curseur - debut));
            }
        }
    }
    debut = curseur;
    while (debut > 0 && caractereDeNom(ligne[debut - 1])) --debut;
    const std::string mot = ligne.substr(debut, curseur - debut);
    std::vector<std::string> trouves;
    if (mot.empty() || std::isdigit((unsigned char)mot[0])) return trouves;

    auto retenir = [&](const std::string& nom, bool casse) {
        if (nom.size() < mot.size()) return;
        if (nom.compare(0, 9, "matlibre_") == 0 && mot.compare(0, 9, "matlibre_") != 0) return;
        bool ok = true;
        for (std::size_t k = 0; k < mot.size() && ok; ++k)
            ok = casse ? nom[k] == mot[k]
                       : std::tolower((unsigned char)nom[k]) ==
                             std::tolower((unsigned char)mot[k]);
        if (ok) trouves.push_back(nom);
    };
    const std::size_t point = mot.rfind('.');
    if (point != std::string::npos) {
        // « s.ch » : les champs d'une structure ; sinon un paquet (« geo.ai »).
        const std::string base = mot.substr(0, point);
        if (const Valeur* v = it.trouverVariable(base)) {
            if (v->estStructure() && v->st)
                for (const std::string& champ : v->st->ordre) retenir(base + "." + champ, true);
            return trouves;
        }
    }
    static const char* motsCles[] = {"break", "case", "catch", "classdef", "continue",
                                     "else", "elseif", "end", "for", "function", "global",
                                     "if", "otherwise", "parfor", "persistent", "return",
                                     "spmd", "switch", "try", "while"};
    for (int passe = 0; passe < 2 && trouves.empty(); ++passe) {
        const bool casse = passe == 0;
        for (const std::string& n : it.nomsVariables()) retenir(n, casse);
        for (const std::string& n : it.nomsNatifs()) retenir(n, casse);
        for (const auto& kv : it.indexFichiers()) retenir(kv.first, casse);
        for (const char* m : motsCles) retenir(m, casse);
        std::error_code ec;
        for (fs::directory_iterator d(fs::current_path(ec), ec), fin; !ec && d != fin;
             d.increment(ec))
            if (d->path().extension() == ".m") retenir(d->path().stem().string(), casse);
    }
    return trouves;
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
        if (!lireCommande("K>> ", commande)) {
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
                std::cerr << rapportErreur(e);
            }
            return;
        }
        if (mot.empty()) continue;
        try {
            it.executerTexte(mot, "<debogueur>");
        } catch (const ErreurMatlab& e) {
            std::cerr << rapportErreur(e);
        }
    }
}

// Ctrl-C : le gestionnaire de signal ne peut presque rien faire — pas
// d'allocation, pas d'affichage. Il lève le drapeau de l'interprète, qui
// s'arrête à son prochain point de contrôle. Le pointeur est global parce
// qu'un gestionnaire de signal ne reçoit rien d'autre.
std::atomic<bool>* drapeauConsole = nullptr;

extern "C" void surSignalInterruption(int) {
    if (drapeauConsole) drapeauConsole->store(true, std::memory_order_relaxed);
#ifndef _WIN32
    // POSIX remet le comportement par defaut sur certains systemes : on
    // reinstalle, sinon le deuxieme Ctrl-C tuerait le programme.
    std::signal(SIGINT, surSignalInterruption);
#endif
}

#ifdef _WIN32
// Windows ne delivre pas de vrai signal : il appelle ce gestionnaire dans
// un fil a lui. Le CRT en fabrique un qui appelle « surSignalInterruption »,
// mais il n'existe que si le programme est lie a la bonne variante, et il
// laisse passer la fermeture par defaut. On s'inscrit donc directement :
// rendre TRUE dit a Windows que l'evenement est traite, et le programme
// n'est pas tue.
BOOL WINAPI surEvenementConsole(DWORD type) {
    if (type != CTRL_C_EVENT && type != CTRL_BREAK_EVENT) return FALSE;
    if (drapeauConsole) drapeauConsole->store(true, std::memory_order_relaxed);
    return TRUE;
}
#endif

// A appeler dans le fil qui execute : Ctrl-C coupe le calcul et rend
// l'invite, au lieu de tuer le programme. C'est ce que fait MATLAB.
void armerCtrlC(Interpreteur& it) {
    drapeauConsole = &it.interruption;
    std::signal(SIGINT, surSignalInterruption);
#ifdef _WIN32
    SetConsoleCtrlHandler(surEvenementConsole, TRUE);
#endif
}

// Vrai si l'entrée standard est un terminal, où quelqu'un tape. Lue dans
// un tube ou un fichier (« echo 'disp(1)' | matlibre »), elle n'appelle
// ni bannière ni invite : comme « matlab -batch », la sortie ne porte que
// ce que les commandes écrivent.
bool entreeEstUnTerminal() {
#ifdef _WIN32
    return _isatty(_fileno(stdin)) != 0;
#else
    return isatty(fileno(stdin)) != 0;
#endif
}

int executerFluxInteractif(Interpreteur& it, bool silencieux) {
    it.modeInteractif = true;
    std::string tampon;
    std::string ligne;
    const bool terminal = entreeEstUnTerminal();
    if (!terminal) silencieux = true;
    if (!silencieux)
        std::cout << "MatLibre " << MATLIBRE_VERSION
                  << " — clone libre du langage MATLAB.\n"
                     "« help nom » pour l'aide, « doc nom » pour la documentation "
                     "complete.\n"
                     "« exit » pour quitter.\n\n";
    // Au terminal, la ligne s'édite : flèches, historique rappelable et
    // gardé d'une session à l'autre, complétion par Tab (EditionLigne.h).
    // Hors terminal, ou sous MATLIBRE_EDITION=0, on lit ligne à ligne.
    LecteurLignes lecteur;
    const bool edition = terminal && lecteur.editionPossible();
    if (edition) {
        lecteur.ouvrirHistorique(LecteurLignes::cheminHistoriqueParDefaut());
        lecteur.definirCompleteur(
            [&it](const std::string& l, std::size_t curseur, std::size_t& debut) {
                return completer(it, l, curseur, debut);
            });
        lecteurConsole = &lecteur;
    }
    // Le débogueur ne doit plus le voir une fois la session finie, par
    // quelque chemin qu'elle finisse (« exit » sort de la boucle par un
    // retour).
    struct Oubli {
        ~Oubli() { lecteurConsole = nullptr; }
    } oubli;
    // La commande corrigée d'un « Did you mean: », posée dans la saisie
    // suivante, comme le font MATLAB et le bureau : Entrée l'exécute.
    std::string proposition;
    for (;;) {
        const std::string invite = terminal ? (tampon.empty() ? ">> " : "... ") : "";
        const LecteurLignes::Resultat lu = lecteur.lire(invite, ligne, proposition);
        proposition.clear();
        if (lu == LecteurLignes::Resultat::FinFichier) break;
        if (lu == LecteurLignes::Resultat::Abandon) {
            // Ctrl-C sur la ligne : elle part, et un bloc entamé avec elle.
            tampon.clear();
            continue;
        }
        if (edition) lecteur.retenir(ligne);
        tampon += ligne + "\n";
        // Continuation explicite.
        std::string sansBlanc = ligne;
        while (!sansBlanc.empty() && (sansBlanc.back() == ' ' || sansBlanc.back() == '\t'))
            sansBlanc.pop_back();
        if (sansBlanc.size() >= 3 && sansBlanc.substr(sansBlanc.size() - 3) == "...") continue;
        try {
            // Un Ctrl-C tombe entre deux commandes n'a rien a interrompre :
            // on repart d'un drapeau propre.
            it.armerInterruption();
            it.executerTexte(tampon, "<console>");
            tampon.clear();
        } catch (const InterruptionUtilisateur&) {
            std::cout << "\nOperation terminated by user.\n";
            tampon.clear();
        } catch (const ErreurMatlab& e) {
            // Un bloc incomplet (if/for/function) attend la suite.
            if (e.identifiant == "MATLAB:parseError" &&
                (e.message.find("Expected 'end'") != std::string::npos ||
                 e.message.find("Unexpected end of statement") != std::string::npos)) {
                continue;
            }
            std::cerr << rapportErreur(e);
            // Une faute de frappe dans la commande : la commande corrigée,
            // comme MATLAB. Pas hors terminal, où personne ne la lirait
            // pour la retaper (« matlab -batch » ne la propose pas non plus).
            if (terminal) {
                const std::string correction = it.correctionCommande(e, tampon);
                if (!correction.empty() && edition) {
                    std::cerr << "\nDid you mean:\n" << std::flush;
                    proposition = correction;
                } else if (!correction.empty()) {
                    std::cerr << "\nDid you mean:\n    " << correction << "\n";
                }
            }
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
    // Fin de fichier sans édition : l'invite attendait sur sa ligne.
    if (terminal && !edition) std::cout << "\n";
    return 0;
}

}  // namespace

int main(int argc, char** argv) {
    // Avant tout affichage : la console de Windows doit lire de l'UTF-8.
    ConsoleUtf8 console;
    // Un tampon franc sur la sortie. Sans lui, la console de Windows fait
    // un appel systeme par ligne : afficher un vecteur de dix millions
    // d'elements demandait des minutes de plus, passees dans le pilote de
    // la console et non dans le calcul. L'invite, elle, se purge
    // explicitement — « std::flush » est deja la ou il faut.
    static char tamponSortie[1 << 16];
    std::setvbuf(stdout, tamponSortie, _IOFBF, sizeof tamponSortie);
    std::vector<std::string> arguments(argv + 1, argv + argc);
    // Les options se lisent jusqu'au nom du script, dans n'importe quel
    // ordre ; ce qui suit le script est a lui (« argv »). « -- » clot les
    // options, pour un script dont le nom commence par un tiret. L'aide et
    // la version se reconnaissent avant de charger la bibliotheque : elles
    // n'ont pas a attendre son demarrage.
    for (const std::string& a : arguments) {
        if (a == "--version" || a == "-v") {
            std::cout << "MatLibre " << MATLIBRE_VERSION << "\n";
            return 0;
        }
        if (a == "--help" || a == "-h") {
            std::cout << "Usage : matlibre [options] [script.m [arguments]]\n"
                      << "  -e, --eval EXPR    evalue EXPR puis quitte\n"
                      << "  -q, --quiet        pas de banniere\n"
                      << "  --path DOSSIER     ajoute DOSSIER au chemin de recherche\n"
                      << "  --test DOSSIER     execute les fichiers de test du dossier\n"
                      << "  -v, --version      affiche la version\n"
                      << "  --                 fin des options (script dont le nom "
                         "commence par -)\n";
            return 0;
        }
        if (a == "--" || a == "-e" || a == "--eval" || a == "--test") break;
        if (a.empty() || a[0] != '-') break;
    }
    Interpreteur it;
    it.installerBibliotheque();
    chargerToolboxes(it, racineToolboxes(argv[0]));
    it.ajouterChemin(fs::current_path().string(), true);
    it.crochetArret = consoleDebogueur;
    // Ctrl-C arrete aussi un script lance depuis la ligne de commande, pas
    // seulement la session interactive.
    armerCtrlC(it);
    it.armerInterruption();

    try {
        bool silencieux = false;
        std::size_t k = 0;
        for (; k < arguments.size(); ++k) {
            const std::string& a = arguments[k];
            if (a == "-q" || a == "--quiet") {
                silencieux = true;
            } else if (a == "--path" || a.rfind("--path=", 0) == 0) {
                std::string dossier;
                if (a == "--path") {
                    if (k + 1 >= arguments.size()) {
                        std::cerr << "matlibre: option --path sans dossier\n";
                        return 2;
                    }
                    dossier = arguments[++k];
                } else {
                    dossier = a.substr(7);
                }
                it.ajouterChemin(dossier, true);
            } else if (a == "-e" || a == "--eval") {
                if (k + 1 >= arguments.size()) {
                    std::cerr << "matlibre: option -e sans expression\n";
                    return 2;
                }
                it.executerTexte(arguments[k + 1], "<eval>");
                return 0;
            } else if (a == "--test") {
                std::string dossier = (k + 1 < arguments.size()) ? arguments[k + 1] : "tests";
                std::vector<Valeur> v = {Valeur::texte(dossier)};
                auto r = it.appeler("runtests", v, 1);
                if (!r.empty() && !r[0].vrai()) return 1;
                return 0;
            } else if (a == "--") {
                ++k;
                break;
            } else if (a.size() > 1 && a[0] == '-') {
                std::cerr << "matlibre: option inconnue « " << a
                          << " » ; « matlibre --help » les liste\n";
                return 2;
            } else {
                break;
            }
        }
        if (k < arguments.size()) {
            // Les arguments restants sont visibles par « argv » dans un
            // script ; un fichier de fonctions les reçoit en entrée, en
            // texte, comme une application compilée par MATLAB.
            std::vector<Valeur> reste;
            for (std::size_t j = k + 1; j < arguments.size(); ++j)
                reste.push_back(Valeur::texte(arguments[j]));
            it.ecrireVariable("argv", Valeur::celluleLigne(reste));
            fs::path fichier(arguments[k]);
            it.ajouterChemin(fichier.parent_path().empty()
                                 ? fs::current_path().string()
                                 : fichier.parent_path().string(),
                             true);
            it.executerFichier(arguments[k], reste);
            return 0;
        }
        return executerFluxInteractif(it, silencieux);
    } catch (const DemandeSortie& s) {
        return s.code;
    } catch (const InterruptionUtilisateur&) {
        std::cout << "\nOperation terminated by user.\n";
        return 130;
    } catch (const ErreurMatlab& e) {
        std::cerr << rapportErreur(e);
        return 1;
    } catch (const std::exception& e) {
        std::cerr << "Erreur interne : " << e.what() << "\n";
        return 3;
    }
}
