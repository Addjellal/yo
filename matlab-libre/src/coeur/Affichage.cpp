#include "matlibre/Affichage.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <sstream>

#include "matlibre/Creux.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

static bool estEntierAffichable(double x) {
    return std::isfinite(x) && x == std::floor(x) && std::fabs(x) < 1e15;
}

std::string nombreVersTexte(double x, int chiffres) {
    if (std::isnan(x)) return "NaN";
    if (std::isinf(x)) return x > 0 ? "Inf" : "-Inf";
    if (estEntierAffichable(x)) return formater("%.0f", x);
    return formater("%.*g", chiffres, x);
}

// Nombre de décimales que « format long » accorde à une classe : quinze
// pour un double, sept pour un single. Au-delà, on n'écrirait plus la
// valeur mais le bruit de sa conversion — 3.141592741012573 n'est pas
// « pi en simple précision », c'est la lecture en double d'un single.
int decimalesLongues(bool simple) { return simple ? 7 : 15; }

std::string rendreScalaire(double x, int format, bool simple) {
    Format f = (Format)format;
    const int longues = decimalesLongues(simple);
    if (std::isnan(x)) return "NaN";
    if (std::isinf(x)) return x > 0 ? "Inf" : "-Inf";
    switch (f) {
        case Format::Long:
            // « format long » montre quinze décimales, pas quinze chiffres
            // significatifs : pi s'écrit 3.141592653589793.
            if (estEntierAffichable(x)) return formater("%.0f", x);
            if (std::fabs(x) >= 1e5 || std::fabs(x) < 1e-5)
                return formater("%.*e", longues, x);
            return formater("%.*f", longues, x);
        case Format::CourtE: return formater("%.4e", x);
        case Format::LongE: return formater("%.*e", longues, x);
        case Format::CourtG: return formater("%g", x);
        case Format::LongG: return formater("%.*g", longues + 1, x);
        case Format::Banque: return formater("%.2f", x);
        case Format::Plus: return x > 0 ? "+" : (x < 0 ? "-" : " ");
        case Format::Hex: {
            unsigned long long b;
            std::memcpy(&b, &x, sizeof(b));
            return formater("%016llx", b);
        }
        case Format::Rationnel: {
            // Approximation rationnelle par fractions continues.
            if (estEntierAffichable(x)) return formater("%.0f", x);
            double v = x;
            long long p0 = 0, q0 = 1, p1 = 1, q1 = 0;
            for (int k = 0; k < 20; ++k) {
                double a = std::floor(v);
                long long ai = (long long)a;
                long long p2 = ai * p1 + p0, q2 = ai * q1 + q0;
                p0 = p1; q0 = q1; p1 = p2; q1 = q2;
                if (std::fabs((double)p1 / (double)q1 - x) < 1e-10 * std::fabs(x)) break;
                double reste = v - a;
                if (reste < 1e-12) break;
                v = 1.0 / reste;
            }
            return formater("%lld/%lld", p1, q1);
        }
        default:
            if (estEntierAffichable(x)) return formater("%.0f", x);
            return formater("%.4f", x);
    }
}

struct PlanColonne {
    bool entiers = true;
    int largeur = 10;
    int decimales = 4;
    double facteur = 1.0;
};

int decimalesLongues(bool simple);

