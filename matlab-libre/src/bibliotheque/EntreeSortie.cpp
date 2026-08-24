// EntreeSortie.cpp — affichage, formatage à la printf, fichiers.
#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fstream>
#include <iostream>
#include <map>
#include <sstream>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

// ------------------------------------------------- moteur de formatage

namespace {

struct Element {
    bool texte = false;
    double nombre = 0;
    std::string chaine;
};

void aplatir(const std::vector<Valeur>& args, std::size_t debut, std::deque<Element>& sortie) {
    for (std::size_t k = debut; k < args.size(); ++k) {
        const Valeur& v = args[k];
        if (v.classe == Classe::Caractere) {
            Element e;
            e.texte = true;
            e.chaine = v.versTexte();
            sortie.push_back(e);
        } else if (v.classe == Classe::Chaine) {
            for (const auto& s : v.chaines) {
                Element e;
                e.texte = true;
                e.chaine = s;
                sortie.push_back(e);
            }
        } else if (v.classe == Classe::Cellule) {
            std::vector<Valeur> contenu(v.cellules.begin(), v.cellules.end());
            aplatir(contenu, 0, sortie);
        } else {
            for (std::size_t i = 0; i < v.nelem(); ++i) {
                Element e;
                e.nombre = v.re.empty() ? 0.0 : v.re[i];
                sortie.push_back(e);
            }
        }
    }
}

std::string echapper(const std::string& s) {
    std::string r;
    for (std::size_t k = 0; k < s.size(); ++k) {
        if (s[k] != '\\' || k + 1 >= s.size()) {
            r += s[k];
            continue;
        }
        char c = s[++k];
        switch (c) {
            case 'n': r += '\n'; break;
            case 't': r += '\t'; break;
            case 'r': r += '\r'; break;
            case '0': r += '\0'; break;
            case 'a': r += '\a'; break;
            case 'b': r += '\b'; break;
            case 'f': r += '\f'; break;
            case 'v': r += '\v'; break;
            case '\\': r += '\\'; break;
            case '\'': r += '\''; break;
            case '"': r += '"'; break;
            default:
                r += '\\';
                r += c;
                break;
        }
    }
    return r;
}

}  // namespace

