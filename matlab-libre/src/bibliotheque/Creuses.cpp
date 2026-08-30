// Creuses.cpp — les fonctions du langage qui manipulent les matrices creuses.
#include <algorithm>
#include <cmath>
#include <memory>
#include <random>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Creux.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

FONCTION(fnSparse) {
    INUTILISE
    for (std::size_t k = 0; k < args.size(); ++k)
        if (!args[k].estTexte() && !args[k].estChaine()) exigerNumerique(args[k], "sparse");
    if (args.empty()) return {creuxVide(0, 0)};
    if (args.size() == 1) {
        if (args[0].estCreux()) return {args[0]};
        return {creuxDepuisDense(args[0])};
    }
    if (args.size() == 2) {
        // sparse(m, n) : matrice creuse de zéros.
        return {creuxVide((int)args[0].scal(), (int)args[1].scal())};
    }
    int m = 0, n = 0;
    if (args.size() >= 5) {
        m = (int)args[3].scal();
        n = (int)args[4].scal();
    } else {
        for (std::size_t k = 0; k < args[0].nelem(); ++k)
            m = std::max(m, (int)args[0].re[k]);
        for (std::size_t k = 0; k < args[1].nelem(); ++k)
            n = std::max(n, (int)args[1].re[k]);
    }
    return {creuxDepuisTriplets(args[0], args[1], args[2], m, n)};
}

FONCTION(fnFull) {
    INUTILISE
    exigerArguments(args, 1, 1, "full");
    return {denseDepuisCreux(args[0])};
}

FONCTION(fnIssparse) {
    INUTILISE
    exigerArguments(args, 1, 1, "issparse");
    return {Valeur::booleen(args[0].estCreux())};
}

FONCTION(fnNnzCreux) {
    INUTILISE
    exigerArguments(args, 1, 1, "nnz");
    return {Valeur::scalaire((double)nombreNonNuls(args[0]))};
}

FONCTION(fnNonzeros) {
    INUTILISE
    exigerArguments(args, 1, 1, "nonzeros");
    std::vector<double> v;
    if (args[0].estCreux()) {
        for (int j = 0; j < args[0].ncolonnes(); ++j)
            for (int p = args[0].creux->debutColonne[(std::size_t)j];
                 p < args[0].creux->debutColonne[(std::size_t)j + 1]; ++p)
                v.push_back(args[0].creux->valeur[(std::size_t)p]);
    } else {
        for (double x : args[0].re)
            if (x != 0) v.push_back(x);
    }
    return {Valeur::colonne(v)};
}

FONCTION(fnNzmax) {
    INUTILISE
    return {Valeur::scalaire((double)nombreNonNuls(args[0]))};
}

FONCTION(fnSpalloc) {
    INUTILISE
    exigerArguments(args, 2, 3, "spalloc");
    return {creuxVide((int)args[0].scal(), (int)args[1].scal())};
}

FONCTION(fnSpeye) {
    INUTILISE
    exigerArguments(args, 1, 2, "speye");
    for (std::size_t k = 0; k < args.size(); ++k) exigerNumerique(args[k], "speye");
    int m = argTaille(args[0].scal(), "speye");
    int n = args.size() > 1 ? argTaille(args[1].scal(), "speye") : m;
    Valeur s = creuxVide(m, n);
    for (int j = 0; j < n; ++j) {
        s.creux->debutColonne[(std::size_t)j] = (int)s.creux->ligne.size();
        if (j < m) {
            s.creux->ligne.push_back(j);
            s.creux->valeur.push_back(1.0);
        }
    }
    s.creux->debutColonne[(std::size_t)n] = (int)s.creux->ligne.size();
    return {s};
}

FONCTION(fnSpones) {
    INUTILISE
    exigerArguments(args, 1, 1, "spones");
    Valeur s = args[0].estCreux() ? args[0] : creuxDepuisDense(args[0]);
    s.creux = std::make_shared<DonneesCreuses>(*s.creux);
    for (auto& v : s.creux->valeur) v = 1.0;
    return {s};
}

FONCTION(fnSpdiags) {
    INUTILISE
    exigerArguments(args, 3, 4, "spdiags");
    // spdiags(B, d, m, n) : place les colonnes de B sur les diagonales d.
    const Valeur& B = args[0];
    const Valeur& d = args[1];
    int m = (int)args[2].scal();
    int n = args.size() > 3 ? (int)args[3].scal() : m;
    std::vector<double> lignes, colonnes, valeurs;
    for (std::size_t k = 0; k < d.nelem(); ++k) {
        int diagonale = (int)d.re[k];
        for (int i = 0; i < m; ++i) {
            int j = i + diagonale;
            if (j < 0 || j >= n) continue;
            int ligneB = (diagonale >= 0) ? j : i;
            if (ligneB >= B.nlignes()) continue;
            double v = B.re[(std::size_t)ligneB + k * (std::size_t)B.nlignes()];
            if (v == 0) continue;
            lignes.push_back(i + 1);
            colonnes.push_back(j + 1);
            valeurs.push_back(v);
        }
    }
    return {creuxDepuisTriplets(Valeur::colonne(lignes), Valeur::colonne(colonnes),
                                Valeur::colonne(valeurs), m, n)};
}

