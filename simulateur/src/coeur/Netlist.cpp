#include "coeur/Netlist.h"

#include <algorithm>

namespace coeur {

const char* Netlist::kMasse = "GND";
const char* Netlist::kAlim = "5V";

const Borne* Instance::borne(const std::string& nom) const {
    for (const auto& b : bornes)
        if (b.nom == nom) return &b;
    return nullptr;
}

double Instance::valeur(const std::string& cle, double defaut) const {
    auto it = valeurs.find(cle);
    return it == valeurs.end() ? defaut : it->second;
}

std::string Instance::texte(const std::string& cle,
                            const std::string& defaut) const {
    auto it = textes.find(cle);
    return it == textes.end() ? defaut : it->second;
}

void Netlist::vider() { instances_.clear(); }

Instance& Netlist::ajouter(const std::string& reference,
                           const std::string& type) {
    if (Instance* existante = trouver(reference)) {
        existante->type = type;
        return *existante;
    }
    Instance instance;
    instance.reference = reference;
    instance.type = type;
    instances_.push_back(std::move(instance));
    return instances_.back();
}

Instance* Netlist::trouver(const std::string& reference) {
    for (auto& i : instances_)
        if (i.reference == reference) return &i;
    return nullptr;
}

const Instance* Netlist::trouver(const std::string& reference) const {
    for (const auto& i : instances_)
        if (i.reference == reference) return &i;
    return nullptr;
}

void Netlist::supprimer(const std::string& reference) {
    instances_.erase(std::remove_if(instances_.begin(), instances_.end(),
                                    [&](const Instance& i) {
                                        return i.reference == reference;
                                    }),
                     instances_.end());
}

void Netlist::relier(const std::string& reference, const std::string& borne,
                     const std::string& noeud) {
    Instance* instance = trouver(reference);
    if (!instance) return;
    for (auto& b : instance->bornes) {
        if (b.nom == borne) {
            b.noeud = noeud;
            return;
        }
    }
    instance->bornes.push_back({borne, noeud});
}

std::vector<std::string> Netlist::noeuds() const {
    std::vector<std::string> resultat{kMasse, kAlim};
    for (const auto& instance : instances_) {
        for (const auto& borne : instance.bornes) {
            if (borne.noeud.empty()) continue;
            if (std::find(resultat.begin(), resultat.end(), borne.noeud)
                == resultat.end())
                resultat.push_back(borne.noeud);
        }
    }
    return resultat;
}

int Netlist::occurrences(const std::string& noeud) const {
    int total = 0;
    for (const auto& instance : instances_)
        for (const auto& borne : instance.bornes)
            if (borne.noeud == noeud) ++total;
    return total;
}

}  // namespace coeur
