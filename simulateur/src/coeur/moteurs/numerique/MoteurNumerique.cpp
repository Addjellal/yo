#include "coeur/moteurs/numerique/MoteurNumerique.h"

#include <algorithm>

namespace coeur {

bool MoteurNumerique::circuit_numerique(const Netlist& netlist) {
    for (const Instance& instance : netlist.instances()) {
        const Modele* modele = Catalogue::instance().modele(instance.type);
        if (modele && modele->reagir) return true;
    }
    return false;
}

int MoteurNumerique::propager(Netlist& netlist,
                              const std::vector<FrontNoeud>& fronts,
                              const std::map<std::string, double>& niveaux,
                              double duree, double tension_haute) {
    int traites = 0;
    for (Instance& instance : netlist.instances()) {
        const Modele* modele = Catalogue::instance().modele(instance.type);
        if (!modele || !modele->reagir) continue;

        // --- ce que le composant voit sur ses entrées
        EntreesNumeriques entrees;
        entrees.duree = duree;
        for (const Borne& borne : instance.bornes) {
            if (borne.noeud.empty()) continue;
            // Une sortie n'est pas une entrée : le composant la pilote, il ne
            // doit pas se relire lui-même.
            if (std::find(modele->sorties_numeriques.begin(),
                          modele->sorties_numeriques.end(), borne.nom)
                != modele->sorties_numeriques.end())
                continue;

            std::string cle = borne.noeud;
            std::transform(cle.begin(), cle.end(), cle.begin(),
                           [](unsigned char c) { return std::tolower(c); });
            auto trouve = niveaux.find(cle);
            entrees.niveaux[borne.nom] =
                trouve != niveaux.end() && trouve->second > seuil_;

            for (const FrontNoeud& front : fronts) {
                if (front.noeud != borne.noeud) continue;
                entrees.evenements.push_back({front.instant, borne.nom,
                                              front.haut});
            }
        }
        std::sort(entrees.evenements.begin(), entrees.evenements.end(),
                  [](const EvenementNumerique& a, const EvenementNumerique& b) {
                      return a.instant < b.instant;
                  });

        // --- ce qu'il en fait
        const std::vector<EvenementNumerique> sorties =
            modele->reagir(instance, entrees);
        ++traites;

        // --- traduction en formes d'onde, une par borne de sortie
        //
        // Chaque sortie part de son niveau courant : le composant n'émet un
        // événement que lorsqu'elle CHANGE, sinon chaque fenêtre repartirait
        // de zéro et les sorties clignoteraient sans raison.
        instance.ondes.clear();
        for (const std::string& borne : modele->sorties_numeriques) {
            const std::string cle = "_niveau_" + borne;
            const bool depart = instance.valeur(cle, 0.0) > 0.5;
            std::vector<std::pair<double, double>> onde;
            onde.emplace_back(0.0, depart ? tension_haute : 0.0);

            bool niveau = depart;
            for (const EvenementNumerique& evenement : sorties) {
                if (evenement.borne != borne) continue;
                if (evenement.haut == niveau) continue;
                // Front raide mais fini : un saut vertical ferait trébucher le
                // solveur, et aucune sortie réelle ne commute en zéro seconde.
                const double instant =
                    std::max(onde.back().first + 1e-9,
                             std::min(duree, evenement.instant));
                onde.emplace_back(std::max(0.0, instant - 5e-9),
                                  niveau ? tension_haute : 0.0);
                onde.emplace_back(instant, evenement.haut ? tension_haute : 0.0);
                niveau = evenement.haut;
            }
            if (onde.back().first < duree)
                onde.emplace_back(duree, niveau ? tension_haute : 0.0);

            instance.ondes[borne] = std::move(onde);
            instance.valeurs[cle] = niveau ? 1.0 : 0.0;
        }
    }
    return traites;
}

}  // namespace coeur