static PlanColonne planifier(const Valeur& v, Format format) {
    PlanColonne p;
    double maxAbs = 0, minAbs = INFINITY;
    bool aFini = false;
    bool aNegatif = false;
    for (std::size_t k = 0; k < v.re.size(); ++k) {
        double x = v.re[k];
        double y = v.im.empty() ? 0.0 : v.im[k];
        if (!std::isfinite(x) || !estEntierAffichable(x)) p.entiers = false;
        if (!v.im.empty() && (!std::isfinite(y) || !estEntierAffichable(y))) p.entiers = false;
        if (x < 0 || y < 0) aNegatif = true;
        double m = std::max(std::fabs(x), std::fabs(y));
        if (std::isfinite(m)) {
            aFini = true;
            maxAbs = std::max(maxAbs, m);
            if (m != 0) minAbs = std::min(minAbs, m);
        }
    }
    if (!aFini) maxAbs = 1.0;
    if (!std::isfinite(minAbs)) minAbs = maxAbs;
    const bool simple = v.classe == Classe::Simple;
    p.decimales = (format == Format::Long || format == Format::LongG)
                      ? decimalesLongues(simple)
                      : 4;
    if (p.entiers) {
        int largeurMax = 1;
        for (std::size_t k = 0; k < v.re.size(); ++k) {
            int l = (int)formater("%.0f", v.re[k]).size();
            largeurMax = std::max(largeurMax, l);
        }
        // Les entiers et les logiques se serrent, comme dans MATLAB : trois
        // espaces devant le plus large, « 1   0   1 ». Les doubles entiers
        // gardent leurs six colonnes au moins.
        if (classeEntiere(v.classe) || v.classe == Classe::Logique)
            p.largeur = largeurMax + 3;
        else
            p.largeur = std::max(largeurMax + 3, 6);
        return p;
    }
    // Facteur commun quand les valeurs sont toutes très grandes ou très petites.
    if (maxAbs >= 1e5 || (maxAbs > 0 && maxAbs < 1e-5)) {
        double e = std::floor(std::log10(maxAbs));
        p.facteur = std::pow(10.0, e);
    }
    int chiffresEntiers = 1;
    double echelle = maxAbs / p.facteur;
    if (echelle >= 1) chiffresEntiers = (int)std::floor(std::log10(echelle)) + 1;
    p.largeur = std::max(chiffresEntiers + 1 + p.decimales + 3 + (aNegatif ? 1 : 0), 8);
    if (format == Format::Long)
        p.largeur = chiffresEntiers + 1 + p.decimales + 3 + (aNegatif ? 1 : 0);
    return p;
}

static std::string cellule(double x, const PlanColonne& p, Format format) {
    if (std::isnan(x)) return "NaN";
    if (std::isinf(x)) return x > 0 ? "Inf" : "-Inf";
    if (p.entiers) return formater("%.0f", x);
    if (format == Format::Banque) return formater("%.2f", x);
    return formater("%.*f", p.decimales, x / p.facteur);
}

// --- en-têtes et résumés, comme dans la fenêtre de commande de MATLAB ------

// Le « × » que MATLAB écrit entre les dimensions : « 2×3 cell array ».
static std::string dimsFois(const Dims& d) {
    std::string s;
    for (std::size_t i = 0; i < d.size(); ++i) {
        if (i) s += "\xC3\x97";
        s += std::to_string(d[i]);
    }
    return s;
}

// La largeur d'un texte UTF-8 à l'écran : un caractère par point de code.
static std::size_t largeurEcran(const std::string& s) {
    std::size_t n = 0;
    for (unsigned char c : s)
        if ((c & 0xC0) != 0x80) ++n;
    return n;
}

static bool estZeroParZero(const Valeur& v) {
    return v.dims.size() == 2 && v.dims[0] == 0 && v.dims[1] == 0;
}

static bool estMembre(const Valeur& v) {
    return v.classe == Classe::Objet && v.st &&
           v.st->champs.count(Interpreteur::champMembre) > 0;
}

// Un champ caché — l'identifiant d'une carte, le membre d'une énumération
// — ne se montre pas.
static bool estCache(const std::string& nom) {
    return nom.empty() || nom[0] == '\x01' || nom.compare(0, 2, "__") == 0;
}

// Le nom d'une classe sans son paquet : « Simulink.Bus » s'annonce « Bus ».
static std::string nomSansPaquet(const std::string& classe) {
    std::size_t p = classe.rfind('.');
    return p == std::string::npos ? classe : classe.substr(p + 1);
}

