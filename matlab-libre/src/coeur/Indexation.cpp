// Indexation.cpp — lecture et écriture indexées.
//
// C'est la partie la plus subtile du langage : indices linéaires ou par
// dimension, deux-points magique, indexation logique, croissance
// automatique à l'écriture, suppression par « = [] », et listes séparées
// par des virgules produites par « c{...} » ou « s.champ ».
#include <algorithm>
#include <cmath>

#include "matlibre/Creux.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

bool estColonMagique(const Valeur& v) {
    return v.classe == Classe::Caractere && v.nelem() == 1 && !v.re.empty() &&
           v.re[0] == (double)':';
}

// Convertit un indice MATLAB (1-based) en positions 0-based.
static std::vector<std::size_t> positions(const Valeur& idx, std::size_t taille,
                                          bool ecriture, std::size_t& borneMax) {
    std::vector<std::size_t> p;
    borneMax = 0;
    if (estColonMagique(idx)) {
        p.resize(taille);
        for (std::size_t k = 0; k < taille; ++k) p[k] = k;
        borneMax = taille;
        return p;
    }
    if (idx.classe == Classe::Logique) {
        for (std::size_t k = 0; k < idx.re.size(); ++k) {
            if (idx.re[k] != 0.0) {
                if (!ecriture && k >= taille)
                    erreur("MATLAB:badsubscript",
                           formater("Index exceeds the number of array elements. Index "
                                    "must not exceed %zu.", taille));
                p.push_back(k);
                borneMax = std::max(borneMax, k + 1);
            }
        }
        return p;
    }
    if (idx.classe == Classe::Cellule)
        erreur("MATLAB:badsubscript",
               "Function 'subsindex' is not defined for values of class 'cell'.");
    for (std::size_t k = 0; k < idx.nelem(); ++k) {
        double x = idx.re.empty() ? 0.0 : idx.re[k];
        if (x != std::floor(x) || std::isnan(x))
            erreur("MATLAB:badsubscript",
                   "Array indices must be positive integers or logical values.");
        if (x < 1)
            erreur("MATLAB:badsubscript",
                   x == 0 ? "Index in position 1 is invalid. Array indices must be "
                            "positive integers or logical values."
                          : "Array indices must be positive integers or logical values.");
        std::size_t i = (std::size_t)x - 1;
        if (!ecriture && i >= taille)
            erreur("MATLAB:badsubscript",
                   formater("Index exceeds the number of array elements. Index must not "
                            "exceed %zu.", taille));
        p.push_back(i);
        borneMax = std::max(borneMax, i + 1);
    }
    return p;
}

static Valeur coquilleVide(const Valeur& modele, const Dims& d) {
    Valeur r;
    r.classe = modele.classe;
    r.nomObjet = modele.nomObjet;
    r.dims = d;
    std::size_t n = produitDims(d);
    switch (modele.classe) {
        case Classe::Cellule: r.cellules.assign(n, Valeur::vide()); break;
        case Classe::Chaine: r.chaines.assign(n, std::string()); break;
        case Classe::Structure:
        case Classe::Objet:
            r.st = std::make_shared<ChampsStructure>();
            if (modele.st) {
                r.st->ordre = modele.st->ordre;
                for (const auto& nom : modele.st->ordre)
                    r.st->champs[nom] = std::vector<Valeur>(n, Valeur::vide());
            }
            break;
        case Classe::Fonction: r.fn = modele.fn; break;
        default:
            r.re.assign(n, 0.0);
            if (!modele.im.empty()) r.im.assign(n, 0.0);
            break;
    }
    return r;
}

