#include "matlibre/Creux.h"

#include <algorithm>
#include <cmath>
#include <sstream>

#include "matlibre/AlgebreLineaire.h"
#include "matlibre/Erreur.h"
#include "matlibre/Operations.h"

namespace matlibre {

Valeur assurerDense(const Valeur& v) {
    if (!v.estCreux()) return v;
    return denseDepuisCreux(v);
}

Valeur creuxVide(int m, int n) {
    Valeur s;
    s.classe = Classe::Double;
    s.dims = {std::max(0, m), std::max(0, n)};
    s.creux = std::make_shared<DonneesCreuses>();
    s.creux->debutColonne.assign((std::size_t)std::max(0, n) + 1, 0);
    return s;
}

Valeur creuxDepuisDense(const Valeur& dense, double tolerance) {
    Valeur d = dense;
    if (d.dims.size() > 2)
        erreur("MATLAB:sparse:ndArray", "N-D arrays cannot be converted to sparse.");
    int m = d.nlignes(), n = d.ncolonnes();
    Valeur s = creuxVide(m, n);
    bool complexe = d.estComplexe();
    if (complexe) s.creux->imaginaire.clear();
    for (int j = 0; j < n; ++j) {
        s.creux->debutColonne[(std::size_t)j] = (int)s.creux->ligne.size();
        for (int i = 0; i < m; ++i) {
            std::size_t k = (std::size_t)i + (std::size_t)j * m;
            double re = k < d.re.size() ? d.re[k] : 0.0;
            double im = (complexe && k < d.im.size()) ? d.im[k] : 0.0;
            if (std::fabs(re) <= tolerance && std::fabs(im) <= tolerance) continue;
            s.creux->ligne.push_back(i);
            s.creux->valeur.push_back(re);
            if (complexe) s.creux->imaginaire.push_back(im);
        }
    }
    s.creux->debutColonne[(std::size_t)n] = (int)s.creux->ligne.size();
    return s;
}

Valeur denseDepuisCreux(const Valeur& s) {
    if (!s.estCreux()) return s;
    int m = s.nlignes(), n = s.ncolonnes();
    Valeur d = Valeur::matrice(m, n);
    bool complexe = !s.creux->imaginaire.empty();
    if (complexe) d.assurerImaginaire();
    for (int j = 0; j < n; ++j) {
        int debut = s.creux->debutColonne[(std::size_t)j];
        int fin = s.creux->debutColonne[(std::size_t)j + 1];
        for (int p = debut; p < fin; ++p) {
            std::size_t k = (std::size_t)s.creux->ligne[(std::size_t)p] + (std::size_t)j * m;
            d.re[k] = s.creux->valeur[(std::size_t)p];
            if (complexe) d.im[k] = s.creux->imaginaire[(std::size_t)p];
        }
    }
    return d;
}

Valeur creuxDepuisTriplets(const Valeur& lignes, const Valeur& colonnes,
                           const Valeur& valeurs, int m, int n) {
    std::size_t nz = std::max(lignes.nelem(), colonnes.nelem());
    // Les doublons s'additionnent, comme le fait la fonction de référence.
    std::vector<std::vector<std::pair<int, double>>> parColonne((std::size_t)std::max(0, n));
    for (std::size_t k = 0; k < nz; ++k) {
        int i = (int)(lignes.nelem() == 1 ? lignes.re[0] : lignes.re[k]) - 1;
        int j = (int)(colonnes.nelem() == 1 ? colonnes.re[0] : colonnes.re[k]) - 1;
        double v = valeurs.nelem() == 1 ? valeurs.re[0]
                                        : (k < valeurs.re.size() ? valeurs.re[k] : 0.0);
        if (i < 0 || j < 0 || i >= m || j >= n)
            erreur("MATLAB:sparse:badSubscript",
                   "Index exceeds matrix dimensions in sparse.");
        if (v == 0) continue;
        auto& colonne = parColonne[(std::size_t)j];
        bool trouve = false;
        for (auto& e : colonne)
            if (e.first == i) {
                e.second += v;
                trouve = true;
                break;
            }
        if (!trouve) colonne.push_back({i, v});
    }
    Valeur s = creuxVide(m, n);
    for (int j = 0; j < n; ++j) {
        auto& colonne = parColonne[(std::size_t)j];
        std::sort(colonne.begin(), colonne.end(),
                  [](const std::pair<int, double>& a, const std::pair<int, double>& b) {
                      return a.first < b.first;
                  });
        s.creux->debutColonne[(std::size_t)j] = (int)s.creux->ligne.size();
        for (const auto& e : colonne) {
            if (e.second == 0) continue;
            s.creux->ligne.push_back(e.first);
            s.creux->valeur.push_back(e.second);
        }
    }
    s.creux->debutColonne[(std::size_t)n] = (int)s.creux->ligne.size();
    return s;
}

double elementCreux(const Valeur& s, int i, int j) {
    if (!s.estCreux()) {
        std::size_t k = (std::size_t)i + (std::size_t)j * s.nlignes();
        return k < s.re.size() ? s.re[k] : 0.0;
    }
    int debut = s.creux->debutColonne[(std::size_t)j];
    int fin = s.creux->debutColonne[(std::size_t)j + 1];
    for (int p = debut; p < fin; ++p)
        if (s.creux->ligne[(std::size_t)p] == i) return s.creux->valeur[(std::size_t)p];
    return 0.0;
}

std::size_t nombreNonNuls(const Valeur& s) {
    if (s.estCreux()) return s.creux->valeur.size();
    std::size_t n = 0;
    for (std::size_t k = 0; k < s.re.size(); ++k)
        if (s.re[k] != 0 || (!s.im.empty() && s.im[k] != 0)) ++n;
    return n;
}

Valeur transposeeCreuse(const Valeur& a) {
    int m = a.nlignes(), n = a.ncolonnes();
    Valeur t = creuxVide(n, m);
    std::vector<std::vector<std::pair<int, double>>> parLigne((std::size_t)m);
    for (int j = 0; j < n; ++j) {
        int debut = a.creux->debutColonne[(std::size_t)j];
        int fin = a.creux->debutColonne[(std::size_t)j + 1];
        for (int p = debut; p < fin; ++p)
            parLigne[(std::size_t)a.creux->ligne[(std::size_t)p]].push_back(
                {j, a.creux->valeur[(std::size_t)p]});
    }
    for (int i = 0; i < m; ++i) {
        t.creux->debutColonne[(std::size_t)i] = (int)t.creux->ligne.size();
        for (const auto& e : parLigne[(std::size_t)i]) {
            t.creux->ligne.push_back(e.first);
            t.creux->valeur.push_back(e.second);
        }
    }
    t.creux->debutColonne[(std::size_t)m] = (int)t.creux->ligne.size();
    return t;
}

// Produit matriciel : le résultat reste creux si les deux facteurs le sont.
Valeur produitCreux(const Valeur& a, const Valeur& b) {
    int m = a.nlignes(), k = a.ncolonnes(), n = b.ncolonnes();
    if (k != b.nlignes())
        erreur("MATLAB:innerdim",
               "Incorrect dimensions for matrix multiplication.");
    bool bCreux = b.estCreux();
    std::vector<double> colonne((std::size_t)m, 0.0);
    if (!bCreux) {
        Valeur r = Valeur::matrice(m, n);
        for (int j = 0; j < n; ++j) {
            std::fill(colonne.begin(), colonne.end(), 0.0);
            for (int p = 0; p < k; ++p) {
                double bv = b.re[(std::size_t)p + (std::size_t)j * k];
                if (bv == 0) continue;
                int debut = a.creux->debutColonne[(std::size_t)p];
                int fin = a.creux->debutColonne[(std::size_t)p + 1];
                for (int q = debut; q < fin; ++q)
                    colonne[(std::size_t)a.creux->ligne[(std::size_t)q]] +=
                        a.creux->valeur[(std::size_t)q] * bv;
            }
            for (int i = 0; i < m; ++i) r.re[(std::size_t)i + (std::size_t)j * m] = colonne[(std::size_t)i];
        }
        return r;
    }
    Valeur r = creuxVide(m, n);
    for (int j = 0; j < n; ++j) {
        std::fill(colonne.begin(), colonne.end(), 0.0);
        int debutB = b.creux->debutColonne[(std::size_t)j];
        int finB = b.creux->debutColonne[(std::size_t)j + 1];
        for (int pb = debutB; pb < finB; ++pb) {
            int p = b.creux->ligne[(std::size_t)pb];
            double bv = b.creux->valeur[(std::size_t)pb];
            int debut = a.creux->debutColonne[(std::size_t)p];
            int fin = a.creux->debutColonne[(std::size_t)p + 1];
            for (int q = debut; q < fin; ++q)
                colonne[(std::size_t)a.creux->ligne[(std::size_t)q]] +=
                    a.creux->valeur[(std::size_t)q] * bv;
        }
        r.creux->debutColonne[(std::size_t)j] = (int)r.creux->ligne.size();
        for (int i = 0; i < m; ++i) {
            if (colonne[(std::size_t)i] == 0) continue;
            r.creux->ligne.push_back(i);
            r.creux->valeur.push_back(colonne[(std::size_t)i]);
        }
    }
    r.creux->debutColonne[(std::size_t)n] = (int)r.creux->ligne.size();
    return r;
}

Valeur sommeCreuse(const Valeur& a, const Valeur& b, double signe) {
    int m = a.nlignes(), n = a.ncolonnes();
    if (m != b.nlignes() || n != b.ncolonnes())
        erreur("MATLAB:dimagree", "Matrix dimensions must agree.");
    Valeur r = creuxVide(m, n);
    std::vector<double> colonne((std::size_t)m, 0.0);
    for (int j = 0; j < n; ++j) {
        std::fill(colonne.begin(), colonne.end(), 0.0);
        for (int p = a.creux->debutColonne[(std::size_t)j];
             p < a.creux->debutColonne[(std::size_t)j + 1]; ++p)
            colonne[(std::size_t)a.creux->ligne[(std::size_t)p]] +=
                a.creux->valeur[(std::size_t)p];
        for (int p = b.creux->debutColonne[(std::size_t)j];
             p < b.creux->debutColonne[(std::size_t)j + 1]; ++p)
            colonne[(std::size_t)b.creux->ligne[(std::size_t)p]] +=
                signe * b.creux->valeur[(std::size_t)p];
        r.creux->debutColonne[(std::size_t)j] = (int)r.creux->ligne.size();
        for (int i = 0; i < m; ++i) {
            if (colonne[(std::size_t)i] == 0) continue;
            r.creux->ligne.push_back(i);
            r.creux->valeur.push_back(colonne[(std::size_t)i]);
        }
    }
    r.creux->debutColonne[(std::size_t)n] = (int)r.creux->ligne.size();
    return r;
}

Valeur produitElementCreux(const Valeur& a, const Valeur& b) {
    int m = a.nlignes(), n = a.ncolonnes();
    Valeur r = creuxVide(m, n);
    for (int j = 0; j < n; ++j) {
        r.creux->debutColonne[(std::size_t)j] = (int)r.creux->ligne.size();
        for (int p = a.creux->debutColonne[(std::size_t)j];
             p < a.creux->debutColonne[(std::size_t)j + 1]; ++p) {
            int i = a.creux->ligne[(std::size_t)p];
            double bv = elementCreux(b, i, j);
            if (bv == 0) continue;
            double v = a.creux->valeur[(std::size_t)p] * bv;
            if (v == 0) continue;
            r.creux->ligne.push_back(i);
            r.creux->valeur.push_back(v);
        }
    }
    r.creux->debutColonne[(std::size_t)n] = (int)r.creux->ligne.size();
    return r;
}

// Résolution : élimination de Gauss creuse pour les petits systèmes,
// gradient bi-conjugué stabilisé au-delà. Le préconditionneur est la
// diagonale, ce qui suffit aux matrices bien échelonnées.
static bool bicgstab(const Valeur& A, const std::vector<double>& b, std::vector<double>& x,
                     int maxIterations, double tolerance) {
    std::size_t n = b.size();
    auto multiplier = [&](const std::vector<double>& v) {
        std::vector<double> y(n, 0.0);
        for (int j = 0; j < (int)n; ++j) {
            for (int p = A.creux->debutColonne[(std::size_t)j];
                 p < A.creux->debutColonne[(std::size_t)j + 1]; ++p)
                y[(std::size_t)A.creux->ligne[(std::size_t)p]] +=
                    A.creux->valeur[(std::size_t)p] * v[(std::size_t)j];
        }
        return y;
    };
    std::vector<double> diagonale(n, 1.0);
    for (int j = 0; j < (int)n; ++j) {
        double d = elementCreux(A, j, j);
        diagonale[(std::size_t)j] = (d == 0) ? 1.0 : d;
    }
    x.assign(n, 0.0);
    std::vector<double> r = b;
    std::vector<double> r0 = r;
    std::vector<double> p(n, 0.0), v(n, 0.0), s(n), t(n);
    double rho = 1, alpha = 1, omega = 1;
    double normeB = 0;
    for (double x2 : b) normeB += x2 * x2;
    normeB = std::sqrt(normeB);
    if (normeB == 0) return true;
    for (int iteration = 0; iteration < maxIterations; ++iteration) {
        double rhoNouveau = 0;
        for (std::size_t k = 0; k < n; ++k) rhoNouveau += r0[k] * r[k];
        if (rhoNouveau == 0) return false;
        double beta = (rhoNouveau / rho) * (alpha / omega);
        for (std::size_t k = 0; k < n; ++k) p[k] = r[k] + beta * (p[k] - omega * v[k]);
        std::vector<double> phat(n);
        for (std::size_t k = 0; k < n; ++k) phat[k] = p[k] / diagonale[k];
        v = multiplier(phat);
        double denominateur = 0;
        for (std::size_t k = 0; k < n; ++k) denominateur += r0[k] * v[k];
        if (denominateur == 0) return false;
        alpha = rhoNouveau / denominateur;
        for (std::size_t k = 0; k < n; ++k) s[k] = r[k] - alpha * v[k];
        std::vector<double> shat(n);
        for (std::size_t k = 0; k < n; ++k) shat[k] = s[k] / diagonale[k];
        t = multiplier(shat);
        double tt = 0, ts = 0;
        for (std::size_t k = 0; k < n; ++k) {
            tt += t[k] * t[k];
            ts += t[k] * s[k];
        }
        omega = (tt == 0) ? 0 : ts / tt;
        for (std::size_t k = 0; k < n; ++k) x[k] += alpha * phat[k] + omega * shat[k];
        for (std::size_t k = 0; k < n; ++k) r[k] = s[k] - omega * t[k];
        double normeR = 0;
        for (std::size_t k = 0; k < n; ++k) normeR += r[k] * r[k];
        if (std::sqrt(normeR) <= tolerance * normeB) return true;
        rho = rhoNouveau;
        if (omega == 0) return false;
    }
    return false;
}

Valeur resoudreCreux(const Valeur& a, const Valeur& b) {
    int n = a.nlignes();
    if (a.ncolonnes() != n || b.nlignes() != n)
        return divisionGauche(assurerDense(a), assurerDense(b));
    // Petits systèmes : la factorisation dense est plus sûre et plus rapide.
    if (n <= 200) return divisionGauche(assurerDense(a), assurerDense(b));
    Valeur second = assurerDense(b);
    Valeur x = Valeur::matrice(n, second.ncolonnes());
    for (int c = 0; c < second.ncolonnes(); ++c) {
        std::vector<double> colonne((std::size_t)n);
        for (int i = 0; i < n; ++i)
            colonne[(std::size_t)i] = second.re[(std::size_t)i + (std::size_t)c * n];
        std::vector<double> solution;
        if (!bicgstab(a, colonne, solution, 20 * n, 1e-12))
            return divisionGauche(assurerDense(a), second);
        for (int i = 0; i < n; ++i)
            x.re[(std::size_t)i + (std::size_t)c * n] = solution[(std::size_t)i];
    }
    return x;
}

std::string rendreCreux(const Valeur& s) {
    std::ostringstream out;
    int n = s.ncolonnes();
    if (s.creux->valeur.empty()) {
        out << formater("   All zero sparse: %dx%d\n", s.nlignes(), n);
        return out.str();
    }
    for (int j = 0; j < n; ++j) {
        for (int p = s.creux->debutColonne[(std::size_t)j];
             p < s.creux->debutColonne[(std::size_t)j + 1]; ++p) {
            double v = s.creux->valeur[(std::size_t)p];
            std::string texte;
            if (v == std::floor(v) && std::fabs(v) < 1e15) texte = formater("%.0f", v);
            else texte = formater("%.4f", v);
            out << formater("   (%d,%d)%*s%s\n", s.creux->ligne[(std::size_t)p] + 1, j + 1,
                            8, "", texte.c_str());
        }
    }
    return out.str();
}

}  // namespace matlibre