std::string formatMatlab(const std::string& formatBrut, const std::vector<Valeur>& args,
                         std::size_t debut) {
    std::string format = echapper(formatBrut);
    std::deque<Element> elements;
    aplatir(args, debut, elements);
    std::string sortie;
    bool consomme = false;
    int tours = 0;
    do {
        ++tours;
        consomme = false;
        std::size_t k = 0;
        while (k < format.size()) {
            char c = format[k];
            if (c != '%') {
                sortie += c;
                ++k;
                continue;
            }
            if (k + 1 < format.size() && format[k + 1] == '%') {
                sortie += '%';
                k += 2;
                continue;
            }
            std::size_t debutSpec = k;
            ++k;
            std::string drapeaux;
            while (k < format.size() && std::strchr("-+ #0", format[k])) drapeaux += format[k++];
            std::string largeur;
            while (k < format.size() && (std::isdigit((unsigned char)format[k]) ||
                                         format[k] == '*')) {
                if (format[k] == '*') {
                    if (!elements.empty()) {
                        largeur = formater("%d", (int)elements.front().nombre);
                        elements.pop_front();
                        consomme = true;
                    }
                    ++k;
                } else {
                    largeur += format[k++];
                }
            }
            std::string precision;
            if (k < format.size() && format[k] == '.') {
                precision += format[k++];
                while (k < format.size() && (std::isdigit((unsigned char)format[k]) ||
                                             format[k] == '*')) {
                    if (format[k] == '*') {
                        if (!elements.empty()) {
                            precision += formater("%d", (int)elements.front().nombre);
                            elements.pop_front();
                            consomme = true;
                        }
                        ++k;
                    } else {
                        precision += format[k++];
                    }
                }
            }
            while (k < format.size() && std::strchr("hlLqjzt", format[k])) ++k;
            if (k >= format.size()) {
                sortie += format.substr(debutSpec);
                break;
            }
            char conversion = format[k++];
            std::string spec = "%" + drapeaux + largeur + precision;

            if (elements.empty()) {
                // Plus d'arguments : MATLAB s'arrête au premier spécificateur.
                if (tours > 1 || !args.empty() || debut < args.size()) {
                    return sortie;
                }
                if (conversion == 's') continue;
                return sortie;
            }
            Element e = elements.front();
            elements.pop_front();
            consomme = true;
            switch (conversion) {
                case 'd':
                case 'i': {
                    if (e.texte) {
                        // Une chaîne se déroule en codes de caractères.
                        std::string reste = e.chaine;
                        if (reste.empty()) break;
                        double x = (double)(unsigned char)reste[0];
                        if (reste.size() > 1) {
                            Element suite;
                            suite.texte = true;
                            suite.chaine = reste.substr(1);
                            elements.push_front(suite);
                        }
                        sortie += formater((spec + "lld").c_str(), (long long)x);
                        break;
                    }
                    if (!std::isfinite(e.nombre)) {
                        std::string t = std::isnan(e.nombre)
                                            ? "NaN"
                                            : (e.nombre > 0 ? "Inf" : "-Inf");
                        sortie += formater(("%" + drapeaux + largeur + "s").c_str(),
                                           t.c_str());
                    } else if (e.nombre != std::floor(e.nombre)) {
                        sortie += formater((spec + "g").c_str(), e.nombre);
                    } else {
                        sortie += formater((spec + "lld").c_str(), (long long)e.nombre);
                    }
                    break;
                }
                case 'u': {
                    sortie += formater((spec + "llu").c_str(),
                                       (unsigned long long)(e.texte ? 0 : e.nombre));
                    break;
                }
                case 'f':
                case 'e':
                case 'E':
                case 'g':
                case 'G': {
                    double x = e.texte ? (e.chaine.empty() ? 0.0 : (double)(unsigned char)
                                                                        e.chaine[0])
                                       : e.nombre;
                    if (std::isnan(x) || std::isinf(x)) {
                        // « %.1f » ne doit pas tronquer « Inf » a « I » : la
                        // precision ne s'applique pas au texte de secours.
                        std::string t = std::isnan(x) ? "NaN" : (x > 0 ? "Inf" : "-Inf");
                        std::string specTexte = "%" + drapeaux + largeur + "s";
                        sortie += formater(specTexte.c_str(), t.c_str());
                    } else {
                        std::string s2 = spec;
                        s2 += conversion;
                        sortie += formater(s2.c_str(), x);
                    }
                    break;
                }
                case 'x':
                case 'X':
                case 'o': {
                    std::string s2 = spec + "ll";
                    s2 += conversion;
                    sortie += formater(s2.c_str(), (long long)(e.texte ? 0 : e.nombre));
                    break;
                }
                case 'c': {
                    if (e.texte) {
                        if (!e.chaine.empty()) {
                            sortie += e.chaine[0];
                            if (e.chaine.size() > 1) {
                                Element suite;
                                suite.texte = true;
                                suite.chaine = e.chaine.substr(1);
                                elements.push_front(suite);
                            }
                        }
                    } else {
                        sortie += (char)(int)e.nombre;
                    }
                    break;
                }
                case 's':
                default: {
                    std::string t;
                    if (e.texte) {
                        t = e.chaine;
                    } else if (e.nombre == std::floor(e.nombre) && std::isfinite(e.nombre)) {
                        t = formater("%lld", (long long)e.nombre);
                    } else {
                        t = formater("%g", e.nombre);
                    }
                    sortie += formater((spec + "s").c_str(), t.c_str());
                    break;
                }
            }
        }
        if (!consomme) break;
    } while (!elements.empty());
    return sortie;
}

namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

std::map<int, std::shared_ptr<std::fstream>>& fichiers() {
    static std::map<int, std::shared_ptr<std::fstream>> table;
    return table;
}
std::map<int, std::string>& nomsFichiers() {
    static std::map<int, std::string> table;
    return table;
}

FONCTION(fnDisp) {
    INUTILISE
    exigerArguments(args, 1, 1, "disp");
    const Valeur& v = args[0];
    std::ostream& os = it.sortie();
    if (v.classe == Classe::Caractere) {
        int l = v.nlignes(), c = v.ncolonnes();
        for (int i = 0; i < l; ++i) {
            std::string ligne;
            for (int j = 0; j < c; ++j)
                ligne += (char)(int)v.re[(std::size_t)i + (std::size_t)j * l];
            os << ligne << "\n";
        }
        if (l == 0) os << "\n";
        os << std::flush;
        return {};
    }
    if (v.classe == Classe::Chaine && v.estScalaire()) {
        os << (v.chaines.empty() ? "" : v.chaines[0]) << "\n";
        return {};
    }
    if (v.estScalaire() && (v.estNumerique() || v.classe == Classe::Logique) &&
        !v.estComplexe()) {
        os << "     " << rendreScalaire(v.re[0], (int)it.format) << "\n";
        return {};
    }
    if (v.estVide()) return {};
    os << rendreValeur(v, (int)it.format, it.formatCompact, 80);
    return {};
}

FONCTION(fnDisplay) {
    INUTILISE
    exigerArguments(args, 1, 2, "display");
    std::string nom = args.size() > 1 ? args[1].versTexte() : "ans";
    afficherResultat(it, nom, args[0]);
    return {};
}

FONCTION(fnSprintf) {
    INUTILISE
    exigerArguments(args, 1, 0, "sprintf");
    return {Valeur::texte(formatMatlab(args[0].versTexte(), args, 1))};
}