// L'en-tête d'un tableau : « 1×3 int8 row vector », « 3×1 single column
// vector », « 2×2 uint8 matrix », « 2×3 char array », « 0×3 empty double
// matrix ». MATLAB le met à tout tableau qui n'est pas de double, et aux
// tableaux vides.
static std::string enteteTableau(const Valeur& v) {
    std::string t = dimsFois(v.dims) + (v.estVide() ? " empty " : " ") + v.classeNom();
    if (!v.estNumerique() || v.dims.size() != 2) return t + " array";
    if (v.dims[0] == 1) return t + " row vector";
    if (v.dims[1] == 1) return t + " column vector";
    return t + " matrix";
}

// L'indice d'une page d'un tableau à plus de deux dimensions : « ,2,1 ».
static std::string etiquettePage(const Dims& dims, std::size_t p) {
    std::string etiquette;
    for (std::size_t d = 2; d < dims.size(); ++d) {
        etiquette += formater(",%zu", p % (std::size_t)dims[d] + 1);
        p /= (std::size_t)dims[d];
    }
    return etiquette;
}

// Un élément numérique, logique ou complexe, écrit comme un scalaire.
static std::string texteElement(const Valeur& e, std::size_t k, int format) {
    const bool simple = e.classe == Classe::Simple;
    std::string t = rendreScalaire(e.re[k], format, simple);
    if (e.estComplexe()) {
        double im = e.im[k];
        t += (im < 0 ? " - " : " + ") + rendreScalaire(std::fabs(im), format, simple) + "i";
    }
    return t;
}

// Un vecteur ligne court se montre en entier, entre crochets : « [1 2 3] ».
static bool estLigneCourte(const Valeur& e, std::size_t plafond) {
    return (e.estNumerique() || e.classe == Classe::Logique) && !e.estCreux() && !e.estVide() &&
           e.dims.size() == 2 && e.nlignes() == 1 &&
           (e.nelem() == 1 || (e.estReel() && e.nelem() <= plafond));
}

static std::string texteLigne(const Valeur& e, int format) {
    std::string t = "[";
    for (std::size_t k = 0; k < e.nelem(); ++k) {
        if (k) t += " ";
        t += texteElement(e, k, format);
    }
    return t + "]";
}

// Une case d'un tableau de cellules, comme MATLAB l'écrit entre ses
// accolades : un nombre entre crochets, calé à droite — « {[  1]} » —, un
// texte entre apostrophes, calé à gauche — « {'Egg'   } » —, et pour le
// reste ses dimensions et sa classe — « {2×3 double} », « {1×1 cell} ».
struct CaseCellule {
    std::string texte;
    bool nombre = false;  // calé à droite dans ses crochets
    bool valeur = true;   // la valeur elle-même, pas son résumé
};

static CaseCellule caseDeCellule(const Valeur& e, int format) {
    CaseCellule c;
    if (estMembre(e) && e.nelem() == 1) {
        c.texte = "[" + e.champ(Interpreteur::champMembre).versTexte() + "]";
        c.nombre = true;
    } else if (estLigneCourte(e, 9)) {
        c.texte = texteLigne(e, format);
        c.nombre = true;
    } else if (e.estTexte() && e.dims.size() == 2 && e.nlignes() == 1 && e.ncolonnes() > 0) {
        c.texte = "'" + e.versTexte() + "'";
    } else if (e.estChaine() && e.estScalaire()) {
        c.texte = "[\"" + (e.chaines.empty() ? std::string() : e.chaines[0]) + "\"]";
    } else if (e.estFonction()) {
        c.texte = e.fn ? e.fn->texte : std::string("@()");
    } else {
        c.texte = dimsFois(e.dims) + " " + e.classeNom();
        c.valeur = false;
    }
    return c;
}