static void copierCase(Valeur& dst, std::size_t di, const Valeur& src, std::size_t si) {
    switch (dst.classe) {
        case Classe::Cellule:
            dst.cellules[di] = si < src.cellules.size() ? src.cellules[si] : Valeur::vide();
            break;
        case Classe::Chaine:
            dst.chaines[di] = si < src.chaines.size() ? src.chaines[si] : std::string();
            break;
        case Classe::Structure:
        case Classe::Objet: {
            // Écrire une structure dans un tableau de structures peut y
            // introduire des champs nouveaux : MATLAB les ajoute alors à
            // tout le tableau, vides ailleurs (« s(1).a = 1; s(1).b = 2 »).
            if (src.st) {
                bool manque = false;
                for (const auto& nom : src.st->ordre)
                    if (!dst.st || dst.st->champs.find(nom) == dst.st->champs.end())
                        manque = true;
                if (manque) {
                    dst.detacherStructure();
                    for (const auto& nom : src.st->ordre) {
                        if (dst.st->champs.find(nom) != dst.st->champs.end()) continue;
                        dst.st->ordre.push_back(nom);
                        dst.st->champs[nom] =
                            std::vector<Valeur>(dst.nelem(), Valeur::vide());
                    }
                }
            }
            for (auto& kv : dst.st->champs) {
                const auto it = src.st ? src.st->champs.find(kv.first)
                                       : decltype(src.st->champs.end())();
                if (src.st && it != src.st->champs.end() && si < it->second.size())
                    kv.second[di] = it->second[si];
            }
            break;
        }
        default:
            // Écrire un complexe dans un tableau réel rend le tableau
            // complexe : sans cette promotion, la partie imaginaire
            // disparaîtrait en silence — c'est ce qui arrivait en faisant
            // grandir un tableau, « p(end+1) = 1+2i » sur un p réel.
            if (!src.im.empty() && dst.im.empty()) dst.assurerImaginaire();
            dst.re[di] = si < src.re.size() ? src.re[si] : 0.0;
            if (!dst.im.empty()) dst.im[di] = si < src.im.size() ? src.im[si] : 0.0;
            break;
    }
}

// ------------------------------------------------------------------ lecture

Valeur Interpreteur::indexer(const Valeur& base, std::vector<Valeur>& idx, char genre) {
    auto liste = indexerListe(base, idx, genre);
    if (liste.empty()) {
        if (genre == '{')
            erreur("MATLAB:badsubscript", "Index exceeds the number of array elements.");
        return Valeur::vide();
    }
    return liste[0];
}

std::vector<Valeur> Interpreteur::indexerListe(const Valeur& base, std::vector<Valeur>& idx,
                                               char genre) {
    if (base.estCreux()) {
        Valeur dense = denseDepuisCreux(base);
        return indexerListe(dense, idx, genre);
    }
    if (genre == '{' && base.classe != Classe::Cellule)
        erreur("MATLAB:cellRefFromNonCell",
               formater("Brace indexing is not supported for variables of this type. "
                        "(class %s)", base.classeNom().c_str()));
    if (idx.empty()) return {base};

    Dims bd = base.dims;
    bd.resize(std::max<std::size_t>(bd.size(), 2), 1);
    std::size_t total = base.nelem();

    std::vector<std::vector<std::size_t>> pos;
    Dims formeResultat;
    if (idx.size() == 1) {
        std::size_t bmax;
        auto p = positions(idx[0], total, false, bmax);
        pos.push_back(p);
        // Forme du résultat : celle de l'indice, sauf pour un vecteur indexé
        // par un vecteur — l'orientation de la source l'emporte alors.
        if (estColonMagique(idx[0])) {
            formeResultat = {(int)p.size(), 1};
        } else if (idx[0].classe == Classe::Logique) {
            // Un masque logique équivaut à find(masque) : un masque en
            // matrice donne une colonne, un masque en ligne une ligne, et
            // deux vecteurs laissent l'orientation à la source.
            if (!idx[0].estVecteur()) {
                formeResultat = Dims{(int)p.size(), 1};
            } else if (base.estVecteur()) {
                formeResultat =
                    base.estLigne() ? Dims{1, (int)p.size()} : Dims{(int)p.size(), 1};
            } else {
                formeResultat =
                    idx[0].estLigne() ? Dims{1, (int)p.size()} : Dims{(int)p.size(), 1};
            }
        } else if (idx[0].dims.size() == 2 && !idx[0].estVecteur() && !idx[0].estScalaire()) {
            formeResultat = idx[0].dims;
        } else if (base.estVecteur() && idx[0].estVecteur()) {
            formeResultat = base.estLigne() ? Dims{1, (int)p.size()} : Dims{(int)p.size(), 1};
        } else {
            formeResultat = idx[0].dims;
            if (produitDims(formeResultat) != p.size())
                formeResultat = Dims{(int)p.size(), 1};
        }
    } else {
        // Les dimensions au-delà du nombre d'indices sont repliées sur la
        // dernière, comme le fait MATLAB.
        Dims effectives(idx.size(), 1);
        for (std::size_t k = 0; k < idx.size(); ++k) {
            if (k + 1 == idx.size()) {
                std::size_t reste = 1;
                for (std::size_t d = k; d < bd.size(); ++d) reste *= (std::size_t)bd[d];
                effectives[k] = (int)reste;
            } else {
                effectives[k] = k < bd.size() ? bd[k] : 1;
            }
        }
        for (std::size_t k = 0; k < idx.size(); ++k) {
            std::size_t bmax;
            auto p = positions(idx[k], (std::size_t)effectives[k], false, bmax);
            if (bmax > (std::size_t)effectives[k])
                erreur("MATLAB:badsubscript",
                       formater("Index in position %zu exceeds array bounds. Index must "
                                "not exceed %d.", k + 1, effectives[k]));
            pos.push_back(p);
            formeResultat.push_back((int)p.size());
        }
        bd = effectives;
    }

    std::size_t n = 1;
    for (auto& p : pos) n *= p.size();
    Valeur r = coquilleVide(base, formeResultat.empty() ? Dims{0, 0} : formeResultat);
    r.normaliserDims();

    if (idx.size() == 1) {
        for (std::size_t k = 0; k < pos[0].size(); ++k) copierCase(r, k, base, pos[0][k]);
    } else {
        std::vector<std::size_t> pas(pos.size(), 1);
        for (std::size_t d = 1; d < pos.size(); ++d)
            pas[d] = pas[d - 1] * (std::size_t)std::max(1, bd[d - 1]);
        std::vector<std::size_t> compteur(pos.size(), 0);
        for (std::size_t k = 0; k < n; ++k) {
            std::size_t src = 0;
            for (std::size_t d = 0; d < pos.size(); ++d) src += pos[d][compteur[d]] * pas[d];
            copierCase(r, k, base, src);
            for (std::size_t d = 0; d < pos.size(); ++d) {
                if (++compteur[d] < pos[d].size()) break;
                compteur[d] = 0;
            }
        }
    }

    if (genre == '{') {
        std::vector<Valeur> liste;
        for (std::size_t k = 0; k < r.cellules.size(); ++k) liste.push_back(r.cellules[k]);
        return liste;
    }
    return {r};
}