FONCTION(fnFprintf) {
    INUTILISE
    exigerArguments(args, 1, 0, "fprintf");
    std::size_t debut = 0;
    int fid = 1;
    if (args[0].estNumerique() && args.size() > 1 && !args[0].estVide()) {
        fid = (int)args[0].scal();
        debut = 1;
    }
    if (debut >= args.size()) return {};
    std::string texte = formatMatlab(args[debut].versTexte(), args, debut + 1);
    // On vide le tampon : un script long doit montrer sa progression.
    if (fid == 1) it.sortie() << texte << std::flush;
    else if (fid == 2) it.erreurSortie() << texte << std::flush;
    else {
        auto f = fichiers().find(fid);
        if (f == fichiers().end())
            erreur("MATLAB:badfid", formater("Invalid file identifier %d.", fid));
        *f->second << texte;
    }
    if (nargout > 0) return {Valeur::scalaire((double)texte.size())};
    return {};
}

FONCTION(fnPrintf) {
    INUTILISE
    exigerArguments(args, 1, 0, "printf");
    it.sortie() << formatMatlab(args[0].versTexte(), args, 1) << std::flush;
    return {};
}

FONCTION(fnNum2str) {
    INUTILISE
    exigerArguments(args, 1, 2, "num2str");
    const Valeur& v = args[0];
    if (v.estTexte() || v.estChaine()) return {Valeur::texte(v.versTexte())};
    if (args.size() > 1 && (args[1].estTexte() || args[1].estChaine()))
        return {Valeur::texte(formatMatlab(args[1].versTexte(), {v}, 0))};
    int chiffres = args.size() > 1 ? (int)args[1].scal() : 0;
    auto un = [&](double x, double y) {
        std::string s;
        if (chiffres > 0) s = formater("%.*g", chiffres, x);
        else if (x == std::floor(x) && std::fabs(x) < 1e15) s = formater("%.0f", x);
        else s = formater("%.4g", x);
        if (y != 0) {
            std::string si = (chiffres > 0) ? formater("%.*g", chiffres, std::fabs(y))
                                            : formater("%.4g", std::fabs(y));
            s += (y < 0 ? "-" : "+") + si + "i";
        }
        return s;
    };
    if (v.estScalaire())
        return {Valeur::texte(un(v.re.empty() ? 0 : v.re[0], v.im.empty() ? 0 : v.im[0]))};
    // Une ligne par ligne de la matrice, colonnes séparées par deux blancs.
    int l = v.nlignes(), c = v.ncolonnes();
    std::vector<std::string> lignes;
    std::size_t largeur = 0;
    std::vector<std::vector<std::string>> cellules((std::size_t)l);
    for (int i = 0; i < l; ++i)
        for (int j = 0; j < c; ++j) {
            std::size_t k = (std::size_t)i + (std::size_t)j * l;
            std::string s = un(v.re[k], v.im.empty() ? 0 : v.im[k]);
            largeur = std::max(largeur, s.size());
            cellules[(std::size_t)i].push_back(s);
        }
    for (int i = 0; i < l; ++i) {
        std::string ligne;
        for (int j = 0; j < c; ++j) {
            if (j) ligne += "  ";
            ligne += formater("%*s", (int)largeur, cellules[(std::size_t)i][(std::size_t)j].c_str());
        }
        lignes.push_back(ligne);
    }
    if (lignes.size() == 1) return {Valeur::texte(lignes[0])};
    std::vector<Valeur> parts;
    for (const auto& s : lignes) parts.push_back(Valeur::texte(s));
    return {concatener(parts, 0)};
}

FONCTION(fnInt2str) {
    INUTILISE
    Valeur r = appliquerReel(args[0], [](double x) {
        return (x < 0) ? -std::floor(-x + 0.5) : std::floor(x + 0.5);
    });
    std::vector<Valeur> a = {r};
    return fnNum2str(it, a, 1);
}

FONCTION(fnMat2str) {
    INUTILISE
    exigerArguments(args, 1, 2, "mat2str");
    const Valeur& v = args[0];
    int chiffres = args.size() > 1 ? (int)args[1].scal() : 15;
    if (v.estTexte()) return {Valeur::texte("\"" + v.versTexte() + "\"")};
    std::string s;
    bool crochets = !v.estScalaire();
    if (v.classe == Classe::Logique) {
        if (crochets) s += "[";
        for (int i = 0; i < v.nlignes(); ++i) {
            if (i) s += ";";
            for (int j = 0; j < v.ncolonnes(); ++j) {
                if (j) s += " ";
                s += v.re[(std::size_t)i + (std::size_t)j * v.nlignes()] != 0 ? "true" : "false";
            }
        }
        if (crochets) s += "]";
        return {Valeur::texte(s)};
    }
    if (crochets) s += "[";
    for (int i = 0; i < v.nlignes(); ++i) {
        if (i) s += ";";
        for (int j = 0; j < v.ncolonnes(); ++j) {
            if (j) s += " ";
            std::size_t k = (std::size_t)i + (std::size_t)j * v.nlignes();
            s += formater("%.*g", chiffres, v.re[k]);
            if (!v.im.empty() && v.im[k] != 0)
                s += formater("%+.*gi", chiffres, v.im[k]);
        }
    }
    if (crochets) s += "]";
    return {Valeur::texte(s)};
}

