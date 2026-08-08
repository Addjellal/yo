#include "core/analysis/Campagne.h"

#include <algorithm>
#include <cmath>
#include <random>
#include <sstream>

#include "core/Device.h"

namespace coeur {

namespace {

std::string format_court(double valeur) {
    std::ostringstream flux;
    flux << valeur;
    return flux.str();
}

// Exécute une analyse sur une netlist donnée et rapporte son balayage.
bool executer(const Netlist& netlist,
              const std::vector<BrocheElectrique>& broches,
              const std::string& directive, Balayage& resultat,
              std::vector<std::string>& erreurs) {
    NgspiceEngine moteur;
    moteur.construire_analyse(netlist, broches, directive);
    if (!moteur.resoudre_analyse()) {
        for (const std::string& message : moteur.erreurs())
            erreurs.push_back(message);
        return false;
    }
    resultat = moteur.balayage();
    return true;
}

}  // namespace

bool valeur_tolerancee(const std::string& type, std::string& propriete) {
    if (type == "resistance") { propriete = "ohms"; return true; }
    if (type == "condensateur") { propriete = "farads"; return true; }
    if (type == "inductance") { propriete = "henrys"; return true; }
    return false;
}

Campagne balayer_parametre(const Netlist& netlist,
                           const std::vector<BrocheElectrique>& broches,
                           const std::string& reference,
                           const std::string& propriete,
                           const std::vector<double>& valeurs,
                           const std::string& directive) {
    Campagne campagne;
    campagne.parametre = reference + "." + propriete;
    for (double valeur : valeurs) {
        // La netlist est recopiée à chaque passe : modifier l'originale
        // ferait dépendre chaque résultat du précédent.
        Netlist essai = netlist;
        Instance* instance = essai.trouver(reference);
        if (!instance) {
            campagne.erreurs.push_back("composant introuvable : " + reference);
            break;
        }
        instance->valeurs[propriete] = valeur;

        Passe passe;
        passe.valeur = valeur;
        passe.etiquette = reference + " = " + format_court(valeur);
        if (executer(essai, broches, directive, passe.balayage, campagne.erreurs))
            campagne.passes.push_back(std::move(passe));
    }
    return campagne;
}

Campagne monte_carlo(const Netlist& netlist,
                     const std::vector<BrocheElectrique>& broches,
                     double tolerance, int tirages, const std::string& directive,
                     unsigned graine) {
    Campagne campagne;
    std::ostringstream titre;
    titre << "tolérance ±" << tolerance << " %";
    campagne.parametre = titre.str();
    if (tirages < 1) return campagne;

    // Générateur à graine fixe : un résultat qu'on ne peut pas refaire à
    // l'identique ne prouve rien.
    std::mt19937 hasard(graine);
    std::uniform_real_distribution<double> loi(-tolerance / 100.0,
                                               tolerance / 100.0);

    for (int tirage = 0; tirage < tirages; ++tirage) {
        Netlist essai = netlist;
        // Le premier tirage garde les valeurs nominales : c'est la référence
        // à laquelle on compare les autres.
        if (tirage > 0) {
            for (Instance& instance : essai.instances()) {
                std::string propriete;
                if (!valeur_tolerancee(instance.type, propriete)) continue;
                const Modele* modele = Catalogue::instance().modele(instance.type);
                double nominale = instance.valeur(propriete, 0.0);
                if (nominale == 0.0 && modele)
                    for (const Propriete& p : modele->proprietes)
                        if (p.cle == propriete) nominale = p.defaut;
                if (nominale <= 0) continue;
                instance.valeurs[propriete] = nominale * (1.0 + loi(hasard));
            }
        }

        Passe passe;
        passe.valeur = tirage;
        passe.etiquette = tirage == 0 ? std::string("valeurs nominales")
                                      : "tirage " + std::to_string(tirage);
        if (executer(essai, broches, directive, passe.balayage, campagne.erreurs))
            campagne.passes.push_back(std::move(passe));
    }
    return campagne;
}

Dispersion disperser(const Campagne& campagne, const std::string& courbe,
                     double abscisse) {
    Dispersion dispersion;
    std::vector<double> releves;
    for (const Passe& passe : campagne.passes) {
        const Courbe* trouvee = passe.balayage.courbe(courbe);
        if (!trouvee || trouvee->valeurs.empty()) continue;
        // Point le plus proche de l'abscisse demandée : les passes n'ont pas
        // forcément les mêmes points de calcul.
        size_t meilleur = 0;
        double ecart = std::fabs(passe.balayage.abscisse.front() - abscisse);
        for (size_t k = 1; k < passe.balayage.abscisse.size()
                           && k < trouvee->valeurs.size(); ++k) {
            const double candidat = std::fabs(passe.balayage.abscisse[k] - abscisse);
            if (candidat >= ecart) continue;
            ecart = candidat;
            meilleur = k;
        }
        releves.push_back(trouvee->valeurs[meilleur]);
    }
    if (releves.empty()) return dispersion;

    dispersion.valide = true;
    dispersion.passes = static_cast<int>(releves.size());
    dispersion.mini = *std::min_element(releves.begin(), releves.end());
    dispersion.maxi = *std::max_element(releves.begin(), releves.end());
    double somme = 0;
    for (double valeur : releves) somme += valeur;
    dispersion.moyenne = somme / releves.size();
    double carres = 0;
    for (double valeur : releves) {
        const double ecart = valeur - dispersion.moyenne;
        carres += ecart * ecart;
    }
    dispersion.ecart_type = std::sqrt(carres / releves.size());
    return dispersion;
}

}  // namespace coeur
