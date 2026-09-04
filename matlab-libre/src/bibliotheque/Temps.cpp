// Temps.cpp — horloges, dates, chronomètres.
#include <cctype>
#include <chrono>
#include <cmath>
#include <ctime>
#include <thread>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

using Horloge = std::chrono::steady_clock;

Horloge::time_point& depart() {
    static Horloge::time_point t = Horloge::now();
    return t;
}

FONCTION(fnTic) {
    INUTILISE
    depart() = Horloge::now();
    if (nargout > 0) {
        auto n = std::chrono::duration_cast<std::chrono::nanoseconds>(
                     depart().time_since_epoch())
                     .count();
        return {Valeur::scalaire((double)n)};
    }
    return {};
}

FONCTION(fnToc) {
    INUTILISE
    double secondes =
        std::chrono::duration<double>(Horloge::now() - depart()).count();
    if (nargout > 0) return {Valeur::scalaire(secondes)};
    it.sortie() << formater("Elapsed time is %f seconds.\n", secondes);
    return {};
}

FONCTION(fnCputime) {
    INUTILISE
    return {Valeur::scalaire((double)std::clock() / (double)CLOCKS_PER_SEC)};
}

// Numéro de série des dates de MATLAB : 1 = 1er janvier de l'an 0.
double versDatenum(int annee, int mois, int jour, int heure, int minute, double seconde) {
    // Algorithme du jour julien, décalé sur l'origine de MATLAB.
    int a = (14 - mois) / 12;
    int y = annee + 4800 - a;
    int m = mois + 12 * a - 3;
    long long jdn = jour + (153 * m + 2) / 5 + 365LL * y + y / 4 - y / 100 + y / 400 - 32045;
    const long long origine = 1721059;  // jdn du 1er janvier de l'an 0 (proleptique)
    return (double)(jdn - origine) + (heure + minute / 60.0 + seconde / 3600.0) / 24.0;
}

void depuisDatenum(double n, int& annee, int& mois, int& jour, int& heure, int& minute,
                   double& seconde) {
    // Le jour et l'heure sont séparés avant tout arrondi. Un numéro de
    // série proche de 738000 ne distingue pas mieux que la dizaine de
    // microsecondes : lire la fraction telle quelle ferait afficher
    // 18:59:59,999997 là où il faut lire 19:00:00, et 60 secondes après
    // arrondi à la seconde. On arrondit donc les secondes du jour à la
    // puissance de dix immédiatement supérieure à la résolution réelle,
    // et l'on reporte sur le jour quand la journée est pleine.
    long long jours = (long long)std::floor(n);
    double secondes = (n - (double)jours) * 86400.0;
    double pasDouble = std::nextafter(std::fabs(n) + 1.0, 1e308) - (std::fabs(n) + 1.0);
    double resolution = std::max(8.0 * 86400.0 * pasDouble, 1e-9);
    double grille = std::pow(10.0, std::ceil(std::log10(resolution)));
    secondes = std::round(secondes / grille) * grille;
    if (secondes >= 86400.0) {
        secondes -= 86400.0;
        jours += 1;
    }
    if (secondes < 0.0) {
        secondes += 86400.0;
        jours -= 1;
    }
    long long jdn = jours + 1721059;
    long long a = jdn + 32044;
    long long b = (4 * a + 3) / 146097;
    long long c = a - (146097 * b) / 4;
    long long d = (4 * c + 3) / 1461;
    long long e = c - (1461 * d) / 4;
    long long m = (5 * e + 2) / 153;
    jour = (int)(e - (153 * m + 2) / 5 + 1);
    mois = (int)(m + 3 - 12 * (m / 10));
    annee = (int)(100 * b + d - 4800 + m / 10);
    heure = (int)std::floor(secondes / 3600.0);
    minute = (int)std::floor((secondes - heure * 3600.0) / 60.0);
    seconde = secondes - heure * 3600.0 - minute * 60.0;
    seconde = std::round(seconde * 1e9) / 1e9;
}

FONCTION(fnNow) {
    INUTILISE
    std::time_t t = std::time(nullptr);
    std::tm local{};
#ifdef _WIN32
    localtime_s(&local, &t);
#else
    localtime_r(&t, &local);
#endif
    return {Valeur::scalaire(versDatenum(local.tm_year + 1900, local.tm_mon + 1, local.tm_mday,
                                         local.tm_hour, local.tm_min, local.tm_sec))};
}