// ----------------------------------------------------------------- écriture

static Valeur convertirPourAffectation(const Valeur& cible, const Valeur& v) {
    if (cible.classe == v.classe) return v;
    if (cible.classe == Classe::Cellule && v.classe != Classe::Cellule) {
        Valeur c = Valeur::celluleDims({1, 1});
        c.cellules[0] = v;
        return c;
    }
    if (cible.classe == Classe::Chaine && v.classe != Classe::Chaine) {
        Valeur s;
        s.classe = Classe::Chaine;
        s.dims = {1, 1};
        s.chaines = {v.versTexte()};
        return s;
    }
    if (classeNumerique(cible.classe) || cible.classe == Classe::Logique ||
        cible.classe == Classe::Caractere) {
        Valeur r = v;
        if (v.classe == Classe::Chaine) r = Valeur::texte(v.chaines.empty() ? "" : v.chaines[0]);
        return r;
    }
    return v;
}

// Classe résultante quand on écrit « v » dans « base ».
static Classe classeApresAffectation(const Valeur& base, const Valeur& v) {
    if (base.estVide() && base.classe == Classe::Double) return v.classe;
    if (base.classe == v.classe) return base.classe;
    if (base.classe == Classe::Cellule || v.classe == Classe::Cellule) return Classe::Cellule;
    if (base.estStructure() || v.estStructure()) return base.classe;
    if (base.classe == Classe::Caractere && classeNumerique(v.classe)) return Classe::Caractere;
    if (classeNumerique(base.classe) && v.classe == Classe::Caractere) return base.classe;
    if (base.classe == Classe::Logique && v.classe != Classe::Logique) return v.classe;
    if (classeEntiere(base.classe)) return base.classe;
    if (classeEntiere(v.classe)) return v.classe;
    if (base.classe == Classe::Chaine || v.classe == Classe::Chaine) return Classe::Chaine;
    return base.classe == Classe::Double ? v.classe : base.classe;
}

static Valeur redimensionnerConservant(const Valeur& base, const Dims& nouvelles) {
    Valeur r = coquilleVide(base, nouvelles);
    if (base.classe == Classe::Caractere)
        std::fill(r.re.begin(), r.re.end(), 0.0);
    Dims bd = base.dims;
    bd.resize(std::max(bd.size(), nouvelles.size()), 1);
    std::size_t n = base.nelem();
    std::vector<std::size_t> pas(nouvelles.size(), 1);
    for (std::size_t d = 1; d < nouvelles.size(); ++d)
        pas[d] = pas[d - 1] * (std::size_t)std::max(1, nouvelles[d - 1]);
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t reste = k, dst = 0;
        for (std::size_t d = 0; d < nouvelles.size(); ++d) {
            std::size_t taille = (std::size_t)std::max(1, bd[d]);
            std::size_t coord = reste % taille;
            reste /= taille;
            dst += coord * pas[d];
        }
        copierCase(r, dst, base, k);
    }
    return r;
}

