#include "core/Device.h"

#include <sstream>

#include "core/Netlist.h"

namespace coeur {

Catalogue& Catalogue::instance() {
    static Catalogue unique;
    return unique;
}

void Catalogue::enregistrer(Modele modele) {
    modeles_[modele.type] = std::move(modele);
}

const Modele* Catalogue::modele(const std::string& type) const {
    auto it = modeles_.find(type);
    return it == modeles_.end() ? nullptr : &it->second;
}

std::vector<const Modele*> Catalogue::tous() const {
    std::vector<const Modele*> resultat;
    resultat.reserve(modeles_.size());
    for (const auto& paire : modeles_) resultat.push_back(&paire.second);
    return resultat;
}

std::vector<std::string> Catalogue::categories() const {
    std::vector<std::string> resultat;
    for (const auto& paire : modeles_) {
        const std::string& c = paire.second.categorie;
        bool deja = false;
        for (const auto& existante : resultat)
            if (existante == c) deja = true;
        if (!deja) resultat.push_back(c);
    }
    return resultat;
}

// ---------------------------------------------------------------------------
// Le catalogue est réparti en fichiers thématiques : chacun décrit une
// famille, et on ajoute un composant sans jamais toucher au reste.
// ---------------------------------------------------------------------------
void enregistrer_base(Catalogue& catalogue);
void enregistrer_cartes(Catalogue& catalogue);
void enregistrer_semiconducteurs(Catalogue& catalogue);
void enregistrer_capteurs(Catalogue& catalogue);
void enregistrer_electromecanique(Catalogue& catalogue);
void enregistrer_logique(Catalogue& catalogue);
void enregistrer_instruments(Catalogue& catalogue);

void Catalogue::enregistrer_modeles_standards() {
    enregistrer_base(*this);
    enregistrer_cartes(*this);
    enregistrer_semiconducteurs(*this);
    enregistrer_capteurs(*this);
    enregistrer_electromecanique(*this);
    enregistrer_logique(*this);
    enregistrer_instruments(*this);
}

}  // namespace coeur
