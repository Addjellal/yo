#include "core/Device.h"

#include <sstream>

#include "core/Netlist.h"

namespace coeur {

// ---------------------------------------------------------------------------
// Lecture des formes d'onde par les composants à état
// ---------------------------------------------------------------------------
double Evolution::moyenne(const std::string& borne) const {
    const std::vector<double>* courbe = tension ? tension(borne) : nullptr;
    if (!courbe || courbe->empty()) return 0.0;
    double somme = 0;
    for (double valeur : *courbe) somme += valeur;
    return somme / courbe->size();
}

double Evolution::rapport_cyclique(const std::string& borne,
                                   double seuil) const {
    const std::vector<double>* courbe = tension ? tension(borne) : nullptr;
    if (!courbe || courbe->empty()) return 0.0;
    size_t hauts = 0;
    for (double valeur : *courbe)
        if (valeur > seuil) ++hauts;
    return static_cast<double>(hauts) / courbe->size();
}

double Evolution::largeur_impulsion(const std::string& borne,
                                    double seuil) const {
    const std::vector<double>* courbe = tension ? tension(borne) : nullptr;
    if (!courbe || !temps || courbe->size() != temps->size() ||
        courbe->size() < 2)
        return 0.0;

    // On cherche en remontant : la dernière impulsion complète est la plus
    // fraîche, donc celle que le composant doit suivre. Une impulsion
    // incomplète en fin de fenêtre est ignorée — sa largeur serait fausse.
    bool fin_vue = false;
    double fin = 0;
    for (size_t k = courbe->size(); k-- > 1;) {
        const bool haut = (*courbe)[k] > seuil;
        const bool haut_avant = (*courbe)[k - 1] > seuil;
        if (!fin_vue) {
            if (haut_avant && !haut) {          // front descendant
                fin_vue = true;
                fin = (*temps)[k];
            }
        } else if (!haut_avant && haut) {       // front montant précédent
            return fin - (*temps)[k];
        }
    }
    return 0.0;
}

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
void enregistrer_actionneurs_dynamiques(Catalogue& catalogue);
void enregistrer_capteurs_avances(Catalogue& catalogue);

void Catalogue::enregistrer_modeles_standards() {
    enregistrer_base(*this);
    enregistrer_cartes(*this);
    enregistrer_semiconducteurs(*this);
    enregistrer_capteurs(*this);
    enregistrer_electromecanique(*this);
    enregistrer_logique(*this);
    enregistrer_instruments(*this);
    enregistrer_actionneurs_dynamiques(*this);
    enregistrer_capteurs_avances(*this);
}

}  // namespace coeur