FONCTION(fnStr2double) {
    INUTILISE
    exigerArguments(args, 1, 1, "str2double");
    const Valeur& v = args[0];
    auto conv = [](const std::string& s) {
        try {
            std::size_t pos = 0;
            std::string t = s;
            while (!t.empty() && std::isspace((unsigned char)t.front())) t.erase(t.begin());
            while (!t.empty() && std::isspace((unsigned char)t.back())) t.pop_back();
            if (t.empty()) return std::nan("");
            double x = std::stod(t, &pos);
            if (pos != t.size()) return std::nan("");
            return x;
        } catch (...) {
            return std::nan("");
        }
    };
    if (v.classe == Classe::Cellule) {
        Valeur r = Valeur::matriceDims(v.dims);
        for (std::size_t k = 0; k < v.cellules.size(); ++k)
            r.re[k] = conv(v.cellules[k].versTexte());
        return {r};
    }
    if (v.classe == Classe::Chaine) {
        Valeur r = Valeur::matriceDims(v.dims);
        for (std::size_t k = 0; k < v.chaines.size(); ++k) r.re[k] = conv(v.chaines[k]);
        return {r};
    }
    return {Valeur::scalaire(conv(v.versTexte()))};
}

FONCTION(fnStr2num) {
    INUTILISE
    exigerArguments(args, 1, 1, "str2num");
    std::string s = args[0].versTexte();
    try {
        it.executerTexte("matlibre__str2num__ = [" + s + "];", "<str2num>");
        Valeur v = it.lireVariable("matlibre__str2num__");
        it.effacerVariable("matlibre__str2num__");
        return {v};
    } catch (const ErreurMatlab&) {
        return {Valeur::vide()};
    }
}

// ------------------------------------------------------------- sscanf

// Analyse syntaxique du format de sscanf. On avance en parallele dans le
// format et dans le texte ; le format est repete tant qu'il consomme
// quelque chose, comme le fait MATLAB.
namespace {

struct ResultatScan {
    std::vector<double> nombres;
    std::string caracteres;
    bool queDesCaracteres = true;
    std::size_t compte = 0;
    std::size_t position = 0;   // indice, base 1, du premier caractere non lu
    std::string erreur;
};

void sauterBlancs(const std::string& s, std::size_t& i) {
    while (i < s.size() && std::isspace((unsigned char)s[i])) ++i;
}

bool lireNombre(const std::string& s, std::size_t& i, char conversion,
                std::size_t largeur, double& valeur) {
    sauterBlancs(s, i);
    std::size_t debut = i;
    std::size_t fin = (largeur == 0) ? s.size() : std::min(s.size(), i + largeur);
    if (debut >= fin) return false;
    std::string morceau = s.substr(debut, fin - debut);
    const char* texte = morceau.c_str();
    char* apres = nullptr;
    if (conversion == 'd' || conversion == 'i' || conversion == 'u') {
        long long v = std::strtoll(texte, &apres, 10);
        if (apres == texte) return false;
        valeur = (double)v;
    } else if (conversion == 'x') {
        long long v = std::strtoll(texte, &apres, 16);
        if (apres == texte) return false;
        valeur = (double)v;
    } else if (conversion == 'o') {
        long long v = std::strtoll(texte, &apres, 8);
        if (apres == texte) return false;
        valeur = (double)v;
    } else {
        double v = std::strtod(texte, &apres);
        if (apres == texte) return false;
        valeur = v;
    }
    i = debut + (std::size_t)(apres - texte);
    return true;
}

ResultatScan scannerTexte(const std::string& texte, const std::string& format,
                          std::size_t maximum) {
    ResultatScan r;
    std::size_t i = 0;
    bool progresse = true;
    while (progresse && i <= texte.size()) {
        progresse = false;
        std::size_t f = 0;
        bool echec = false;
        while (f < format.size()) {
            char c = format[f];
            if (std::isspace((unsigned char)c)) {
                sauterBlancs(texte, i);
                ++f;
                continue;
            }
            if (c != '%') {
                sauterBlancs(texte, i);
                if (i < texte.size() && texte[i] == c) { ++i; ++f; progresse = true; continue; }
                echec = true;
                break;
            }
            ++f;
            if (f < format.size() && format[f] == '%') {
                sauterBlancs(texte, i);
                if (i < texte.size() && texte[i] == '%') { ++i; ++f; progresse = true; continue; }
                echec = true;
                break;
            }
            bool ignorer = false;
            if (f < format.size() && format[f] == '*') { ignorer = true; ++f; }
            std::size_t largeur = 0;
            while (f < format.size() && std::isdigit((unsigned char)format[f])) {
                largeur = largeur * 10 + (std::size_t)(format[f] - '0');
                ++f;
            }
            // Les modificateurs de longueur du C sont acceptes et ignores.
            while (f < format.size() && std::strchr("hlLqjzt", format[f])) ++f;
            if (f >= format.size()) { echec = true; break; }
            char conversion = format[f++];
            if (conversion == 'c') {
                std::size_t n = largeur == 0 ? 1 : largeur;
                if (i + n > texte.size()) { echec = true; break; }
                if (!ignorer) {
                    r.caracteres += texte.substr(i, n);
                    r.compte += n;
                }
                i += n;
                progresse = true;
            } else if (conversion == 's') {
                sauterBlancs(texte, i);
                std::size_t debut = i;
                while (i < texte.size() && !std::isspace((unsigned char)texte[i]) &&
                       (largeur == 0 || i - debut < largeur))
                    ++i;
                if (i == debut) { echec = true; break; }
                if (!ignorer) {
                    r.caracteres += texte.substr(debut, i - debut);
                    r.compte += i - debut;
                }
                progresse = true;
            } else {
                double valeur = 0;
                if (!lireNombre(texte, i, conversion, largeur, valeur)) { echec = true; break; }
                if (!ignorer) {
                    r.nombres.push_back(valeur);
                    r.queDesCaracteres = false;
                    ++r.compte;
                }
                progresse = true;
            }
            if (maximum != 0 && r.compte >= maximum) { echec = true; break; }
        }
        if (echec && !progresse) break;
        if (maximum != 0 && r.compte >= maximum) break;
        if (echec) continue;
    }
    r.position = i + 1;
    return r;
}

}  // namespace