FONCTION(fnClock) {
    INUTILISE
    std::time_t t = std::time(nullptr);
    std::tm local{};
#ifdef _WIN32
    localtime_s(&local, &t);
#else
    localtime_r(&t, &local);
#endif
    std::vector<double> v = {(double)(local.tm_year + 1900), (double)(local.tm_mon + 1),
                             (double)local.tm_mday, (double)local.tm_hour,
                             (double)local.tm_min, (double)local.tm_sec};
    return {Valeur::ligne(v)};
}

// Le numero d'un mois d'apres son nom anglais, abrege ou entier : c'est
// ce qu'ecrit DATESTR, et ce que MATLAB relit.
int moisDepuisNom(const std::string& nom) {
    static const char* noms[] = {"jan", "feb", "mar", "apr", "may", "jun",
                                 "jul", "aug", "sep", "oct", "nov", "dec"};
    std::string court;
    for (char c : nom) {
        if (court.size() >= 3) break;
        court += (char)std::tolower((unsigned char)c);
    }
    for (int k = 0; k < 12; ++k)
        if (court == noms[k]) return k + 1;
    return 0;
}

// Une date ecrite : « aaaa-mm-jj », « mm/jj/aaaa » ou « jj-mmm-aaaa ».
// Cette derniere forme est celle que DATESTR ecrit ; sans elle, le
// parcours datestr puis datenum ne revenait pas a son point de depart.
bool lireDateTexte(const std::string& s, double& sortie) {
    int a = 0, m = 0, j = 0, h = 0, mi = 0;
    double se = 0;
    char nomMois[32] = {0};
    if (std::sscanf(s.c_str(), "%d-%31[A-Za-z]-%d %d:%d:%lf", &j, nomMois, &a, &h, &mi, &se) >= 3) {
        m = moisDepuisNom(nomMois);
        if (m > 0) {
            sortie = versDatenum(a, m, j, h, mi, se);
            return true;
        }
    }
    h = mi = 0;
    se = 0;
    if (std::sscanf(s.c_str(), "%d-%d-%d %d:%d:%lf", &a, &m, &j, &h, &mi, &se) >= 3) {
        sortie = versDatenum(a, m, j, h, mi, se);
        return true;
    }
    a = m = j = 0;
    if (std::sscanf(s.c_str(), "%d/%d/%d", &m, &j, &a) == 3) {
        sortie = versDatenum(a, m, j, 0, 0, 0);
        return true;
    }
    return false;
}

// La valeur d'un argument diffuse : un scalaire vaut pour toutes les
// positions, un tableau donne sa case. C'est la regle de MATLAB pour
// DATENUM(Y,M,D), ou l'annee peut etre unique et les jours nombreux.
double caseDiffusee(const Valeur& v, std::size_t k) {
    if (v.nelem() == 0) return 0.0;
    if (v.nelem() == 1) return v.re[0];
    return v.re[k];
}

