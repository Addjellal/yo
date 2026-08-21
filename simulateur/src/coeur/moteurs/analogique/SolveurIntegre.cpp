#include "coeur/moteurs/analogique/SolveurIntegre.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <complex>
#include <cstdlib>
#include <cstring>
#include <set>
#include <sstream>

#include "coeur/moteurs/analogique/NgspiceEngine.h"   // pour Formes

namespace coeur {

namespace {

constexpr double kPi = 3.14159265358979323846;
constexpr double kBoltzmann = 1.380649e-23;
constexpr double kCharge = 1.602176634e-19;
constexpr double kGmin = 1e-12;

std::string minuscules(std::string texte) {
    std::transform(texte.begin(), texte.end(), texte.begin(),
                   [](unsigned char c) { return std::tolower(c); });
    return texte;
}

// Valeur SPICE : « 4.7k », « 100n », « 1meg », « 1e-7 ». Le suffixe l'emporte
// sur la casse — SPICE ne distingue pas « M » de « m », et « MEG » seul veut
// dire méga.
double valeur_spice(const std::string& texte) {
    if (texte.empty()) return 0.0;
    char* fin = nullptr;
    const double base = std::strtod(texte.c_str(), &fin);
    if (!fin || *fin == '\0') return base;

    std::string suffixe = minuscules(fin);
    // On tolère les unités collées : « 10k », « 10kohm », « 1meg ».
    if (suffixe.rfind("meg", 0) == 0) return base * 1e6;
    switch (suffixe[0]) {
        case 't': return base * 1e12;
        case 'g': return base * 1e9;
        case 'k': return base * 1e3;
        case 'm':
            if (suffixe.rfind("mil", 0) == 0) return base * 25.4e-6;
            return base * 1e-3;
        case 'u': return base * 1e-6;
        case 'n': return base * 1e-9;
        case 'p': return base * 1e-12;
        case 'f': return base * 1e-15;
        default: return base;
    }
}

std::vector<std::string> decouper(const std::string& ligne) {
    std::vector<std::string> mots;
    std::istringstream flux(ligne);
    std::string mot;
    while (flux >> mot) mots.push_back(mot);
    return mots;
}

// Isole les parenthèses et les virgules pour que « SIN(0 1 1000) » se découpe
// comme le reste.
std::string aerer(const std::string& ligne) {
    std::string resultat;
    for (char c : ligne) {
        if (c == '(' || c == ')' || c == ',') {
            resultat += ' ';
            resultat += c;
            resultat += ' ';
        } else {
            resultat += c;
        }
    }
    return resultat;
}

// Limitation des tensions de jonction : sans elle, la première itération de
// Newton envoie l'exponentielle à l'infini et le calcul ne repart jamais.
// C'est la fonction `pnjlim` de SPICE.
double limiter_jonction(double neuve, double ancienne, double vt, double vcrit,
                        bool& limitee) {
    limitee = false;
    if (neuve > vcrit && std::fabs(neuve - ancienne) > 2 * vt) {
        limitee = true;
        if (ancienne > 0) {
            const double argument = 1 + (neuve - ancienne) / vt;
            neuve = argument > 0 ? ancienne + vt * std::log(argument)
                                 : vcrit;
        } else {
            neuve = vt * std::log(std::max(neuve / vt, 1e-12));
        }
    } else if (neuve < 0) {
        const double plancher = ancienne > 0 ? -1.0 : ancienne - 10 * vt;
        if (neuve < plancher) {
            neuve = plancher;
            limitee = true;
        }
    }
    return neuve;
}

double exponentielle_bornee(double x) {
    return std::exp(std::min(x, 60.0));
}

// --- modèle de composant ---------------------------------------------------
struct ModeleSpice {
    std::string nom;
    std::string type;                       // "D", "NPN", "PNP", "NMOS", "SW"
    std::map<std::string, double> parametres;

    double lire(const char* cle, double defaut) const {
        auto it = parametres.find(cle);
        return it == parametres.end() ? defaut : it->second;
    }
};

// --- source indépendante ---------------------------------------------------
struct SourceSpice {
    double continu = 0;
    double alternatif = 0;                  // module de l'excitation .ac
    bool sinusoidale = false;
    double offset = 0, amplitude = 0, frequence = 0, retard = 0;
    // PULSE(v1 v2 retard montee descente largeur periode) : le créneau de
    // SPICE, dont le générateur de signaux se sert pour le carré et le
    // triangle.
    bool impulsion = false;
    double v1 = 0, v2 = 0, montee = 0, descente = 0, largeur = 0, periode = 0;
    std::vector<std::pair<double, double>> lineaire_par_morceaux;

    // Instants où la source change de pente : le calcul doit s'y arrêter,
    // sinon un front de cent nanosecondes passe entre deux pas.
    void ruptures(double fin, std::set<double>& points) const {
        for (const auto& point : lineaire_par_morceaux)
            if (point.first > 0 && point.first < fin) points.insert(point.first);
        if (!impulsion || periode <= 0) return;
        for (double debut = retard; debut < fin; debut += periode) {
            const double coudes[] = {debut, debut + montee,
                                     debut + montee + largeur,
                                     debut + montee + largeur + descente};
            for (double coude : coudes)
                if (coude > 0 && coude < fin) points.insert(coude);
        }
    }

    double valeur(double instant) const {
        if (!lineaire_par_morceaux.empty()) {
            const auto& points = lineaire_par_morceaux;
            if (instant <= points.front().first) return points.front().second;
            if (instant >= points.back().first) return points.back().second;
            for (size_t k = 1; k < points.size(); ++k) {
                if (instant > points[k].first) continue;
                const double t0 = points[k - 1].first, v0 = points[k - 1].second;
                const double t1 = points[k].first, v1 = points[k].second;
                if (t1 - t0 < 1e-18) return v1;
                return v0 + (v1 - v0) * (instant - t0) / (t1 - t0);
            }
            return points.back().second;
        }
        if (impulsion) {
            if (periode <= 0) return v1;
            if (instant < retard) return v1;
            double phase = std::fmod(instant - retard, periode);
            if (phase < 0) phase += periode;
            if (montee > 0 && phase < montee)
                return v1 + (v2 - v1) * phase / montee;
            if (phase < montee + largeur) return v2;
            if (descente > 0 && phase < montee + largeur + descente)
                return v2 - (v2 - v1) * (phase - montee - largeur) / descente;
            return v1;
        }
        if (sinusoidale) {
            if (instant < retard) return offset;
            return offset
                   + amplitude
                         * std::sin(2 * kPi * frequence * (instant - retard));
        }
        return continu;
    }
};

// --- élément du circuit ----------------------------------------------------
struct Element {
    char genre = 'R';
    std::string nom;                        // minuscules, lettre comprise
    int a = -1, b = -1, c = -1, d = -1;     // bornes externes
    int interne1 = -1, interne2 = -1, interne3 = -1;
    double valeur = 0;
    double largeur = 1, longueur = 1;       // MOS : W et L
    SourceSpice source;
    const ModeleSpice* modele = nullptr;
    std::string nom_modele;                 // résolu une fois le fichier lu
    ExpressionSpice expression;
    int branche = -1;                       // inconnue de courant
    int mesure = -1;                        // F : branche de la source mesurée
    double gain = 0;

    // État d'intégration.
    double tension_precedente = 0;
    double courant_precedent = 0;
    // État de Newton (tensions de jonction retenues d'une itération à l'autre).
    double vd = 0, vbe = 0, vbc = 0, vgs = 0, vds = 0;
    // Limitation d'une source comportementale entre deux itérations.
    bool b_initialisee = false;
    double b_precedente = 0, b_delta = 0, b_pas = 5.0;
    // Linéarisation au point de fonctionnement, réutilisée en alternatif.
    double gd = 0, ieq = 0;
    double gm = 0, gmu = 0, gpi = 0, gmub = 0, go = 0, ieqc = 0, ieqb = 0;
    double courant = 0;                     // relevé
};

}  // namespace

// ---------------------------------------------------------------------------
struct SolveurIntegre::Impl {
    std::map<std::string, int> indices;
    std::vector<std::string> noms_noeuds;
    std::vector<Element> elements;
    std::map<std::string, ModeleSpice> modeles;
    std::vector<std::string> directives;

    int nb_noeuds = 0;
    int nb_branches = 0;
    int taille = 0;
    double temperature = 27.0;

    std::map<int, double> conditions_initiales;
    bool uic = false;

    // Système linéaire.
    std::vector<double> matrice, second_membre, solution;
    std::vector<std::complex<double>> matrice_c, second_membre_c, solution_c;

    std::vector<std::string> erreurs;

    // --- construction ------------------------------------------------------
    int noeud(const std::string& nom_brut) {
        const std::string nom = minuscules(nom_brut);
        if (nom == "0" || nom == "gnd") return -1;
        auto it = indices.find(nom);
        if (it != indices.end()) return it->second;
        const int indice = nb_noeuds++;
        indices[nom] = indice;
        noms_noeuds.push_back(nom);
        return indice;
    }

    int noeud_interne(const std::string& nom) {
        return noeud("#" + nom);
    }

    // --- accès au système --------------------------------------------------
    void ajouter(int ligne, int colonne, double valeur) {
        if (ligne < 0 || colonne < 0) return;
        matrice[static_cast<size_t>(ligne) * taille + colonne] += valeur;
    }
    void conductance(int a, int b, double g) {
        ajouter(a, a, g);
        ajouter(b, b, g);
        ajouter(a, b, -g);
        ajouter(b, a, -g);
    }
    void injecter(int noeud_cible, double courant) {
        if (noeud_cible >= 0) second_membre[noeud_cible] += courant;
    }
    // Courant `valeur` circulant de `de` vers `vers` à travers l'élément.
    void source_courant(int de, int vers, double valeur) {
        injecter(de, -valeur);
        injecter(vers, valeur);
    }

    double tension(const std::vector<double>& x, int noeud_lu) const {
        return noeud_lu >= 0 && noeud_lu < static_cast<int>(x.size())
                   ? x[noeud_lu]
                   : 0.0;
    }

    double thermique() const {
        return kBoltzmann * (temperature + 273.15) / kCharge;
    }

