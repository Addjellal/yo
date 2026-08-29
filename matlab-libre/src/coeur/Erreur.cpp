#include "matlibre/Erreur.h"

#include <cstdarg>
#include <cstdio>
#include <fstream>
#include <string>
#include <vector>

namespace matlibre {

void erreur(const std::string& identifiant, const std::string& message) {
    throw ErreurMatlab(identifiant, message);
}

void erreurSimple(const std::string& message) { throw ErreurMatlab("", message); }

std::string formater(const char* format, ...) {
    va_list args;
    va_start(args, format);
    va_list copie;
    va_copy(copie, args);
    int n = std::vsnprintf(nullptr, 0, format, copie);
    va_end(copie);
    if (n < 0) {
        va_end(args);
        return std::string();
    }
    std::vector<char> tampon((std::size_t)n + 1);
    std::vsnprintf(tampon.data(), tampon.size(), format, args);
    va_end(args);
    return std::string(tampon.data(), (std::size_t)n);
}

// La ligne « n » d'un fichier, sans ses blancs de fin. Rendue vide quand
// le fichier n'est plus lisible : un rapport d'erreur ne doit jamais
// echouer a son tour.
static std::string ligneDuFichier(const std::string& fichier, int n) {
    if (fichier.empty() || n <= 0) return std::string();
    std::ifstream f(fichier);
    if (!f) return std::string();
    std::string ligne;
    for (int k = 1; k <= n; ++k)
        if (!std::getline(f, ligne)) return std::string();
    while (!ligne.empty() && (ligne.back() == ' ' || ligne.back() == '\t' ||
                              ligne.back() == '\r'))
        ligne.pop_back();
    std::size_t debut = ligne.find_first_not_of(" \t");
    if (debut == std::string::npos) return std::string();
    return ligne.substr(debut);
}

std::string rapportErreur(const ErreurMatlab& e) {
    // Les cadres anonymes — la console, « eval » — ne se nomment pas : on
    // ne garde que ceux qui viennent d'un fichier.
    std::vector<const CadreErreur*> cadres;
    for (const auto& c : e.pile)
        if (!c.nom.empty() && c.ligne > 0) cadres.push_back(&c);
    if (cadres.empty() && e.fonctionNative.empty()) return "Error: " + e.message + "\n";

    std::string rapport;
    if (!e.fonctionNative.empty()) {
        rapport += "Error using " + e.fonctionNative + "\n";
    } else {
        // L'erreur vient du code lui-meme : le cadre le plus profond est
        // celui qui a echoue.
        rapport += formater("Error using %s (line %d)\n", cadres[0]->nom.c_str(),
                            cadres[0]->ligne);
    }
    rapport += e.message + "\n";
    std::size_t premier = e.fonctionNative.empty() ? 1 : 0;
    for (std::size_t k = premier; k < cadres.size(); ++k) {
        rapport += formater("\nError in %s (line %d)\n", cadres[k]->nom.c_str(),
                            cadres[k]->ligne);
        std::string source = ligneDuFichier(cadres[k]->fichier, cadres[k]->ligne);
        if (!source.empty()) rapport += "    " + source + "\n";
    }
    return rapport;
}

// --- interruption ---------------------------------------------------
//
// Le drapeau est propre au fil : chaque interpreteur pose le sien quand il
// commence a executer. Un pointeur, et non un booleen, pour que le fil qui
// demande l'arret ecrive dans le meme mot que celui qui le lit.
namespace {
thread_local std::atomic<bool>* drapeau = nullptr;
}

void poserDrapeauInterruption(std::atomic<bool>* nouveau) { drapeau = nouveau; }

std::atomic<bool>* drapeauInterruption() { return drapeau; }

void demanderInterruption() {
    if (drapeau) drapeau->store(true, std::memory_order_relaxed);
}

void verifierInterruption() {
    if (!drapeau) return;
    if (!drapeau->load(std::memory_order_relaxed)) return;
    drapeau->store(false, std::memory_order_relaxed);
    throw InterruptionUtilisateur{};
}

}  // namespace matlibre
