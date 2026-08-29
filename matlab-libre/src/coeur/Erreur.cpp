#include "matlibre/Erreur.h"

#include <cstdarg>
#include <cstdio>
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