    // Courant de saturation à la température de travail. C'est lui qui fait
    // baisser la tension de seuil d'une jonction quand elle chauffe — environ
    // deux millivolts par degré. Sans cette correction, le modèle ferait
    // l'inverse, puisque seul kT/q augmenterait.
    double saturation_chaude(double is, double n) const {
        constexpr double kNominale = 300.15;      // 27 °C
        constexpr double kBandeInterdite = 1.11;  // eV, silicium
        constexpr double kExposant = 3.0;         // XTI
        const double t = temperature + 273.15;
        if (t <= 0 || std::fabs(t - kNominale) < 1e-9) return is;
        const double rapport = t / kNominale;
        const double vt = kBoltzmann * t / kCharge;
        const double vt_nominal = kBoltzmann * kNominale / kCharge;
        return is * std::pow(rapport, kExposant / n)
               * std::exp(-kBandeInterdite / (n * vt)
                          + kBandeInterdite / (n * vt_nominal));
    }

    // --- résolution --------------------------------------------------------
    template <typename Scalaire>
    static bool eliminer(std::vector<Scalaire>& a, std::vector<Scalaire>& b,
                         int n) {
        // Équilibrage des lignes. Une source commandée à fort gain met un
        // coefficient de 10^5 à côté de conductances de 10^-3 : sans mise à
        // l'échelle, le pivot se perd dans les erreurs d'arrondi et une
        // chaîne d'amplificateurs devient insoluble.
        for (int ligne = 0; ligne < n; ++ligne) {
            double maximum = 0;
            for (int k = 0; k < n; ++k)
                maximum = std::max(maximum,
                                   std::abs(a[static_cast<size_t>(ligne) * n + k]));
            if (maximum <= 0) continue;
            const double facteur = 1.0 / maximum;
            for (int k = 0; k < n; ++k)
                a[static_cast<size_t>(ligne) * n + k] *= facteur;
            b[ligne] *= facteur;
        }
        for (int colonne = 0; colonne < n; ++colonne) {
            int pivot = colonne;
            double meilleur = std::abs(a[static_cast<size_t>(colonne) * n + colonne]);
            for (int ligne = colonne + 1; ligne < n; ++ligne) {
                const double candidat =
                    std::abs(a[static_cast<size_t>(ligne) * n + colonne]);
                if (candidat > meilleur) {
                    meilleur = candidat;
                    pivot = ligne;
                }
            }
            if (meilleur < 1e-18) return false;
            if (pivot != colonne) {
                for (int k = 0; k < n; ++k)
                    std::swap(a[static_cast<size_t>(colonne) * n + k],
                              a[static_cast<size_t>(pivot) * n + k]);
                std::swap(b[colonne], b[pivot]);
            }
            const Scalaire diagonale = a[static_cast<size_t>(colonne) * n + colonne];
            for (int ligne = colonne + 1; ligne < n; ++ligne) {
                const Scalaire facteur =
                    a[static_cast<size_t>(ligne) * n + colonne] / diagonale;
                if (std::abs(facteur) == 0.0) continue;
                for (int k = colonne; k < n; ++k)
                    a[static_cast<size_t>(ligne) * n + k] -=
                        facteur * a[static_cast<size_t>(colonne) * n + k];
                b[ligne] -= facteur * b[colonne];
            }
        }
        for (int ligne = n - 1; ligne >= 0; --ligne) {
            Scalaire somme = b[ligne];
            for (int k = ligne + 1; k < n; ++k)
                somme -= a[static_cast<size_t>(ligne) * n + k] * b[k];
            b[ligne] = somme / a[static_cast<size_t>(ligne) * n + ligne];
        }
        return true;
    }

    enum class Mode { Continu, Transitoire, ConditionsInitiales };

    void preparer_systeme() {
        matrice.assign(static_cast<size_t>(taille) * taille, 0.0);
        second_membre.assign(taille, 0.0);
    }

    // Linéarise et empile tous les éléments.
    void assembler(const std::vector<double>& x, double instant, double pas,
                   Mode mode, bool trapeze, double gmin);
    // Vrai si l'assemblage précédent a dû brider une source : tant que c'est
    // le cas, on n'a pas le droit de déclarer la convergence.
    bool limitation_appliquee = false;

    // Facteur appliqué aux sources indépendantes. Vaut un, sauf pendant le
    // « pas sur les sources » : voir resoudre_newton.
    double echelle_sources = 1.0;
    bool resoudre_newton(std::vector<double>& x, double instant, double pas,
                         Mode mode, bool trapeze);

    void relever_courants(const std::vector<double>& x, double pas, Mode mode,
                          bool trapeze);
    void memoriser_etat(const std::vector<double>& x, double pas, Mode mode,
                        bool trapeze);

