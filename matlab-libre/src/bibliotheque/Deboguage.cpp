// Deboguage.cpp (bibliothèque) — profile, dbstop et le reste du débogueur.
//
// Le profileur mesure vraiment : temps total, temps propre hors appels
// imbriqués, nombre d'appels, et passages ligne à ligne. Le débogueur pose
// de vrais points d'arrêt : l'exécution s'interrompt, on inspecte l'espace
// de travail, on avance pas à pas.
#include <algorithm>
#include <cctype>
#include <iostream>
#include <memory>
#include <sstream>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

Valeur tableProfil(Interpreteur& it) {
    auto liste = it.profil.classees();
    Valeur s = Valeur::structureVide();
    s.dims = {1, (int)std::max<std::size_t>(liste.size(), 1)};
    s.st = std::make_shared<ChampsStructure>();
    s.st->ordre = {"FunctionName", "NumCalls", "TotalTime", "SelfTime"};
    std::size_t n = std::max<std::size_t>(liste.size(), 1);
    for (const auto& nom : s.st->ordre) s.st->champs[nom] = std::vector<Valeur>(n, Valeur::vide());
    for (std::size_t k = 0; k < liste.size(); ++k) {
        s.st->champs["FunctionName"][k] = Valeur::texte(liste[k].nom);
        s.st->champs["NumCalls"][k] = Valeur::scalaire((double)liste[k].appels);
        s.st->champs["TotalTime"][k] = Valeur::scalaire(liste[k].tempsTotal);
        s.st->champs["SelfTime"][k] = Valeur::scalaire(liste[k].tempsPropre);
    }
    if (liste.empty()) s.dims = {0, 0};
    return s;
}

FONCTION(fnProfile) {
    INUTILISE
    std::string action = args.empty() ? std::string("status") : args[0].versTexte();
    for (auto& c : action) c = (char)std::tolower((unsigned char)c);
    if (action == "on") {
        it.profil.effacer();
        it.profil.demarrer();
        return {};
    }
    if (action == "resume") {
        it.profil.demarrer();
        return {};
    }
    if (action == "off") {
        it.profil.arreter();
        return {};
    }
    if (action == "clear") {
        it.profil.effacer();
        return {};
    }
    if (action == "info") {
        Valeur info = Valeur::structureVide();
        info.poserChamp("FunctionTable", tableProfil(it));
        info.poserChamp("ClockPrecision", Valeur::scalaire(1e-9));
        info.poserChamp("Name", Valeur::texte("MatLibre Profiler"));
        return {info};
    }
    if (action == "status") {
        if (nargout > 0) {
            Valeur s = Valeur::structureVide();
            s.poserChamp("ProfilerStatus", Valeur::texte(it.profil.actif ? "on" : "off"));
            s.poserChamp("DetailLevel", Valeur::texte("mmex"));
            return {s};
        }
        it.sortie() << "Profiler status: " << (it.profil.actif ? "on" : "off") << "\n";
        return {};
    }
    if (action == "viewer" || action == "report") {
        auto liste = it.profil.classees();
        it.sortie() << formater("%-28s %10s %12s %12s\n", "Function", "Calls", "Total (s)",
                                "Self (s)");
        it.sortie() << std::string(64, '-') << "\n";
        for (const auto& e : liste)
            it.sortie() << formater("%-28s %10lld %12.6f %12.6f\n", e.nom.c_str(), e.appels,
                                    e.tempsTotal, e.tempsPropre);
        return {};
    }
    erreur("MATLAB:profile:UnknownAction", "Unrecognized profile action '" + action + "'.");
}

// Lignes chaudes d'une fonction : ce que montre le profil détaillé.
FONCTION(fnProfileLignes) {
    INUTILISE
    exigerArguments(args, 1, 1, "matlibre_profil_lignes");
    std::string nom = args[0].versTexte();
    auto p = it.profil.entrees.find(nom);
    if (p == it.profil.entrees.end()) return {Valeur::vide()};
    const auto& lignes = p->second.lignes;
    Valeur m = Valeur::matrice((int)lignes.size(), 2, 0.0);
    int k = 0;
    int n = (int)lignes.size();
    for (const auto& kv : lignes) {
        m.re[(std::size_t)k] = kv.first;
        m.re[(std::size_t)(n + k)] = (double)kv.second;
        ++k;
    }
    return {m};
}

// --- points d'arrêt --------------------------------------------------------

FONCTION(fnDbstop) {
    INUTILISE
    if (args.empty()) {
        it.debogueur.arretSurErreur = true;
        return {};
    }
    std::string premier = args[0].versTexte();
    if (premier == "if" || premier == "error" || premier == "caught" || premier == "warning") {
        it.debogueur.arretSurErreur = true;
        return {};
    }
    // dbstop('in','f','at',12) ou dbstop('f', 12)
    std::string fichier;
    int ligne = 0;
    std::string condition;
    for (std::size_t k = 0; k < args.size(); ++k) {
        std::string a = args[k].estNumerique() ? std::string() : args[k].versTexte();
        if (a == "in" && k + 1 < args.size()) {
            fichier = args[++k].versTexte();
        } else if (a == "at" && k + 1 < args.size()) {
            ligne = (int)args[++k].scal();
        } else if (a == "if" && k + 1 < args.size()) {
            condition = args[++k].versTexte();
        } else if (args[k].estNumerique()) {
            ligne = (int)args[k].scal();
        } else if (fichier.empty()) {
            fichier = a;
        }
    }
    if (fichier.empty())
        erreur("MATLAB:dbstop:InvalidInput", "Specify the file where the breakpoint goes.");
    it.debogueur.poser(fichier, ligne, condition);
    return {};
}