// Un champ de structure ou une propriété d'objet, résumé sur une ligne
// comme dans MATLAB : sa valeur quand elle est courte, sinon ses
// dimensions et sa classe — entre accolades pour une cellule.
static std::string resumeChamp(const Valeur& e, int format) {
    if (estMembre(e) && e.nelem() == 1) return e.champ(Interpreteur::champMembre).versTexte();
    if (e.estCreux()) return "[" + dimsFois(e.dims) + " double]";
    if (estLigneCourte(e, 12)) return e.nelem() == 1 ? texteElement(e, 0, format) : texteLigne(e, format);
    switch (e.classe) {
        case Classe::Caractere:
            if (e.dims.size() == 2 && e.nlignes() == 1 && e.ncolonnes() > 0)
                return "'" + e.versTexte() + "'";
            if (estZeroParZero(e)) return "''";
            break;
        case Classe::Chaine:
            if (e.estScalaire())
                return "\"" + (e.chaines.empty() ? std::string() : e.chaines[0]) + "\"";
            break;
        case Classe::Fonction: return e.fn ? e.fn->texte : std::string("@()");
        case Classe::Cellule: {
            if (estZeroParZero(e)) return "{}";
            // une ligne de quelques valeurs courtes : « {'a'  'bb'} »
            if (e.dims.size() == 2 && e.nlignes() == 1 && e.nelem() <= 10) {
                std::string t = "{";
                bool courte = true;
                for (std::size_t k = 0; k < e.nelem() && courte; ++k) {
                    CaseCellule c = caseDeCellule(e.cellules[k], format);
                    courte = c.valeur;
                    if (k) t += "  ";
                    t += c.texte;
                }
                t += "}";
                if (courte && largeurEcran(t) <= 60) return t;
            }
            return "{" + dimsFois(e.dims) + " cell}";
        }
        case Classe::Double:
            if (estZeroParZero(e)) return "[]";
            break;
        default: break;
    }
    return "[" + dimsFois(e.dims) + " " + e.classeNom() + "]";
}

static void ecrireNumerique(std::ostream& os, const Valeur& v, Format format,
                            int largeurEcran) {
    PlanColonne p = planifier(v, format);
    int l = v.nlignes(), c = v.ncolonnes();
    if (p.facteur != 1.0) {
        int e = (int)std::round(std::log10(p.facteur));
        os << formater("  1.0e%+03d *\n\n", e);
    }
    int largeurCellule = p.largeur;
    if (v.estComplexe()) largeurCellule = 2 * p.largeur + 2;
    int parPaquet = std::max(1, (largeurEcran - 3) / std::max(1, largeurCellule));
    // La ligne est bâtie dans un tampon réutilisé : dix millions de
    // colonnes font dix millions de lignes, et autant d'allocations si on
    // en crée une par tour.
    std::string ligne;
    for (int debut = 0; debut < c; debut += parPaquet) {
        verifierInterruption();
        int fin = std::min(c, debut + parPaquet);
        if (c > parPaquet) {
            if (fin - debut == 1) os << formater("  Column %d\n\n", debut + 1);
            else os << formater("  Columns %d through %d\n\n", debut + 1, fin);
        }
        for (int i = 0; i < l; ++i) {
            // Ctrl-C : un tableau de dix millions d'elements demande des
            // minutes a mettre en forme. On regarde toutes les mille
            // lignes — assez souvent pour repondre, assez rare pour ne
            // rien couter.
            if ((i & 1023) == 0) verifierInterruption();
            ligne.clear();
            for (int j = debut; j < fin; ++j) {
                std::size_t k = (std::size_t)i + (std::size_t)j * l;
                std::string texte = cellule(v.re[k], p, format);
                if (v.estComplexe()) {
                    double im = v.im[k];
                    std::string ti = cellule(std::fabs(im), p, format);
                    texte += (im < 0 ? " - " : " + ") + ti + "i";
                }
                ligne += formater("%*s", largeurCellule, texte.c_str());
            }
            ligne += '\n';
            os.write(ligne.data(), (std::streamsize)ligne.size());
        }
        if (fin < c) os << "\n";
    }
}