FONCTION(fnSscanf) {
    INUTILISE
    exigerArguments(args, 2, 3, "sscanf");
    std::string texte = args[0].versTexte();
    std::string format = args[1].versTexte();
    std::size_t maximum = 0;
    int lignes = -1, colonnes = -1;
    if (args.size() > 2 && !args[2].estVide()) {
        const Valeur& taille = args[2];
        if (taille.nelem() == 1) {
            double v = taille.scal();
            if (std::isfinite(v) && v > 0) maximum = (std::size_t)v;
        } else if (taille.nelem() >= 2) {
            lignes = (int)taille.re[0];
            double c = taille.re[1];
            if (std::isfinite(c)) {
                colonnes = (int)c;
                if (lignes > 0 && colonnes > 0) maximum = (std::size_t)(lignes * colonnes);
            }
        }
    }
    ResultatScan r = scannerTexte(texte, format, maximum);
    Valeur sortie;
    if (r.queDesCaracteres && !r.caracteres.empty()) {
        sortie = Valeur::texte(r.caracteres);
    } else {
        std::vector<double> v = r.nombres;
        for (char c : r.caracteres) v.push_back((double)(unsigned char)c);
        sortie = Valeur::matrice((int)v.size(), v.empty() ? 0 : 1);
        for (std::size_t k = 0; k < v.size(); ++k) sortie.re[k] = v[k];
        if (lignes > 0 && !v.empty()) {
            int total = (int)v.size();
            int nc = (colonnes > 0) ? colonnes : (total + lignes - 1) / lignes;
            // MATLAB remplit colonne par colonne et complete par des zeros.
            Valeur m = Valeur::matrice(lignes, nc, 0.0);
            for (int k = 0; k < total && k < lignes * nc; ++k) m.re[(std::size_t)k] = v[(std::size_t)k];
            sortie = m;
        }
    }
    std::vector<Valeur> sorties{sortie};
    if (nargout >= 2) sorties.push_back(Valeur::scalaire((double)r.compte));
    if (nargout >= 3) sorties.push_back(Valeur::texte(r.erreur));
    if (nargout >= 4) sorties.push_back(Valeur::scalaire((double)r.position));
    return sorties;
}

// ------------------------------------------------------------- erreurs

bool ressembleIdentifiant(const std::string& s) {
    if (s.find(':') == std::string::npos) return false;
    if (s.find(' ') != std::string::npos) return false;
    if (s.find('%') != std::string::npos) return false;
    for (char c : s)
        if (!(std::isalnum((unsigned char)c) || c == ':' || c == '_' || c == '-')) return false;
    return true;
}

FONCTION(fnError) {
    INUTILISE
    if (args.empty()) erreur("MATLAB:error", "Not enough input arguments.");
    if (args[0].estStructure()) {
        std::string id = args[0].aChamp("identifier") ? args[0].champ("identifier").versTexte()
                                                      : "";
        std::string msg = args[0].aChamp("message") ? args[0].champ("message").versTexte() : "";
        erreur(id, msg);
    }
    std::string premier = args[0].versTexte();
    if (args.size() > 1 && ressembleIdentifiant(premier))
        erreur(premier, formatMatlab(args[1].versTexte(), args, 2));
    if (args.size() == 1 && ressembleIdentifiant(premier) && premier.find(' ') ==
                                                                 std::string::npos)
        erreur(premier, premier);
    erreur("", formatMatlab(premier, args, 1));
}