FONCTION(fnDbclear) {
    INUTILISE
    if (args.empty() || args[0].versTexte() == "all") {
        it.debogueur.toutRetirer();
        it.debogueur.arretSurErreur = false;
        return {};
    }
    std::string fichier;
    int ligne = 0;
    for (std::size_t k = 0; k < args.size(); ++k) {
        if (args[k].estNumerique()) ligne = (int)args[k].scal();
        else if (args[k].versTexte() == "in" && k + 1 < args.size()) fichier = args[++k].versTexte();
        else if (args[k].versTexte() == "at" && k + 1 < args.size()) ligne = (int)args[++k].scal();
        else if (fichier.empty()) fichier = args[k].versTexte();
    }
    it.debogueur.retirer(fichier, ligne);
    return {};
}

FONCTION(fnDbstatus) {
    INUTILISE
    if (nargout > 0) {
        const auto& points = it.debogueur.points;
        Valeur s = Valeur::structureVide();
        std::size_t n = std::max<std::size_t>(points.size(), 1);
        s.dims = {1, (int)points.size()};
        s.st = std::make_shared<ChampsStructure>();
        s.st->ordre = {"name", "line", "cond"};
        for (const auto& nom : s.st->ordre)
            s.st->champs[nom] = std::vector<Valeur>(n, Valeur::vide());
        for (std::size_t k = 0; k < points.size(); ++k) {
            s.st->champs["name"][k] = Valeur::texte(points[k].fichier);
            s.st->champs["line"][k] = Valeur::scalaire(points[k].ligne);
            s.st->champs["cond"][k] = Valeur::texte(points[k].condition);
        }
        if (points.empty()) s.dims = {0, 0};
        return {s};
    }
    for (const auto& p : it.debogueur.points) {
        it.sortie() << "Breakpoint for " << p.fichier << " is on line " << p.ligne;
        if (!p.condition.empty()) it.sortie() << " if " << p.condition;
        it.sortie() << ".\n";
    }
    return {};
}

FONCTION(fnDbstep) {
    INUTILISE
    std::string mode = args.empty() ? std::string() : args[0].versTexte();
    if (mode == "in") it.debogueur.action = ActionDebogueur::EntrerDedans;
    else if (mode == "out") it.debogueur.action = ActionDebogueur::SortirDe;
    else it.debogueur.action = ActionDebogueur::PasAPas;
    it.debogueur.profondeurPause = it.profondeur();
    return {};
}

FONCTION(fnDbcont) {
    INUTILISE
    it.debogueur.action = ActionDebogueur::Continuer;
    return {};
}

FONCTION(fnDbquit) {
    INUTILISE
    it.debogueur.action = ActionDebogueur::Quitter;
    return {};
}

FONCTION(fnDbstack) {
    INUTILISE
    int n = it.profondeur();
    Valeur s = Valeur::structureVide();
    s.dims = {1, n - 1 > 0 ? n - 1 : 0};
    s.st = std::make_shared<ChampsStructure>();
    s.st->ordre = {"file", "name", "line"};
    std::size_t taille = (std::size_t)std::max(n - 1, 1);
    for (const auto& nom : s.st->ordre)
        s.st->champs[nom] = std::vector<Valeur>(taille, Valeur::vide());
    int k = 0;
    for (int i = n - 1; i >= 1; --i) {
        const Portee& p = it.porteeNumero(i);
        s.st->champs["file"][(std::size_t)k] =
            Valeur::texte(p.fonction ? p.fonction->fichier : std::string());
        s.st->champs["name"][(std::size_t)k] = Valeur::texte(p.nomFonction);
        s.st->champs["line"][(std::size_t)k] = Valeur::scalaire(it.debogueur.ligneCourante);
        ++k;
    }
    if (n <= 1) s.dims = {0, 0};
    return {s};
}

// keyboard : rend la main à l'utilisateur au milieu d'un programme.
FONCTION(fnKeyboard) {
    INUTILISE
    if (!it.crochetArret) {
        it.sortie() << "K>> (keyboard : pas de console attachee, on continue)\n";
        return {};
    }
    it.debogueur.enPause = true;
    it.crochetArret(it, it.fichierExecute(), it.debogueur.ligneCourante);
    it.debogueur.enPause = false;
    return {};
}

}  // namespace

void enregistrerDeboguage(Interpreteur& it) {
    it.enregistrer("profile", fnProfile, "deboguage",
                   "profile  Profileur : on, off, clear, info, viewer.");
    it.enregistrer("matlibre_profil_lignes", fnProfileLignes, "deboguage",
                   "matlibre_profil_lignes  Passages ligne a ligne d'une fonction.");
    it.enregistrer("dbstop", fnDbstop, "deboguage", "dbstop  Pose un point d'arret.");
    it.enregistrer("dbclear", fnDbclear, "deboguage", "dbclear  Retire un point d'arret.");
    it.enregistrer("dbstatus", fnDbstatus, "deboguage", "dbstatus  Liste les points d'arret.");
    it.enregistrer("dbstep", fnDbstep, "deboguage", "dbstep  Avance d'une instruction.");
    it.enregistrer("dbcont", fnDbcont, "deboguage", "dbcont  Reprend l'execution.");
    it.enregistrer("dbquit", fnDbquit, "deboguage", "dbquit  Abandonne l'execution.");
    it.enregistrer("dbstack", fnDbstack, "deboguage", "dbstack  Pile des appels.");
    it.enregistrer("keyboard", fnKeyboard, "deboguage",
                   "keyboard  Rend la main a l'utilisateur.");
}

}  // namespace matlibre
