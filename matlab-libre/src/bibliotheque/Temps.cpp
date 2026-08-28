// Temps.cpp — horloges, dates, chronomètres.
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
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
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

FONCTION(fnDatenum) {
    INUTILISE
    if (args.empty()) {
        std::vector<Valeur> aucun;
        return fnNow(it, aucun, 1);
    }
    if (args.size() >= 3) {
        int annee = (int)args[0].scal(), mois = (int)args[1].scal(), jour = (int)args[2].scal();
        int heure = args.size() > 3 ? (int)args[3].scal() : 0;
        int minute = args.size() > 4 ? (int)args[4].scal() : 0;
        double seconde = args.size() > 5 ? args[5].scal() : 0.0;
        return {Valeur::scalaire(versDatenum(annee, mois, jour, heure, minute, seconde))};
    }
    if (args[0].nelem() >= 3 && args[0].estNumerique()) {
        const Valeur& v = args[0];
        return {Valeur::scalaire(versDatenum(
            (int)v.re[0], (int)v.re[1], (int)v.re[2], v.nelem() > 3 ? (int)v.re[3] : 0,
            v.nelem() > 4 ? (int)v.re[4] : 0, v.nelem() > 5 ? v.re[5] : 0.0))};
    }
    // Texte « aaaa-mm-jj » ou « jj/mm/aaaa ».
    std::string s = args[0].versTexte();
    int a = 0, m = 0, j = 0, h = 0, mi = 0;
    double se = 0;
    if (std::sscanf(s.c_str(), "%d-%d-%d %d:%d:%lf", &a, &m, &j, &h, &mi, &se) >= 3)
        return {Valeur::scalaire(versDatenum(a, m, j, h, mi, se))};
    if (std::sscanf(s.c_str(), "%d/%d/%d", &m, &j, &a) == 3)
        return {Valeur::scalaire(versDatenum(a, m, j, 0, 0, 0))};
    erreur("MATLAB:datenum:ConvertDateString", "Unable to convert the date string.");
}

FONCTION(fnDatestr) {
    INUTILISE
    double n;
    if (args.empty()) {
        std::vector<Valeur> aucun;
        n = fnNow(it, aucun, 1)[0].scal();
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
    if (args.size() > 1 && (args[1].estTexte() || args[1].estChaine())) {
        std::string f = args[1].versTexte();
        std::string r;
        for (std::size_t k = 0; k < f.size();) {
            if (f.compare(k, 4, "yyyy") == 0) { r += formater("%04d", annee); k += 4; }
            else if (f.compare(k, 2, "mm") == 0) { r += formater("%02d", mois); k += 2; }
            else if (f.compare(k, 2, "dd") == 0) { r += formater("%02d", jour); k += 2; }
            else if (f.compare(k, 2, "HH") == 0) { r += formater("%02d", heure); k += 2; }
            else if (f.compare(k, 2, "MM") == 0) { r += formater("%02d", minute); k += 2; }
            else if (f.compare(k, 2, "SS") == 0) {
                r += formater("%02d", (int)std::round(seconde));
                k += 2;
            } else {
                r += f[k++];
            }
        }
        sortie = r;
    }
    return {Valeur::texte(sortie)};
}

FONCTION(fnDatevec) {
    INUTILISE
    exigerArguments(args, 1, 1, "datevec");
    int annee, mois, jour, heure, minute;
    double seconde;
    depuisDatenum(args[0].scal(), annee, mois, jour, heure, minute, seconde);
    std::vector<double> v = {(double)annee, (double)mois,  (double)jour,
                             (double)heure, (double)minute, seconde};
    return {Valeur::ligne(v)};
}

FONCTION(fnDate) {
    INUTILISE
    std::vector<Valeur> aucun;
    return fnDatestr(it, aucun, 1);
}

FONCTION(fnEtime) {
    INUTILISE
    exigerArguments(args, 2, 2, "etime");
    const Valeur& t2 = args[0];
    const Valeur& t1 = args[1];
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
    long long jours = (long long)std::floor(args[0].scal());
    int jour = (int)(((jours + 5) % 7) + 1);
    static const char* noms[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    if (nargout >= 2)
        return {Valeur::scalaire(jour), Valeur::texte(noms[(jour - 1) % 7])};
    return {Valeur::scalaire(jour)};
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