static void ecrireTexte(std::ostream& os, const Valeur& v) {
    int l = v.nlignes(), c = v.ncolonnes();
    for (int i = 0; i < l; ++i) {
        if ((i & 1023) == 0) verifierInterruption();
        std::string ligne;
        for (int j = 0; j < c; ++j)
            ligne += (char)(int)v.re[(std::size_t)i + (std::size_t)j * l];
        os << "    '" << ligne << "'\n";
    }
}

// Un tableau de chaînes : chaque colonne à la largeur de sa plus longue
// chaîne, quatre espaces entre elles, comme dans MATLAB.
static void ecrireChaines(std::ostream& os, const Valeur& v) {
    int l = v.nlignes(), c = v.ncolonnes();
    auto texte = [&](std::size_t k) {
        return "\"" + (k < v.chaines.size() ? v.chaines[k] : std::string()) + "\"";
    };
    std::vector<std::size_t> larges((std::size_t)c, 0);
    for (int j = 0; j < c; ++j)
        for (int i = 0; i < l; ++i)
            larges[(std::size_t)j] =
                std::max(larges[(std::size_t)j],
                         largeurEcran(texte((std::size_t)i + (std::size_t)j * l)));
    for (int i = 0; i < l; ++i) {
        if ((i & 1023) == 0) verifierInterruption();
        std::string ligne;
        for (int j = 0; j < c; ++j) {
            std::string t = texte((std::size_t)i + (std::size_t)j * l);
            ligne += "    " + t;
            if (j + 1 < c) ligne += std::string(larges[(std::size_t)j] - largeurEcran(t), ' ');
        }
        os << ligne << "\n";
    }
}

std::string descriptionCourte(const Valeur& v) {
    std::string d = texteDims(v.dims);
    if (v.classe == Classe::Cellule) return d + " cell";
    if (v.estStructure()) return d + " " + v.classeNom();
    return d + " " + v.classeNom();
}

// Une page d'un tableau de cellules : chaque case entre accolades, les
// cases d'une colonne à la même largeur, quatre espaces entre les
// colonnes, et des paquets de colonnes quand la fenêtre est trop étroite,
// comme pour les nombres.
static void ecrireCasesPage(std::ostream& os, const Valeur& v, std::size_t debut, int l, int c,
                            int format, int largeur) {
    std::vector<CaseCellule> cases((std::size_t)l * (std::size_t)c);
    std::vector<std::size_t> larges((std::size_t)c, 0);
    for (int j = 0; j < c; ++j) {
        verifierInterruption();
        for (int i = 0; i < l; ++i) {
            std::size_t k = (std::size_t)i + (std::size_t)j * (std::size_t)l;
            cases[k] = caseDeCellule(v.cellules[debut + k], format);
            larges[(std::size_t)j] = std::max(larges[(std::size_t)j], largeurEcran(cases[k].texte));
        }
    }
    std::vector<std::pair<int, int>> paquets;
    int premiere = 0;
    std::size_t occupe = 0;
    for (int j = 0; j < c; ++j) {
        std::size_t colonne = larges[(std::size_t)j] + 6;
        if (j > premiere && occupe + colonne > (std::size_t)std::max(largeur, 20)) {
            paquets.emplace_back(premiere, j);
            premiere = j;
            occupe = 0;
        }
        occupe += colonne;
    }
    paquets.emplace_back(premiere, c);
    std::string ligne;
    for (const auto& paquet : paquets) {
        if (paquets.size() > 1) {
            if (paquet.second - paquet.first == 1)
                os << formater("  Column %d\n\n", paquet.first + 1);
            else
                os << formater("  Columns %d through %d\n\n", paquet.first + 1, paquet.second);
        }
        for (int i = 0; i < l; ++i) {
            if ((i & 1023) == 0) verifierInterruption();
            ligne.clear();
            for (int j = paquet.first; j < paquet.second; ++j) {
                const CaseCellule& e = cases[(std::size_t)i + (std::size_t)j * (std::size_t)l];
                std::string marge(larges[(std::size_t)j] - largeurEcran(e.texte), ' ');
                ligne += "    {";
                ligne += e.nombre ? "[" + marge + e.texte.substr(1) : e.texte + marge;
                ligne += "}";
            }
            ligne += '\n';
            os.write(ligne.data(), (std::streamsize)ligne.size());
        }
        if (paquet.second < c) os << "\n";
    }
}