FONCTION(fnSprand) {
    INUTILISE
    exigerArguments(args, 3, 3, "sprand");
    int m = (int)args[0].scal();
    int n = (int)args[1].scal();
    double densite = args[2].scal();
    std::uniform_real_distribution<double> loi(0.0, 1.0);
    std::vector<double> lignes, colonnes, valeurs;
    for (int j = 0; j < n; ++j)
        for (int i = 0; i < m; ++i)
            if (loi(it.generateur) < densite) {
                lignes.push_back(i + 1);
                colonnes.push_back(j + 1);
                valeurs.push_back(loi(it.generateur));
            }
    return {creuxDepuisTriplets(Valeur::colonne(lignes), Valeur::colonne(colonnes),
                                Valeur::colonne(valeurs), m, n)};
}

FONCTION(fnSprandn) {
    INUTILISE
    exigerArguments(args, 3, 3, "sprandn");
    int m = (int)args[0].scal();
    int n = (int)args[1].scal();
    double densite = args[2].scal();
    std::uniform_real_distribution<double> uniforme(0.0, 1.0);
    std::normal_distribution<double> normale(0.0, 1.0);
    std::vector<double> lignes, colonnes, valeurs;
    for (int j = 0; j < n; ++j)
        for (int i = 0; i < m; ++i)
            if (uniforme(it.generateur) < densite) {
                lignes.push_back(i + 1);
                colonnes.push_back(j + 1);
                valeurs.push_back(normale(it.generateur));
            }
    return {creuxDepuisTriplets(Valeur::colonne(lignes), Valeur::colonne(colonnes),
                                Valeur::colonne(valeurs), m, n)};
}

FONCTION(fnSpy) {
    INUTILISE
    exigerArguments(args, 1, 1, "spy");
    exigerNumerique(args[0], "spy");
    std::vector<double> x, y;
    const Valeur& s = args[0];
    if (s.estCreux()) {
        for (int j = 0; j < s.ncolonnes(); ++j)
            for (int p = s.creux->debutColonne[(std::size_t)j];
                 p < s.creux->debutColonne[(std::size_t)j + 1]; ++p) {
                x.push_back(j + 1);
                y.push_back(s.creux->ligne[(std::size_t)p] + 1);
            }
    } else {
        for (int j = 0; j < s.ncolonnes(); ++j)
            for (int i = 0; i < s.nlignes(); ++i)
                if (s.re[(std::size_t)i + (std::size_t)j * s.nlignes()] != 0) {
                    x.push_back(j + 1);
                    y.push_back(i + 1);
                }
    }
    std::vector<Valeur> appel = {Valeur::ligne(x), Valeur::ligne(y)};
    it.appeler("scatter", appel, 0);
    std::vector<Valeur> titre = {Valeur::texte(formater("nnz = %zu", x.size()))};
    it.appeler("title", titre, 0);
    return {};
}

}  // namespace

void enregistrerCreuses(Interpreteur& it) {
    it.enregistrer("sparse", fnSparse, "creux",
                   "sparse  Matrice creuse.\n"
                   "  S = sparse(A) comprime une matrice pleine.\n"
                   "  S = sparse(m,n) cree une matrice creuse de zeros.\n"
                   "  S = sparse(i,j,v,m,n) construit depuis des triplets ; les\n"
                   "  doublons s'additionnent.");
    it.enregistrer("full", fnFull, "creux", "full  Matrice pleine correspondante.");
    it.enregistrer("issparse", fnIssparse, "creux", "issparse  Le stockage est-il creux.");
    it.enregistrer("nnz", fnNnzCreux, "creux", "nnz  Nombre d'elements non nuls.");
    it.enregistrer("nonzeros", fnNonzeros, "creux", "nonzeros  Valeurs non nulles.");
    it.enregistrer("nzmax", fnNzmax, "creux", "nzmax  Place reservee aux non-nuls.");
    it.enregistrer("spalloc", fnSpalloc, "creux", "spalloc  Matrice creuse vide.");
    it.enregistrer("speye", fnSpeye, "creux", "speye  Identite creuse.");
    it.enregistrer("spones", fnSpones, "creux", "spones  Motif de non-nuls, valeurs a 1.");
    it.enregistrer("spdiags", fnSpdiags, "creux", "spdiags  Matrice creuse par diagonales.");
    it.enregistrer("sprand", fnSprand, "creux", "sprand  Matrice creuse uniforme.");
    it.enregistrer("sprandn", fnSprandn, "creux", "sprandn  Matrice creuse normale.");
    it.enregistrer("spy", fnSpy, "creux", "spy  Trace le motif des non-nuls.");
}

}  // namespace matlibre