FONCTION(fnWarning) {
    INUTILISE
    if (args.empty()) return {};
    std::string premier = args[0].versTexte();
    if (premier == "off" || premier == "on") {
        std::string cible = args.size() > 1 ? args[1].versTexte() : "all";
        if (cible == "all") it.avertissementsActifs = (premier == "on");
        else if (premier == "off") it.avertissementsEteints.insert(cible);
        else it.avertissementsEteints.erase(cible);
        return {};
    }
    std::string id, message;
    if (args.size() > 1 && ressembleIdentifiant(premier)) {
        id = premier;
        message = formatMatlab(args[1].versTexte(), args, 2);
    } else {
        message = formatMatlab(premier, args, 1);
    }
    if (!it.avertissementsActifs || it.avertissementsEteints.count(id)) return {};
    it.erreurSortie() << "Warning: " << message << "\n";
    return {};
}

FONCTION(fnLasterr) {
    INUTILISE
    return {Valeur::texte(it.dernierMessage)};
}

FONCTION(fnMException) {
    INUTILISE
    exigerArguments(args, 1, 0, "MException");
    Valeur e = Valeur::structureVide();
    e.classe = Classe::Objet;
    e.nomObjet = "MException";
    e.poserChamp("identifier", Valeur::texte(args[0].versTexte()));
    e.poserChamp("message",
                 Valeur::texte(args.size() > 1 ? formatMatlab(args[1].versTexte(), args, 2)
                                               : ""));
    e.poserChamp("stack", Valeur::vide());
    return {e};
}

FONCTION(fnRethrow) {
    INUTILISE
    exigerArguments(args, 1, 1, "rethrow");
    std::string id = args[0].aChamp("identifier") ? args[0].champ("identifier").versTexte() : "";
    std::string msg = args[0].aChamp("message") ? args[0].champ("message").versTexte() : "";
    erreur(id, msg);
}

FONCTION(fnAssertLance) {
    INUTILISE
    exigerArguments(args, 1, 0, "throw");
    return fnRethrow(it, args, nargout);
}

// -------------------------------------------------------------- fichiers

FONCTION(fnFopen) {
    INUTILISE
    exigerArguments(args, 1, 3, "fopen");
    std::string nom = args[0].versTexte();
    std::string mode = args.size() > 1 ? args[1].versTexte() : "r";
    std::ios::openmode drapeaux = std::ios::in;
    if (mode.find('w') != std::string::npos) drapeaux = std::ios::out | std::ios::trunc;
    else if (mode.find('a') != std::string::npos) drapeaux = std::ios::out | std::ios::app;
    else if (mode.find('+') != std::string::npos) drapeaux = std::ios::in | std::ios::out;
    if (mode.find('b') != std::string::npos) drapeaux |= std::ios::binary;
    auto f = std::make_shared<std::fstream>(nom, drapeaux);
    if (!f->is_open()) {
        if (nargout >= 2) return {Valeur::scalaire(-1), Valeur::texte("No such file or directory")};
        return {Valeur::scalaire(-1)};
    }
    static int prochain = 3;
    int fid = prochain++;
    fichiers()[fid] = f;
    nomsFichiers()[fid] = nom;
    if (nargout >= 2) return {Valeur::scalaire(fid), Valeur::texte("")};
    return {Valeur::scalaire(fid)};
}

FONCTION(fnFclose) {
    INUTILISE
    exigerArguments(args, 1, 1, "fclose");
    if (args[0].estTexte() && args[0].versTexte() == "all") {
        fichiers().clear();
        return {Valeur::scalaire(0)};
    }
    int fid = (int)args[0].scal();
    auto f = fichiers().find(fid);
    if (f == fichiers().end()) return {Valeur::scalaire(-1)};
    f->second->close();
    fichiers().erase(f);
    return {Valeur::scalaire(0)};
}

std::fstream& fluxDe(int fid) {
    auto f = fichiers().find(fid);
    if (f == fichiers().end())
        erreur("MATLAB:badfid", formater("Invalid file identifier %d.", fid));
    return *f->second;
}

FONCTION(fnFgetl) {
    INUTILISE
    exigerArguments(args, 1, 1, "fgetl");
    std::string ligne;
    if (!std::getline(fluxDe((int)args[0].scal()), ligne)) return {Valeur::scalaire(-1)};
    if (!ligne.empty() && ligne.back() == '\r') ligne.pop_back();
    return {Valeur::texte(ligne)};
}