// Un tableau de cellules, comme MATLAB : l'en-tête « 2×2 cell array »,
// puis les cases ; au-delà de deux dimensions, page par page, chacune
// nommée d'après la variable — « C(:,:,2) = ».
static void ecrireCellule(std::ostream& os, const Valeur& v, int format, bool compact,
                          int largeur, const std::string& nom, bool entete) {
    verifierInterruption();
    if (v.estVide()) {
        if (entete) os << "  " << enteteTableau(v) << "\n";
        return;
    }
    if (entete) {
        os << "  " << enteteTableau(v) << "\n";
        if (!compact) os << "\n";
    }
    int l = v.dims[0], c = v.dims.size() > 1 ? v.dims[1] : 1;
    std::size_t taillePage = (std::size_t)l * (std::size_t)c;
    if (v.dims.size() <= 2) {
        ecrireCasesPage(os, v, 0, l, c, format, largeur);
        return;
    }
    std::size_t pages = v.nelem() / std::max<std::size_t>(taillePage, 1);
    for (std::size_t p = 0; p < pages; ++p) {
        os << (nom.empty() ? std::string("ans") : nom) << "(:,:" << etiquettePage(v.dims, p)
           << ") =\n";
        if (!compact) os << "\n";
        ecrireCasesPage(os, v, p * taillePage, l, c, format, largeur);
        if (p + 1 < pages && !compact) os << "\n";
    }
}

// Une énumération : ses membres, par leur nom, rangés comme le tableau.
static std::string rendreEnumeration(const Valeur& v) {
    std::vector<std::string> noms;
    for (std::size_t k = 0; k < v.nelem(); ++k)
        noms.push_back(v.champ(Interpreteur::champMembre, k).versTexte());
    if (noms.size() == 1) return "  " + v.nomObjet + " enumeration\n\n    " + noms[0] + "\n";
    std::string sortie = "  " + dimsFois(v.dims) + " " + v.nomObjet + " enumeration array\n";
    if (noms.empty()) return sortie;
    sortie += "\n";
    std::size_t large = 0;
    for (const auto& n : noms) large = std::max(large, n.size());
    int l = v.nlignes(), c = (int)(noms.size() / std::max(1, l));
    for (int i = 0; i < l; ++i) {
        std::string ligne = "   ";
        for (int j = 0; j < c; ++j) {
            const std::string& n = noms[(std::size_t)(i + j * l)];
            ligne += " " + n;
            if (j + 1 < c) ligne += std::string(large - n.size() + 3, ' ');
        }
        sortie += ligne + "\n";
    }
    return sortie;
}