FONCTION(fnDatenum) {
    INUTILISE
    if (args.empty()) {
        std::vector<Valeur> aucun;
        return fnNow(it, aucun, 1);
    }
    if (args.size() >= 3) {
        // Les six champs se diffusent : la forme du resultat est celle du
        // plus grand d'entre eux.
        std::size_t n = 1;
        Dims forme{1, 1};
        for (std::size_t k = 0; k < args.size() && k < 6; ++k) {
            exigerNumerique(args[k], "datenum");
            if (args[k].nelem() > n) {
                n = args[k].nelem();
                forme = args[k].dims;
            }
        }
        for (std::size_t k = 0; k < args.size() && k < 6; ++k)
            if (args[k].nelem() != 1 && args[k].nelem() != n)
                erreur("MATLAB:datenum:InputSizeMismatch",
                       "DATENUM inputs must be scalars or of the same size.");
        Valeur sortie = Valeur::matriceDims(forme);
        for (std::size_t k = 0; k < n; ++k)
            sortie.re[k] = versDatenum(
                (int)caseDiffusee(args[0], k), (int)caseDiffusee(args[1], k),
                (int)caseDiffusee(args[2], k),
                args.size() > 3 ? (int)caseDiffusee(args[3], k) : 0,
                args.size() > 4 ? (int)caseDiffusee(args[4], k) : 0,
                args.size() > 5 ? caseDiffusee(args[5], k) : 0.0);
        return {sortie};
    }
    // Un tableau de textes : une date par cellule, rangee en colonne.
    if (args[0].estCellule() || args[0].estChaine()) {
        const Valeur& v = args[0];
        std::size_t n = v.nelem();
        Valeur sortie = Valeur::matrice((int)n, 1);
        for (std::size_t k = 0; k < n; ++k) {
            std::string s = v.estCellule() ? v.cellules[k].versTexte() : v.chaines[k];
            if (!lireDateTexte(s, sortie.re[k]))
                erreur("MATLAB:datenum:ConvertDateString",
                       "Unable to convert the date string.");
        }
        if (n == 1) return {Valeur::scalaire(sortie.re[0])};
        return {sortie};
    }
    if (args[0].estNumerique() && args[0].nelem() >= 3) {
        const Valeur& v = args[0];
        int lignes = v.nlignes();
        int colonnes = v.ncolonnes();
        // Une matrice de plusieurs lignes porte une date par ligne ; un
        // simple vecteur porte une seule date.
        if (v.ndims() == 2 && lignes > 1 && (colonnes == 3 || colonnes == 6)) {
            Valeur sortie = Valeur::matrice(lignes, 1);
            for (int l = 0; l < lignes; ++l) {
                auto champ = [&](int c) {
                    return c < colonnes ? v.re[(std::size_t)c * lignes + l] : 0.0;
                };
                sortie.re[l] = versDatenum((int)champ(0), (int)champ(1), (int)champ(2),
                                           (int)champ(3), (int)champ(4), champ(5));
            }
            return {sortie};
        }
        return {Valeur::scalaire(versDatenum(
            (int)v.re[0], (int)v.re[1], (int)v.re[2], v.nelem() > 3 ? (int)v.re[3] : 0,
            v.nelem() > 4 ? (int)v.re[4] : 0, v.nelem() > 5 ? v.re[5] : 0.0))};
    }
    double resultat = 0.0;
    if (lireDateTexte(args[0].versTexte(), resultat)) return {Valeur::scalaire(resultat)};
    erreur("MATLAB:datenum:ConvertDateString", "Unable to convert the date string.");
}