FONCTION(fnFgets) {
    INUTILISE
    exigerArguments(args, 1, 2, "fgets");
    std::string ligne;
    if (!std::getline(fluxDe((int)args[0].scal()), ligne)) return {Valeur::scalaire(-1)};
    return {Valeur::texte(ligne + "\n")};
}

FONCTION(fnFeof) {
    INUTILISE
    exigerArguments(args, 1, 1, "feof");
    return {Valeur::booleen(fluxDe((int)args[0].scal()).eof())};
}

FONCTION(fnFrewind) {
    INUTILISE
    exigerArguments(args, 1, 1, "frewind");
    auto& f = fluxDe((int)args[0].scal());
    f.clear();
    f.seekg(0);
    return {};
}

FONCTION(fnFread) {
    INUTILISE
    exigerArguments(args, 1, 3, "fread");
    auto& f = fluxDe((int)args[0].scal());
    std::size_t combien = (std::size_t)-1;
    if (args.size() > 1 && !args[1].estVide() && args[1].estNumerique())
        combien = (std::size_t)args[1].scal();
    std::vector<double> octets;
    char c;
    while (octets.size() < combien && f.get(c)) octets.push_back((double)(unsigned char)c);
    return {Valeur::colonne(octets)};
}

FONCTION(fnFwrite) {
    INUTILISE
    exigerArguments(args, 2, 3, "fwrite");
    auto& f = fluxDe((int)args[0].scal());
    const Valeur& v = args[1];
    if (v.estTexte() || v.estChaine()) {
        std::string s = v.versTexte();
        f.write(s.data(), (std::streamsize)s.size());
        return {Valeur::scalaire((double)s.size())};
    }
    for (double x : v.re) f.put((char)(int)x);
    return {Valeur::scalaire((double)v.nelem())};
}

FONCTION(fnFileread) {
    INUTILISE
    exigerArguments(args, 1, 1, "fileread");
    std::ifstream f(args[0].versTexte(), std::ios::binary);
    if (!f) erreur("MATLAB:fileread:cannotOpenFile",
                   "Could not open file " + args[0].versTexte() + ".");
    std::ostringstream ss;
    ss << f.rdbuf();
    return {Valeur::texte(ss.str())};
}

FONCTION(fnFilewrite) {
    INUTILISE
    exigerArguments(args, 2, 2, "filewrite");
    std::ofstream f(args[0].versTexte(), std::ios::binary);
    f << args[1].versTexte();
    return {};
}

FONCTION(fnInput) {
    INUTILISE
    exigerArguments(args, 1, 2, "input");
    it.sortie() << args[0].versTexte() << std::flush;
    std::string ligne;
    if (!std::getline(std::cin, ligne)) return {Valeur::vide()};
    bool brut = args.size() > 1 && args[1].versTexte() == "s";
    if (brut) return {Valeur::texte(ligne)};
    if (ligne.empty()) return {Valeur::vide()};
    std::vector<Valeur> a = {Valeur::texte(ligne)};
    return fnStr2num(it, a, 1);
}

FONCTION(fnFormat) {
    INUTILISE
    if (args.empty()) {
        it.format = Format::Court;
        it.formatCompact = false;
        return {};
    }
    std::string mode = args[0].versTexte();
    if (mode == "short") it.format = Format::Court;
    else if (mode == "long") it.format = Format::Long;
    else if (mode == "shortE" || mode == "short e") it.format = Format::CourtE;
    else if (mode == "longE" || mode == "long e") it.format = Format::LongE;
    else if (mode == "shortG" || mode == "short g") it.format = Format::CourtG;
    else if (mode == "longG" || mode == "long g") it.format = Format::LongG;
    else if (mode == "hex") it.format = Format::Hex;
    else if (mode == "rat") it.format = Format::Rationnel;
    else if (mode == "bank") it.format = Format::Banque;
    else if (mode == "+") it.format = Format::Plus;
    else if (mode == "compact") it.formatCompact = true;
    else if (mode == "loose") it.formatCompact = false;
    return {};
}

// --------------------------------------------------------- fichiers texte

FONCTION(fnDlmwrite) {
    INUTILISE
    exigerArguments(args, 2, 3, "dlmwrite");
    std::string sep = args.size() > 2 ? args[2].versTexte() : ",";
    std::ofstream f(args[0].versTexte());
    const Valeur& v = args[1];
    for (int i = 0; i < v.nlignes(); ++i) {
        for (int j = 0; j < v.ncolonnes(); ++j) {
            if (j) f << sep;
            f << formater("%g", v.re[(std::size_t)i + (std::size_t)j * v.nlignes()]);
        }
        f << "\n";
    }
    return {};
}