// Suppression : « A(idx) = [] ».
static Valeur supprimer(const Valeur& base, std::vector<Valeur>& idx) {
    Dims bd = base.dims;
    bd.resize(std::max<std::size_t>(bd.size(), 2), 1);
    if (idx.size() == 1) {
        std::size_t bmax;
        auto p = positions(idx[0], base.nelem(), false, bmax);
        std::vector<bool> retire(base.nelem(), false);
        for (auto k : p) retire[k] = true;
        std::vector<std::size_t> gardes;
        for (std::size_t k = 0; k < base.nelem(); ++k)
            if (!retire[k]) gardes.push_back(k);
        Dims nd = base.estColonne() && !base.estScalaire() ? Dims{(int)gardes.size(), 1}
                                                           : Dims{1, (int)gardes.size()};
        if (gardes.empty()) nd = base.estColonne() ? Dims{0, 1} : Dims{1, 0};
        if (gardes.empty() && base.estScalaire()) nd = Dims{0, 0};
        Valeur r = coquilleVide(base, nd);
        for (std::size_t k = 0; k < gardes.size(); ++k) copierCase(r, k, base, gardes[k]);
        return r;
    }
    // Une seule dimension peut être « réduite » ; les autres doivent être « : ».
    int dimension = -1;
    for (std::size_t k = 0; k < idx.size(); ++k) {
        if (estColonMagique(idx[k])) continue;
        std::size_t bmax;
        auto p = positions(idx[k], (std::size_t)(k < bd.size() ? bd[k] : 1), false, bmax);
        bool tout = p.size() == (std::size_t)(k < bd.size() ? bd[k] : 1);
        if (tout) continue;
        if (dimension >= 0)
            erreur("MATLAB:indexedAssignmentDimensionMismatch",
                   "A null assignment can have only one non-colon index.");
        dimension = (int)k;
    }
    if (dimension < 0) dimension = 0;
    std::size_t bmax;
    auto p = positions(idx[(std::size_t)dimension],
                       (std::size_t)bd[(std::size_t)dimension], false, bmax);
    std::vector<bool> retire((std::size_t)bd[(std::size_t)dimension], false);
    for (auto k : p) retire[k] = true;
    std::vector<std::size_t> gardes;
    for (std::size_t k = 0; k < retire.size(); ++k)
        if (!retire[k]) gardes.push_back(k);
    Dims nd = bd;
    nd[(std::size_t)dimension] = (int)gardes.size();
    Valeur r = coquilleVide(base, nd);
    std::size_t n = produitDims(nd);
    std::vector<std::size_t> pasSrc(bd.size(), 1), pasDst(nd.size(), 1);
    for (std::size_t d = 1; d < bd.size(); ++d)
        pasSrc[d] = pasSrc[d - 1] * (std::size_t)std::max(1, bd[d - 1]);
    for (std::size_t d = 1; d < nd.size(); ++d)
        pasDst[d] = pasDst[d - 1] * (std::size_t)std::max(1, nd[d - 1]);
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t reste = k, src = 0;
        for (std::size_t d = 0; d < nd.size(); ++d) {
            std::size_t coord = reste % (std::size_t)std::max(1, nd[d]);
            reste /= (std::size_t)std::max(1, nd[d]);
            if ((int)d == dimension) coord = gardes[coord];
            src += coord * pasSrc[d];
        }
        copierCase(r, k, base, src);
    }
    return r;
}