    // Analyse alternative autour du point de fonctionnement courant.
    bool resoudre_alternatif(double frequence, std::vector<std::complex<double>>& x,
                             int injection_a = -2, int injection_b = -2);
    // Courant complexe traversant chaque élément, déduit de la solution
    // alternative. Sans cela une réponse en fréquence ne montre que des
    // tensions, et l'on ne peut ni lire l'impédance d'un montage ni voir le
    // pic de courant d'un RLC série — qui est justement là où le montage
    // consomme.
    void courants_alternatifs(
        const std::vector<std::complex<double>>& x, double frequence,
        std::vector<std::pair<std::string, std::complex<double>>>* sortie) const;
};

// ---------------------------------------------------------------------------
// Assemblage
// ---------------------------------------------------------------------------
void SolveurIntegre::Impl::assembler(const std::vector<double>& x,
                                     double instant, double pas, Mode mode,
                                     bool trapeze, double gmin) {
    preparer_systeme();
    limitation_appliquee = false;
    const double vt = thermique();

    // Conductance minimale vers la masse : c'est ce qui évite qu'un nœud
    // laissé en l'air rende la matrice singulière.
    for (int k = 0; k < nb_noeuds; ++k) ajouter(k, k, gmin);

    for (Element& element : elements) {
        switch (element.genre) {
            case 'R': {
                const double resistance = std::max(element.valeur, 1e-9);
                conductance(element.a, element.b, 1.0 / resistance);
                break;
            }
            case 'C': {
                // Le condensateur porte une inconnue de courant, mais elle ne
                // sert qu'à l'état initial : ailleurs, il faut quand même une
                // équation pour cette ligne, sans quoi la matrice est
                // singulière.
                if (mode != Mode::ConditionsInitiales)
                    ajouter(element.branche, element.branche, 1.0);
                if (mode == Mode::Continu) break;         // circuit ouvert
                if (mode == Mode::ConditionsInitiales) {
                    // Le condensateur impose sa tension initiale : c'est ce
                    // que veut dire « uic ».
                    const int branche = element.branche;
                    ajouter(element.a, branche, 1.0);
                    ajouter(element.b, branche, -1.0);
                    ajouter(branche, element.a, 1.0);
                    ajouter(branche, element.b, -1.0);
                    second_membre[branche] += element.tension_precedente;
                    break;
                }
                const double capacite = element.valeur;
                if (pas <= 0) break;
                if (trapeze) {
                    const double geq = 2 * capacite / pas;
                    const double ieq = geq * element.tension_precedente
                                       + element.courant_precedent;
                    conductance(element.a, element.b, geq);
                    source_courant(element.b, element.a, ieq);
                } else {
                    const double geq = capacite / pas;
                    const double ieq = geq * element.tension_precedente;
                    conductance(element.a, element.b, geq);
                    source_courant(element.b, element.a, ieq);
                }
                break;
            }
            case 'L': {
                const int branche = element.branche;
                ajouter(element.a, branche, 1.0);
                ajouter(element.b, branche, -1.0);
                ajouter(branche, element.a, 1.0);
                ajouter(branche, element.b, -1.0);
                if (mode == Mode::Continu) {
                    // court-circuit : v = 0
                } else if (mode == Mode::ConditionsInitiales) {
                    // courant initial imposé (nul par défaut) : la bobine se
                    // comporte en source de courant.
                    ajouter(branche, element.a, -1.0);
                    ajouter(branche, element.b, 1.0);
                    ajouter(branche, branche, 1.0);
                    second_membre[branche] += element.courant_precedent;
                } else if (pas > 0) {
                    const double facteur =
                        trapeze ? 2 * element.valeur / pas : element.valeur / pas;
                    ajouter(branche, branche, -facteur);
                    second_membre[branche] -= facteur * element.courant_precedent;
                    if (trapeze)
                        second_membre[branche] -= element.tension_precedente;
                }
                break;
            }
            case 'V': {
                const int branche = element.branche;
                ajouter(element.a, branche, 1.0);
                ajouter(element.b, branche, -1.0);
                ajouter(branche, element.a, 1.0);
                ajouter(branche, element.b, -1.0);
                second_membre[branche] +=
                    echelle_sources
                    * (mode == Mode::Continu ? element.source.valeur(0.0)
                                             : element.source.valeur(instant));
                break;
            }
            case 'I': {
                const double courant =
                    echelle_sources
                    * (mode == Mode::Continu ? element.source.valeur(0.0)
                                             : element.source.valeur(instant));
                source_courant(element.a, element.b, courant);
                break;
            }
            case 'D': {
                const ModeleSpice* modele = element.modele;
                const double n = modele ? modele->lire("N", 1.0) : 1.0;
                const double is =
                    saturation_chaude(modele ? modele->lire("IS", 1e-14) : 1e-14,
                                      n);
                const double bv = modele ? modele->lire("BV", 0.0) : 0.0;
                const double ibv = modele ? modele->lire("IBV", 1e-3) : 1e-3;
                const int anode = element.interne1 >= 0 ? element.interne1
                                                        : element.a;
                if (element.interne1 >= 0) {
                    const double rs = modele ? modele->lire("RS", 0.0) : 0.0;
                    conductance(element.a, element.interne1,
                                1.0 / std::max(rs, 1e-9));
                }
                const double nvt = n * vt;
                const double vcrit = nvt * std::log(nvt / (std::sqrt(2.0) * is));
                bool limitee = false;
                double v = tension(x, anode) - tension(x, element.b);
                v = limiter_jonction(v, element.vd, nvt, vcrit, limitee);
                // Tant qu'on bride la jonction, la solution n'est pas la
                // bonne : le petit écart entre deux itérations vient de la
                // bride, pas de la convergence.
                if (limitee) limitation_appliquee = true;
                element.vd = v;

                // Conduction directe et claquage inverse s'ADDITIONNENT au
                // lieu de s'exclure. C'est ce qui rend le courant continu.
                //
                // L'ancienne écriture basculait d'une branche à l'autre à
                // v = -BV, et le courant y sautait de zéro à IBV — cinq
                // milliampères d'un coup. Newton ne traverse pas une
                // discontinuité : le point de repos d'une Zener 5V1 sous 9 V
                // ne convergeait pas, parce que le courant qu'il lui faut
                // (3,9 mA) tombe précisément DANS le saut. Sous 12 V il en
                // faut 6,9, au-delà du saut, et tout allait bien — d'où un
                // défaut qui ne se voyait qu'en dessous d'un certain seuil.
                //
                // Le terme de claquage est écrit en (exp - 1) : il s'annule
                // exactement à v = -BV et croît en dessous. Le courant est
                // donc continu ; seule sa pente a un coude, ce que Newton
                // encaisse sans peine.
                const double exposant = exponentielle_bornee(v / nvt);
                double courant_diode = is * (exposant - 1.0);
                double conductance_diode = is * exposant / nvt;
                if (bv > 0) {
                    // Claquage inverse, dans la formulation de SPICE — celle
                    // de diotemp.c et dioload.c de ngspice, et non une
                    // approximation.
                    //
                    // Deux choses la caractérisent, et les deux comptent :
                    //
                    //   1. le terme « - 1 + vb/vt » raccorde l'exponentielle
                    //      au courant de fuite. Sans lui le courant SAUTE de
                    //      zéro à IBV à la tension de claquage, et Newton ne
                    //      traverse pas une discontinuité — une Zener 5V1 sous
                    //      9 V ne convergeait pas, parce que les 3,9 mA qu'il
                    //      lui faut tombent précisément dans ce saut ;
                    //
                    //   2. la tension de claquage employée n'est PAS BV mais
                    //      une valeur ajustée vb, cherchée par itération pour
                    //      que le courant vaille exactement IBV à V = BV.
                    //      C'est ce qui rend la fiche du constructeur
                    //      respectée : « 5,1 V sous 5 mA » veut dire cela et
                    //      rien d'autre.
                    const double vt_seul = nvt / std::max(n, 1e-9);
                    double vb = bv;
                    double courant_bv = ibv;
                    // Une valeur d'IBV plus petite que le courant de fuite à
                    // BV n'a pas de sens : ngspice la relève, et sans cela le
                    // logarithme ci-dessous prendrait un argument négatif.
                    if (courant_bv < is * bv / vt_seul) {
                        courant_bv = is * bv / vt_seul;
                        vb = bv;
                    } else {
                        vb = bv - vt_seul * std::log(1 + courant_bv / is);
                        for (int tour = 0; tour < 25; ++tour) {
                            const double argument =
                                courant_bv / is + 1 - vb / vt_seul;
                            if (argument <= 0) break;
                            vb = bv - vt_seul * std::log(argument);
                            const double obtenu =
                                is * (exponentielle_bornee((bv - vb) / vt_seul)
                                      - 1 + vb / vt_seul);
                            if (std::fabs(obtenu - courant_bv)
                                <= 1e-3 * courant_bv + 1e-12)
                                break;
                        }
                    }
                    if (v < -vb) {
                        const double claquage =
                            exponentielle_bornee(-(v + vb) / vt_seul);
                        courant_diode =
                            -is * (claquage - 1 + vb / vt_seul);
                        conductance_diode = is * claquage / vt_seul;
                    }
                }
                conductance_diode = std::max(conductance_diode, kGmin);
                const double equivalent = courant_diode - conductance_diode * v;
                conductance(anode, element.b, conductance_diode);
                source_courant(anode, element.b, equivalent);
                element.gd = conductance_diode;
                element.ieq = equivalent;
                element.courant = courant_diode;
                break;
            }
            case 'Q': {
                const ModeleSpice* modele = element.modele;
                const bool pnp = modele && modele->type == "PNP";
                const double signe = pnp ? -1.0 : 1.0;
                const double is =
                    saturation_chaude(modele ? modele->lire("IS", 1e-16) : 1e-16,
                                      1.0);
                const double bf = modele ? modele->lire("BF", 100.0) : 100.0;
                const double br = modele ? modele->lire("BR", 1.0) : 1.0;
                const double vaf = modele ? modele->lire("VAF", 0.0) : 0.0;

                const int nc = element.interne1 >= 0 ? element.interne1 : element.a;
                const int nb = element.interne2 >= 0 ? element.interne2 : element.b;
                const int ne = element.interne3 >= 0 ? element.interne3 : element.c;
                if (element.interne1 >= 0)
                    conductance(element.a, element.interne1,
                                1.0 / std::max(modele->lire("RC", 0.0), 1e-9));
                if (element.interne2 >= 0)
                    conductance(element.b, element.interne2,
                                1.0 / std::max(modele->lire("RB", 0.0), 1e-9));
                if (element.interne3 >= 0)
                    conductance(element.c, element.interne3,
                                1.0 / std::max(modele->lire("RE", 0.0), 1e-9));

                const double vcrit = vt * std::log(vt / (std::sqrt(2.0) * is));
                bool limitee = false;
                double vbe = signe * (tension(x, nb) - tension(x, ne));
                double vbc = signe * (tension(x, nb) - tension(x, nc));
                vbe = limiter_jonction(vbe, element.vbe, vt, vcrit, limitee);
                if (limitee) limitation_appliquee = true;
                vbc = limiter_jonction(vbc, element.vbc, vt, vcrit, limitee);
                if (limitee) limitation_appliquee = true;
                element.vbe = vbe;
                element.vbc = vbc;

                const double expbe = exponentielle_bornee(vbe / vt);
                const double expbc = exponentielle_bornee(vbc / vt);
                // Modèle d'Ebers-Moll, version transport.
                double courant_collecteur =
                    is * ((expbe - expbc) - (expbc - 1.0) / br);
                double courant_base =
                    is * ((expbe - 1.0) / bf + (expbc - 1.0) / br);
                double gm = is * expbe / vt;
                double gmu = -is * expbc / vt * (1.0 + 1.0 / br);
                double gpi = is * expbe / (bf * vt);
                double gmub = is * expbc / (br * vt);
                double go = 0;
                if (vaf > 0) {
                    // Effet Early : la pente de sortie n'est plus nulle.
                    go = std::fabs(courant_collecteur) / vaf;
                    courant_collecteur *= (1.0 + (vbe - vbc) / vaf);
                }
                gpi = std::max(gpi, kGmin);

                const double ieqc =
                    courant_collecteur - gm * vbe - gmu * vbc;
                const double ieqb = courant_base - gpi * vbe - gmub * vbc;

                // Courant sortant de chaque nœud (voir l'entête : le sens est
                // celui du courant entrant dans la borne du composant).
                ajouter(nc, nb, signe * signe * (gm + gmu));
                ajouter(nc, ne, -signe * signe * gm);
                ajouter(nc, nc, -signe * signe * gmu + go);
                ajouter(nc, ne, -go);
                ajouter(nb, nb, gpi + gmub);
                ajouter(nb, ne, -gpi);
                ajouter(nb, nc, -gmub);
                ajouter(ne, nb, -(gm + gmu + gpi + gmub));
                ajouter(ne, ne, gm + gpi + go);
                ajouter(ne, nc, gmu + gmub - go);
                injecter(nc, -signe * ieqc);
                injecter(nb, -signe * ieqb);
                injecter(ne, signe * (ieqc + ieqb));

                element.gm = gm;
                element.gmu = gmu;
                element.gpi = gpi;
                element.gmub = gmub;
                element.go = go;
                element.courant = signe * courant_collecteur;
                break;
            }
            case 'M': {
                const ModeleSpice* modele = element.modele;
                const bool pmos = modele && modele->type == "PMOS";
                const double signe = pmos ? -1.0 : 1.0;
                const double seuil = modele ? modele->lire("VTO", 1.0) : 1.0;
                const double kp = modele ? modele->lire("KP", 2e-5) : 2e-5;
                const double lambda = modele ? modele->lire("LAMBDA", 0.0) : 0.0;
                const double beta = kp * element.largeur / element.longueur;

                double vgs = signe * (tension(x, element.b) - tension(x, element.c));
                double vds = signe * (tension(x, element.a) - tension(x, element.c));
                // Amortissement : un MOS qui saute d'un extrême à l'autre
                // empêche Newton de converger.
                vgs = element.vgs + std::max(-2.0, std::min(2.0, vgs - element.vgs));
                vds = element.vds + std::max(-2.0, std::min(2.0, vds - element.vds));
                element.vgs = vgs;
                element.vds = vds;

                double courant_drain = 0, gm = 0, gds = 0;
                const double surtension = vgs - seuil;
                if (surtension <= 0) {
                    courant_drain = 0;
                    gm = 0;
                    gds = kGmin;
                } else if (vds >= surtension) {          // saturation
                    const double base = 0.5 * beta * surtension * surtension;
                    courant_drain = base * (1 + lambda * vds);
                    gm = beta * surtension * (1 + lambda * vds);
                    gds = base * lambda + kGmin;
                } else {                                  // régime ohmique
                    const double base =
                        beta * (surtension * vds - 0.5 * vds * vds);
                    courant_drain = base * (1 + lambda * vds);
                    gm = beta * vds * (1 + lambda * vds);
                    gds = beta * (surtension - vds) * (1 + lambda * vds)
                          + base * lambda + kGmin;
                }
                const double equivalent = courant_drain - gm * vgs - gds * vds;
                ajouter(element.a, element.b, signe * signe * gm);
                ajouter(element.a, element.c, -signe * signe * gm);
                conductance(element.a, element.c, gds);
                injecter(element.a, -signe * equivalent);
                injecter(element.c, signe * equivalent);
                // La grille ne prend pas de courant continu.
                element.gm = gm;
                element.go = gds;
                element.courant = signe * courant_drain;
                break;
            }
            case 'S': {
                const ModeleSpice* modele = element.modele;
                const double seuil = modele ? modele->lire("VT", 0.0) : 0.0;
                const double hysteresis = modele ? modele->lire("VH", 0.0) : 0.0;
                const double ferme = modele ? modele->lire("RON", 1.0) : 1.0;
                const double ouvert = modele ? modele->lire("ROFF", 1e12) : 1e12;
                const double commande =
                    tension(x, element.c) - tension(x, element.d);
                double resistance;
                const double marge = std::max(hysteresis, 1e-3);
                if (commande > seuil + marge) {
                    resistance = ferme;
                } else if (commande < seuil - marge) {
                    resistance = ouvert;
                } else {
                    // Transition continue : un saut franc empêcherait Newton
                    // de converger.
                    const double part = (commande - (seuil - marge)) / (2 * marge);
                    resistance = std::exp(std::log(ouvert)
                                          + part * (std::log(ferme)
                                                    - std::log(ouvert)));
                }
                conductance(element.a, element.b, 1.0 / std::max(resistance, 1e-9));
                element.gd = 1.0 / std::max(resistance, 1e-9);
                break;
            }
            case 'B': {
                const int branche = element.branche;
                ajouter(element.a, branche, 1.0);
                ajouter(element.b, branche, -1.0);
                ajouter(branche, element.a, 1.0);
                ajouter(branche, element.b, -1.0);

                double valeur = element.expression.evaluer(x);
                // Une porte logique ou un amplificateur saturé passe d'une
                // butée à l'autre sans rien entre les deux : Newton y oscille
                // indéfiniment. On bride le saut, et on le divise par deux à
                // chaque changement de sens — la bissection finit toujours par
                // trouver le coude.
                if (element.b_initialisee) {
                    double delta = valeur - element.b_precedente;
                    if (delta * element.b_delta < 0)
                        element.b_pas = std::max(element.b_pas * 0.5, 1e-13);
                    if (std::fabs(delta) > element.b_pas) {
                        valeur = element.b_precedente
                                 + (delta > 0 ? element.b_pas : -element.b_pas);
                        delta = valeur - element.b_precedente;
                        // Une fois le pas devenu infime, la source ne bouge
                        // plus : la bissection a trouvé son point fixe, et
                        // continuer à refuser la convergence serait absurde.
                        if (element.b_pas > 1e-7) limitation_appliquee = true;
                    }
                    element.b_delta = delta;
                }
                element.b_precedente = valeur;
                element.b_initialisee = true;
                double correction = valeur;
                // Dérivées numériques : elles font de la source comportementale
                // une source commandée, et Newton converge alors comme sur un
                // composant ordinaire.
                std::vector<double> perturbee = x;
                for (int dependance : element.expression.dependances()) {
                    if (dependance < 0 || dependance >= nb_noeuds) continue;
                    const double reference = x[dependance];
                    // Sécante à écart croissant. Une dérivée prise trop près
                    // du point courant vaut zéro dès que la source est en
                    // butée — et une pente nulle, c'est Newton qui saute d'un
                    // rail à l'autre sans jamais voir le coude entre les deux.
                    // On élargit donc l'écart jusqu'à ce que la fonction
                    // bouge : la pente obtenue est plus faible que la vraie,
                    // mais elle pointe dans le bon sens, et c'est tout ce que
                    // demande la méthode de la sécante.
                    static const double ecarts[] = {1e-6, 1e-3, 5e-2, 0.5, 2.0,
                                                    8.0};
                    double pente = 0;
                    bool elargie = false;
                    for (double ecart : ecarts) {
                        perturbee[dependance] = reference + ecart;
                        const double haute = element.expression.evaluer(perturbee);
                        perturbee[dependance] = reference - ecart;
                        const double basse = element.expression.evaluer(perturbee);
                        perturbee[dependance] = reference;
                        pente = (haute - basse) / (2 * ecart);
                        if (std::fabs(pente) > 1e-12) break;
                        elargie = true;
                    }
                    if (std::fabs(pente) < 1e-12) continue;
                    // La pente trouvée au loin est une invention : la vraie
                    // dérivée est nulle ici. On la garde modeste, sans quoi
                    // une chaîne d'étages saturés multiplierait ces gains
                    // fictifs jusqu'à rendre la matrice insoluble.
                    // La pente d'une source comportementale sert à guider
                    // Newton, pas à décrire le composant : la valeur exacte,
                    // elle, vient de l'expression. On la borne donc, sans quoi
                    // cinq étages de gain 200 000 en cascade donnent une
                    // matrice que la double précision ne sait plus inverser.
                    constexpr double kBorne = 10.0;
                    pente = std::max(-kBorne, std::min(kBorne, pente));
                    (void)elargie;
                    ajouter(branche, dependance, -pente);
                    correction -= pente * reference;
                }
                second_membre[branche] += correction;
                break;
            }
            case 'F': {
                if (element.mesure >= 0) {
                    ajouter(element.a, element.mesure, element.gain);
                    ajouter(element.b, element.mesure, -element.gain);
                }
                break;
            }
            default: break;
        }
    }
}

// ---------------------------------------------------------------------------
bool SolveurIntegre::Impl::resoudre_newton(std::vector<double>& x, double instant,
                                           double pas, Mode mode, bool trapeze) {
    // Une chaîne d'amplificateurs saturés demande une bissection par
    // étage : le budget d'itérations doit suivre.
    const int maximum = 600;
    // Rampe de conductance minimale : quand le circuit refuse de converger,
    // on le rend d'abord très résistif, puis on resserre. C'est le « gmin
    // stepping » de SPICE.
    const double rampe[] = {kGmin, 1e-9, 1e-6, 1e-3};
    for (int essai = 3; essai >= 0; --essai) {
        const double gmin = rampe[essai];
        std::vector<double> courant = x;
        bool converge = false;
        for (Element& element : elements) {
            element.b_initialisee = false;
            element.b_pas = 5.0;
            element.b_delta = 0;
        }
        for (int iteration = 0; iteration < maximum; ++iteration) {
            assembler(courant, instant, pas, mode, trapeze, gmin);
            std::vector<double> a = matrice, b = second_membre;
            if (!eliminer(a, b, taille)) break;

            double ecart = 0;
            for (int k = 0; k < taille; ++k) {
                const double variation = std::fabs(b[k] - courant[k]);
                const double tolerance =
                    1e-6 + 1e-3 * std::max(std::fabs(b[k]), std::fabs(courant[k]));
                ecart = std::max(ecart, variation / tolerance);
            }
            if (ecart <= 1.0 && !limitation_appliquee) {
                courant = b;
                converge = true;
                break;
            }
            courant = b;
        }
        if (!converge) continue;
        if (essai == 0) {
            x = courant;
            return true;
        }
        x = courant;   // point de départ du palier suivant
    }

    // --- PAS SUR LES SOURCES ---------------------------------------------
    //
    // La seconde méthode de secours de SPICE, et celle qui traite les cas que
    // la rampe de conductance ne sait pas prendre : au lieu de rendre le
    // circuit résistif, on l'ÉTEINT puis on le rallume par paliers. À chaque
    // palier, la solution du précédent sert de point de départ — Newton part
    // donc toujours d'un état proche, et les jonctions changent de régime
    // progressivement au lieu d'être sautées d'un bond.
    //
    // C'est ce qu'il faut pour un montage qui n'a pas de solution « molle » :
    // une Zener en régulation, une chaîne d'étages saturés, un circuit à
    // rebouclage. La rampe de gmin, elle, ne fait qu'ajouter des fuites, ce
    // qui n'aide pas quand le problème est le CHEMIN vers la solution.
    //
    // Le point de repos seulement : en transitoire, l'état précédent fournit
    // déjà un départ proche, et rien ne justifierait ce coût.
    if (mode == Mode::Continu) {
        static const double paliers[] = {0.05, 0.1, 0.2, 0.35, 0.5, 0.7, 0.85,
                                         1.0};
        std::vector<double> courant(taille, 0.0);
        bool tout_passe = true;
        for (double palier : paliers) {
            echelle_sources = palier;
            bool converge = false;
            for (Element& element : elements) {
                element.b_initialisee = false;
                element.b_pas = 5.0;
                element.b_delta = 0;
            }
            for (int iteration = 0; iteration < maximum; ++iteration) {
                assembler(courant, instant, pas, mode, trapeze, kGmin);
                std::vector<double> a = matrice, b = second_membre;
                if (!eliminer(a, b, taille)) break;
                double ecart = 0;
                for (int k = 0; k < taille; ++k) {
                    const double variation = std::fabs(b[k] - courant[k]);
                    const double tolerance =
                        1e-6
                        + 1e-3 * std::max(std::fabs(b[k]), std::fabs(courant[k]));
                    ecart = std::max(ecart, variation / tolerance);
                }
                courant = b;
                if (ecart <= 1.0 && !limitation_appliquee) {
                    converge = true;
                    break;
                }
            }
            if (!converge) { tout_passe = false; break; }
        }
        echelle_sources = 1.0;
        if (tout_passe) {
            x = courant;
            return true;
        }
    }

    // Les deux méthodes ont échoué : le circuit n'a pas de point de repos
    // atteignable, et le dire vaut mieux que rendre un résultat inventé.
    return false;
}

void SolveurIntegre::Impl::relever_courants(const std::vector<double>& x,
                                            double pas, Mode mode,
                                            bool trapeze) {
    for (Element& element : elements) {
        switch (element.genre) {
            case 'R':
                element.courant = (tension(x, element.a) - tension(x, element.b))
                                  / std::max(element.valeur, 1e-9);
                break;
            case 'S':
                element.courant =
                    (tension(x, element.a) - tension(x, element.b)) * element.gd;
                break;
            case 'C': {
                const double u = tension(x, element.a) - tension(x, element.b);
                if (mode == Mode::Continu) {
                    element.courant = 0;
                } else if (mode == Mode::ConditionsInitiales) {
                    element.courant = element.branche >= 0 ? x[element.branche] : 0;
                } else if (pas > 0) {
                    element.courant =
                        trapeze ? 2 * element.valeur / pas
                                      * (u - element.tension_precedente)
                                  - element.courant_precedent
                                : element.valeur / pas
                                      * (u - element.tension_precedente);
                }
                break;
            }
            case 'L':
            case 'V':
            case 'B':
                if (element.branche >= 0) element.courant = x[element.branche];
                break;
            case 'I':
                element.courant = element.source.valeur(
                    mode == Mode::Continu ? 0.0 : element.tension_precedente);
                break;
            default: break;    // D, Q, M : relevés pendant l'assemblage
        }
    }
}

void SolveurIntegre::Impl::memoriser_etat(const std::vector<double>& x,
                                          double pas, Mode mode, bool trapeze) {
    relever_courants(x, pas, mode, trapeze);
    for (Element& element : elements) {
        if (element.genre == 'C') {
            element.tension_precedente =
                tension(x, element.a) - tension(x, element.b);
            element.courant_precedent = element.courant;
        } else if (element.genre == 'L') {
            element.courant_precedent =
                element.branche >= 0 ? x[element.branche] : 0.0;
            element.tension_precedente =
                tension(x, element.a) - tension(x, element.b);
        }
    }
}

// ---------------------------------------------------------------------------
// Analyse alternative : mêmes conductances qu'au point de fonctionnement,
// mais les réactances deviennent complexes.
// ---------------------------------------------------------------------------
bool SolveurIntegre::Impl::resoudre_alternatif(
    double frequence, std::vector<std::complex<double>>& x, int injection_a,
    int injection_b) {
    using Complexe = std::complex<double>;
    const double omega = 2 * kPi * frequence;
    std::vector<Complexe> a(static_cast<size_t>(taille) * taille, Complexe(0, 0));
    std::vector<Complexe> b(taille, Complexe(0, 0));

    auto pose = [&](int ligne, int colonne, Complexe valeur) {
        if (ligne < 0 || colonne < 0) return;
        a[static_cast<size_t>(ligne) * taille + colonne] += valeur;
    };
    auto admittance = [&](int n1, int n2, Complexe y) {
        pose(n1, n1, y);
        pose(n2, n2, y);
        pose(n1, n2, -y);
        pose(n2, n1, -y);
    };
    auto injecte = [&](int noeud_cible, Complexe courant) {
        if (noeud_cible >= 0) b[noeud_cible] += courant;
    };

    for (int k = 0; k < nb_noeuds; ++k) pose(k, k, Complexe(kGmin, 0));

    // Quand on injecte une source d'essai (relevé d'une fonction de
    // transfert pour le bruit), les excitations du circuit se taisent.
    const bool sources_actives = injection_a == -2;

    for (const Element& element : elements) {
        switch (element.genre) {
            case 'R':
                admittance(element.a, element.b,
                           Complexe(1.0 / std::max(element.valeur, 1e-9), 0));
                break;
            case 'C':
                admittance(element.a, element.b,
                           Complexe(0, omega * element.valeur));
                pose(element.branche, element.branche, Complexe(1, 0));
                break;
            case 'L': {
                const int branche = element.branche;
                pose(element.a, branche, Complexe(1, 0));
                pose(element.b, branche, Complexe(-1, 0));
                pose(branche, element.a, Complexe(1, 0));
                pose(branche, element.b, Complexe(-1, 0));
                pose(branche, branche, Complexe(0, -omega * element.valeur));
                break;
            }
            case 'V': {
                const int branche = element.branche;
                pose(element.a, branche, Complexe(1, 0));
                pose(element.b, branche, Complexe(-1, 0));
                pose(branche, element.a, Complexe(1, 0));
                pose(branche, element.b, Complexe(-1, 0));
                if (sources_actives)
                    b[branche] += Complexe(element.source.alternatif, 0);
                break;
            }
            case 'I':
                if (sources_actives) {
                    injecte(element.a, Complexe(-element.source.alternatif, 0));
                    injecte(element.b, Complexe(element.source.alternatif, 0));
                }
                break;
            case 'D': {
                const int anode = element.interne1 >= 0 ? element.interne1
                                                        : element.a;
                if (element.interne1 >= 0 && element.modele)
                    admittance(element.a, element.interne1,
                               Complexe(1.0 / std::max(element.modele->lire("RS", 0.0),
                                                       1e-9),
                                        0));
                admittance(anode, element.b, Complexe(element.gd, 0));
                break;
            }
            case 'Q': {
                const ModeleSpice* modele = element.modele;
                const int nc = element.interne1 >= 0 ? element.interne1 : element.a;
                const int nb = element.interne2 >= 0 ? element.interne2 : element.b;
                const int ne = element.interne3 >= 0 ? element.interne3 : element.c;
                if (element.interne1 >= 0)
                    admittance(element.a, nc,
                               Complexe(1.0 / std::max(modele->lire("RC", 0.0), 1e-9), 0));
                if (element.interne2 >= 0)
                    admittance(element.b, nb,
                               Complexe(1.0 / std::max(modele->lire("RB", 0.0), 1e-9), 0));
                if (element.interne3 >= 0)
                    admittance(element.c, ne,
                               Complexe(1.0 / std::max(modele->lire("RE", 0.0), 1e-9), 0));
                pose(nc, nb, Complexe(element.gm + element.gmu, 0));
                pose(nc, ne, Complexe(-element.gm, 0));
                pose(nc, nc, Complexe(-element.gmu + element.go, 0));
                pose(nc, ne, Complexe(-element.go, 0));
                pose(nb, nb, Complexe(element.gpi + element.gmub, 0));
                pose(nb, ne, Complexe(-element.gpi, 0));
                pose(nb, nc, Complexe(-element.gmub, 0));
                pose(ne, nb, Complexe(-(element.gm + element.gmu + element.gpi
                                        + element.gmub), 0));
                pose(ne, ne, Complexe(element.gm + element.gpi + element.go, 0));
                pose(ne, nc, Complexe(element.gmu + element.gmub - element.go, 0));
                break;
            }
            case 'M':
                pose(element.a, element.b, Complexe(element.gm, 0));
                pose(element.a, element.c, Complexe(-element.gm, 0));
                admittance(element.a, element.c, Complexe(element.go, 0));
                break;
            case 'S':
                admittance(element.a, element.b, Complexe(element.gd, 0));
                break;
            case 'B': {
                const int branche = element.branche;
                pose(element.a, branche, Complexe(1, 0));
                pose(element.b, branche, Complexe(-1, 0));
                pose(branche, element.a, Complexe(1, 0));
                pose(branche, element.b, Complexe(-1, 0));
                // Pentes relevées au point de fonctionnement : c'est le gain
                // petit signal de la source comportementale.
                std::vector<double> perturbee = solution;
                const double valeur = element.expression.evaluer(solution);
                for (int dependance : element.expression.dependances()) {
                    if (dependance < 0 || dependance >= nb_noeuds) continue;
                    const double reference = solution[dependance];
                    const double delta =
                        std::max(1e-6, 1e-4 * std::fabs(reference));
                    perturbee[dependance] = reference + delta;
                    const double pente =
                        (element.expression.evaluer(perturbee) - valeur) / delta;
                    perturbee[dependance] = reference;
                    if (std::fabs(pente) < 1e-12) continue;
                    pose(branche, dependance, Complexe(-pente, 0));
                }
                break;
            }
            case 'F':
                if (element.mesure >= 0) {
                    pose(element.a, element.mesure, Complexe(element.gain, 0));
                    pose(element.b, element.mesure, Complexe(-element.gain, 0));
                }
                break;
            default: break;
        }
    }

    // Injection d'une source d'essai : c'est ainsi qu'on relève une fonction
    // de transfert pour l'analyse de bruit.
    if (injection_a != -2) {
        injecte(injection_a, Complexe(-1, 0));
        injecte(injection_b, Complexe(1, 0));
    }

    if (!eliminer(a, b, taille)) return false;
    x = b;
    return true;
}

// ---------------------------------------------------------------------------
// Courants alternatifs
//
// La solution alternative donne les tensions de nœuds et les courants des
// branches explicites (L, V, B). Les autres se déduisent de la loi du
// composant, avec la même admittance que celle empilée plus haut : c'est la
// seule façon d'être cohérent avec la matrice qui vient d'être résolue.
//
// Les transistors sont laissés de côté : leur courant petit signal se répartit
// sur trois bornes, et « I(q1) » ne désignerait rien de précis.
// ---------------------------------------------------------------------------
void SolveurIntegre::Impl::courants_alternatifs(
    const std::vector<std::complex<double>>& x, double frequence,
    std::vector<std::pair<std::string, std::complex<double>>>* sortie) const {
    using Complexe = std::complex<double>;
    const double omega = 2 * kPi * frequence;
    auto potentiel = [&](int noeud) {
        return noeud >= 0 && noeud < static_cast<int>(x.size()) ? x[noeud]
                                                                : Complexe(0, 0);
    };
    auto branche = [&](int rang) {
        return rang >= 0 && rang < static_cast<int>(x.size()) ? x[rang]
                                                              : Complexe(0, 0);
    };
    for (const Element& element : elements) {
        const Complexe u = potentiel(element.a) - potentiel(element.b);
        Complexe courant(0, 0);
        switch (element.genre) {
            case 'R':
                courant = u / std::max(element.valeur, 1e-9);
                break;
            case 'C':
                courant = Complexe(0, omega * element.valeur) * u;
                break;
            case 'L':
            case 'V':
            case 'B':
                courant = branche(element.branche);
                break;
            case 'I':
                courant = Complexe(element.source.alternatif, 0);
                break;
            case 'D': {
                // La diode est vue par sa conductance au point de repos ; la
                // résistance série, quand le modèle en donne une, est déjà
                // dans le nœud interne.
                const int anode =
                    element.interne1 >= 0 ? element.interne1 : element.a;
                courant = Complexe(element.gd, 0)
                          * (potentiel(anode) - potentiel(element.b));
                break;
            }
            default:
                continue;
        }
        // Le nom rendu est celui de l'élément, pas encore « I(...) » : c'est
        // l'appelant qui filtre ce qui appartient au montage, et il a besoin
        // du nom brut pour cela.
        sortie->emplace_back(element.nom, courant);
    }
}

// ---------------------------------------------------------------------------
// Interface publique
// ---------------------------------------------------------------------------
SolveurIntegre::SolveurIntegre() : impl_(new Impl) {}
SolveurIntegre::~SolveurIntegre() { delete impl_; }

bool SolveurIntegre::charger(const std::string& deck) {
    erreurs_.clear();
    tensions_.clear();
    courants_.clear();
    delete impl_;
    impl_ = new Impl;

    std::istringstream flux(deck);
    std::string ligne;
    bool premiere = true;
    // On note l'INDICE de l'élément, jamais son adresse : le vecteur grandit
    // au fil de la lecture et déplace ce qu'il contient.
    std::vector<std::pair<size_t, std::string>> mesures_a_lier;
    std::vector<std::pair<size_t, std::string>> expressions;

    while (std::getline(flux, ligne)) {
        // Nettoyage : commentaires et espaces.
        const size_t commentaire = ligne.find(';');
        if (commentaire != std::string::npos) ligne = ligne.substr(0, commentaire);
        while (!ligne.empty() && std::isspace(static_cast<unsigned char>(ligne.back())))
            ligne.pop_back();
        size_t debut = 0;
        while (debut < ligne.size()
               && std::isspace(static_cast<unsigned char>(ligne[debut])))
            ++debut;
        ligne = ligne.substr(debut);
        if (ligne.empty()) continue;
        if (ligne[0] == '*') continue;
        if (premiere && ligne[0] != '.'
            && !std::isalpha(static_cast<unsigned char>(ligne[0]))) {
            premiere = false;
            continue;
        }
        if (premiere) {
            // La première ligne d'un fichier SPICE est son titre.
            premiere = false;
            if (minuscules(ligne).rfind("circuit", 0) == 0) continue;
        }

        if (ligne[0] == '.') {
            const std::string minuscule = minuscules(ligne);
            if (minuscule.rfind(".model", 0) == 0) {
                const std::vector<std::string> mots = decouper(aerer(ligne));
                if (mots.size() < 3) continue;
                ModeleSpice modele;
                modele.nom = minuscules(mots[1]);
                modele.type = mots[2];
                std::transform(modele.type.begin(), modele.type.end(),
                               modele.type.begin(),
                               [](unsigned char c) { return std::toupper(c); });
                for (size_t k = 3; k < mots.size(); ++k) {
                    const size_t egal = mots[k].find('=');
                    if (egal == std::string::npos) continue;
                    std::string cle = mots[k].substr(0, egal);
                    std::transform(cle.begin(), cle.end(), cle.begin(),
                                   [](unsigned char c) { return std::toupper(c); });
                    modele.parametres[cle] =
                        valeur_spice(mots[k].substr(egal + 1));
                }
                impl_->modeles[modele.nom] = modele;
                continue;
            }
            if (minuscule.rfind(".ic", 0) == 0) {
                // « .ic V(noeud)=valeur », éventuellement plusieurs par ligne.
                std::string reste = ligne.substr(3);
                size_t position = 0;
                while ((position = minuscules(reste).find("v(", position))
                       != std::string::npos) {
                    const size_t fin = reste.find(')', position);
                    if (fin == std::string::npos) break;
                    const std::string nom = reste.substr(position + 2,
                                                         fin - position - 2);
                    const size_t egal = reste.find('=', fin);
                    if (egal == std::string::npos) break;
                    impl_->conditions_initiales[impl_->noeud(nom)] =
                        valeur_spice(reste.substr(egal + 1));
                    position = egal;
                }
                continue;
            }
            impl_->directives.push_back(ligne);
            continue;
        }

        // --- élément
        const char genre = static_cast<char>(
            std::toupper(static_cast<unsigned char>(ligne[0])));
        Element element;
        element.genre = genre;

        if (genre == 'B') {
            const std::vector<std::string> mots = decouper(ligne);
            if (mots.size() < 4) {
                erreurs_.push_back("source comportementale incomplète : " + ligne);
                continue;
            }
            element.nom = minuscules(mots[0]);
            element.a = impl_->noeud(mots[1]);
            element.b = impl_->noeud(mots[2]);
            const size_t egal = ligne.find('=');
            if (egal == std::string::npos) {
                erreurs_.push_back("source comportementale sans « = » : " + ligne);
                continue;
            }
            expressions.emplace_back(impl_->elements.size(),
                                     ligne.substr(egal + 1));
            impl_->elements.push_back(element);
            continue;
        }

        const std::vector<std::string> mots = decouper(aerer(ligne));
        if (mots.size() < 3) {
            erreurs_.push_back("carte incomplète : " + ligne);
            continue;
        }
        element.nom = minuscules(mots[0]);

        switch (genre) {
            case 'R':
            case 'C':
            case 'L':
                element.a = impl_->noeud(mots[1]);
                element.b = impl_->noeud(mots[2]);
                element.valeur = mots.size() > 3 ? valeur_spice(mots[3]) : 0.0;
                break;
            case 'V':
            case 'I': {
                element.a = impl_->noeud(mots[1]);
                element.b = impl_->noeud(mots[2]);
                for (size_t k = 3; k < mots.size(); ++k) {
                    const std::string cle = minuscules(mots[k]);
                    if (cle == "dc" && k + 1 < mots.size()) {
                        element.source.continu = valeur_spice(mots[++k]);
                    } else if (cle == "ac" && k + 1 < mots.size()) {
                        element.source.alternatif = valeur_spice(mots[++k]);
                    } else if (cle == "sin") {
                        element.source.sinusoidale = true;
                        std::vector<double> arguments;
                        while (++k < mots.size() && mots[k] != ")")
                            if (mots[k] != "(")
                                arguments.push_back(valeur_spice(mots[k]));
                        if (arguments.size() > 0) element.source.offset = arguments[0];
                        if (arguments.size() > 1) element.source.amplitude = arguments[1];
                        if (arguments.size() > 2) element.source.frequence = arguments[2];
                        if (arguments.size() > 3) element.source.retard = arguments[3];
                    } else if (cle == "pulse") {
                        element.source.impulsion = true;
                        std::vector<double> arguments;
                        while (++k < mots.size() && mots[k] != ")")
                            if (mots[k] != "(")
                                arguments.push_back(valeur_spice(mots[k]));
                        const double defauts[7] = {0, 0, 0, 1e-9, 1e-9, 0, 0};
                        double lus[7];
                        for (int j = 0; j < 7; ++j)
                            lus[j] = j < static_cast<int>(arguments.size())
                                         ? arguments[j]
                                         : defauts[j];
                        element.source.v1 = lus[0];
                        element.source.v2 = lus[1];
                        element.source.retard = lus[2];
                        element.source.montee = std::max(lus[3], 1e-12);
                        element.source.descente = std::max(lus[4], 1e-12);
                        element.source.largeur = lus[5];
                        element.source.periode = lus[6];
                    } else if (cle == "pwl") {
                        std::vector<double> arguments;
                        while (++k < mots.size() && mots[k] != ")")
                            if (mots[k] != "(")
                                arguments.push_back(valeur_spice(mots[k]));
                        for (size_t j = 0; j + 1 < arguments.size(); j += 2)
                            element.source.lineaire_par_morceaux.emplace_back(
                                arguments[j], arguments[j + 1]);
                    } else if (cle != "(" && cle != ")" && k == 3) {
                        // Valeur nue : « V1 a b 5 ».
                        element.source.continu = valeur_spice(mots[k]);
                    }
                }
                break;
            }
            case 'D':
                element.a = impl_->noeud(mots[1]);
                element.b = impl_->noeud(mots[2]);
                if (mots.size() > 3) element.nom_modele = minuscules(mots[3]);
                break;
            case 'Q':
                if (mots.size() < 5) {
                    erreurs_.push_back("transistor incomplet : " + ligne);
                    continue;
                }
                element.a = impl_->noeud(mots[1]);   // collecteur
                element.b = impl_->noeud(mots[2]);   // base
                element.c = impl_->noeud(mots[3]);   // émetteur
                element.nom_modele = minuscules(mots[4]);
                break;
            case 'M':
                if (mots.size() < 5) {
                    erreurs_.push_back("transistor MOS incomplet : " + ligne);
                    continue;
                }
                element.a = impl_->noeud(mots[1]);   // drain
                element.b = impl_->noeud(mots[2]);   // grille
                element.c = impl_->noeud(mots[3]);   // source
                element.d = impl_->noeud(mots[4]);   // substrat
                if (mots.size() > 5) element.nom_modele = minuscules(mots[5]);
                for (size_t k = 6; k < mots.size(); ++k) {
                    const std::string cle = minuscules(mots[k]);
                    if (cle.rfind("w=", 0) == 0)
                        element.largeur = valeur_spice(mots[k].substr(2));
                    if (cle.rfind("l=", 0) == 0)
                        element.longueur = valeur_spice(mots[k].substr(2));
                }
                break;
            case 'S':
                if (mots.size() < 6) {
                    erreurs_.push_back("interrupteur incomplet : " + ligne);
                    continue;
                }
                element.a = impl_->noeud(mots[1]);
                element.b = impl_->noeud(mots[2]);
                element.c = impl_->noeud(mots[3]);
                element.d = impl_->noeud(mots[4]);
                element.nom_modele = minuscules(mots[5]);
                break;
            case 'F':
                if (mots.size() < 5) {
                    erreurs_.push_back("source commandée incomplète : " + ligne);
                    continue;
                }
                element.a = impl_->noeud(mots[1]);
                element.b = impl_->noeud(mots[2]);
                element.gain = valeur_spice(mots[4]);
                mesures_a_lier.emplace_back(impl_->elements.size(),
                                            minuscules(mots[3]));
                impl_->elements.push_back(element);
                continue;
            default:
                erreurs_.push_back("élément inconnu : " + ligne);
                continue;
        }
        impl_->elements.push_back(element);
    }

    // Les modèles ne se résolvent qu'ici : dans un fichier SPICE, les
    // « .model » viennent après les composants qui s'y réfèrent.
    for (Element& element : impl_->elements) {
        if (element.nom_modele.empty()) continue;
        auto it = impl_->modeles.find(element.nom_modele);
        if (it == impl_->modeles.end()) {
            erreurs_.push_back("modèle inconnu : " + element.nom_modele);
            continue;
        }
        element.modele = &it->second;
        // Les résistances d'accès demandent un nœud interne chacune.
        if (element.genre == 'D' && element.modele->lire("RS", 0.0) > 0)
            element.interne1 = impl_->noeud_interne(element.nom + "_a");
        if (element.genre == 'Q') {
            if (element.modele->lire("RC", 0.0) > 0)
                element.interne1 = impl_->noeud_interne(element.nom + "_c");
            if (element.modele->lire("RB", 0.0) > 0)
                element.interne2 = impl_->noeud_interne(element.nom + "_b");
            if (element.modele->lire("RE", 0.0) > 0)
                element.interne3 = impl_->noeud_interne(element.nom + "_e");
        }
    }

    // Les expressions se compilent une fois la table des nœuds complète.
    for (const auto& paire : expressions) {
        Element& element = impl_->elements[paire.first];
        if (!element.expression.compiler(
                paire.second, [this](const std::string& nom_noeud) {
                    return impl_->noeud(nom_noeud);
                }))
            erreurs_.push_back(element.expression.erreur());
    }

    // Attribution des inconnues de courant : tout ce qui impose une tension
    // ou dont le courant est une variable d'état.
    impl_->nb_branches = 0;
    for (Element& element : impl_->elements) {
        const bool porte_une_branche = element.genre == 'V'
                                       || element.genre == 'L'
                                       || element.genre == 'B'
                                       || element.genre == 'C';
        if (!porte_une_branche) continue;
        element.branche = impl_->nb_noeuds + impl_->nb_branches;
        ++impl_->nb_branches;
    }
    // Une source commandée en courant désigne la branche qu'elle mesure.
    for (const auto& paire : mesures_a_lier) {
        Element& element = impl_->elements[paire.first];
        for (const Element& autre : impl_->elements)
            if (autre.nom == paire.second) element.mesure = autre.branche;
    }

    impl_->taille = impl_->nb_noeuds + impl_->nb_branches;
    impl_->solution.assign(impl_->taille, 0.0);
    if (impl_->taille == 0) {
        erreurs_.push_back("le circuit est vide");
        return false;
    }
    return true;
}

// ---------------------------------------------------------------------------
// Lecture des directives
// ---------------------------------------------------------------------------
namespace {

struct Directive {
    std::string type;
    std::vector<std::string> mots;
};

Directive lire_directive(const std::string& ligne) {
    Directive directive;
    const std::vector<std::string> mots = decouper(ligne);
    if (mots.empty()) return directive;
    directive.type = minuscules(mots[0]);
    directive.mots.assign(mots.begin() + 1, mots.end());
    return directive;
}

// Un nœud interne (créé pour la résistance série d'une diode) ne regarde que
// le solveur : il n'a pas à figurer dans les relevés.
bool noeud_visible(const std::string& nom) { return nom.empty() || nom[0] != '#'; }

}  // namespace

// ---------------------------------------------------------------------------
bool SolveurIntegre::point_repos() {
    tensions_.clear();
    courants_.clear();
    impl_->temperature = 27.0;
    for (const std::string& ligne : impl_->directives) {
        const Directive directive = lire_directive(ligne);
        if (directive.type == ".temp" && !directive.mots.empty())
            impl_->temperature = valeur_spice(directive.mots[0]);
    }

    std::vector<double> x(impl_->taille, 0.0);
    if (!impl_->resoudre_newton(x, 0.0, 0.0, Impl::Mode::Continu, false)) {
        erreurs_.push_back("le point de repos n'a pas convergé");
        return false;
    }
    impl_->solution = x;
    impl_->relever_courants(x, 0.0, Impl::Mode::Continu, false);

    for (int k = 0; k < impl_->nb_noeuds; ++k) {
        if (!noeud_visible(impl_->noms_noeuds[k])) continue;
        tensions_[impl_->noms_noeuds[k]] = x[k];
    }
    tensions_["0"] = 0.0;
    for (const Element& element : impl_->elements) {
        courants_[element.nom] = element.courant;
        if (element.nom.size() > 1)
            courants_[element.nom.substr(1)] = element.courant;
    }
    return true;
}

// ---------------------------------------------------------------------------
bool SolveurIntegre::transitoire(Formes& formes) {
    formes.vider();
    tensions_.clear();
    courants_.clear();

    double pas_demande = 0, fin = 0, debut = 0, pas_maximal = 0;
    bool uic = false;
    bool trouvee = false;
    for (const std::string& ligne : impl_->directives) {
        const Directive directive = lire_directive(ligne);
        if (directive.type != ".tran") continue;
        trouvee = true;
        if (directive.mots.size() > 0) pas_demande = valeur_spice(directive.mots[0]);
        if (directive.mots.size() > 1) fin = valeur_spice(directive.mots[1]);
        if (directive.mots.size() > 2) debut = valeur_spice(directive.mots[2]);
        if (directive.mots.size() > 3) pas_maximal = valeur_spice(directive.mots[3]);
        for (const std::string& mot : directive.mots)
            if (minuscules(mot) == "uic") uic = true;
    }
    if (!trouvee || fin <= 0) {
        erreurs_.push_back("aucune directive .tran exploitable");
        return false;
    }
    if (pas_maximal <= 0) pas_maximal = pas_demande;
    if (pas_maximal <= 0) pas_maximal = fin / 100;

    // Points de rupture : chaque coude d'une source linéaire par morceaux.
    // Sans eux, un front de cent nanosecondes passerait entre deux pas de
    // cinquante microsecondes — c'est exactement ce que fait SPICE.
    std::set<double> ruptures;
    ruptures.insert(0.0);
    ruptures.insert(fin);
    for (const Element& element : impl_->elements)
        element.source.ruptures(fin, ruptures);

    // État initial.
    std::vector<double> x(impl_->taille, 0.0);
    for (Element& element : impl_->elements) {
        element.tension_precedente = 0;
        element.courant_precedent = 0;
        element.vd = element.vbe = element.vbc = element.vgs = element.vds = 0;
    }
    if (uic) {
        for (const auto& condition : impl_->conditions_initiales)
            if (condition.first >= 0 && condition.first < impl_->nb_noeuds)
                x[condition.first] = condition.second;
        // Les condensateurs partent des tensions imposées, les bobines d'un
        // courant nul : c'est la définition de « uic ».
        for (Element& element : impl_->elements)
            if (element.genre == 'C')
                element.tension_precedente = impl_->tension(x, element.a)
                                             - impl_->tension(x, element.b);
        if (!impl_->resoudre_newton(x, 0.0, 0.0, Impl::Mode::ConditionsInitiales,
                                    false))
            erreurs_.push_back("l'état initial n'a pas convergé ; on continue");
    } else if (!impl_->resoudre_newton(x, 0.0, 0.0, Impl::Mode::Continu, false)) {
        erreurs_.push_back("le point de repos initial n'a pas convergé");
        return false;
    }
    impl_->memoriser_etat(x, 0.0, uic ? Impl::Mode::ConditionsInitiales
                                      : Impl::Mode::Continu, false);

    // Deux éléments peuvent revendiquer la même clé : « RM1 » et « LM1 » se
    // réduisent tous deux à « m1 ». Un seul doit écrire, sinon le relevé
    // compte deux valeurs par instant et tout se décale dans le temps.
    std::map<std::string, size_t> proprietaire;
    for (size_t k = 0; k < impl_->elements.size(); ++k) {
        proprietaire[impl_->elements[k].nom] = k;
        if (impl_->elements[k].nom.size() > 1)
            proprietaire[impl_->elements[k].nom.substr(1)] = k;
    }

    auto enregistrer = [&](double instant, const std::vector<double>& etat) {
        if (instant < debut) return;
        formes.temps.push_back(instant);
        for (int k = 0; k < impl_->nb_noeuds; ++k) {
            const std::string& nom = impl_->noms_noeuds[k];
            if (!noeud_visible(nom)) continue;
            formes.tensions[nom].push_back(etat[k]);
        }
        for (const auto& entree : proprietaire)
            formes.courants[entree.first].push_back(
                impl_->elements[entree.second].courant);
    };
    enregistrer(0.0, x);

    double instant = 0.0;
    bool premier_pas = true;      // après une rupture, Euler amorti d'abord
    int garde = 0;
    const int garde_maximale = 2000000;
    while (instant < fin - 1e-15 && ++garde < garde_maximale) {
        double pas = pas_maximal;
        // On ne dépasse jamais la prochaine rupture : on s'y arrête.
        auto suivante = ruptures.upper_bound(instant + 1e-15);
        if (suivante != ruptures.end())
            pas = std::min(pas, *suivante - instant);
        if (premier_pas) pas = std::min(pas, pas_maximal / 20);
        pas = std::max(pas, 1e-15);
        const double vise = std::min(instant + pas, fin);
        pas = vise - instant;

        std::vector<double> essai = x;
        const bool trapeze = !premier_pas;
        if (!impl_->resoudre_newton(essai, vise, pas, Impl::Mode::Transitoire,
                                    trapeze)) {
            // Un pas plus court est la seule réponse utile à un refus de
            // convergence.
            if (pas > 1e-12) {
                premier_pas = true;
                pas_maximal = std::max(pas_maximal / 2, 1e-12);
                continue;
            }
            erreurs_.push_back("la simulation transitoire n'a pas convergé");
            break;
        }
        x = essai;
        instant = vise;
        impl_->memoriser_etat(x, pas, Impl::Mode::Transitoire, trapeze);
        enregistrer(instant, x);
        premier_pas = ruptures.count(instant) > 0;
    }

    impl_->solution = x;
    for (int k = 0; k < impl_->nb_noeuds; ++k) {
        if (!noeud_visible(impl_->noms_noeuds[k])) continue;
        tensions_[impl_->noms_noeuds[k]] = x[k];
    }
    tensions_["0"] = 0.0;
    for (const Element& element : impl_->elements) {
        courants_[element.nom] = element.courant;
        if (element.nom.size() > 1)
            courants_[element.nom.substr(1)] = element.courant;
    }
    return !formes.temps.empty();
}

// ---------------------------------------------------------------------------
// Balayages : continu, fréquentiel, bruit
// ---------------------------------------------------------------------------
namespace {

// Mêmes exclusions que du côté de ngspice : ce qui n'appartient pas au
// montage ne doit pas encombrer la légende.
bool grandeur_utile(const std::string& nom) {
    if (nom.find("_src") != std::string::npos) return false;
    if (nom.find("_nc_") != std::string::npos) return false;
    if (nom == "5v" || nom == "3v3" || nom == "valim" || nom == "valim33")
        return false;
    if (nom.rfind("rfuite", 0) == 0) return false;
    if (nom.rfind("#", 0) == 0) return false;
    return true;
}

std::vector<double> echelle_logarithmique(double debut, double fin,
                                          int par_decade) {
    std::vector<double> points;
    if (debut <= 0 || fin <= debut || par_decade <= 0) return points;
    const double rapport = std::pow(10.0, 1.0 / par_decade);
    for (double f = debut; f <= fin * (1 + 1e-12); f *= rapport)
        points.push_back(f);
    return points;
}

}  // namespace

bool SolveurIntegre::analyse(Balayage& balayage) {
    balayage.vider();
    Directive analyse_demandee;
    for (const std::string& ligne : impl_->directives) {
        const Directive directive = lire_directive(ligne);
        if (directive.type == ".dc" || directive.type == ".ac"
            || directive.type == ".noise")
            analyse_demandee = directive;
    }
    if (analyse_demandee.type.empty()) {
        erreurs_.push_back("aucune directive de balayage");
        return false;
    }

    // --- balayage continu --------------------------------------------------
    if (analyse_demandee.type == ".dc") {
        if (analyse_demandee.mots.size() < 4) {
            erreurs_.push_back("directive .dc incomplète");
            return false;
        }
        const std::string cible = minuscules(analyse_demandee.mots[0]);
        const double debut = valeur_spice(analyse_demandee.mots[1]);
        const double fin = valeur_spice(analyse_demandee.mots[2]);
        double pas = valeur_spice(analyse_demandee.mots[3]);
        if (pas == 0) pas = (fin - debut) != 0 ? (fin - debut) : 1;

        Element* balayee = nullptr;
        for (Element& element : impl_->elements)
            if (element.nom == cible) balayee = &element;
        const bool temperature = cible == "temp";
        if (!balayee && !temperature) {
            erreurs_.push_back("grandeur inconnue au balayage : " + cible);
            return false;
        }
        balayage.grandeur = temperature ? "temp-sweep"
                                        : (cible[0] == 'r' ? "res-sweep"
                                                           : "v-sweep");
        balayage.unite = temperature ? "°C" : (cible[0] == 'r' ? "Ω" : "V");

        const double memoire_valeur = balayee ? balayee->valeur : 0.0;
        const double memoire_source = balayee ? balayee->source.continu : 0.0;
        const double memoire_temperature = impl_->temperature;

        std::map<std::string, std::vector<double>> releves;
        for (double valeur = debut;
             (pas > 0 ? valeur <= fin + pas / 1e6 : valeur >= fin + pas / 1e6);
             valeur += pas) {
            if (temperature) {
                impl_->temperature = valeur;
            } else if (balayee->genre == 'R') {
                balayee->valeur = valeur;
            } else {
                balayee->source.continu = valeur;
            }
            std::vector<double> x = impl_->solution;
            if (!impl_->resoudre_newton(x, 0.0, 0.0, Impl::Mode::Continu, false)) {
                erreurs_.push_back("un point du balayage n'a pas convergé");
                continue;
            }
            impl_->relever_courants(x, 0.0, Impl::Mode::Continu, false);
            balayage.abscisse.push_back(valeur);
            for (int k = 0; k < impl_->nb_noeuds; ++k) {
                const std::string& nom = impl_->noms_noeuds[k];
                if (!grandeur_utile(nom)) continue;
                releves[nom].push_back(x[k]);
            }
            for (const Element& element : impl_->elements) {
                const std::string reference = element.nom.size() > 1
                                                  ? element.nom.substr(1)
                                                  : element.nom;
                if (!grandeur_utile(element.nom)) continue;
                releves["I(" + reference + ")"].push_back(element.courant);
            }
        }
        if (balayee) {
            balayee->valeur = memoire_valeur;
            balayee->source.continu = memoire_source;
        }
        impl_->temperature = memoire_temperature;

        for (auto& releve : releves) {
            if (releve.second.size() != balayage.abscisse.size()) continue;
            Courbe courbe;
            courbe.nom = releve.first;
            courbe.valeurs = std::move(releve.second);
            balayage.courbes.push_back(std::move(courbe));
        }
        std::sort(balayage.courbes.begin(), balayage.courbes.end(),
                  [](const Courbe& a, const Courbe& b) { return a.nom < b.nom; });
        return !balayage.abscisse.empty();
    }

    // Les deux analyses qui suivent partent du point de fonctionnement.
    if (!point_repos()) return false;

    // --- réponse en fréquence ---------------------------------------------
    if (analyse_demandee.type == ".ac") {
        if (analyse_demandee.mots.size() < 4) {
            erreurs_.push_back("directive .ac incomplète");
            return false;
        }
        const int par_decade =
            static_cast<int>(valeur_spice(analyse_demandee.mots[1]));
        const double debut = valeur_spice(analyse_demandee.mots[2]);
        const double fin = valeur_spice(analyse_demandee.mots[3]);
        balayage.abscisse = echelle_logarithmique(debut, fin, par_decade);
        if (balayage.abscisse.empty()) {
            erreurs_.push_back("plage de fréquences vide");
            return false;
        }
        balayage.logarithmique = true;
        balayage.grandeur = "Fréquence";
        balayage.unite = "Hz";

        std::map<std::string, std::pair<std::vector<double>, std::vector<double>>>
            releves;
        for (double frequence : balayage.abscisse) {
            std::vector<std::complex<double>> x;
            if (!impl_->resoudre_alternatif(frequence, x)) {
                erreurs_.push_back("la réponse en fréquence n'a pas abouti");
                return false;
            }
            for (int k = 0; k < impl_->nb_noeuds; ++k) {
                const std::string& nom = impl_->noms_noeuds[k];
                if (!grandeur_utile(nom)) continue;
                releves[nom].first.push_back(std::abs(x[k]));
                releves[nom].second.push_back(std::arg(x[k]) * 180.0 / kPi);
            }
            std::vector<std::pair<std::string, std::complex<double>>> courants;
            impl_->courants_alternatifs(x, frequence, &courants);
            for (const auto& courant : courants) {
                if (!grandeur_utile(courant.first)) continue;
                const std::string reference =
                    courant.first.size() > 1 ? courant.first.substr(1)
                                             : courant.first;
                const std::string nom = "I(" + reference + ")";
                releves[nom].first.push_back(std::abs(courant.second));
                releves[nom].second.push_back(std::arg(courant.second) * 180.0
                                              / kPi);
            }
        }
        for (auto& releve : releves) {
            Courbe courbe;
            courbe.nom = releve.first;
            courbe.valeurs = std::move(releve.second.first);
            courbe.phases = std::move(releve.second.second);
            balayage.courbes.push_back(std::move(courbe));
        }
        std::sort(balayage.courbes.begin(), balayage.courbes.end(),
                  [](const Courbe& a, const Courbe& b) { return a.nom < b.nom; });
        return true;
    }

    // --- bruit -------------------------------------------------------------
    // « .noise V(SORTIE) VGBF1 dec 10 10 1meg »
    if (analyse_demandee.mots.size() < 6) {
        erreurs_.push_back("directive .noise incomplète");
        return false;
    }
    std::string sortie = minuscules(analyse_demandee.mots[0]);
    const size_t ouvrante = sortie.find('(');
    const size_t fermante = sortie.find(')');
    if (ouvrante != std::string::npos && fermante != std::string::npos)
        sortie = sortie.substr(ouvrante + 1, fermante - ouvrante - 1);
    const std::string entree = minuscules(analyse_demandee.mots[1]);
    const int par_decade = static_cast<int>(valeur_spice(analyse_demandee.mots[3]));
    const double debut = valeur_spice(analyse_demandee.mots[4]);
    const double fin = valeur_spice(analyse_demandee.mots[5]);

    auto rang_noeud = impl_->indices.find(sortie);
    if (rang_noeud == impl_->indices.end()) {
        erreurs_.push_back("nœud de sortie inconnu pour le bruit : " + sortie);
        return false;
    }
    const int noeud_sortie = rang_noeud->second;

    balayage.abscisse = echelle_logarithmique(debut, fin, par_decade);
    if (balayage.abscisse.empty()) {
        erreurs_.push_back("plage de fréquences vide");
        return false;
    }
    balayage.logarithmique = true;
    balayage.grandeur = "Fréquence";
    balayage.unite = "Hz";

    // Densité spectrale de chaque source de bruit, en A²/Hz.
    struct SourceBruit {
        std::string nom;
        int a = -1, b = -1;
        double densite = 0;
    };
    const double kt4 = 4 * kBoltzmann * (impl_->temperature + 273.15);
    std::vector<SourceBruit> sources;
    for (const Element& element : impl_->elements) {
        const std::string reference =
            element.nom.size() > 1 ? element.nom.substr(1) : element.nom;
        if (element.genre == 'R' && element.valeur > 0) {
            // Bruit thermique : 4kT/R, la formule de Johnson-Nyquist.
            sources.push_back({reference, element.a, element.b,
                               kt4 / element.valeur});
        } else if (element.genre == 'D') {
            // Bruit de grenaille de la jonction.
            sources.push_back({reference, element.a, element.b,
                               2 * kCharge * std::fabs(element.courant)});
        }
    }

    std::vector<double> totaux;
    std::map<std::string, std::vector<double>> contributions;
    std::vector<double> gains;
    for (double frequence : balayage.abscisse) {
        // Gain de l'entrée vers la sortie : il ramène le bruit à l'entrée.
        std::vector<std::complex<double>> reponse;
        double gain = 0;
        if (impl_->resoudre_alternatif(frequence, reponse))
            gain = std::abs(reponse[noeud_sortie]);
        gains.push_back(gain);

        double total = 0;
        for (const SourceBruit& source : sources) {
            std::vector<std::complex<double>> transfert;
            if (!impl_->resoudre_alternatif(frequence, transfert, source.a,
                                            source.b))
                continue;
            const double module = std::abs(transfert[noeud_sortie]);
            const double part = source.densite * module * module;
            total += part;
            contributions[source.nom].push_back(std::sqrt(part));
        }
        totaux.push_back(std::sqrt(total));
    }

    Courbe spectre;
    spectre.nom = "onoise_spectrum";
    spectre.valeurs = totaux;
    balayage.courbes.push_back(spectre);

    Courbe ramene;
    ramene.nom = "inoise_spectrum";
    for (size_t k = 0; k < totaux.size(); ++k)
        ramene.valeurs.push_back(gains[k] > 1e-30 ? totaux[k] / gains[k] : 0.0);
    balayage.courbes.push_back(ramene);

    for (auto& contribution : contributions) {
        if (contribution.second.size() != balayage.abscisse.size()) continue;
        if (!grandeur_utile(contribution.first)) continue;
        Courbe courbe;
        courbe.nom = "bruit(" + contribution.first + ")";
        courbe.valeurs = std::move(contribution.second);
        balayage.courbes.push_back(std::move(courbe));
    }
    (void)entree;
    std::sort(balayage.courbes.begin(), balayage.courbes.end(),
              [](const Courbe& a, const Courbe& b) { return a.nom < b.nom; });
    return true;
}

}  // namespace coeur