FONCTION(fnDlmread) {
    INUTILISE
    exigerArguments(args, 1, 2, "dlmread");
    std::ifstream f(args[0].versTexte());
    if (!f) erreur("MATLAB:dlmread:FileNotFound", "File not found.");
    std::string sep = args.size() > 1 ? args[1].versTexte() : ",";
    char separateur = sep.empty() ? ',' : sep[0];
    std::vector<std::vector<double>> lignes;
    std::string ligne;
    while (std::getline(f, ligne)) {
        if (ligne.empty()) continue;
        std::vector<double> valeurs;
        std::string courant;
        for (char c : ligne) {
            if (c == separateur || (separateur == ' ' && std::isspace((unsigned char)c))) {
                if (!courant.empty()) valeurs.push_back(std::atof(courant.c_str()));
                courant.clear();
            } else {
                courant += c;
            }
        }
        if (!courant.empty()) valeurs.push_back(std::atof(courant.c_str()));
        lignes.push_back(valeurs);
    }
    std::size_t colonnes = 0;
    for (auto& l : lignes) colonnes = std::max(colonnes, l.size());
    Valeur r = Valeur::matrice((int)lignes.size(), (int)colonnes);
    for (std::size_t i = 0; i < lignes.size(); ++i)
        for (std::size_t j = 0; j < lignes[i].size(); ++j)
            r.re[i + j * lignes.size()] = lignes[i][j];
    return {r};
}

FONCTION(fnCsvread) {
    INUTILISE
    return fnDlmread(it, args, nargout);
}
FONCTION(fnCsvwrite) {
    INUTILISE
    std::vector<Valeur> a = {args[0], args[1], Valeur::texte(",")};
    return fnDlmwrite(it, a, nargout);
}

}  // namespace

void enregistrerEntreeSortie(Interpreteur& it) {
    it.enregistrer("disp", fnDisp, "es", "disp  Affiche une valeur sans son nom.");
    it.enregistrer("display", fnDisplay, "es", "display  Affiche une valeur avec son nom.");
    it.enregistrer("sprintf", fnSprintf, "es", "sprintf  Formate dans une chaine.");
    it.enregistrer("sscanf", fnSscanf, "es", "sscanf  Lit des donnees depuis une chaine.");
    it.enregistrer("fprintf", fnFprintf, "es", "fprintf  Ecrit du texte formate.");
    it.enregistrer("printf", fnPrintf, "es", "printf  Ecrit du texte formate (sortie standard).");
    it.enregistrer("num2str", fnNum2str, "es", "num2str  Nombre vers texte.");
    it.enregistrer("int2str", fnInt2str, "es", "int2str  Entier arrondi vers texte.");
    it.enregistrer("mat2str", fnMat2str, "es", "mat2str  Matrice vers texte relisible.");
    it.enregistrer("str2double", fnStr2double, "es", "str2double  Texte vers nombre.");
    it.enregistrer("str2num", fnStr2num, "es", "str2num  Evalue un texte comme expression.");
    it.enregistrer("error", fnError, "es", "error  Leve une erreur.");
    it.enregistrer("warning", fnWarning, "es", "warning  Emet un avertissement.");
    it.enregistrer("lasterr", fnLasterr, "es", "lasterr  Dernier message d'erreur.");
    it.enregistrer("MException", fnMException, "es", "MException  Construit une exception.");
    it.enregistrer("rethrow", fnRethrow, "es", "rethrow  Relance une exception.");
    it.enregistrer("throw", fnAssertLance, "es", "throw  Lance une exception.");
    it.enregistrer("fopen", fnFopen, "es", "fopen  Ouvre un fichier.");
    it.enregistrer("fclose", fnFclose, "es", "fclose  Ferme un fichier.");
    it.enregistrer("fgetl", fnFgetl, "es", "fgetl  Lit une ligne sans le saut de ligne.");
    it.enregistrer("fgets", fnFgets, "es", "fgets  Lit une ligne avec le saut de ligne.");
    it.enregistrer("feof", fnFeof, "es", "feof  Fin de fichier atteinte.");
    it.enregistrer("frewind", fnFrewind, "es", "frewind  Revient au debut du fichier.");
    it.enregistrer("fread", fnFread, "es", "fread  Lit des octets.");
    it.enregistrer("fwrite", fnFwrite, "es", "fwrite  Ecrit des octets.");
    it.enregistrer("fileread", fnFileread, "es", "fileread  Lit un fichier entier.");
    it.enregistrer("filewrite", fnFilewrite, "es", "filewrite  Ecrit un fichier entier.");
    it.enregistrer("input", fnInput, "es", "input  Demande une saisie a l'utilisateur.");
    it.enregistrer("format", fnFormat, "es", "format  Choisit le format d'affichage.");
    it.enregistrer("dlmread", fnDlmread, "es", "dlmread  Lit un fichier delimite.");
    it.enregistrer("dlmwrite", fnDlmwrite, "es", "dlmwrite  Ecrit un fichier delimite.");
    it.enregistrer("csvread", fnCsvread, "es", "csvread  Lit un fichier CSV.");
    it.enregistrer("csvwrite", fnCsvwrite, "es", "csvwrite  Ecrit un fichier CSV.");
}

}  // namespace matlibre
