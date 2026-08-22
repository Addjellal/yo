#include "matlibre/Affichage.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <iostream>
#include <sstream>

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

std::string rendreScalaire(double x, int format) {
    Format f = (Format)format;
    if (std::isnan(x)) return "NaN";
    if (std::isinf(x)) return x > 0 ? "Inf" : "-Inf";
    switch (f) {
        case Format::Long:
            // « format long » montre quinze décimales, pas quinze chiffres
            // significatifs : pi s'écrit 3.141592653589793.
            if (estEntierAffichable(x)) return formater("%.0f", x);
            if (std::fabs(x) >= 1e5 || std::fabs(x) < 1e-5) return formater("%.15e", x);
            return formater("%.15f", x);
        case Format::CourtE: return formater("%.4e", x);
        case Format::LongE: return formater("%.15e", x);
        case Format::CourtG: return formater("%g", x);
        case Format::LongG: return formater("%.15g", x);
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
    p.decimales = (format == Format::Long || format == Format::LongG) ? 15 : 4;
    if (p.entiers) {
        int largeurMax = 1;
        for (std::size_t k = 0; k < v.re.size(); ++k) {
            int l = (int)formater("%.0f", v.re[k]).size();
            largeurMax = std::max(largeurMax, l);
        }
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
    if (format == Format::Long) p.largeur = chiffresEntiers + 1 + 15 + 3 + (aNegatif ? 1 : 0);
    return p;
}

static std::string cellule(double x, const PlanColonne& p, Format format) {
    if (std::isnan(x)) return "NaN";
    if (std::isinf(x)) return x > 0 ? "Inf" : "-Inf";
    if (p.entiers) return formater("%.0f", x);
    if (format == Format::Banque) return formater("%.2f", x);
    return formater("%.*f", p.decimales, x / p.facteur);
}

static std::string indenter(const std::string& texte, int n) {
    std::string espaces(n, ' ');
    std::istringstream in(texte);
    std::string ligne, sortie;
    while (std::getline(in, ligne)) sortie += espaces + ligne + "\n";
    return sortie;
}

static std::string rendreStructure(const Valeur& v, int format, bool compact, int largeur);
static std::string rendreCellule(const Valeur& v, int format, bool compact, int largeur);

static std::string rendreNumerique(const Valeur& v, Format format, int largeurEcran) {
    PlanColonne p = planifier(v, format);
    int l = v.nlignes(), c = v.ncolonnes();
    std::string sortie;
    if (p.facteur != 1.0) {
        int e = (int)std::round(std::log10(p.facteur));
        sortie += formater("  1.0e%+03d *\n\n", e);
    }
    int largeurCellule = p.largeur;
    if (v.estComplexe()) largeurCellule = 2 * p.largeur + 2;
    int parPaquet = std::max(1, (largeurEcran - 3) / std::max(1, largeurCellule));
    for (int debut = 0; debut < c; debut += parPaquet) {
        int fin = std::min(c, debut + parPaquet);
        if (c > parPaquet) {
            if (fin - debut == 1) sortie += formater("  Column %d\n\n", debut + 1);
            else sortie += formater("  Columns %d through %d\n\n", debut + 1, fin);
        }
        for (int i = 0; i < l; ++i) {
            std::string ligne;
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
            sortie += ligne + "\n";
        }
        if (fin < c) sortie += "\n";
    }
    return sortie;
}

static std::string rendreTexte(const Valeur& v) {
    int l = v.nlignes(), c = v.ncolonnes();
    std::string sortie;
    for (int i = 0; i < l; ++i) {
        std::string ligne;
        for (int j = 0; j < c; ++j)
            ligne += (char)(int)v.re[(std::size_t)i + (std::size_t)j * l];
        sortie += "    '" + ligne + "'\n";
    }
    return sortie;
}

static std::string rendreChaines(const Valeur& v) {
    int l = v.nlignes(), c = v.ncolonnes();
    std::string sortie;
    for (int i = 0; i < l; ++i) {
        std::string ligne;
        for (int j = 0; j < c; ++j) {
            std::size_t k = (std::size_t)i + (std::size_t)j * l;
            ligne += "    \"" + (k < v.chaines.size() ? v.chaines[k] : std::string()) + "\"";
        }
        sortie += ligne + "\n";
    }
    return sortie;
}

std::string descriptionCourte(const Valeur& v) {
    std::string d = texteDims(v.dims);
    if (v.classe == Classe::Cellule) return d + " cell";
    if (v.estStructure()) return d + " " + v.classeNom();
    return d + " " + v.classeNom();
}

static std::string rendreCellule(const Valeur& v, int format, bool compact, int largeur) {
    if (v.estVide()) return "  {}\n";
    int l = v.nlignes(), c = v.ncolonnes();
    std::string sortie = "  {\n";
    for (int j = 0; j < c; ++j) {
        for (int i = 0; i < l; ++i) {
            std::size_t k = (std::size_t)i + (std::size_t)j * l;
            const Valeur& e = v.cellules[k];
            std::string entete = formater("[%d,%d] = ", i + 1, j + 1);
            if (e.estScalaire() && (e.estNumerique() || e.classe == Classe::Logique)) {
                sortie += "    " + entete + rendreScalaire(e.re.empty() ? 0 : e.re[0], format) +
                          "\n";
            } else if (e.estTexte() && e.nlignes() <= 1) {
                sortie += "    " + entete + "'" + e.versTexte() + "'\n";
            } else if (e.estChaine() && e.estScalaire()) {
                sortie += "    " + entete + "\"" + (e.chaines.empty() ? "" : e.chaines[0]) +
                          "\"\n";
            } else if (e.estVide()) {
                sortie += "    " + entete + "[]\n";
            } else {
                sortie += "    " + entete + "\n";
                sortie += indenter(rendreValeur(e, format, compact, largeur - 6), 4);
            }
        }
    }
    sortie += "  }\n";
    return sortie;
}

static std::string rendreStructure(const Valeur& v, int format, bool compact, int largeur) {
    std::string sortie;
    if (v.nelem() != 1) {
        sortie += formater("  %s struct array with fields:\n\n", texteDims(v.dims).c_str());
        for (const auto& nom : v.champs()) sortie += "    " + nom + "\n";
        return sortie;
    }
    for (const auto& nom : v.champs()) {
        Valeur e = v.champ(nom, 0);
        std::string entete = "    " + nom + ": ";
        if (e.estScalaire() && (e.estNumerique() || e.classe == Classe::Logique)) {
            sortie += entete + rendreScalaire(e.re.empty() ? 0 : e.re[0], format) + "\n";
        } else if (e.estTexte() && e.nlignes() <= 1) {
            sortie += entete + "'" + e.versTexte() + "'\n";
        } else if (e.estChaine() && e.estScalaire()) {
            sortie += entete + "\"" + (e.chaines.empty() ? "" : e.chaines[0]) + "\"\n";
        } else if (e.estVide()) {
            sortie += entete + "[]\n";
        } else if (e.classe == Classe::Fonction) {
            sortie += entete + (e.fn ? e.fn->texte : "@()") + "\n";
        } else if (e.nelem() <= 12 && e.estNumerique() && e.dims.size() == 2 &&
                   e.nlignes() == 1) {
            std::string ligne = "[";
            for (std::size_t k = 0; k < e.re.size(); ++k) {
                if (k) ligne += " ";
                ligne += rendreScalaire(e.re[k], format);
            }
            ligne += "]";
            sortie += entete + ligne + "\n";
        } else {
            sortie += entete + "[" + texteDims(e.dims) + " " + e.classeNom() + "]\n";
        }
    }
    return sortie;
}

std::string rendreValeur(const Valeur& v, int format, bool compact, int largeur) {
    Format f = (Format)format;
    switch (v.classe) {
        case Classe::Fonction:
            return "    " + (v.fn ? v.fn->texte : std::string("@()")) + "\n";
        case Classe::Cellule: return rendreCellule(v, format, compact, largeur);
        case Classe::Structure:
        case Classe::Objet: return rendreStructure(v, format, compact, largeur);
        case Classe::Caractere:
            if (v.estVide()) return "  ''\n";
            return rendreTexte(v);
        case Classe::Chaine:
            if (v.estVide()) return "  0x0 empty string array\n";
            return rendreChaines(v);
        default: break;
    }
    if (v.estVide()) return formater("  %s empty %s matrix\n", texteDims(v.dims).c_str(),
                                     v.classeNom());
    if (v.dims.size() > 2) {
        // Affichage page par page, comme MATLAB.
        std::string sortie;
        int l = v.dims[0], c = v.dims[1];
        std::size_t pageTaille = (std::size_t)l * c;
        std::size_t pages = v.nelem() / std::max<std::size_t>(pageTaille, 1);
        for (std::size_t p = 0; p < pages; ++p) {
            Dims reste(v.dims.begin() + 2, v.dims.end());
            std::string etiquette;
            std::size_t r = p;
            for (std::size_t d = 0; d < reste.size(); ++d) {
                etiquette += formater(",%zu", r % (std::size_t)reste[d] + 1);
                r /= (std::size_t)reste[d];
            }
            sortie += formater("ans(:,:%s) =\n\n", etiquette.c_str());
            Valeur page = Valeur::matrice(l, c);
            page.classe = v.classe;
            for (std::size_t k = 0; k < pageTaille; ++k) page.re[k] = v.re[p * pageTaille + k];
            sortie += rendreNumerique(page, f, largeur);
            sortie += "\n";
        }
        return sortie;
    }
    return rendreNumerique(v, f, largeur);
}

void afficherResultat(Interpreteur& it, const std::string& nom, const Valeur& v) {
    std::ostream& os = it.sortie();
    int format = (int)it.format;
    bool compact = it.formatCompact;
    // Cas court : « x = 5 » sur une seule ligne.
    bool court = false;
    std::string valeurCourte;
    if (v.estScalaire() && (v.estNumerique() || v.classe == Classe::Logique) &&
        !v.estComplexe()) {
        court = true;
        valeurCourte = rendreScalaire(v.re[0], format);
    } else if (v.estScalaire() && v.estComplexe()) {
        court = true;
        double re = v.re[0], im = v.im[0];
        valeurCourte = rendreScalaire(re, format) + (im < 0 ? " - " : " + ") +
                       rendreScalaire(std::fabs(im), format) + "i";
    } else if (v.classe == Classe::Fonction) {
        court = true;
        valeurCourte = v.fn ? v.fn->texte : "@()";
    } else if (v.estTexte() && v.nlignes() == 1) {
        court = true;
        valeurCourte = "'" + v.versTexte() + "'";
    } else if (v.estChaine() && v.estScalaire()) {
        court = true;
        valeurCourte = "\"" + (v.chaines.empty() ? std::string() : v.chaines[0]) + "\"";
    } else if (v.estVide() && v.classe == Classe::Double) {
        court = true;
        valeurCourte = "[]";
    } else if (v.estVide() && v.classe == Classe::Cellule) {
        court = true;
        valeurCourte = "{}";
    }
    if (court) {
        os << nom << " = " << valeurCourte << "\n";
        if (!compact) os << "\n";
        return;
    }
    os << nom << " =\n";
    if (!compact) os << "\n";
    os << rendreValeur(v, format, compact, 80);
    if (!compact) os << "\n";
}

}  // namespace matlibre