static Valeur ecrire(Valeur base, std::vector<Valeur>& idx, const Valeur& valeur, char genre) {
    if (base.estCreux()) {
        // L'écriture passe par le dense puis revient au creux : c'est le
        // comportement observable de MATLAB, au coût près.
        Valeur dense = denseDepuisCreux(base);
        return creuxDepuisDense(ecrire(std::move(dense), idx, valeur, genre));
    }
    Valeur v = valeur;
    if (genre == '{') {
        if (base.classe != Classe::Cellule && base.estVide()) base = Valeur::celluleDims({0, 0});
        if (base.classe != Classe::Cellule)
            erreur("MATLAB:cellAssToNonCell",
                   "Brace indexing is not supported for variables of this type.");
        Valeur c = Valeur::celluleDims({1, 1});
        c.cellules[0] = v;
        v = c;
    }
    Classe cible = classeApresAffectation(base, v);
    if (base.classe != cible) {
        Valeur nb = base;
        if (base.estVide() && base.classe != cible) {
            nb = coquilleVide(v, base.dims);
            nb.classe = cible;
            if (cible == Classe::Structure || cible == Classe::Objet) {
                nb.st = std::make_shared<ChampsStructure>();
                if (v.st) nb.st->ordre = v.st->ordre;
                for (const auto& nom : nb.st->ordre) nb.st->champs[nom] = {};
            }
        } else {
            nb.classe = cible;
            if (cible == Classe::Cellule && base.classe != Classe::Cellule) {
                nb = coquilleVide(v, base.dims);
                for (std::size_t k = 0; k < base.nelem(); ++k)
                    nb.cellules[k] = extraireElement(base, k);
            } else if (cible == Classe::Chaine && base.classe != Classe::Chaine) {
                nb = coquilleVide(v, base.dims);
                for (std::size_t k = 0; k < base.nelem(); ++k)
                    nb.chaines[k] = extraireElement(base, k).versTexte();
            }
        }
        base = nb;
    }
    v = convertirPourAffectation(base, v);
    if (!v.im.empty() && base.im.empty() && !base.re.empty()) base.assurerImaginaire();
    if (base.im.empty() && !v.im.empty()) base.assurerImaginaire();

    Dims bd = base.dims;
    bd.resize(std::max<std::size_t>(bd.size(), 2), 1);

    if (idx.size() == 1) {
        std::size_t bmax;
        auto p = positions(idx[0], base.nelem(), true, bmax);
        if (estColonMagique(idx[0]) && base.estVide() && v.nelem() > 0) {
            p.resize(v.nelem());
            for (std::size_t k = 0; k < p.size(); ++k) p[k] = k;
            bmax = v.nelem();
        }
        if (bmax > base.nelem()) {
            if (base.estVide()) {
                base = redimensionnerConservant(base, Dims{1, (int)bmax});
            } else if (base.estVecteur() || base.estScalaire()) {
                Dims nd = base.estColonne() && base.dims[1] == 1 && base.dims[0] > 1
                              ? Dims{(int)bmax, 1}
                              : Dims{1, (int)bmax};
                if (base.estColonne() && !base.estLigne()) nd = Dims{(int)bmax, 1};
                base = redimensionnerConservant(base, nd);
            } else {
                erreur("MATLAB:resizeMatrix",
                       "Unable to perform assignment because the indices on the left side "
                       "are not compatible with the size of the right side.");
            }
        }
        if (v.nelem() != 1 && v.nelem() != p.size())
            erreur("MATLAB:subsassignnumelmismatch",
                   "Unable to perform assignment because the left and right sides have a "
                   "different number of elements.");
        for (std::size_t k = 0; k < p.size(); ++k)
            copierCase(base, p[k], v, v.nelem() == 1 ? 0 : k);
        return base;
    }

    // Indices multiples : croissance dimension par dimension.
    std::vector<std::vector<std::size_t>> pos;
    Dims nd = bd;
    nd.resize(std::max(nd.size(), idx.size()), 1);
    for (std::size_t k = 0; k < idx.size(); ++k) {
        std::size_t taille = k < bd.size() ? (std::size_t)bd[k] : 1;
        if (k + 1 == idx.size() && idx.size() < bd.size()) {
            taille = 1;
            for (std::size_t d = k; d < bd.size(); ++d) taille *= (std::size_t)bd[d];
        }
        std::size_t bmax;
        std::vector<std::size_t> p;
        if (estColonMagique(idx[k]) && taille == 0) {
            std::size_t vt = k < v.dims.size() ? (std::size_t)v.dims[k] : 1;
            p.resize(vt);
            for (std::size_t x = 0; x < vt; ++x) p[x] = x;
            bmax = vt;
        } else {
            p = positions(idx[k], taille, true, bmax);
        }
        pos.push_back(p);
        if (bmax > (std::size_t)nd[k]) nd[k] = (int)bmax;
    }
    if (!memeDims(nd, base.dims)) base = redimensionnerConservant(base, nd);
    std::size_t n = 1;
    for (auto& p : pos) n *= p.size();
    if (v.nelem() != 1 && v.nelem() != n)
        erreur("MATLAB:subsassigndimmismatch",
               "Unable to perform assignment because the size of the left side is not "
               "compatible with the size of the right side.");
    std::vector<std::size_t> pas(pos.size(), 1);
    for (std::size_t d = 1; d < pos.size(); ++d)
        pas[d] = pas[d - 1] * (std::size_t)std::max(1, nd[d - 1]);
    std::vector<std::size_t> compteur(pos.size(), 0);
    for (std::size_t k = 0; k < n; ++k) {
        std::size_t dst = 0;
        for (std::size_t d = 0; d < pos.size(); ++d) dst += pos[d][compteur[d]] * pas[d];
        copierCase(base, dst, v, v.nelem() == 1 ? 0 : k);
        for (std::size_t d = 0; d < pos.size(); ++d) {
            if (++compteur[d] < pos[d].size()) break;
            compteur[d] = 0;
        }
    }
    return base;
}

