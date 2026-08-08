// Catalogue — circuits numériques pilotés par des fronts.
//
// Ces composants ne se décrivent pas par une équation électrique : ils
// réagissent à des transitions. Leur modèle est donc une machine à états
// nourrie d'événements datés, et leurs sorties redeviennent des sources dans
// le circuit analogique.
//
// C'est ce qui manquait pour tout ce qui se pilote « en série » : un registre
// à décalage, un compteur, demain un afficheur.
#include <algorithm>
#include <functional>
#include <string>
#include <vector>

#include "core/Netlist.h"
#include "core/catalogue/Traits.h"

namespace coeur {

namespace {

// Lecture et écriture d'un octet rangé dans une valeur d'instance : le modèle
// n'a pas d'autre mémoire que l'instance elle-même.
int octet(const Instance& i, const std::string& cle) {
    return static_cast<int>(i.valeur(cle, 0.0)) & 0xFF;
}

// Sources continues des sorties, pour l'analyse au point de repos : sans
// elles, un registre laisserait ses huit sorties en l'air dès qu'on ne fait
// pas de transitoire.
std::vector<std::string> sorties_continues(const Instance& i,
                                           const std::vector<std::string>& bornes,
                                           const std::function<std::string(
                                               const std::string&)>& noeud,
                                           double impedance) {
    std::vector<std::string> lignes;
    for (size_t k = 0; k < bornes.size(); ++k) {
        const std::string& borne = bornes[k];
        const bool haut = i.valeur("_niveau_" + borne, 0.0) > 0.5;
        const std::string interne = i.reference + "_" + borne + "_src";
        lignes.push_back("V" + i.reference + "_" + borne + " " + interne
                         + " 0 DC " + traits::nombre(haut ? 5.0 : 0.0));
        lignes.push_back("R" + i.reference + "_" + borne + " " + interne + " "
                         + noeud(borne) + " " + traits::nombre(impedance));
    }
    return lignes;
}

// Traduction des formes d'onde calculées par le moteur numérique en sources
// linéaires par morceaux.
std::vector<std::string> sorties_datees(const Instance& i,
                                        const std::vector<std::string>& bornes,
                                        const std::function<std::string(
                                            const std::string&)>& noeud,
                                        double impedance, double duree) {
    std::vector<std::string> lignes;
    for (const std::string& borne : bornes) {
        auto onde = i.ondes.find(borne);
        const std::string interne = i.reference + "_" + borne + "_src";
        if (onde == i.ondes.end() || onde->second.empty()) {
            const bool haut = i.valeur("_niveau_" + borne, 0.0) > 0.5;
            lignes.push_back("V" + i.reference + "_" + borne + " " + interne
                             + " 0 DC " + traits::nombre(haut ? 5.0 : 0.0));
        } else {
            std::string pwl = "V" + i.reference + "_" + borne + " " + interne
                              + " 0 PWL(";
            for (size_t k = 0; k < onde->second.size(); ++k) {
                if (k) pwl += " ";
                pwl += traits::nombre(std::min(onde->second[k].first, duree))
                       + " " + traits::nombre(onde->second[k].second);
            }
            lignes.push_back(pwl + ")");
        }
        lignes.push_back("R" + i.reference + "_" + borne + " " + interne + " "
                         + noeud(borne) + " " + traits::nombre(impedance));
    }
    return lignes;
}

}  // namespace

void enregistrer_numerique(Catalogue& catalogue) {
    using namespace traits;

    {   // ------------------------------------- registre à décalage 74HC595
        // Trois fils pour huit sorties : c'est le composant qui rend le
        // multiplexage abordable, et celui qu'on rencontre partout dès qu'un
        // montage manque de broches.
        Modele m;
        m.type = "registre_74hc595";
        m.libelle = "Registre à décalage 74HC595";
        m.categorie = "Numérique";
        m.prefixe = "IC";
        m.sorties_numeriques = {"Q0", "Q1", "Q2", "Q3",
                                "Q4", "Q5", "Q6", "Q7"};
        m.impedance_sortie = 100.0;

        const double pas = 26;
        const double haut = -105;
        // Entrées à gauche, sorties à droite : la lecture suit le sens du
        // signal.
        const char* entrees[] = {"SER", "SRCLK", "RCLK", "OE", "SRCLR"};
        for (int k = 0; k < 5; ++k) {
            const double y = haut + k * pas;
            m.bornes.push_back({entrees[k], {-70, y}, ""});
            m.symbole.push_back(ligne(-70, y, -50, y));
            m.symbole.push_back(texte(-44, y + 4, entrees[k], 9));
        }
        for (int k = 0; k < 8; ++k) {
            const double y = haut + k * pas;
            const std::string nom = "Q" + std::to_string(k);
            m.bornes.push_back({nom, {70, y}, ""});
            m.symbole.push_back(ligne(50, y, 70, y));
            m.symbole.push_back(texte(30, y + 4, nom, 9));
        }
        m.symbole.insert(m.symbole.begin(), rect(-50, haut - 20, 50, haut + 7 * pas + 20));
        m.symbole.push_back(texte(-30, haut - 6, "74HC595", 10));
        m.empreinte = {"DIP16", {}, 19.0, 6.4};

        m.vers_spice = [](const Instance& i, const auto& noeud) {
            return sorties_continues(i, {"Q0", "Q1", "Q2", "Q3", "Q4", "Q5",
                                         "Q6", "Q7"},
                                     noeud, 100.0);
        };
        m.vers_spice_transitoire = [](const Instance& i, const auto& noeud,
                                      double duree) {
            return sorties_datees(i, {"Q0", "Q1", "Q2", "Q3", "Q4", "Q5", "Q6",
                                      "Q7"},
                                  noeud, 100.0, duree);
        };

        // La machine à états, telle que la décrit la fiche technique :
        //   * front montant de SRCLK  -> décalage, SER entre par le bas ;
        //   * front montant de RCLK   -> le registre est recopié au verrou ;
        //   * SRCLR bas               -> registre vidé ;
        //   * OE haut                 -> sorties en haute impédance (ici,
        //                                on les met à zéro : le simulateur
        //                                n'a pas de troisième état).
        m.reagir = [](Instance& i,
                      const EntreesNumeriques& entrees) {
            std::vector<EvenementNumerique> sorties;
            int registre = octet(i, "_registre");
            int verrou = octet(i, "_verrou");

            auto publier = [&](double instant, int valeur) {
                const bool actif = !entrees.niveau_a("OE", instant)
                                   || i.borne("OE") == nullptr
                                   || i.borne("OE")->noeud.empty();
                for (int bit = 0; bit < 8; ++bit) {
                    const bool niveau = actif && ((valeur >> bit) & 1);
                    sorties.push_back(
                        {instant, "Q" + std::to_string(bit), niveau});
                }
            };

            bool srclk = entrees.niveaux.count("SRCLK")
                         && entrees.niveaux.at("SRCLK");
            bool rclk = entrees.niveaux.count("RCLK")
                        && entrees.niveaux.at("RCLK");
            for (const EvenementNumerique& evenement : entrees.evenements) {
                if (evenement.borne == "SRCLR" && !evenement.haut) {
                    registre = 0;
                    continue;
                }
                if (evenement.borne == "SRCLK") {
                    if (evenement.haut && !srclk) {
                        const bool serie = entrees.niveau_a("SER",
                                                            evenement.instant);
                        registre = ((registre << 1) | (serie ? 1 : 0)) & 0xFF;
                    }
                    srclk = evenement.haut;
                    continue;
                }
                if (evenement.borne == "RCLK") {
                    if (evenement.haut && !rclk) {
                        verrou = registre;
                        // Le verrou change : c'est le seul moment où les
                        // sorties bougent.
                        publier(evenement.instant, verrou);
                    }
                    rclk = evenement.haut;
                    continue;
                }
                if (evenement.borne == "OE") publier(evenement.instant, verrou);
            }

            i.valeurs["_registre"] = registre;
            i.valeurs["_verrou"] = verrou;
            return sorties;
        };

        m.lecture = [](const Instance& i) {
            const int verrou = octet(i, "_verrou");
            std::string binaire;
            for (int bit = 7; bit >= 0; --bit)
                binaire += ((verrou >> bit) & 1) ? '1' : '0';
            return binaire;
        };
        catalogue.enregistrer(std::move(m));
    }
}

}  // namespace coeur
