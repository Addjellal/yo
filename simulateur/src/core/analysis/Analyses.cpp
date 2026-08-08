#include "core/analysis/Analyses.h"

#include <algorithm>
#include <cmath>

namespace coeur {

namespace {

constexpr double kPi = 3.14159265358979323846;

// Valeur d'un signal échantillonné à un instant quelconque, par interpolation
// linéaire. Les points d'une analyse transitoire ne sont pas régulièrement
// espacés : sans cette étape, toute mesure serait biaisée par la répartition
// des instants de calcul.
double interpoler(const std::vector<double>& temps,
                  const std::vector<double>& valeurs, double t) {
    if (temps.empty()) return 0.0;
    if (t <= temps.front()) return valeurs.front();
    if (t >= temps.back()) return valeurs.back();
    const auto it = std::lower_bound(temps.begin(), temps.end(), t);
    const size_t k = static_cast<size_t>(it - temps.begin());
    if (k == 0) return valeurs.front();
    const double t0 = temps[k - 1], t1 = temps[k];
    if (t1 <= t0) return valeurs[k];
    const double poids = (t - t0) / (t1 - t0);
    return valeurs[k - 1] + poids * (valeurs[k] - valeurs[k - 1]);
}

// Instant précis où le signal franchit un seuil entre deux échantillons.
double instant_franchissement(double t0, double v0, double t1, double v1,
                              double seuil) {
    if (std::fabs(v1 - v0) < 1e-15) return t1;
    return t0 + (seuil - v0) / (v1 - v0) * (t1 - t0);
}

// Fronts montants d'un signal, détectés avec hystérésis autour du niveau
// médian. L'hystérésis évite qu'un signal bruité ou légèrement ondulé compte
// plusieurs fronts là où l'œil n'en voit qu'un.
std::vector<double> fronts_montants(const std::vector<double>& temps,
                                    const std::vector<double>& valeurs,
                                    double median, double hysteresis) {
    std::vector<double> fronts;
    bool haut = valeurs.front() > median;
    for (size_t k = 1; k < temps.size(); ++k) {
        if (!haut && valeurs[k] > median + hysteresis) {
            fronts.push_back(instant_franchissement(temps[k - 1], valeurs[k - 1],
                                                    temps[k], valeurs[k],
                                                    median));
            haut = true;
        } else if (haut && valeurs[k] < median - hysteresis) {
            haut = false;
        }
    }
    return fronts;
}

double module(const Courbe& courbe, size_t k) {
    return k < courbe.valeurs.size() ? std::fabs(courbe.valeurs[k]) : 0.0;
}

}  // namespace

// ---------------------------------------------------------------------------
// Balayage
// ---------------------------------------------------------------------------
const Courbe* Balayage::courbe(const std::string& nom) const {
    for (const auto& c : courbes)
        if (c.nom == nom) return &c;
    return nullptr;
}

std::vector<double> gain_decibels(const Courbe& sortie, const Courbe* entree) {
    std::vector<double> gains;
    gains.reserve(sortie.valeurs.size());
    for (size_t k = 0; k < sortie.valeurs.size(); ++k) {
        const double numerateur = module(sortie, k);
        const double denominateur = entree ? module(*entree, k) : 1.0;
        if (numerateur <= 1e-18 || denominateur <= 1e-18) {
            gains.push_back(-360.0);   // plancher, pour rester traçable
            continue;
        }
        gains.push_back(20.0 * std::log10(numerateur / denominateur));
    }
    return gains;
}

double gain_maximal(const Courbe& sortie, const Courbe* entree) {
    const std::vector<double> gains = gain_decibels(sortie, entree);
    if (gains.empty()) return 0.0;
    return *std::max_element(gains.begin(), gains.end());
}

double frequence_coupure(const Balayage& balayage, const Courbe& sortie,
                         const Courbe* entree) {
    const std::vector<double> gains = gain_decibels(sortie, entree);
    if (gains.size() < 2 || gains.size() != balayage.abscisse.size()) return 0.0;

    const size_t sommet =
        static_cast<size_t>(std::max_element(gains.begin(), gains.end())
                            - gains.begin());
    const double seuil = gains[sommet] - 3.0;
    for (size_t k = sommet + 1; k < gains.size(); ++k) {
        if (gains[k] > seuil) continue;
        // interpolation dans l'espace logarithmique : c'est là que la courbe
        // est droite, donc là que l'interpolation est juste.
        const double g0 = gains[k - 1], g1 = gains[k];
        const double f0 = balayage.abscisse[k - 1], f1 = balayage.abscisse[k];
        if (f0 <= 0 || f1 <= 0 || std::fabs(g1 - g0) < 1e-12) return f1;
        const double poids = (seuil - g0) / (g1 - g0);
        return std::pow(10.0, std::log10(f0)
                                  + poids * (std::log10(f1) - std::log10(f0)));
    }
    return 0.0;
}

// ---------------------------------------------------------------------------
// Mesures sur une forme d'onde
// ---------------------------------------------------------------------------
Mesures mesurer(const std::vector<double>& temps,
                const std::vector<double>& valeurs) {
    Mesures m;
    const size_t n = std::min(temps.size(), valeurs.size());
    if (n < 2) return m;
    const double duree = temps[n - 1] - temps[0];
    if (duree <= 0) return m;

    m.valide = true;
    m.minimum = m.maximum = valeurs[0];
    double integrale = 0.0, integrale_carre = 0.0;
    for (size_t k = 0; k < n; ++k) {
        m.minimum = std::min(m.minimum, valeurs[k]);
        m.maximum = std::max(m.maximum, valeurs[k]);
        if (k == 0) continue;
        const double pas = temps[k] - temps[k - 1];
        integrale += 0.5 * (valeurs[k] + valeurs[k - 1]) * pas;
        integrale_carre +=
            0.5 * (valeurs[k] * valeurs[k] + valeurs[k - 1] * valeurs[k - 1])
            * pas;
    }
    m.moyenne = integrale / duree;
    m.efficace = std::sqrt(std::max(0.0, integrale_carre / duree));
    m.crete_a_crete = m.maximum - m.minimum;

    if (m.crete_a_crete < 1e-9) return m;   // signal plat : rien de plus à dire

    const double median = 0.5 * (m.minimum + m.maximum);
    const double hysteresis = 0.1 * m.crete_a_crete;
    const std::vector<double> t(temps.begin(), temps.begin() + n);
    const std::vector<double> v(valeurs.begin(), valeurs.begin() + n);
    const std::vector<double> fronts =
        fronts_montants(t, v, median, hysteresis);
    if (fronts.size() >= 2) {
        const double periode =
            (fronts.back() - fronts.front()) / (fronts.size() - 1);
        if (periode > 0) m.frequence = 1.0 / periode;

        // Rapport cyclique : proportion du temps passé au-dessus du niveau
        // médian, mesurée sur un nombre entier de périodes seulement — sinon
        // une demi-période supplémentaire fausserait le résultat.
        const double debut = fronts.front(), fin = fronts.back();
        double haut = 0.0;
        double instant_montee = debut;
        bool en_haut = true;
        for (size_t k = 1; k < n; ++k) {
            if (temps[k] <= debut || temps[k - 1] >= fin) continue;
            if (en_haut && valeurs[k] < median - hysteresis) {
                haut += instant_franchissement(temps[k - 1], valeurs[k - 1],
                                               temps[k], valeurs[k], median)
                        - instant_montee;
                en_haut = false;
            } else if (!en_haut && valeurs[k] > median + hysteresis) {
                instant_montee = instant_franchissement(
                    temps[k - 1], valeurs[k - 1], temps[k], valeurs[k], median);
                en_haut = true;
            }
        }
        if (en_haut) haut += fin - instant_montee;
        m.rapport_cyclique = 100.0 * haut / (fin - debut);
    }

    // Temps de montée du premier front : 10 % → 90 % de l'amplitude.
    const double bas = m.minimum + 0.1 * m.crete_a_crete;
    const double sommet = m.minimum + 0.9 * m.crete_a_crete;
    double t10 = 0.0;
    bool vu10 = false;
    for (size_t k = 1; k < n; ++k) {
        if (!vu10 && valeurs[k - 1] < bas && valeurs[k] >= bas) {
            t10 = instant_franchissement(temps[k - 1], valeurs[k - 1], temps[k],
                                         valeurs[k], bas);
            vu10 = true;
        } else if (vu10 && valeurs[k - 1] < sommet && valeurs[k] >= sommet) {
            m.temps_montee = instant_franchissement(temps[k - 1], valeurs[k - 1],
                                                    temps[k], valeurs[k], sommet)
                             - t10;
            break;
        }
    }

    // Dépassement : la pointe rapportée à la valeur d'arrivée. C'est la
    // définition utilisée pour une réponse indicielle.
    const double finale = valeurs[n - 1];
    if (finale > 1e-9 && m.maximum > finale)
        m.depassement = 100.0 * (m.maximum - finale) / finale;
    return m;
}

// ---------------------------------------------------------------------------
// Spectre et distorsion harmonique
// ---------------------------------------------------------------------------
Spectre analyser_spectre(const std::vector<double>& temps,
                         const std::vector<double>& valeurs, int harmoniques,
                         double frequence_imposee) {
    Spectre spectre;
    const size_t n = std::min(temps.size(), valeurs.size());
    if (n < 8 || harmoniques < 1) return spectre;
    const double duree = temps[n - 1] - temps[0];
    if (duree <= 0) return spectre;

    const std::vector<double> t(temps.begin(), temps.begin() + n);
    const std::vector<double> v(valeurs.begin(), valeurs.begin() + n);

    // Fondamentale : imposée, ou déduite des fronts montants.
    double f0 = frequence_imposee;
    double debut = t.front();
    if (f0 <= 0) {
        const double mini = *std::min_element(v.begin(), v.end());
        const double maxi = *std::max_element(v.begin(), v.end());
        if (maxi - mini < 1e-9) return spectre;         // signal continu
        const std::vector<double> fronts =
            fronts_montants(t, v, 0.5 * (mini + maxi), 0.1 * (maxi - mini));
        if (fronts.size() < 2) return spectre;          // moins d'une période
        const double periode =
            (fronts.back() - fronts.front()) / (fronts.size() - 1);
        if (periode <= 0) return spectre;
        f0 = 1.0 / periode;
        debut = fronts.front();
    }

    // La décomposition n'est exacte que sur un nombre ENTIER de périodes :
    // sinon la troncature crée des harmoniques qui n'existent pas.
    const double periode = 1.0 / f0;
    const int periodes = static_cast<int>((t.back() - debut) / periode + 1e-6);
    if (periodes < 1) return spectre;
    const double fenetre = periodes * periode;

    // Ré-échantillonnage régulier : les sommes de corrélation qui suivent
    // supposent un pas constant. Il faut au moins une quinzaine de points par
    // période de l'harmonique le plus élevé, sinon celui-ci se replierait sur
    // les autres et fausserait la distorsion.
    const long long souhaite = 16LL * harmoniques * periodes;
    const int points = static_cast<int>(std::min(65536LL, std::max(2048LL, souhaite)));
    std::vector<double> echantillons(points);
    for (int k = 0; k < points; ++k)
        echantillons[k] =
            interpoler(t, v, debut + fenetre * k / static_cast<double>(points));

    double somme = 0.0;
    for (double x : echantillons) somme += x;
    spectre.continu = somme / points;

    double carre = 0.0;
    for (double x : echantillons) {
        const double ecart = x - spectre.continu;
        carre += ecart * ecart;
    }
    spectre.efficace = std::sqrt(carre / points);

    spectre.valide = true;
    spectre.fondamentale = f0;
    double energie_harmoniques = 0.0, amplitude_fondamentale = 0.0;
    for (int rang = 1; rang <= harmoniques; ++rang) {
        double a = 0.0, b = 0.0;
        for (int k = 0; k < points; ++k) {
            // La fenêtre couvre `periodes` périodes : l'harmonique de rang n y
            // accomplit donc n × periodes tours, et non n.
            const double angle = 2.0 * kPi * rang * periodes * k / points;
            a += echantillons[k] * std::cos(angle);
            b += echantillons[k] * std::sin(angle);
        }
        a *= 2.0 / points;
        b *= 2.0 / points;
        RaieSpectre raie;
        raie.rang = rang;
        raie.frequence = rang * f0;
        raie.amplitude = std::sqrt(a * a + b * b);
        spectre.raies.push_back(raie);
        if (rang == 1)
            amplitude_fondamentale = raie.amplitude;
        else
            energie_harmoniques += raie.amplitude * raie.amplitude;
    }
    if (amplitude_fondamentale > 1e-12) {
        spectre.thd =
            100.0 * std::sqrt(energie_harmoniques) / amplitude_fondamentale;
        for (auto& raie : spectre.raies)
            raie.amplitude_relative =
                100.0 * raie.amplitude / amplitude_fondamentale;
    }
    return spectre;
}

}  // namespace coeur