// Une structure ou un objet, comme MATLAB : l'en-tête « struct with
// fields: » ou « Point with properties: », puis un champ par ligne, les
// noms calés à droite pour aligner les deux-points. Un tableau de
// structures ne montre que ses champs. « disp » d'une structure omet
// l'en-tête ; celui d'un objet le garde.
static void ecrireStructure(std::ostream& os, const Valeur& v, int format, bool compact,
                            bool entete) {
    verifierInterruption();
    if (estMembre(v)) {
        os << rendreEnumeration(v);
        return;
    }
    const bool objet = v.classe == Classe::Objet;
    const std::string classe = objet ? nomSansPaquet(v.nomObjet) : std::string("struct");
    const char* genre = objet ? "properties" : "fields";
    std::vector<std::string> noms;
    for (const auto& nom : v.champs())
        if (!estCache(nom)) noms.push_back(nom);
    if (v.nelem() != 1) {
        os << "  " << dimsFois(v.dims) << (v.estVide() ? " empty " : " ") << classe
           << " array with ";
        if (noms.empty()) {
            os << "no " << genre << ".\n";
            return;
        }
        os << genre << ":\n";
        if (!compact) os << "\n";
        for (const auto& nom : noms) os << "    " << nom << "\n";
        return;
    }
    if (noms.empty()) {
        if (entete || objet) os << "  " << classe << " with no " << genre << ".\n";
        return;
    }
    if (entete || objet) {
        os << "  " << classe << " with " << genre << ":\n";
        if (!compact) os << "\n";
    }
    std::size_t large = 0;
    for (const auto& nom : noms) large = std::max(large, nom.size());
    for (const auto& nom : noms)
        os << "    " << std::string(large - nom.size(), ' ') << nom << ": "
           << resumeChamp(v.champ(nom, 0), format) << "\n";
}

void ecrireValeur(std::ostream& os, const Valeur& v, int format, bool compact, int largeur,
                  const std::string& nom) {
    Format f = (Format)format;
    const bool entete = !nom.empty();
    if (v.estCreux()) { os << rendreCreux(v); return; }
    switch (v.classe) {
        case Classe::Fonction:
            os << "    " << (v.fn ? v.fn->texte : std::string("@()")) << "\n";
            return;
        case Classe::Cellule: ecrireCellule(os, v, format, compact, largeur, nom, entete); return;
        case Classe::Structure:
        case Classe::Objet: ecrireStructure(os, v, format, compact, entete); return;
        case Classe::Caractere:
        case Classe::Chaine:
            if (v.estVide() || entete) {
                os << "  " << enteteTableau(v) << "\n";
                if (v.estVide()) return;
                if (!compact) os << "\n";
            }
            if (v.classe == Classe::Caractere) ecrireTexte(os, v);
            else ecrireChaines(os, v);
            return;
        default: break;
    }
    if (v.estVide()) {
        os << "  " << enteteTableau(v) << "\n";
        return;
    }
    // un tableau qui n'est pas de double dit sa classe : « int8 »,
    // « 1×3 logical array »
    if (entete && v.classe != Classe::Double) {
        os << "  " << (v.estScalaire() ? std::string(v.classeNom()) : enteteTableau(v)) << "\n";
        if (!compact) os << "\n";
    }
    if (v.dims.size() > 2) {
        // Affichage page par page, chacune nommée d'après la variable,
        // comme MATLAB : « x(:,:,2) = ».
        int l = v.dims[0], c = v.dims[1];
        std::size_t pageTaille = (std::size_t)l * c;
        std::size_t pages = v.nelem() / std::max<std::size_t>(pageTaille, 1);
        for (std::size_t p = 0; p < pages; ++p) {
            verifierInterruption();
            os << (nom.empty() ? std::string("ans") : nom) << "(:,:" << etiquettePage(v.dims, p)
               << ") =\n";
            if (!compact) os << "\n";
            Valeur page = Valeur::matrice(l, c);
            page.classe = v.classe;
            for (std::size_t k = 0; k < pageTaille; ++k) page.re[k] = v.re[p * pageTaille + k];
            if (v.estComplexe()) {
                page.im.assign(pageTaille, 0.0);
                for (std::size_t k = 0; k < pageTaille; ++k)
                    page.im[k] = v.im[p * pageTaille + k];
            }
            ecrireNumerique(os, page, f, largeur);
            if (!compact && p + 1 < pages) os << "\n";
        }
        return;
    }
    ecrireNumerique(os, v, f, largeur);
}