// Écriture par indices déjà évalués : c'est « ecrire » rendu accessible aux
// autres unités, notamment à l'exécution parallèle de parfor.
Valeur Interpreteur::ecrireIndex(Valeur base, std::vector<Valeur>& idx, const Valeur& v,
                                 char genre) {
    return ecrire(std::move(base), idx, v, genre);
}

Valeur Interpreteur::affecterIndex(Valeur base, const std::vector<ElementAcces>& chaine,
                                   std::size_t k, const Valeur& v, bool suppression) {
    if (k >= chaine.size()) return v;
    const ElementAcces& e = chaine[k];

    if (e.genre == '.' || e.genre == '?') {
        std::string nom = e.nom;
        if (e.genre == '?') {
            auto args = evaluerListe(e.args);
            if (args.empty()) erreur("MATLAB:badsubscript", "Invalid dynamic field name.");
            nom = args[0].versTexte();
        }
        // Un objet reçoit ses propriétés par ses accesseurs : c'est là que
        // « set.Propriete » d'une classe prend effet, et ce qui fait qu'un
        // objet « handle » se modifie à travers toutes ses copies.
        if (base.classe == Classe::Objet && !estCarte(base)) {
            if (k + 1 == chaine.size()) return ecrireProprieteObjet(std::move(base), nom, v);
            Valeur ancienne = lireProprieteObjet(base, nom);
            Valeur nouvelle = affecterIndex(std::move(ancienne), chaine, k + 1, v, suppression);
            return ecrireProprieteObjet(std::move(base), nom, nouvelle);
        }
        if (!base.estStructure()) {
            if (!base.estVide())
                erreur("MATLAB:invalidAssignment",
                       "Unable to perform assignment because dot indexing is not "
                       "supported for variables of this type.");
            base = Valeur::structureVide();
        }
        if (produitDims(base.dims) == 0) {
            base.dims = {1, 1};
            base.detacherStructure();
            for (auto& kv : base.st->champs) kv.second.resize(1, Valeur::vide());
        }
        if (base.nelem() != 1)
            erreur("MATLAB:index:expected_one_output_from_expression",
                   "Expected one output from a curly brace or dot indexing expression, "
                   "but there were multiple results.");
        Valeur ancienne = base.aChamp(nom) ? base.champ(nom, 0) : Valeur::vide();
        Valeur nouvelle = affecterIndex(std::move(ancienne), chaine, k + 1, v, suppression);
        base.poserChamp(nom, std::move(nouvelle), 0);
        return base;
    }

    auto idx = evaluerIndices(e.args, &base, 0, (int)e.args.size());
    if (k + 1 == chaine.size()) {
        if (suppression && e.genre == '(') return supprimer(base, idx);
        return ecrire(std::move(base), idx, v, e.genre);
    }
    // Accès intermédiaire : lire, modifier, réécrire.
    Valeur sous;
    bool existe = true;
    try {
        if (e.genre == '{') {
            auto liste = indexerListe(base, idx, '{');
            sous = liste.empty() ? Valeur::vide() : liste[0];
        } else {
            sous = indexer(base, idx, '(');
        }
    } catch (const ErreurMatlab&) {
        existe = false;
        sous = Valeur::vide();
    }
    (void)existe;
    Valeur nouvelle = affecterIndex(std::move(sous), chaine, k + 1, v, suppression);
    return ecrire(std::move(base), idx, nouvelle, e.genre);
}

}  // namespace matlibre