// Une date mise en forme, selon le modele de MATLAB ou le format donne.
std::string ecrireDate(double n, const std::string& format) {
    int annee, mois, jour, heure, minute;
    double seconde;
    depuisDatenum(n, annee, mois, jour, heure, minute, seconde);
    static const char* moisCourt[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
    if (format.empty())
        return formater("%02d-%s-%04d %02d:%02d:%02d", jour,
                        moisCourt[std::max(0, std::min(11, mois - 1))], annee, heure, minute,
                        (int)std::round(seconde));
    std::string r;
    for (std::size_t k = 0; k < format.size();) {
        if (format.compare(k, 4, "yyyy") == 0) { r += formater("%04d", annee); k += 4; }
        else if (format.compare(k, 3, "mmm") == 0) {
            r += moisCourt[std::max(0, std::min(11, mois - 1))];
            k += 3;
        }
        else if (format.compare(k, 2, "mm") == 0) { r += formater("%02d", mois); k += 2; }
        else if (format.compare(k, 2, "dd") == 0) { r += formater("%02d", jour); k += 2; }
        else if (format.compare(k, 2, "HH") == 0) { r += formater("%02d", heure); k += 2; }
        else if (format.compare(k, 2, "MM") == 0) { r += formater("%02d", minute); k += 2; }
        else if (format.compare(k, 2, "SS") == 0) {
            r += formater("%02d", (int)std::round(seconde));
            k += 2;
        } else {
            r += format[k++];
        }
    }
    return r;
}

FONCTION(fnDatestr) {
    INUTILISE
    // Plusieurs dates donnent une matrice de caracteres, une ligne par
    // date : c'est ce que rend MATLAB, et ce dont les echeanciers ont
    // besoin.
    if (!args.empty() && args[0].estNumerique() && args[0].nelem() > 1) {
        std::string format;
        if (args.size() > 1 && (args[1].estTexte() || args[1].estChaine()))
            format = args[1].versTexte();
        std::vector<std::string> lignes;
        std::size_t largeur = 0;
        for (std::size_t k = 0; k < args[0].nelem(); ++k) {
            lignes.push_back(ecrireDate(args[0].re[k], format));
            largeur = std::max(largeur, lignes.back().size());
        }
        Valeur sortie = Valeur::matrice((int)lignes.size(), (int)largeur, (double)' ');
        sortie.classe = Classe::Caractere;
        for (std::size_t l = 0; l < lignes.size(); ++l)
            for (std::size_t c = 0; c < lignes[l].size(); ++c)
                sortie.re[c * lignes.size() + l] = (double)(unsigned char)lignes[l][c];
        return {sortie};
    }
    double n;
    if (args.empty()) {
        std::vector<Valeur> aucun;
        n = fnNow(it, aucun, 1)[0].scal();
    } else if (args[0].estTexte() || args[0].estChaine() || args[0].estCellule()) {
        std::vector<Valeur> un{args[0]};
        Arguments passe(un);
        n = fnDatenum(it, passe, 1)[0].scal();
    } else {
        n = args[0].scal();
    }
    int annee, mois, jour, heure, minute;
    double seconde;
    depuisDatenum(n, annee, mois, jour, heure, minute, seconde);
    static const char* moisCourt[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                                      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
    std::string sortie = formater("%02d-%s-%04d %02d:%02d:%02d", jour,
                                  moisCourt[std::max(0, std::min(11, mois - 1))], annee, heure,
                                  minute, (int)std::round(seconde));
    if (args.size() > 1 && (args[1].estTexte() || args[1].estChaine()))
        sortie = ecrireDate(n, args[1].versTexte());
    return {Valeur::texte(sortie)};
}

FONCTION(fnDatevec) {
    INUTILISE
    exigerArguments(args, 1, 1, "datevec");
    // Un vecteur de numeros de serie donne une ligne par date : c'est ce
    // qu'attendent les fonctions financieres, qui travaillent sur des
    // echeanciers entiers.
    std::vector<double> numeros;
    if (args[0].estTexte() || args[0].estChaine() || args[0].estCellule()) {
        std::vector<Valeur> un{args[0]};
        Arguments passe(un);
        std::vector<Valeur> r = fnDatenum(it, passe, 1);
        numeros.assign(r[0].re.begin(), r[0].re.end());
    } else {
        exigerNumerique(args[0], "datevec");
        numeros.assign(args[0].re.begin(), args[0].re.end());
    }
    int n = (int)numeros.size();
    if (n == 0) return {Valeur::matrice(0, 6)};
    Valeur sortie = Valeur::matrice(n, 6);
    for (int k = 0; k < n; ++k) {
        int annee, mois, jour, heure, minute;
        double seconde;
        depuisDatenum(numeros[k], annee, mois, jour, heure, minute, seconde);
        double champs[6] = {(double)annee, (double)mois,   (double)jour,
                            (double)heure, (double)minute, seconde};
        for (int c = 0; c < 6; ++c) sortie.re[(std::size_t)c * n + k] = champs[c];
    }
    return {sortie};
}

FONCTION(fnDate) {
    INUTILISE
    std::vector<Valeur> aucun;
    return fnDatestr(it, aucun, 1);
}

FONCTION(fnEtime) {
    INUTILISE
    exigerArguments(args, 2, 2, "etime");
    exigerNumerique(args[0], "etime");
    if (args.size() > 1) exigerNumerique(args[1], "etime");
    const Valeur& t2 = args[0];
    const Valeur& t1 = args[1];
    // Un vecteur de date porte ses six champs : sans eux, on lisait hors
    // du tableau.
    if (t2.re.size() < 6 || t1.re.size() < 6)
        erreur("MATLAB:etime:InvalidDateVector",
               "ETIME expects two date vectors of six elements.");
    double a = versDatenum((int)t2.re[0], (int)t2.re[1], (int)t2.re[2], (int)t2.re[3],
                           (int)t2.re[4], t2.re[5]);
    double b = versDatenum((int)t1.re[0], (int)t1.re[1], (int)t1.re[2], (int)t1.re[3],
                           (int)t1.re[4], t1.re[5]);
    return {Valeur::scalaire((a - b) * 86400.0)};
}

FONCTION(fnPause) {
    INUTILISE
    if (args.empty()) return {};
    if (args[0].estTexte()) return {};
    double s = args[0].scal();
    if (s > 0 && s < 3600)
        std::this_thread::sleep_for(std::chrono::duration<double>(s));
    return {};
}

FONCTION(fnWeekday) {
    INUTILISE
    exigerArguments(args, 1, 1, "weekday");
    static const char* noms[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    std::vector<double> numeros;
    if (args[0].estTexte() || args[0].estChaine() || args[0].estCellule()) {
        std::vector<Valeur> un{args[0]};
        Arguments passe(un);
        std::vector<Valeur> r = fnDatenum(it, passe, 1);
        numeros.assign(r[0].re.begin(), r[0].re.end());
    } else {
        exigerNumerique(args[0], "weekday");
        numeros.assign(args[0].re.begin(), args[0].re.end());
    }
    Dims forme = args[0].estNumerique() ? args[0].dims : Dims{(int)numeros.size(), 1};
    Valeur sortie = Valeur::matriceDims(forme);
    for (std::size_t k = 0; k < numeros.size(); ++k) {
        long long jours = (long long)std::floor(numeros[k]);
        sortie.re[k] = (double)(((jours + 5) % 7) + 1);
    }
    if (nargout >= 2) {
        // Les noms sont empiles en lignes, comme la matrice de caracteres
        // que rend MATLAB.
        int n = (int)numeros.size();
        Valeur lettres = Valeur::matrice(n, 3);
        lettres.classe = Classe::Caractere;
        for (int k = 0; k < n; ++k) {
            const char* nom = noms[((int)sortie.re[k] - 1) % 7];
            for (int c = 0; c < 3; ++c) lettres.re[(std::size_t)c * n + k] = (double)nom[c];
        }
        return {sortie, lettres};
    }
    return {sortie};
}


// --- fonctions vectorisées servant de socle à datetime ------------------

// Diffuse un ensemble d'arguments numériques comme le fait MATLAB : les
// scalaires s'étendent à la taille du plus grand tableau.
Dims dimsCommunes(const std::vector<Valeur>& v) {
    Dims d = {1, 1};
    for (const auto& a : v)
        if (a.nelem() > produitDims(d)) d = a.dims;
    return d;
}

double elementDiffuse(const Valeur& v, std::size_t k) {
    if (v.nelem() == 0) return 0.0;
    if (v.nelem() == 1) return v.re[0];
    return v.re[k % v.nelem()];
}

FONCTION(fnYmdVersNum) {
    INUTILISE
    if (args.size() < 3)
        erreur("MATLAB:minrhs", "matlibre_ymd2num requires at least three arguments.");
    for (std::size_t k = 0; k < args.size(); ++k) exigerNumerique(args[k], "matlibre_ymd2num");
    Dims d = dimsCommunes(args);
    std::size_t n = produitDims(d);
    Valeur r = Valeur::matriceDims(d, 0.0);
    for (std::size_t k = 0; k < n; ++k) {
        double annee = elementDiffuse(args[0], k);
        double mois = elementDiffuse(args[1], k);
        double jour = elementDiffuse(args[2], k);
        double heure = args.size() > 3 ? elementDiffuse(args[3], k) : 0.0;
        double minute = args.size() > 4 ? elementDiffuse(args[4], k) : 0.0;
        double seconde = args.size() > 5 ? elementDiffuse(args[5], k) : 0.0;
        // Les mois hors de 1..12 débordent sur l'année, comme datenum.
        double debordement = std::floor((mois - 1) / 12.0);
        annee += debordement;
        mois -= debordement * 12.0;
        double base = versDatenum((int)annee, (int)mois, 1, 0, 0, 0.0);
        r.re[k] = base + (jour - 1) + (heure * 3600.0 + minute * 60.0 + seconde) / 86400.0;
    }
    return {r};
}

FONCTION(fnNumVersYmd) {
    INUTILISE
    exigerArguments(args, 1, 1, "matlibre_num2ymd");
    exigerNumerique(args[0], "datevec");
    std::size_t n = args[0].nelem();
    Valeur r = Valeur::matrice((int)n, 6, 0.0);
    for (std::size_t k = 0; k < n; ++k) {
        int annee, mois, jour, heure, minute;
        double seconde;
        depuisDatenum(args[0].re[k], annee, mois, jour, heure, minute, seconde);
        r.re[k] = annee;
        r.re[n + k] = mois;
        r.re[2 * n + k] = jour;
        r.re[3 * n + k] = heure;
        r.re[4 * n + k] = minute;
        r.re[5 * n + k] = seconde;
    }
    return {r};
}

FONCTION(fnAjouterMois) {
    INUTILISE
    exigerArguments(args, 2, 2, "matlibre_addmonths");
    for (std::size_t k = 0; k < args.size(); ++k) exigerNumerique(args[k], "addmonths");
    Dims d = dimsCommunes(args);
    std::size_t n = produitDims(d);
    Valeur r = Valeur::matriceDims(d, 0.0);
    for (std::size_t k = 0; k < n; ++k) {
        double x = elementDiffuse(args[0], k);
        double k_mois = elementDiffuse(args[1], k);
        int annee, mois, jour, heure, minute;
        double seconde;
        depuisDatenum(x, annee, mois, jour, heure, minute, seconde);
        long long total = (long long)annee * 12 + (mois - 1) + (long long)k_mois;
        int na = (int)(total / 12);
        int nm = (int)(total % 12) + 1;
        if (nm <= 0) { nm += 12; na -= 1; }
        // Le jour est ramené au dernier jour du mois cible, comme MATLAB :
        // 31 janvier + 1 mois donne le 28 (ou 29) février.
        static const int longueur[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
        int maxi = longueur[nm - 1];
        bool bissextile = (na % 4 == 0 && na % 100 != 0) || (na % 400 == 0);
        if (nm == 2 && bissextile) maxi = 29;
        int nj = jour < maxi ? jour : maxi;
        r.re[k] = versDatenum(na, nm, nj, heure, minute, seconde);
    }
    return {r};
}

// Jour de la semaine et numéro de semaine ISO, utilisés par datetime.
FONCTION(fnJourSemaine) {
    INUTILISE
    exigerArguments(args, 1, 1, "matlibre_weekday");
    exigerNumerique(args[0], "weekday");
    Valeur r = Valeur::matriceDims(args[0].dims, 0.0);
    for (std::size_t k = 0; k < args[0].nelem(); ++k) {
        long long jours = (long long)std::floor(args[0].re[k]);
        r.re[k] = (double)(((jours % 7) + 7 + 5) % 7 + 1);
    }
    return {r};
}

}  // namespace

void enregistrerTemps(Interpreteur& it) {
    it.enregistrer("tic", fnTic, "temps", "tic  Demarre le chronometre.");
    it.enregistrer("toc", fnToc, "temps", "toc  Temps ecoule depuis tic.");
    it.enregistrer("cputime", fnCputime, "temps", "cputime  Temps processeur consomme.");
    it.enregistrer("now", fnNow, "temps", "now  Date et heure courantes en numero de serie.");
    it.enregistrer("clock", fnClock, "temps", "clock  Date et heure en vecteur.");
    it.enregistrer("datenum", fnDatenum, "temps", "datenum  Date -> numero de serie.");
    it.enregistrer("datestr", fnDatestr, "temps", "datestr  Numero de serie -> texte.");
    it.enregistrer("datevec", fnDatevec, "temps", "datevec  Numero de serie -> vecteur.");
    it.enregistrer("date", fnDate, "temps", "date  Date du jour.");
    it.enregistrer("etime", fnEtime, "temps", "etime  Secondes entre deux vecteurs d'horloge.");
    it.enregistrer("pause", fnPause, "temps", "pause  Attend un nombre de secondes.");
    it.enregistrer("weekday", fnWeekday, "temps", "weekday  Jour de la semaine.");
    it.enregistrer("matlibre_ymd2num", fnYmdVersNum, "temps",
                   "matlibre_ymd2num  Composantes de date -> numero de serie (vectorise).");
    it.enregistrer("matlibre_num2ymd", fnNumVersYmd, "temps",
                   "matlibre_num2ymd  Numero de serie -> matrice Nx6 de composantes.");
    it.enregistrer("matlibre_addmonths", fnAjouterMois, "temps",
                   "matlibre_addmonths  Ajout de mois calendaires avec calage de fin de mois.");
    it.enregistrer("matlibre_weekday", fnJourSemaine, "temps",
                   "matlibre_weekday  Jour de la semaine (1 = dimanche), vectorise.");
}

}  // namespace matlibre