// La forme en chaîne reste, pour « evalc » et tout ce qui a besoin du
// texte plutôt que de l'écran.
std::string rendreValeur(const Valeur& v, int format, bool compact, int largeur,
                         const std::string& nom) {
    std::ostringstream os;
    ecrireValeur(os, v, format, compact, largeur, nom);
    return os.str();
}

// Une carte (containers.Map) se montre par ses propriétés, comme dans
// MATLAB : le nombre de clés et les types des clés et des valeurs.
void ecrireCarte(std::ostream& os, Interpreteur& it, const Valeur& v, bool compact) {
    os << "  Map with properties:\n";
    if (!compact) os << "\n";
    os << "        Count: "
       << rendreScalaire(it.lireProprieteObjet(v, "Count").scal(), (int)it.format) << "\n";
    os << "      KeyType: " << it.lireProprieteObjet(v, "KeyType").versTexte() << "\n";
    os << "    ValueType: " << it.lireProprieteObjet(v, "ValueType").versTexte() << "\n";
}

void afficherResultat(Interpreteur& it, const std::string& nom, const Valeur& v) {
    std::ostream& os = it.sortie();
    // Une classe qui définit display prend en charge tout l'affichage ; si
    // elle ne définit que disp, on écrit l'en-tête « nom = » puis on lui
    // laisse le corps, comme le fait l'affichage par défaut de MATLAB.
    if (v.classe == Classe::Objet && !it.estCarte(v)) {
        auto def = it.classeDe(v);
        if (def && def->aMethode("display")) {
            it.appelerMethode(v, "display", {}, 0);
            return;
        }
        if (def && def->aMethode("disp")) {
            os << nom << " = \n";
            if (!it.formatCompact) os << "\n";
            it.appelerMethode(v, "disp", {}, 0);
            if (!it.formatCompact) os << "\n";
            return;
        }
    }
    int format = (int)it.format;
    bool compact = it.formatCompact;
    // Cas court : « x = 5 » sur une seule ligne — un double, un texte, une
    // chaîne, une poignée, [] et {}. Un scalaire d'une autre classe dit sa
    // classe au-dessus de sa valeur, comme dans MATLAB (« int8 »,
    // « logical »).
    bool court = false;
    std::string valeurCourte;
    if (v.estScalaire() && v.classe == Classe::Double && !v.estCreux()) {
        court = true;
        valeurCourte = texteElement(v, 0, format);
    } else if (v.classe == Classe::Fonction) {
        court = true;
        valeurCourte = v.fn ? v.fn->texte : "@()";
    } else if (v.estTexte() && v.dims.size() == 2 && v.nlignes() == 1 && v.ncolonnes() > 0) {
        court = true;
        valeurCourte = "'" + v.versTexte() + "'";
    } else if (v.estChaine() && v.estScalaire()) {
        court = true;
        valeurCourte = "\"" + (v.chaines.empty() ? std::string() : v.chaines[0]) + "\"";
    } else if (estZeroParZero(v) && v.classe == Classe::Double && !v.estCreux()) {
        court = true;
        valeurCourte = "[]";
    } else if (estZeroParZero(v) && v.classe == Classe::Cellule) {
        court = true;
        valeurCourte = "{}";
    }
    if (court) {
        os << nom << " = " << valeurCourte << "\n";
        if (!compact) os << "\n";
        return;
    }
    // Un tableau de doubles à plus de deux dimensions commence par sa
    // première page, « x(:,:,1) = », sans « x = » au-dessus : il n'a pas
    // d'en-tête à montrer.
    if (!(v.classe == Classe::Double && v.dims.size() > 2 && !v.estCreux())) {
        os << nom << " =\n";
        if (!compact) os << "\n";
    }
    if (it.estCarte(v)) ecrireCarte(os, it, v, compact);
    else ecrireValeur(os, v, format, compact, 80, nom);
    if (!compact) os << "\n";
}

}  // namespace matlibre
