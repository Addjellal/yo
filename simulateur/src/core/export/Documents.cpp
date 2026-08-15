#include "core/export/Documents.h"

#include <algorithm>
#include <cmath>
#include <ctime>
#include <iomanip>
#include <map>
#include <set>
#include <sstream>

#include "core/Device.h"

namespace coeur {

namespace {

const Modele* modele_de(const Instance& instance) {
    return Catalogue::instance().modele(instance.type);
}

bool est_alimentation(const std::string& noeud) {
    return noeud == Netlist::kMasse || noeud == Netlist::kAlim ||
           noeud == "3V3" || noeud == "VIN";
}

// Un composant purement symbolique (masse, symbole d'alimentation) n'a rien à
// contrôler : il n'a qu'une borne et impose son nœud.
bool est_symbole_alimentation(const Modele* modele) {
    return modele && !modele->noeud_impose.empty();
}

std::string echapper_csv(const std::string& texte) {
    if (texte.find(';') == std::string::npos &&
        texte.find('"') == std::string::npos)
        return texte;
    std::string resultat = "\"";
    for (char c : texte) {
        if (c == '"') resultat += '"';
        resultat += c;
    }
    return resultat + "\"";
}

std::string date_du_jour() {
    const std::time_t maintenant = std::time(nullptr);
    std::tm decompose{};
#ifdef _WIN32
    localtime_s(&decompose, &maintenant);
#else
    localtime_r(&maintenant, &decompose);
#endif
    char tampon[32] = {};
    std::strftime(tampon, sizeof tampon, "%Y-%m-%d", &decompose);
    return tampon;
}

}  // namespace

// ---------------------------------------------------------------------------
// Mise en forme des valeurs
// ---------------------------------------------------------------------------
std::string format_ingenieur(double valeur, const std::string& unite) {
    static const struct { double facteur; const char* prefixe; } echelles[] = {
        {1e9, "G"}, {1e6, "M"}, {1e3, "k"}, {1.0, ""},
        {1e-3, "m"}, {1e-6, "µ"}, {1e-9, "n"}, {1e-12, "p"}};

    std::ostringstream flux;
    std::string prefixe;
    if (valeur == 0) {
        flux << 0;
    } else {
        const double absolue = std::fabs(valeur);
        for (const auto& echelle : echelles) {
            if (absolue < echelle.facteur && echelle.facteur > 1e-12) continue;
            flux << std::setprecision(4) << valeur / echelle.facteur;
            prefixe = echelle.prefixe;
            break;
        }
        if (flux.str().empty()) flux << valeur;
    }
    // Le préfixe appartient à l'unité, pas au nombre : « 4.7 kΩ », jamais
    // « 4.7k Ω ».
    if (!prefixe.empty() || !unite.empty()) flux << " " << prefixe << unite;
    return flux.str();
}

std::string valeur_lisible(const Instance& instance) {
    const Modele* modele = modele_de(instance);
    if (!modele) return {};
    std::vector<std::string> morceaux;
    for (const auto& propriete : modele->proprietes) {
        if (morceaux.size() >= 2) break;
        if (propriete.genre == Propriete::Genre::Choix) {
            morceaux.push_back(
                instance.texte(propriete.cle, propriete.defaut_texte));
        } else {
            morceaux.push_back(format_ingenieur(
                instance.valeur(propriete.cle, propriete.defaut),
                propriete.unite));
        }
    }
    std::string resultat;
    for (size_t k = 0; k < morceaux.size(); ++k) {
        if (morceaux[k].empty()) continue;
        if (!resultat.empty()) resultat += " / ";
        resultat += morceaux[k];
    }
    return resultat;
}

// ---------------------------------------------------------------------------
// Nomenclature
// ---------------------------------------------------------------------------
std::vector<LigneNomenclature> nomenclature(const Netlist& netlist) {
    std::vector<LigneNomenclature> lignes;
    for (const auto& instance : netlist.instances()) {
        const Modele* modele = modele_de(instance);
        if (!modele) continue;
        // Masse et symboles d'alimentation ne s'achètent pas.
        if (est_symbole_alimentation(modele)) continue;

        const std::string valeur = valeur_lisible(instance);
        auto trouvee = std::find_if(
            lignes.begin(), lignes.end(), [&](const LigneNomenclature& ligne) {
                return ligne.type == instance.type && ligne.valeur == valeur;
            });
        if (trouvee == lignes.end()) {
            LigneNomenclature ligne;
            ligne.designation = modele->libelle;
            ligne.type = instance.type;
            ligne.valeur = valeur;
            ligne.empreinte = modele->empreinte.nom;
            ligne.references.push_back(instance.reference);
            lignes.push_back(std::move(ligne));
        } else {
            trouvee->references.push_back(instance.reference);
        }
    }
    for (auto& ligne : lignes)
        std::sort(ligne.references.begin(), ligne.references.end());
    std::sort(lignes.begin(), lignes.end(),
              [](const LigneNomenclature& a, const LigneNomenclature& b) {
                  if (a.designation != b.designation)
                      return a.designation < b.designation;
                  return a.valeur < b.valeur;
              });
    return lignes;
}

std::string nomenclature_csv(const Netlist& netlist) {
    std::ostringstream flux;
    flux << "Quantite;Designation;Valeur;References;Empreinte\n";
    for (const auto& ligne : nomenclature(netlist)) {
        std::string references;
        for (const auto& reference : ligne.references) {
            if (!references.empty()) references += " ";
            references += reference;
        }
        flux << ligne.quantite() << ";" << echapper_csv(ligne.designation) << ";"
             << echapper_csv(ligne.valeur) << ";" << echapper_csv(references)
             << ";" << echapper_csv(ligne.empreinte) << "\n";
    }
    return flux.str();
}

// ---------------------------------------------------------------------------
// Contrôle des règles électriques
// ---------------------------------------------------------------------------
std::vector<Anomalie> controler_regles(const Netlist& netlist) {
    std::vector<Anomalie> anomalies;
    using Gravite = Anomalie::Gravite;
    auto signaler = [&anomalies](Gravite gravite, const std::string& reference,
                                 const std::string& message,
                                 const std::string& remede = {},
                                 const std::string& borne = {}) {
        anomalies.push_back({gravite, reference, message, remede, borne});
    };

    if (netlist.instances().empty()) return anomalies;

    // Table nœud -> composants raccordés : la plupart des règles s'y lisent.
    std::map<std::string, std::vector<const Instance*>> par_noeud;
    std::map<std::string, int> occurrences_reference;
    bool masse_presente = false;
    for (const auto& instance : netlist.instances()) {
        ++occurrences_reference[instance.reference];
        for (const auto& borne : instance.bornes) {
            if (borne.noeud.empty()) continue;
            par_noeud[borne.noeud].push_back(&instance);
            if (borne.noeud == Netlist::kMasse) masse_presente = true;
        }
    }

    if (!masse_presente)
        signaler(Gravite::Erreur, "",
                 "aucune masse dans le circuit : les tensions n'ont pas de "
                 "référence",
                 "Posez une masse (palette ▸ Alimentation ▸ Masse) et reliez-y "
                 "le retour du montage.");

    for (const auto& paire : occurrences_reference)
        if (paire.second > 1)
            signaler(Gravite::Erreur, paire.first,
                     "référence utilisée " + std::to_string(paire.second)
                         + " fois : chaque composant doit être unique",
                     "Renommez l'un des deux dans le panneau Propriétés.");

    for (const auto& instance : netlist.instances()) {
        const Modele* modele = modele_de(instance);
        if (!modele) {
            signaler(Gravite::Erreur, instance.reference,
                     "type inconnu du catalogue : « " + instance.type + " »",
                     "Ce projet vient sans doute d'une version plus récente. "
                     "Effacez ce composant et reposez-en un équivalent.");
            continue;
        }
        if (est_symbole_alimentation(modele)) continue;

        // Bornes en l'air. La référence est le symbole du catalogue : une
        // borne jamais reliée n'apparaît pas du tout dans l'instance, c'est
        // justement le cas qu'il faut attraper.
        // Sur une carte ou un boîtier à nombreuses broches, laisser des
        // broches libres est normal : c'est un avertissement, pas une faute.
        // Sur un composant à deux ou trois bornes, c'est un oubli de câblage.
        if (!modele->carte) {
            const Gravite gravite = modele->bornes.size() <= 3
                                        ? Gravite::Erreur
                                        : Gravite::Avertissement;
            for (const auto& borne_symbole : modele->bornes) {
                const Borne* borne = instance.borne(borne_symbole.nom);
                if (!borne || borne->noeud.empty())
                    signaler(gravite, instance.reference,
                             "borne « " + borne_symbole.nom
                                 + " » non connectée",
                             "Tirez un fil depuis cette borne : cliquez "
                             "dessus, puis cliquez la borne d'arrivée.",
                             borne_symbole.nom);
            }
        }

        // Générateur court-circuité, ou deux sources en parallèle
        if (modele->generateur && instance.bornes.size() >= 2) {
            const std::string& a = instance.bornes[0].noeud;
            const std::string& b = instance.bornes[1].noeud;
            if (!a.empty() && a == b)
                signaler(Gravite::Erreur, instance.reference,
                         "source court-circuitée : ses deux bornes sont sur le "
                         "même nœud",
                         "Débranchez l'une des deux bornes, ou intercalez un "
                         "composant entre elles.");
            for (const auto& autre : netlist.instances()) {
                if (&autre == &instance) continue;
                if (autre.reference <= instance.reference) continue;
                const Modele* modele_autre = modele_de(autre);
                if (!modele_autre || !modele_autre->generateur) continue;
                if (autre.bornes.size() < 2) continue;
                const std::string& c = autre.bornes[0].noeud;
                const std::string& d = autre.bornes[1].noeud;
                if (a.empty() || b.empty()) continue;
                if ((a == c && b == d) || (a == d && b == c))
                    signaler(Gravite::Erreur, instance.reference,
                             "en parallèle avec " + autre.reference
                                 + " : deux sources ne peuvent pas imposer la "
                                   "même tension",
                             "Gardez-en une seule, ou séparez-les par une "
                             "résistance.");
            }
        }

        // Résistance nulle : c'est un fil, presque toujours involontaire
        if (instance.type == "resistance" && instance.valeur("ohms", 220) <= 0)
            signaler(Gravite::Avertissement, instance.reference,
                     "valeur nulle : la résistance se comporte en fil",
                     "Donnez-lui une valeur dans le panneau Propriétés.");

        // Composant lumineux sans résistance de limitation, faute classique
        if (modele->lumineux) {
            bool limite = false;
            for (const auto& borne : instance.bornes) {
                if (borne.noeud.empty()) continue;
                for (const Instance* voisin : par_noeud[borne.noeud])
                    if (voisin != &instance && voisin->type == "resistance")
                        limite = true;
            }
            if (!limite)
                signaler(Gravite::Avertissement, instance.reference,
                         "aucune résistance série : le courant n'est pas "
                         "limité",
                         "Intercalez une résistance : 220 Ω pour une LED sous "
                         "5 V, 100 Ω sous 3,3 V.");
        }

        // Broche de microcontrôleur reliée à une alimentation
        if (modele->carte) {
            for (const auto& borne : instance.bornes) {
                if (borne.noeud.empty()) continue;
                if (est_alimentation(borne.nom)) continue;   // broche d'alim
                if (est_alimentation(borne.noeud))
                    signaler(Gravite::Erreur, instance.reference,
                             "broche « " + borne.nom
                                 + " » reliée directement à « " + borne.noeud
                                 + " » : la sortie serait détruite",
                             "Retirez ce fil. Pour piloter une charge, passez "
                             "par une résistance ou un transistor.");
            }
        }
    }

    // Deux alimentations différentes ramenées sur le même nœud.
    //
    // C'est le court-circuit que rien ne rattrapait. Relier le 5V d'une carte
    // à sa masse, ou poser un générateur entre les deux, donne au solveur deux
    // potentiels imposés pour un seul nœud : le point de repos ne converge
    // pas, et le message se répète à chaque pas de temps sans jamais dire d'où
    // il vient. Pire, selon l'ordre d'assemblage la matrice peut être
    // résoluble et le circuit tourner avec une masse à 5 V — accepté sans un
    // mot, ce qui est le cas le plus trompeur des deux.
    //
    // La règle se lit d'un nœud : combien de potentiels distincts y arrivent.
    {
        // nœud -> { nom de l'alimentation -> composant qui l'apporte }
        std::map<std::string, std::map<std::string, std::string>> potentiels;
        for (const auto& instance : netlist.instances()) {
            const Modele* modele = modele_de(instance);
            if (!modele) continue;
            if (!modele->noeud_impose.empty()) {
                // Symbole de masse ou d'alimentation : il impose son potentiel
                // au nœud sur lequel on le pose.
                for (const auto& borne : instance.bornes)
                    if (!borne.noeud.empty())
                        potentiels[borne.noeud][modele->noeud_impose] =
                            instance.reference;
                continue;
            }
            // Les broches d'alimentation d'une carte sont tenues par sa propre
            // régulation : deux d'entre elles sur un même nœud, c'est le
            // régulateur en court-circuit.
            if (!modele->carte) continue;
            for (const auto& borne : instance.bornes)
                if (!borne.noeud.empty() && est_alimentation(borne.nom))
                    potentiels[borne.noeud][borne.nom] = instance.reference;
        }
        for (const auto& paire : potentiels) {
            if (paire.second.size() < 2) continue;
            std::string lesquelles, porteurs;
            for (const auto& potentiel : paire.second) {
                if (!lesquelles.empty()) lesquelles += " et ";
                lesquelles += "« " + potentiel.first + " »";
                if (porteurs.find(potentiel.second) == std::string::npos) {
                    if (!porteurs.empty()) porteurs += ", ";
                    porteurs += potentiel.second;
                }
            }
            signaler(Gravite::Erreur, porteurs,
                     lesquelles + " arrivent sur le même nœud : deux "
                     "potentiels imposés pour un seul nœud, c'est un "
                     "court-circuit d'alimentation",
                     "Séparez ces deux points : ils ne doivent pas partager "
                     "de fil.");
        }
    }

    // Nœuds ne reliant qu'une seule borne : un fil qui ne mène nulle part
    for (const auto& paire : par_noeud) {
        if (est_alimentation(paire.first)) continue;
        if (netlist.occurrences(paire.first) > 1) continue;
        signaler(Gravite::Avertissement, paire.first,
                 "ce nœud ne relie qu'une seule borne",
                 "Reliez-le à un autre composant, ou effacez le fil qui ne "
                 "mène nulle part.");
    }

    std::stable_sort(anomalies.begin(), anomalies.end(),
                     [](const Anomalie& a, const Anomalie& b) {
                         return static_cast<int>(a.gravite)
                                < static_cast<int>(b.gravite);
                     });
    return anomalies;
}

std::string rapport_regles(const Netlist& netlist) {
    const std::vector<Anomalie> anomalies = controler_regles(netlist);
    int erreurs = 0, avertissements = 0;
    for (const auto& anomalie : anomalies) {
        if (anomalie.gravite == Anomalie::Gravite::Erreur) ++erreurs;
        else if (anomalie.gravite == Anomalie::Gravite::Avertissement)
            ++avertissements;
    }

    std::ostringstream flux;
    flux << "Contrôle des règles électriques — " << date_du_jour() << "\n";
    flux << netlist.instances().size() << " composants, "
         << netlist.noeuds().size() << " nœuds.\n";
    flux << erreurs << " erreur(s), " << avertissements
         << " avertissement(s).\n\n";
    if (anomalies.empty()) {
        flux << "Aucune anomalie détectée.\n";
        return flux.str();
    }
    for (const auto& anomalie : anomalies) {
        switch (anomalie.gravite) {
            case Anomalie::Gravite::Erreur: flux << "[ERREUR]        "; break;
            case Anomalie::Gravite::Avertissement:
                flux << "[AVERTISSEMENT] ";
                break;
            case Anomalie::Gravite::Information:
                flux << "[INFORMATION]   ";
                break;
        }
        if (!anomalie.reference.empty()) flux << anomalie.reference << " : ";
        flux << anomalie.message << "\n";
        // Le rapport sert de compte rendu de TP : sans le remède, l'élève
        // rapporte une liste de reproches au lieu d'une liste de corrections.
        if (!anomalie.remede.empty())
            flux << "                \u2192 " << anomalie.remede << "\n";
    }
    return flux.str();
}

// ---------------------------------------------------------------------------
// Exports
// ---------------------------------------------------------------------------
std::string netlist_kicad(const Netlist& netlist) {
    std::ostringstream flux;
    flux << "(export (version D)\n";
    flux << "  (design\n";
    flux << "    (source \"simulateur\")\n";
    flux << "    (date \"" << date_du_jour() << "\")\n";
    flux << "    (tool \"Simulateur embarque\"))\n";

    flux << "  (components\n";
    for (const auto& instance : netlist.instances()) {
        const Modele* modele = modele_de(instance);
        if (est_symbole_alimentation(modele)) continue;
        flux << "    (comp (ref \"" << instance.reference << "\")\n";
        flux << "      (value \"" << valeur_lisible(instance) << "\")\n";
        if (modele && !modele->empreinte.nom.empty())
            flux << "      (footprint \"" << modele->empreinte.nom << "\")\n";
        flux << "      (libsource (lib \"simulateur\") (part \"" << instance.type
             << "\")))\n";
    }
    flux << "  )\n";

    // Nœuds : un « net » par nœud, chaque borne devient un « node ».
    std::map<std::string, std::vector<std::pair<std::string, std::string>>> nets;
    for (const auto& instance : netlist.instances()) {
        const Modele* modele = modele_de(instance);
        if (est_symbole_alimentation(modele)) continue;
        for (const auto& borne : instance.bornes) {
            if (borne.noeud.empty()) continue;
            nets[borne.noeud].emplace_back(instance.reference, borne.nom);
        }
    }
    flux << "  (nets\n";
    int code = 0;
    for (const auto& net : nets) {
        flux << "    (net (code " << ++code << ") (name \"" << net.first
             << "\")\n";
        for (const auto& borne : net.second)
            flux << "      (node (ref \"" << borne.first << "\") (pin \""
                 << borne.second << "\"))\n";
        flux << "    )\n";
    }
    flux << "  )\n)\n";
    return flux.str();
}

std::string courbes_csv(const Formes& formes) {
    std::ostringstream flux;
    if (formes.vide()) return flux.str();

    std::vector<std::string> noms;
    std::vector<const std::vector<double>*> colonnes;
    for (const auto& paire : formes.tensions) {
        noms.push_back("V(" + paire.first + ")");
        colonnes.push_back(&paire.second);
    }
    for (const auto& paire : formes.courants) {
        noms.push_back("I(" + paire.first + ")");
        colonnes.push_back(&paire.second);
    }

    flux << "temps";
    for (const auto& nom : noms) flux << ";" << nom;
    flux << "\n";
    flux << std::setprecision(9);
    for (size_t k = 0; k < formes.temps.size(); ++k) {
        flux << formes.temps[k];
        for (const auto* colonne : colonnes)
            flux << ";" << (k < colonne->size() ? (*colonne)[k] : 0.0);
        flux << "\n";
    }
    return flux.str();
}

std::string balayage_csv(const Balayage& balayage) {
    std::ostringstream flux;
    if (balayage.vide()) return flux.str();

    flux << (balayage.grandeur.empty() ? "abscisse" : balayage.grandeur);
    for (const auto& courbe : balayage.courbes) {
        flux << ";" << courbe.nom;
        if (courbe.complexe()) flux << ";phase(" << courbe.nom << ")";
    }
    flux << "\n";
    flux << std::setprecision(9);
    for (size_t k = 0; k < balayage.abscisse.size(); ++k) {
        flux << balayage.abscisse[k];
        for (const auto& courbe : balayage.courbes) {
            flux << ";" << (k < courbe.valeurs.size() ? courbe.valeurs[k] : 0.0);
            if (courbe.complexe())
                flux << ";" << (k < courbe.phases.size() ? courbe.phases[k] : 0.0);
        }
        flux << "\n";
    }
    return flux.str();
}

}  // namespace coeur
