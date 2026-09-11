// Texte.cpp — chaînes de caractères, tableaux de caractères et « string ».
#include <algorithm>
#include <cctype>
#include <cmath>
#include <regex>
#include <set>
#include <cstring>
#include <sstream>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

std::string formatMatlab(const std::string& format, const std::vector<Valeur>& args,
                         std::size_t debut);

namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

bool estTextuel(const Valeur& v) {
    return v.classe == Classe::Caractere || v.classe == Classe::Chaine;
}

// Beaucoup de fonctions acceptent indifféremment un texte, une string ou une
// cellule de textes ; on récupère la liste, et l'on sait la reconstituer.
struct ListeTextes {
    std::vector<std::string> valeurs;
    Classe origine = Classe::Caractere;
    Dims dims{1, 1};
    bool multiple = false;
};

ListeTextes listeDe(const Valeur& v) {
    ListeTextes l;
    l.origine = v.classe;
    l.dims = v.dims;
    if (v.classe == Classe::Cellule) {
        l.multiple = true;
        for (const auto& c : v.cellules) l.valeurs.push_back(c.versTexte());
    } else if (v.classe == Classe::Chaine) {
        l.multiple = v.nelem() != 1;
        for (const auto& s : v.chaines) l.valeurs.push_back(s);
    } else if (v.classe == Classe::Caractere && v.nlignes() > 1) {
        l.multiple = true;
        int nl = v.nlignes(), nc = v.ncolonnes();
        for (int i = 0; i < nl; ++i) {
            std::string s;
            for (int j = 0; j < nc; ++j)
                s += (char)(int)v.re[(std::size_t)i + (std::size_t)j * nl];
            l.valeurs.push_back(s);
        }
        l.dims = {nl, 1};
    } else {
        l.valeurs.push_back(v.versTexte());
    }
    return l;
}

Valeur reconstituer(const ListeTextes& l, const std::vector<std::string>& valeurs) {
    if (!l.multiple && valeurs.size() == 1) {
        if (l.origine == Classe::Chaine) return Valeur::chaine(valeurs[0]);
        return Valeur::texte(valeurs[0]);
    }
    if (l.origine == Classe::Chaine) {
        Valeur r;
        r.classe = Classe::Chaine;
        r.dims = l.dims;
        r.chaines = valeurs;
        return r;
    }
    Valeur r = Valeur::celluleDims(l.dims);
    if (r.cellules.size() != valeurs.size()) r = Valeur::celluleDims({1, (int)valeurs.size()});
    for (std::size_t k = 0; k < valeurs.size(); ++k) r.cellules[k] = Valeur::texte(valeurs[k]);
    return r;
}

// Une liste vide donne un résultat vide : c'est le cas de strcmp({}, 'x').
bool listeVide(const ListeTextes& a, const ListeTextes& b) {
    return a.valeurs.empty() || b.valeurs.empty();
}

// Comparer deux listes de longueurs différentes n'a pas de sens : MATLAB
// l'interdit, sauf si l'un des deux côtés est unique et se répand sur
// l'autre. Sans cette vérification, la boucle de comparaison lisait
// au-delà de la plus courte — ce qui passait inaperçu sur strcmp et
// faisait tomber strcmpi, qui recopie la chaîne pour la mettre en
// minuscules.
void exigerMemeTaille(const ListeTextes& a, const ListeTextes& b, const char* nom) {
    if (a.valeurs.size() == 1 || b.valeurs.size() == 1) return;
    if (a.valeurs.size() == b.valeurs.size()) return;
    throw ErreurMatlab(std::string("MATLAB:") + nom + ":InputsSizeMismatch",
                       std::string(nom) + " : les deux arguments doivent avoir la même "
                       "taille, ou l'un des deux se réduire à un seul texte ; ici " +
                       std::to_string(a.valeurs.size()) + " et " +
                       std::to_string(b.valeurs.size()) + ".");
}

Valeur videLogique(const ListeTextes& modele) {
    Valeur r = Valeur::matriceDims(modele.dims);
    r.classe = Classe::Logique;
    r.re.clear();
    r.dims = {0, 0};
    return r;
}

Valeur logiqueComme(const ListeTextes& l, const std::vector<bool>& valeurs) {
    Valeur r = Valeur::matriceDims(l.multiple ? l.dims : Dims{1, 1});
    r.classe = Classe::Logique;
    r.re.resize(valeurs.size());
    for (std::size_t k = 0; k < valeurs.size(); ++k) r.re[k] = valeurs[k] ? 1 : 0;
    if (!l.multiple) r.dims = {1, 1};
    return r;
}

std::string minuscules(std::string s) {
    for (auto& c : s) c = (char)std::tolower((unsigned char)c);
    return s;
}
std::string majuscules(std::string s) {
    for (auto& c : s) c = (char)std::toupper((unsigned char)c);
    return s;
}

FONCTION(fnUpper) {
    INUTILISE
    exigerArguments(args, 1, 1, "upper");
    ListeTextes l = listeDe(args[0]);
    std::vector<std::string> r;
    for (auto& s : l.valeurs) r.push_back(majuscules(s));
    return {reconstituer(l, r)};
}
FONCTION(fnLower) {
    INUTILISE
    exigerArguments(args, 1, 1, "lower");
    ListeTextes l = listeDe(args[0]);
    std::vector<std::string> r;
    for (auto& s : l.valeurs) r.push_back(minuscules(s));
    return {reconstituer(l, r)};
}

FONCTION(fnStrtrim) {
    INUTILISE
    exigerArguments(args, 1, 1, "strtrim");
    ListeTextes l = listeDe(args[0]);
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        while (!s.empty() && std::isspace((unsigned char)s.front())) s.erase(s.begin());
        while (!s.empty() && std::isspace((unsigned char)s.back())) s.pop_back();
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

// STRIP fait plus que STRTRIM : il dit de quel cote retirer, et quoi.
// « strip(t,'left','0') » enleve les zeros de tete sans toucher au reste,
// ce qu'aucune composition de STRTRIM ne donne.
FONCTION(fnStrip) {
    INUTILISE
    exigerArguments(args, 1, 3, "strip");
    bool aGauche = true, aDroite = true;
    bool surBlancs = true;
    char remplissage = ' ';
    std::size_t rang = 1;
    if (args.size() > rang && (args[rang].estTexte() || args[rang].estChaine())) {
        std::string mot = minuscules(args[rang].versTexte());
        if (mot == "left" || mot == "right" || mot == "both") {
            aGauche = (mot != "right");
            aDroite = (mot != "left");
            ++rang;
        }
    }
    if (args.size() > rang) {
        std::string caractere = args[rang].versTexte();
        if (caractere.size() != 1)
            throw ErreurMatlab("MATLAB:strip:InvalidPadCharacter",
                               "strip : le caractere de remplissage tient sur un seul caractere.");
        remplissage = caractere[0];
        surBlancs = false;
        ++rang;
    }
    if (rang < args.size())
        throw ErreurMatlab("MATLAB:strip:TooManyInputs",
                           "strip : trop d'arguments ; attendus un cote puis un caractere.");
    ListeTextes l = listeDe(args[0]);
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        auto aRetirer = [&](char c) {
            return surBlancs ? std::isspace((unsigned char)c) != 0 : c == remplissage;
        };
        if (aGauche)
            while (!s.empty() && aRetirer(s.front())) s.erase(s.begin());
        if (aDroite)
            while (!s.empty() && aRetirer(s.back())) s.pop_back();
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

FONCTION(fnDeblank) {
    INUTILISE
    ListeTextes l = listeDe(args[0]);
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        while (!s.empty() && (std::isspace((unsigned char)s.back()) || s.back() == '\0'))
            s.pop_back();
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

FONCTION(fnStrcat) {
    INUTILISE
    exigerArguments(args, 1, 0, "strcat");
    bool cellule = false;
    std::size_t n = 1;
    for (const auto& a : args)
        if (a.classe == Classe::Cellule || (a.classe == Classe::Chaine && a.nelem() > 1)) {
            cellule = true;
            n = std::max(n, a.nelem());
        }
    if (!cellule) {
        std::string s;
        for (const auto& a : args) {
            std::string t = a.versTexte();
            // strcat retire les blancs finaux des tableaux de caractères.
            if (a.classe == Classe::Caractere)
                while (!t.empty() && t.back() == ' ') t.pop_back();
            s += t;
        }
        bool chaine = false;
        for (const auto& a : args)
            if (a.classe == Classe::Chaine) chaine = true;
        return {chaine ? Valeur::chaine(s) : Valeur::texte(s)};
    }
    std::vector<std::string> sortie(n);
    for (const auto& a : args) {
        ListeTextes l = listeDe(a);
        for (std::size_t k = 0; k < n; ++k)
            sortie[k] += l.valeurs.size() == 1 ? l.valeurs[0]
                                               : (k < l.valeurs.size() ? l.valeurs[k] : "");
    }
    Valeur r = Valeur::celluleDims({1, (int)n});
    for (std::size_t k = 0; k < n; ++k) r.cellules[k] = Valeur::texte(sortie[k]);
    return {r};
}

FONCTION(fnStrcmp) {
    INUTILISE
    exigerArguments(args, 2, 2, "strcmp");
    const Valeur& a = args[0];
    const Valeur& b = args[1];
    if (!estTextuel(a) && a.classe != Classe::Cellule) return {Valeur::booleen(false)};
    ListeTextes la = listeDe(a), lb = listeDe(b);
    if (listeVide(la, lb)) return {videLogique(la.valeurs.empty() ? la : lb)};
    exigerMemeTaille(la, lb, "strcmp");
    std::size_t n = std::max(la.valeurs.size(), lb.valeurs.size());
    std::vector<bool> r(n);
    for (std::size_t k = 0; k < n; ++k) {
        const std::string& x = la.valeurs[la.valeurs.size() == 1 ? 0 : k];
        const std::string& y = lb.valeurs[lb.valeurs.size() == 1 ? 0 : k];
        r[k] = (x == y);
    }
    const ListeTextes& modele = la.multiple ? la : lb;
    return {logiqueComme(modele, r)};
}

FONCTION(fnStrcmpi) {
    INUTILISE
    exigerArguments(args, 2, 2, "strcmpi");
    ListeTextes la = listeDe(args[0]), lb = listeDe(args[1]);
    if (listeVide(la, lb)) return {videLogique(la.valeurs.empty() ? la : lb)};
    exigerMemeTaille(la, lb, "strcmpi");
    std::size_t n = std::max(la.valeurs.size(), lb.valeurs.size());
    std::vector<bool> r(n);
    for (std::size_t k = 0; k < n; ++k)
        r[k] = minuscules(la.valeurs[la.valeurs.size() == 1 ? 0 : k]) ==
               minuscules(lb.valeurs[lb.valeurs.size() == 1 ? 0 : k]);
    return {logiqueComme(la.multiple ? la : lb, r)};
}

FONCTION(fnStrncmp) {
    INUTILISE
    exigerArguments(args, 3, 3, "strncmp");
    std::size_t n = (std::size_t)args[2].scal();
    ListeTextes la = listeDe(args[0]), lb = listeDe(args[1]);
    if (listeVide(la, lb)) return {videLogique(la.valeurs.empty() ? la : lb)};
    exigerMemeTaille(la, lb, "strncmp");
    std::size_t m = std::max(la.valeurs.size(), lb.valeurs.size());
    std::vector<bool> r(m);
    for (std::size_t k = 0; k < m; ++k) {
        const std::string& x = la.valeurs[la.valeurs.size() == 1 ? 0 : k];
        const std::string& y = lb.valeurs[lb.valeurs.size() == 1 ? 0 : k];
        r[k] = x.size() >= n && y.size() >= n && x.compare(0, n, y, 0, n) == 0;
    }
    return {logiqueComme(la.multiple ? la : lb, r)};
}

FONCTION(fnStrncmpi) {
    INUTILISE
    exigerArguments(args, 3, 3, "strncmpi");
    std::size_t n = (std::size_t)args[2].scal();
    ListeTextes la = listeDe(args[0]), lb = listeDe(args[1]);
    if (listeVide(la, lb)) return {videLogique(la.valeurs.empty() ? la : lb)};
    exigerMemeTaille(la, lb, "strncmpi");
    std::size_t m = std::max(la.valeurs.size(), lb.valeurs.size());
    std::vector<bool> r(m);
    for (std::size_t k = 0; k < m; ++k) {
        std::string x = minuscules(la.valeurs[la.valeurs.size() == 1 ? 0 : k]);
        std::string y = minuscules(lb.valeurs[lb.valeurs.size() == 1 ? 0 : k]);
        r[k] = x.size() >= n && y.size() >= n && x.compare(0, n, y, 0, n) == 0;
    }
    return {logiqueComme(la.multiple ? la : lb, r)};
}

FONCTION(fnStrfind) {
    INUTILISE
    exigerArguments(args, 2, 2, "strfind");
    std::string texte = args[0].versTexte();
    std::string motif = args[1].versTexte();
    std::vector<double> positions;
    if (!motif.empty()) {
        std::size_t p = texte.find(motif);
        while (p != std::string::npos) {
            positions.push_back((double)(p + 1));
            p = texte.find(motif, p + 1);
        }
    }
    if (positions.empty()) return {Valeur::matrice(1, 0)};
    return {Valeur::ligne(positions)};
}

FONCTION(fnStrrep) {
    INUTILISE
    exigerArguments(args, 3, 3, "strrep");
    ListeTextes l = listeDe(args[0]);
    std::string ancien = args[1].versTexte();
    std::string nouveau = args[2].versTexte();
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        if (!ancien.empty()) {
            std::string sortie;
            std::size_t p = 0;
            for (;;) {
                std::size_t q = s.find(ancien, p);
                if (q == std::string::npos) {
                    sortie += s.substr(p);
                    break;
                }
                sortie += s.substr(p, q - p) + nouveau;
                p = q + ancien.size();
            }
            s = sortie;
        }
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

// ---------------------------------------------------- extraction et insertion
//
// La famille moderne des chaines de MATLAB : erase, replace, insertAfter,
// insertBefore, extractAfter, extractBefore, extractBetween, count et
// matches. Toutes acceptent un texte, une cellule de textes ou un tableau
// string, et rendent la meme forme que ce qu'on leur donne.

// Remplace toutes les occurrences d un motif. Un motif vide ne remplace
// rien : sans cette garde, la boucle ne finirait jamais.
std::string remplacerTout(const std::string& s, const std::string& ancien,
                          const std::string& nouveau_) {
    if (ancien.empty()) return s;
    std::string sortie;
    std::size_t p = 0;
    for (;;) {
        std::size_t q = s.find(ancien, p);
        if (q == std::string::npos) {
            sortie += s.substr(p);
            return sortie;
        }
        sortie += s.substr(p, q - p) + nouveau_;
        p = q + ancien.size();
    }
}

FONCTION(fnErase) {
    INUTILISE
    exigerArguments(args, 2, 2, "erase");
    ListeTextes l = listeDe(args[0]);
    ListeTextes m = listeDe(args[1]);
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        for (const auto& motif : m.valeurs) s = remplacerTout(s, motif, "");
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

// replace accepte plusieurs motifs a la fois, appliques dans l ordre : c est
// ce qui la distingue de strrep, qui n en prend qu un.
FONCTION(fnReplace) {
    INUTILISE
    exigerArguments(args, 3, 3, "replace");
    ListeTextes l = listeDe(args[0]);
    ListeTextes anciens = listeDe(args[1]);
    ListeTextes nouveaux = listeDe(args[2]);
    if (nouveaux.valeurs.size() != 1 && nouveaux.valeurs.size() != anciens.valeurs.size())
        throw ErreurMatlab("MATLAB:replace:SizeMismatch",
                           "Il faut un remplacement, ou autant que de motifs.");
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        for (std::size_t k = 0; k < anciens.valeurs.size(); ++k) {
            const std::string& n =
                nouveaux.valeurs.size() == 1 ? nouveaux.valeurs[0] : nouveaux.valeurs[k];
            s = remplacerTout(s, anciens.valeurs[k], n);
        }
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

// insertAfter et insertBefore posent le texte a chaque occurrence du motif,
// non seulement a la premiere : c est la regle de MATLAB.
Valeur inserer(const Arguments& args, bool apres, const char* nom) {
    ListeTextes l = listeDe(args[0]);
    std::string motif = args[1].versTexte();
    std::string ajout = args[2].versTexte();
    std::vector<std::string> r;
    for (const auto& s : l.valeurs) {
        if (motif.empty()) {
            r.push_back(s);
            continue;
        }
        std::string sortie;
        std::size_t p = 0;
        for (;;) {
            std::size_t q = s.find(motif, p);
            if (q == std::string::npos) {
                sortie += s.substr(p);
                break;
            }
            if (apres)
                sortie += s.substr(p, q - p + motif.size()) + ajout;
            else
                sortie += s.substr(p, q - p) + ajout + motif;
            p = q + motif.size();
        }
        r.push_back(sortie);
    }
    (void)nom;
    return reconstituer(l, r);
}

FONCTION(fnInsertAfter) {
    INUTILISE
    exigerArguments(args, 3, 3, "insertAfter");
    return {inserer(args, true, "insertAfter")};
}

FONCTION(fnInsertBefore) {
    INUTILISE
    exigerArguments(args, 3, 3, "insertBefore");
    return {inserer(args, false, "insertBefore")};
}

// extractAfter et extractBefore rendent une chaine vide quand le motif est
// absent : c est ce que fait MATLAB, et cela evite d avoir a tester avant.
Valeur extraire(const Arguments& args, bool apres) {
    ListeTextes l = listeDe(args[0]);
    std::vector<std::string> r;
    bool parPosition = args[1].estNumerique();
    std::string motif = parPosition ? std::string() : args[1].versTexte();
    for (const auto& s : l.valeurs) {
        if (parPosition) {
            std::size_t n = (std::size_t)args[1].scal();
            if (apres)
                r.push_back(n >= s.size() ? std::string() : s.substr(n));
            else
                r.push_back(n == 0 ? std::string()
                                   : s.substr(0, std::min(n - 1, s.size())));
            continue;
        }
        std::size_t q = s.find(motif);
        if (q == std::string::npos || motif.empty()) {
            r.push_back(std::string());
        } else if (apres) {
            r.push_back(s.substr(q + motif.size()));
        } else {
            r.push_back(s.substr(0, q));
        }
    }
    return reconstituer(l, r);
}

FONCTION(fnExtractAfter) {
    INUTILISE
    exigerArguments(args, 2, 2, "extractAfter");
    return {extraire(args, true)};
}

FONCTION(fnExtractBefore) {
    INUTILISE
    exigerArguments(args, 2, 2, "extractBefore");
    return {extraire(args, false)};
}

// extractBetween rend ce qui separe deux motifs. « Boundaries » decide si
// les motifs eux-memes font partie du resultat.
FONCTION(fnExtractBetween) {
    INUTILISE
    exigerArguments(args, 3, 5, "extractBetween");
    ListeTextes l = listeDe(args[0]);
    bool inclusif = false;
    for (std::size_t k = 3; k + 1 < args.size(); k += 2)
        if (minuscules(args[k].versTexte()) == "boundaries")
            inclusif = minuscules(args[k + 1].versTexte()) == "inclusive";
    bool parPosition = args[1].estNumerique() && args[2].estNumerique();
    std::vector<std::string> r;
    for (const auto& s : l.valeurs) {
        if (parPosition) {
            std::size_t a = (std::size_t)args[1].scal();
            std::size_t b = (std::size_t)args[2].scal();
            if (a < 1 || b < a || a > s.size()) {
                r.push_back(std::string());
            } else {
                b = std::min(b, s.size());
                r.push_back(s.substr(a - 1, b - a + 1));
            }
            continue;
        }
        std::string debut = args[1].versTexte();
        std::string fin = args[2].versTexte();
        std::size_t p = s.find(debut);
        if (p == std::string::npos || debut.empty() || fin.empty()) {
            r.push_back(std::string());
            continue;
        }
        std::size_t q = s.find(fin, p + debut.size());
        if (q == std::string::npos) {
            r.push_back(std::string());
            continue;
        }
        if (inclusif)
            r.push_back(s.substr(p, q + fin.size() - p));
        else
            r.push_back(s.substr(p + debut.size(), q - p - debut.size()));
    }
    return {reconstituer(l, r)};
}

// Les bornes d'un morceau se disent de deux facons : par position, ou par
// les textes qui l'encadrent. La recherche est la meme pour extraire,
// remplacer ou effacer ; seul ce qu'on met a la place change. RENDRE dit
// ce que devient le morceau trouve.
static std::vector<std::string> entreBornes(const ListeTextes& l, const Arguments& args,
                                            const std::string& remplacement,
                                            const char* nom) {
    bool inclusif = false;
    for (std::size_t k = 3; k + 1 < args.size(); k += 2)
        if (minuscules(args[k].versTexte()) == "boundaries")
            inclusif = minuscules(args[k + 1].versTexte()) == "inclusive";
    bool parPosition = args[1].estNumerique() && args[2].estNumerique();
    std::vector<std::string> r;
    for (const auto& s : l.valeurs) {
        std::size_t debutMorceau = std::string::npos, finMorceau = 0;
        if (parPosition) {
            long a = (long)args[1].scal();
            long b = (long)args[2].scal();
            if (a < 1 || b < a - 1 || (std::size_t)a > s.size() + 1)
                throw ErreurMatlab(std::string("MATLAB:") + nom + ":InvalidPositions",
                                   std::string(nom) + " : les positions sortent du texte.");
            debutMorceau = (std::size_t)(a - 1);
            finMorceau = std::min((std::size_t)b, s.size());
            if (finMorceau < debutMorceau) finMorceau = debutMorceau;
        } else {
            std::string ouvrant = args[1].versTexte();
            std::string fermant = args[2].versTexte();
            if (ouvrant.empty() || fermant.empty()) { r.push_back(s); continue; }
            std::size_t p = s.find(ouvrant);
            if (p == std::string::npos) { r.push_back(s); continue; }
            std::size_t q = s.find(fermant, p + ouvrant.size());
            if (q == std::string::npos) { r.push_back(s); continue; }
            if (inclusif) {
                debutMorceau = p;
                finMorceau = q + fermant.size();
            } else {
                debutMorceau = p + ouvrant.size();
                finMorceau = q;
            }
        }
        r.push_back(s.substr(0, debutMorceau) + remplacement + s.substr(finMorceau));
    }
    return r;
}

FONCTION(fnReplaceBetween) {
    INUTILISE
    exigerArguments(args, 4, 6, "replaceBetween");
    ListeTextes l = listeDe(args[0]);
    // Le remplacement est le quatrieme argument ; les options suivent.
    std::string remplacement = args[3].versTexte();
    std::vector<Valeur> passees;
    passees.push_back(args[0]);
    passees.push_back(args[1]);
    passees.push_back(args[2]);
    for (std::size_t k = 4; k < args.size(); ++k) passees.push_back(args[k]);
    Arguments options(passees);
    return {reconstituer(l, entreBornes(l, options, remplacement, "replaceBetween"))};
}

FONCTION(fnEraseBetween) {
    INUTILISE
    exigerArguments(args, 3, 5, "eraseBetween");
    ListeTextes l = listeDe(args[0]);
    return {reconstituer(l, entreBornes(l, args, std::string(), "eraseBetween"))};
}

// count compte les occurrences sans se recouvrir : « aaa » contient une
// seule fois « aa », comme dans MATLAB.
FONCTION(fnCount) {
    INUTILISE
    exigerArguments(args, 2, 4, "count");
    ListeTextes l = listeDe(args[0]);
    ListeTextes m = listeDe(args[1]);
    bool ignorerCasse = false;
    for (std::size_t k = 2; k + 1 < args.size(); k += 2)
        if (minuscules(args[k].versTexte()) == "ignorecase") ignorerCasse = args[k + 1].vrai();
    std::vector<double> r;
    for (const auto& s0 : l.valeurs) {
        std::string s = ignorerCasse ? minuscules(s0) : s0;
        double total = 0;
        for (const auto& p0 : m.valeurs) {
            std::string p = ignorerCasse ? minuscules(p0) : p0;
            if (p.empty()) continue;
            std::size_t q = s.find(p);
            while (q != std::string::npos) {
                total += 1;
                q = s.find(p, q + p.size());
            }
        }
        r.push_back(total);
    }
    // La forme suit celle de la liste, non celle du tableau de caracteres :
    // « aaa » est un seul texte, non trois.
    Valeur v = Valeur::matriceDims(l.multiple ? l.dims : Dims{1, 1});
    v.re = r;
    if (!l.multiple) v.dims = {1, 1};
    return {v};
}

// matches demande l egalite entiere, la ou contains se contente d une
// occurrence : c est la difference entre « est-ce ce mot » et « ce mot y
// est-il ».
FONCTION(fnMatches) {
    INUTILISE
    exigerArguments(args, 2, 4, "matches");
    ListeTextes l = listeDe(args[0]);
    ListeTextes m = listeDe(args[1]);
    bool ignorerCasse = false;
    for (std::size_t k = 2; k + 1 < args.size(); k += 2)
        if (minuscules(args[k].versTexte()) == "ignorecase") ignorerCasse = args[k + 1].vrai();
    std::vector<bool> r;
    for (const auto& s : l.valeurs) {
        bool trouve = false;
        for (const auto& p : m.valeurs) {
            if (ignorerCasse ? (minuscules(s) == minuscules(p)) : (s == p)) trouve = true;
        }
        r.push_back(trouve);
    }
    return {logiqueComme(l, r)};
}

// regexptranslate rend un texte utilisable comme motif : « escape » protege
// les caracteres speciaux, « wildcard » traduit les jokers du shell.
FONCTION(fnRegexptranslate) {
    INUTILISE
    exigerArguments(args, 2, 2, "regexptranslate");
    std::string mode = minuscules(args[0].versTexte());
    ListeTextes l = listeDe(args[1]);
    std::vector<std::string> r;
    for (const auto& s : l.valeurs) {
        std::string sortie;
        if (mode == "escape") {
            for (char c : s) {
                if (std::strchr("$.?[]^*+|()\\{}", c)) sortie += '\\';
                sortie += c;
            }
        } else if (mode == "wildcard") {
            for (char c : s) {
                if (c == '*') sortie += ".*";
                else if (c == '?') sortie += '.';
                else if (std::strchr("$.[]^+|()\\{}", c)) { sortie += '\\'; sortie += c; }
                else sortie += c;
            }
        } else if (mode == "flexible") {
            sortie = s;
        } else {
            throw ErreurMatlab("MATLAB:regexptranslate:InvalidOperation",
                               "Operation inconnue : " + mode + ".");
        }
        r.push_back(sortie);
    }
    return {reconstituer(l, r)};
}

FONCTION(fnStrsplit) {
    INUTILISE
    exigerArguments(args, 1, 6, "strsplit");
    std::string texte = args[0].versTexte();
    std::vector<std::string> separateurs;
    // « CollapseDelimiters » vaut vrai par défaut, comme dans MATLAB :
    // deux séparateurs qui se suivent n'engendrent pas de case vide au
    // milieu. Sans cela, découper un texte sur les espaces rendrait une
    // case vide chaque fois que deux espaces se suivent.
    bool regrouper = true;
    std::size_t k = 1;
    if (args.size() > 1 && args[1].classe != Classe::Caractere &&
        args[1].classe != Classe::Chaine && args[1].classe != Classe::Cellule) {
        erreur("MATLAB:strsplit:InvalidDelimiter",
               "The delimiter must be a character vector, a string, or a cell array.");
    }
    bool separateurDonne = false;
    if (args.size() > 1) {
        std::string premier = args[1].classe == Classe::Cellule
                                  ? std::string()
                                  : args[1].versTexte();
        bool estOption = args.size() > 2 &&
                         (premier == "CollapseDelimiters" || premier == "Delimiter");
        if (!estOption) {
            separateurDonne = true;
            if (args[1].classe == Classe::Cellule)
                for (const auto& c : args[1].cellules) separateurs.push_back(c.versTexte());
            else separateurs.push_back(premier);
            k = 2;
        }
    }
    for (; k + 1 < args.size(); k += 2) {
        std::string nom = args[k].versTexte();
        if (nom == "CollapseDelimiters") regrouper = args[k + 1].vrai();
        else if (nom == "Delimiter") {
            separateurs.clear();
            separateurDonne = true;
            if (args[k + 1].classe == Classe::Cellule)
                for (const auto& c : args[k + 1].cellules)
                    separateurs.push_back(c.versTexte());
            else separateurs.push_back(args[k + 1].versTexte());
        }
    }
    if (!separateurDonne) {
        // Le séparateur par défaut est l'espace au sens large : espace,
        // tabulation, saut de ligne, retour chariot, saut de page,
        // tabulation verticale.
        for (char c : std::string(" \t\n\r\f\v")) separateurs.push_back(std::string(1, c));
    }
    std::vector<std::string> morceaux;
    std::string courant;
    std::size_t i = 0;
    while (i < texte.size()) {
        std::size_t taille = 0;
        for (const auto& sep : separateurs)
            if (!sep.empty() && texte.compare(i, sep.size(), sep) == 0) {
                taille = sep.size();
                break;
            }
        if (taille == 0) {
            courant += texte[i++];
            continue;
        }
        morceaux.push_back(courant);
        courant.clear();
        i += taille;
        if (!regrouper) continue;
        // On avale les séparateurs qui suivent immédiatement.
        bool encore = true;
        while (encore && i < texte.size()) {
            encore = false;
            for (const auto& sep : separateurs)
                if (!sep.empty() && texte.compare(i, sep.size(), sep) == 0) {
                    i += sep.size();
                    encore = true;
                    break;
                }
        }
    }
    morceaux.push_back(courant);
    Valeur r = Valeur::celluleDims({1, (int)morceaux.size()});
    for (std::size_t j = 0; j < morceaux.size(); ++j) r.cellules[j] = Valeur::texte(morceaux[j]);
    return {r};
}

FONCTION(fnStrjoin) {
    INUTILISE
    exigerArguments(args, 1, 2, "strjoin");
    ListeTextes l = listeDe(args[0]);
    std::string sep = args.size() > 1 ? args[1].versTexte() : " ";
    std::string r;
    for (std::size_t k = 0; k < l.valeurs.size(); ++k) {
        if (k) r += sep;
        r += l.valeurs[k];
    }
    return {args[0].classe == Classe::Chaine ? Valeur::chaine(r) : Valeur::texte(r)};
}

FONCTION(fnStrtok) {
    INUTILISE
    exigerArguments(args, 1, 2, "strtok");
    std::string texte = args[0].versTexte();
    std::string delim = args.size() > 1 ? args[1].versTexte() : " \t\n\r\f\v";
    std::size_t debut = texte.find_first_not_of(delim);
    if (debut == std::string::npos) return {Valeur::texte(""), Valeur::texte("")};
    std::size_t fin = texte.find_first_of(delim, debut);
    std::string jeton = texte.substr(debut, fin == std::string::npos ? std::string::npos
                                                                     : fin - debut);
    std::string reste = fin == std::string::npos ? "" : texte.substr(fin);
    if (nargout >= 2) return {Valeur::texte(jeton), Valeur::texte(reste)};
    return {Valeur::texte(jeton)};
}

FONCTION(fnFliplrTexte) {
    INUTILISE
    ListeTextes l = listeDe(args[0]);
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        std::reverse(s.begin(), s.end());
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

FONCTION(fnBlanks) {
    INUTILISE
    int n = (int)argScalaire(args, 0, "blanks");
    return {Valeur::texte(std::string((std::size_t)std::max(0, n), ' '))};
}

// MATLAB : « newline » rend le caractere de fin de ligne, char(10). Il
// evite d'ecrire sprintf('\n') pour une seule lettre.
FONCTION(fnNewline) {
    INUTILISE
    return {Valeur::texte(std::string(1, '\n'))};
}

FONCTION(fnStrjust) {
    INUTILISE
    return {args[0]};
}

FONCTION(fnContains) {
    INUTILISE
    exigerArguments(args, 2, 4, "contains");
    ListeTextes l = listeDe(args[0]);
    ListeTextes m = listeDe(args[1]);
    bool ignorerCasse = false;
    for (std::size_t k = 2; k + 1 < args.size(); k += 2)
        if (minuscules(args[k].versTexte()) == "ignorecase") ignorerCasse = args[k + 1].vrai();
    std::vector<bool> r;
    if (l.valeurs.empty()) return {videLogique(l)};
    for (auto s : l.valeurs) {
        bool trouve = false;
        for (auto p : m.valeurs) {
            std::string a = ignorerCasse ? minuscules(s) : s;
            std::string b = ignorerCasse ? minuscules(p) : p;
            if (a.find(b) != std::string::npos) trouve = true;
        }
        r.push_back(trouve);
    }
    return {logiqueComme(l, r)};
}

FONCTION(fnStartsWith) {
    INUTILISE
    exigerArguments(args, 2, 4, "startsWith");
    ListeTextes l = listeDe(args[0]);
    ListeTextes m = listeDe(args[1]);
    std::vector<bool> r;
    for (auto& s : l.valeurs) {
        bool trouve = false;
        for (auto& p : m.valeurs)
            if (s.size() >= p.size() && s.compare(0, p.size(), p) == 0) trouve = true;
        r.push_back(trouve);
    }
    return {logiqueComme(l, r)};
}

FONCTION(fnEndsWith) {
    INUTILISE
    exigerArguments(args, 2, 4, "endsWith");
    ListeTextes l = listeDe(args[0]);
    ListeTextes m = listeDe(args[1]);
    std::vector<bool> r;
    for (auto& s : l.valeurs) {
        bool trouve = false;
        for (auto& p : m.valeurs)
            if (s.size() >= p.size() && s.compare(s.size() - p.size(), p.size(), p) == 0)
                trouve = true;
        r.push_back(trouve);
    }
    return {logiqueComme(l, r)};
}

FONCTION(fnStrlength) {
    INUTILISE
    exigerArguments(args, 1, 1, "strlength");
    ListeTextes l = listeDe(args[0]);
    Valeur r = Valeur::matriceDims(l.multiple ? l.dims : Dims{1, 1});
    r.re.resize(l.valeurs.size());
    for (std::size_t k = 0; k < l.valeurs.size(); ++k) r.re[k] = (double)l.valeurs[k].size();
    return {r};
}

FONCTION(fnPad) {
    INUTILISE
    exigerArguments(args, 1, 3, "pad");
    exigerSansObjet(args[0], "pad");
    if (args.size() > 1) exigerNumerique(args[1], "pad");
    ListeTextes l = listeDe(args[0]);
    std::size_t largeur = 0;
    if (args.size() > 1) largeur = (std::size_t)argTaille(args[1].scal(), "pad");
    else
        for (auto& s : l.valeurs) largeur = std::max(largeur, s.size());
    std::vector<std::string> r;
    for (auto s : l.valeurs) {
        while (s.size() < largeur) s += ' ';
        r.push_back(s);
    }
    return {reconstituer(l, r)};
}

// --------------------------------------------------------- expressions rég.

// Retire les noms de groupe « (?<nom>... ) » du motif et rend, pour
// chacun, le rang du groupe capturant correspondant. La bibliotheque
// standard ne connait pas cette notation — elle vient de Perl et MATLAB
// l'emploie —, mais un groupe nomme n'est qu'un groupe capturant qui
// porte une etiquette : il suffit de retenir l'etiquette et de la rendre
// au motif sans elle.
std::string extraireNomsGroupes(const std::string& motif,
                                std::vector<std::pair<std::string, int>>& noms) {
    noms.clear();
    std::string sortie;
    int rangCapturant = 0;
    for (std::size_t k = 0; k < motif.size(); ++k) {
        // Ce qui est echappe n'ouvre rien.
        if (motif[k] == '\\' && k + 1 < motif.size()) {
            sortie += motif[k];
            sortie += motif[k + 1];
            ++k;
            continue;
        }
        if (motif[k] != '(') {
            sortie += motif[k];
            continue;
        }
        if (k + 2 < motif.size() && motif[k + 1] == '?' && motif[k + 2] == '<' &&
            k + 3 < motif.size() && motif[k + 3] != '=' && motif[k + 3] != '!') {
            std::size_t ferme = motif.find('>', k + 3);
            if (ferme != std::string::npos) {
                ++rangCapturant;
                noms.push_back({motif.substr(k + 3, ferme - k - 3), rangCapturant});
                sortie += '(';
                k = ferme;
                continue;
            }
        }
        // « (?: », « (?= », « (?! » ne capturent pas ; « ( » seul si.
        if (!(k + 1 < motif.size() && motif[k + 1] == '?')) ++rangCapturant;
        sortie += motif[k];
    }
    return sortie;
}

std::regex compilerMotif(const std::string& motif, bool ignorerCasse) {
    auto drapeaux = std::regex::ECMAScript;
    if (ignorerCasse) drapeaux |= std::regex::icase;
    std::vector<std::pair<std::string, int>> noms;
    std::string nu = extraireNomsGroupes(motif, noms);
    try {
        return std::regex(nu, drapeaux);
    } catch (const std::regex_error& e) {
        // Un motif valide que le moteur ne sait pas lire n'est pas un
        // motif fautif : le dire autrement enverrait chercher une faute
        // qui n'existe pas. La regression arriere en est le seul cas.
        if (nu.find("(?<=") != std::string::npos || nu.find("(?<!") != std::string::npos)
            erreur("MATLAB:regexp:unsupported",
                   "La regression arriere « (?<= » n'est pas traitee par le moteur "
                   "d'expressions regulieres employe ici.");
        erreur("MATLAB:regexp:badPattern",
               std::string("Invalid regular expression: ") + e.what());
    }
}

std::vector<Valeur> regexpInterne(std::vector<Valeur>& args, int nargout, bool ignorerCasse) {
    exigerArguments(args, 2, 0, "regexp");
    std::string texte = args[0].versTexte();
    std::string motif = args[1].versTexte();
    std::vector<std::string> options;
    for (std::size_t k = 2; k < args.size(); ++k) options.push_back(minuscules(args[k].versTexte()));
    bool uneFois = std::find(options.begin(), options.end(), "once") != options.end();
    std::vector<std::pair<std::string, int>> nomsGroupes;
    extraireNomsGroupes(motif, nomsGroupes);
    std::regex re = compilerMotif(motif, ignorerCasse);

    std::vector<double> debuts, fins;
    std::vector<std::string> correspondances;
    std::vector<Valeur> jetons;
    std::vector<Valeur> nomsTrouves;
    auto debut = std::sregex_iterator(texte.begin(), texte.end(), re);
    auto fin = std::sregex_iterator();
    for (auto i = debut; i != fin; ++i) {
        const std::smatch& m = *i;
        debuts.push_back((double)(m.position(0) + 1));
        fins.push_back((double)(m.position(0) + m.length(0)));
        correspondances.push_back(m.str(0));
        Valeur groupe = Valeur::celluleDims({1, (int)(m.size() > 1 ? m.size() - 1 : 0)});
        for (std::size_t g = 1; g < m.size(); ++g)
            groupe.cellules[g - 1] = Valeur::texte(m[g].matched ? m.str(g) : "");
        jetons.push_back(groupe);
        // Un groupe nomme donne un champ ; « names » n'etait qu'une
        // structure vide, alors que l'aide la promettait remplie.
        Valeur nomme = Valeur::structureVide();
        for (const auto& nc : nomsGroupes) {
            std::size_t g = (std::size_t)nc.second;
            nomme.poserChamp(nc.first,
                             Valeur::texte(g < m.size() && m[g].matched ? m.str(g) : ""));
        }
        nomsTrouves.push_back(nomme);
        if (uneFois) break;
    }

    auto celluleDeTextes = [&](const std::vector<std::string>& v) {
        Valeur c = Valeur::celluleDims({1, (int)v.size()});
        for (std::size_t k = 0; k < v.size(); ++k) c.cellules[k] = Valeur::texte(v[k]);
        return c;
    };

    // Ordre par défaut des sorties : start, end, te, match, tokens, names, split
    std::vector<Valeur> sorties;
    std::vector<std::string> demandes;
    for (const auto& o : options)
        if (o == "match" || o == "tokens" || o == "start" || o == "end" || o == "names" ||
            o == "split")
            demandes.push_back(o);
    if (demandes.empty()) demandes = {"start", "end", "tokenextents", "match", "tokens"};

    for (const auto& d : demandes) {
        if (d == "start") {
            if (uneFois)
                sorties.push_back(debuts.empty() ? Valeur::vide()
                                                 : Valeur::scalaire(debuts[0]));
            else sorties.push_back(Valeur::ligne(debuts));
        } else if (d == "end") {
            if (uneFois)
                sorties.push_back(fins.empty() ? Valeur::vide() : Valeur::scalaire(fins[0]));
            else sorties.push_back(Valeur::ligne(fins));
        } else if (d == "match") {
            if (uneFois)
                sorties.push_back(Valeur::texte(correspondances.empty() ? ""
                                                                        : correspondances[0]));
            else sorties.push_back(celluleDeTextes(correspondances));
        } else if (d == "tokens") {
            if (uneFois)
                sorties.push_back(jetons.empty() ? Valeur::celluleDims({1, 0}) : jetons[0]);
            else {
                Valeur c = Valeur::celluleDims({1, (int)jetons.size()});
                for (std::size_t k = 0; k < jetons.size(); ++k) c.cellules[k] = jetons[k];
                sorties.push_back(c);
            }
        } else if (d == "split") {
            std::vector<std::string> morceaux;
            std::size_t precedent = 0;
            for (std::size_t k = 0; k < debuts.size(); ++k) {
                morceaux.push_back(texte.substr(precedent, (std::size_t)debuts[k] - 1 -
                                                               precedent));
                precedent = (std::size_t)fins[k];
            }
            morceaux.push_back(texte.substr(precedent));
            sorties.push_back(celluleDeTextes(morceaux));
        } else if (d == "names") {
            // MATLAB rend une structure par correspondance, reunies en un
            // tableau de structures ; une seule correspondance rend une
            // structure simple.
            if (nomsTrouves.empty()) sorties.push_back(Valeur::structureVide());
            else if (uneFois || nomsTrouves.size() == 1) sorties.push_back(nomsTrouves[0]);
            else {
                sorties.push_back(concatener(nomsTrouves, 2));
            }
        } else {
            sorties.push_back(Valeur::structureVide());
        }
        if ((int)sorties.size() >= std::max(1, nargout)) break;
    }
    return sorties;
}

FONCTION(fnRegexp) {
    INUTILISE
    return regexpInterne(args, nargout, false);
}
FONCTION(fnRegexpi) {
    INUTILISE
    return regexpInterne(args, nargout, true);
}

FONCTION(fnRegexprep) {
    INUTILISE
    exigerArguments(args, 3, 0, "regexprep");
    ListeTextes l = listeDe(args[0]);
    std::string motif = args[1].versTexte();
    std::string remplacement = args[2].versTexte();
    bool ignorerCasse = false;
    bool uneFois = false;
    for (std::size_t k = 3; k < args.size(); ++k) {
        std::string o = minuscules(args[k].versTexte());
        if (o == "ignorecase") ignorerCasse = true;
        if (o == "once") uneFois = true;
    }
    // MATLAB note les groupes « $1 », comme ECMAScript.
    std::regex re = compilerMotif(motif, ignorerCasse);
    std::vector<std::string> r;
    for (const auto& s : l.valeurs) {
        auto drapeaux = uneFois ? std::regex_constants::format_first_only
                                : std::regex_constants::format_default;
        r.push_back(std::regex_replace(s, re, remplacement, drapeaux));
    }
    return {reconstituer(l, r)};
}

// ------------------------------------------------------------- conversions

FONCTION(fnCellstr) {
    INUTILISE
    exigerArguments(args, 1, 1, "cellstr");
    ListeTextes l = listeDe(args[0]);
    Valeur r = Valeur::celluleDims({(int)l.valeurs.size(), 1});
    for (std::size_t k = 0; k < l.valeurs.size(); ++k) {
        std::string s = l.valeurs[k];
        while (!s.empty() && s.back() == ' ') s.pop_back();
        r.cellules[k] = Valeur::texte(s);
    }
    return {r};
}

FONCTION(fnIscellstr) {
    INUTILISE
    if (args[0].classe != Classe::Cellule) return {Valeur::booleen(false)};
    for (const auto& c : args[0].cellules)
        if (c.classe != Classe::Caractere) return {Valeur::booleen(false)};
    return {Valeur::booleen(true)};
}

FONCTION(fnString) {
    INUTILISE
    exigerSansObjet(args[0], "string");
    if (args.empty()) return {Valeur::videClasse(Classe::Chaine)};
    const Valeur& v = args[0];
    if (v.classe == Classe::Chaine) return {v};
    if (v.classe == Classe::Caractere) return {Valeur::chaine(v.versTexte())};
    if (v.classe == Classe::Cellule) {
        Valeur r;
        r.classe = Classe::Chaine;
        r.dims = v.dims;
        for (const auto& c : v.cellules) r.chaines.push_back(c.versTexte());
        return {r};
    }
    Valeur r;
    r.classe = Classe::Chaine;
    r.dims = v.dims;
    for (std::size_t k = 0; k < v.nelem(); ++k) {
        double x = v.re[k];
        r.chaines.push_back(x == std::floor(x) && std::fabs(x) < 1e15 ? formater("%.0f", x)
                                                                      : formater("%g", x));
    }
    return {r};
}

// « std::isspace » et ses voisines n'admettent qu'une valeur representable
// en « unsigned char », ou EOF. « isletter(NaN) » leur passait INT_MIN, et
// la table de la bibliotheque C etait lue hors de ses bornes.
static int pointDeCode(double x) {
    if (!(x >= 0.0 && x <= 255.0)) return 0;
    return (int)x;
}

FONCTION(fnIsspace) {
    INUTILISE
    exigerNumerique(args[0], "isspace");
    Valeur v = args[0];
    Valeur r = Valeur::matriceDims(v.dims);
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < v.nelem(); ++k)
        r.re[k] = std::isspace(pointDeCode(v.re[k])) ? 1 : 0;
    return {r};
}
FONCTION(fnIsletter) {
    INUTILISE
    exigerNumerique(args[0], "isletter");
    Valeur v = args[0];
    Valeur r = Valeur::matriceDims(v.dims);
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < v.nelem(); ++k)
        r.re[k] = std::isalpha(pointDeCode(v.re[k])) ? 1 : 0;
    return {r};
}
FONCTION(fnIsdigitTexte) {
    INUTILISE
    exigerNumerique(args[0], "isdigit");
    Valeur v = args[0];
    Valeur r = Valeur::matriceDims(v.dims);
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < v.nelem(); ++k)
        r.re[k] = std::isdigit(pointDeCode(v.re[k])) ? 1 : 0;
    return {r};
}

FONCTION(fnStrvcat) {
    INUTILISE
    std::vector<Valeur> lignes;
    std::size_t largeur = 0;
    for (const auto& a : args) {
        ListeTextes l = listeDe(a);
        for (auto& s : l.valeurs) largeur = std::max(largeur, s.size());
    }
    for (const auto& a : args) {
        ListeTextes l = listeDe(a);
        for (auto s : l.valeurs) {
            while (s.size() < largeur) s += ' ';
            lignes.push_back(Valeur::texte(s));
        }
    }
    if (lignes.empty()) return {Valeur::texte("")};
    return {concatener(lignes, 0)};
}

FONCTION(fnSprintfChaine) {
    INUTILISE
    exigerArguments(args, 1, 0, "compose");
    std::string s = formatMatlab(args[0].versTexte(), args, 1);
    return {Valeur::chaine(s)};
}

// Tri « naturel » : les suites de chiffres se comparent comme des
// nombres, le reste caractere par caractere. « fichier2 » passe ainsi
// avant « fichier10 », que l'ordre alphabetique met a l'envers.
int comparerNaturel(const std::string& a, const std::string& b) {
    std::size_t i = 0, j = 0;
    while (i < a.size() && j < b.size()) {
        bool chiffreA = std::isdigit((unsigned char)a[i]) != 0;
        bool chiffreB = std::isdigit((unsigned char)b[j]) != 0;
        if (chiffreA && chiffreB) {
            // Les zeros de tete ne comptent pas dans la valeur.
            std::size_t da = i, db = j;
            while (da < a.size() && a[da] == '0') ++da;
            while (db < b.size() && b[db] == '0') ++db;
            std::size_t fa = da, fb = db;
            while (fa < a.size() && std::isdigit((unsigned char)a[fa])) ++fa;
            while (fb < b.size() && std::isdigit((unsigned char)b[fb])) ++fb;
            if (fa - da != fb - db) return (fa - da) < (fb - db) ? -1 : 1;
            for (std::size_t k = 0; k < fa - da; ++k)
                if (a[da + k] != b[db + k]) return a[da + k] < b[db + k] ? -1 : 1;
            i = fa;
            j = fb;
            continue;
        }
        if (a[i] != b[j]) return (unsigned char)a[i] < (unsigned char)b[j] ? -1 : 1;
        ++i;
        ++j;
    }
    if (i < a.size()) return 1;
    if (j < b.size()) return -1;
    return 0;
}

FONCTION(fnNatsort) {
    INUTILISE
    exigerArguments(args, 1, 1, "natsort");
    ListeTextes l = listeDe(args[0]);
    std::vector<std::size_t> ordre(l.valeurs.size());
    for (std::size_t k = 0; k < ordre.size(); ++k) ordre[k] = k;
    std::stable_sort(ordre.begin(), ordre.end(), [&](std::size_t x, std::size_t y) {
        return comparerNaturel(l.valeurs[x], l.valeurs[y]) < 0;
    });
    std::vector<Valeur> tries;
    for (std::size_t k : ordre) tries.push_back(Valeur::texte(l.valeurs[k]));
    if (nargout >= 2) {
        std::vector<double> indices;
        for (std::size_t k : ordre) indices.push_back((double)(k + 1));
        return {Valeur::celluleLigne(tries), Valeur::ligne(indices)};
    }
    return {Valeur::celluleLigne(tries)};
}


// --- espace de noms matlab.lang ------------------------------------------

// Rend un identifiant valide : lettres, chiffres et « _ », premier caractère
// alphabétique. Les autres caractères deviennent « _ », et un nom vide ou
// commençant par un chiffre reçoit le préfixe « x », comme le documente
// matlab.lang.makeValidName.
std::string rendreNomValide(const std::string& entree) {
    std::string s;
    for (char c : entree) {
        if (std::isalnum((unsigned char)c) || c == '_') s += c;
        else if (!s.empty() || true) s += '_';
    }
    // Un blanc suivi d'une lettre donne une majuscule dans MATLAB ; on garde
    // ici la substitution simple par « _ », plus lisible et réversible.
    while (!s.empty() && s.back() == '_' && s.size() > 1 && entree.back() != '_')
        s.pop_back();
    if (s.empty()) s = "x";
    if (!std::isalpha((unsigned char)s[0])) s = "x" + s;
    if (s.size() > 63) s = s.substr(0, 63);
    return s;
}

FONCTION(fnMakeValidName) {
    INUTILISE
    exigerArguments(args, 1, 3, "matlab.lang.makeValidName");
    const Valeur& v = args[0];
    if (v.classe == Classe::Cellule) {
        Valeur r = v;
        for (std::size_t k = 0; k < r.cellules.size(); ++k)
            r.cellules[k] = Valeur::texte(rendreNomValide(r.cellules[k].versTexte()));
        return {r};
    }
    if (v.classe == Classe::Chaine) {
        Valeur r = v;
        for (auto& c : r.chaines) c = rendreNomValide(c);
        return {r};
    }
    return {Valeur::texte(rendreNomValide(v.versTexte()))};
}

FONCTION(fnMakeUniqueStrings) {
    INUTILISE
    exigerArguments(args, 1, 3, "matlab.lang.makeUniqueStrings");
    std::vector<std::string> noms;
    bool cellule = args[0].classe == Classe::Cellule;
    if (cellule)
        for (const auto& c : args[0].cellules) noms.push_back(c.versTexte());
    else
        noms.push_back(args[0].versTexte());
    std::set<std::string> vus;
    for (auto& n : noms) {
        if (!vus.count(n)) { vus.insert(n); continue; }
        int k = 1;
        std::string candidat;
        do {
            candidat = n + "_" + std::to_string(k++);
        } while (vus.count(candidat));
        n = candidat;
        vus.insert(n);
    }
    if (!cellule) return {Valeur::texte(noms[0])};
    std::vector<Valeur> cases;
    for (const auto& n : noms) cases.push_back(Valeur::texte(n));
    Valeur r = Valeur::celluleLigne(cases);
    r.dims = args[0].dims;
    return {r};
}

FONCTION(fnIsValidName) {
    INUTILISE
    exigerArguments(args, 1, 1, "isvarname");
    std::string s = args[0].versTexte();
    bool ok = !s.empty() && (std::isalpha((unsigned char)s[0]) != 0);
    for (char c : s)
        if (!std::isalnum((unsigned char)c) && c != '_') ok = false;
    static const std::set<std::string> motsCles = {
        "break", "case", "catch", "classdef", "continue", "else", "elseif", "end",
        "for", "function", "global", "if", "otherwise", "parfor", "persistent",
        "return", "spmd", "switch", "try", "while"};
    if (motsCles.count(s)) ok = false;
    return {Valeur::booleen(ok)};
}

}  // namespace

void enregistrerTexte(Interpreteur& it) {
    it.enregistrer("upper", fnUpper, "texte", "upper  Passe en majuscules.");
    it.enregistrer("toupper", fnUpper, "texte", "toupper  Passe en majuscules.");
    it.enregistrer("lower", fnLower, "texte", "lower  Passe en minuscules.");
    it.enregistrer("tolower", fnLower, "texte", "tolower  Passe en minuscules.");
    it.enregistrer("strtrim", fnStrtrim, "texte", "strtrim  Retire les blancs aux deux bouts.");
    it.enregistrer("deblank", fnDeblank, "texte", "deblank  Retire les blancs finaux.");
    it.enregistrer("strcat", fnStrcat, "texte", "strcat  Concatene des textes.");
    it.enregistrer("strcmp", fnStrcmp, "texte", "strcmp  Comparaison exacte.");
    it.enregistrer("strcmpi", fnStrcmpi, "texte", "strcmpi  Comparaison sans la casse.");
    it.enregistrer("strncmp", fnStrncmp, "texte", "strncmp  Comparaison des n premiers.");
    it.enregistrer("strncmpi", fnStrncmpi, "texte",
                   "strncmpi  Comparaison des n premiers, sans la casse.");
    it.enregistrer("strfind", fnStrfind, "texte", "strfind  Positions d'un motif.");
    it.enregistrer("strrep", fnStrrep, "texte", "strrep  Remplace un motif.");
    it.enregistrer("strsplit", fnStrsplit, "texte", "strsplit  Decoupe selon un separateur.");
    it.enregistrer("strjoin", fnStrjoin, "texte", "strjoin  Assemble avec un separateur.");
    it.enregistrer("strtok", fnStrtok, "texte", "strtok  Premier jeton et reste.");
    it.enregistrer("reverse", fnFliplrTexte, "texte", "reverse  Inverse un texte.");
    it.enregistrer("blanks", fnBlanks, "texte", "blanks  Chaine de n espaces.");
    it.enregistrer("newline", fnNewline, "texte", "newline  Caractere de fin de ligne.");
    it.enregistrer("strjust", fnStrjust, "texte", "strjust  Justifie un tableau de caracteres.");
    it.enregistrer("contains", fnContains, "texte", "contains  Le texte contient-il le motif.");
    it.enregistrer("startsWith", fnStartsWith, "texte", "startsWith  Commence par le motif.");
    it.enregistrer("endsWith", fnEndsWith, "texte", "endsWith  Finit par le motif.");
    it.enregistrer("strlength", fnStrlength, "texte", "strlength  Longueur de chaque texte.");
    it.enregistrer("pad", fnPad, "texte", "pad  Complete par des espaces.");
    it.enregistrer("regexp", fnRegexp, "texte", "regexp  Expression reguliere.");
    it.enregistrer("regexpi", fnRegexpi, "texte", "regexpi  Expression reguliere, sans la casse.");
    it.enregistrer("regexprep", fnRegexprep, "texte", "regexprep  Remplacement par motif.");
    it.enregistrer("cellstr", fnCellstr, "texte", "cellstr  Vers cellule de textes.");
    it.enregistrer("iscellstr", fnIscellstr, "texte", "iscellstr  Cellule de textes ?");
    it.enregistrer("string", fnString, "texte", "string  Vers tableau string.");
    it.enregistrer("isspace", fnIsspace, "texte", "isspace  Caracteres blancs.");
    it.enregistrer("isletter", fnIsletter, "texte", "isletter  Caracteres alphabetiques.");
    it.enregistrer("isdigit", fnIsdigitTexte, "texte", "isdigit  Caracteres numeriques.");
    it.enregistrer("strvcat", fnStrvcat, "texte", "strvcat  Empile des textes en lignes.");
    it.enregistrer("compose", fnSprintfChaine, "texte", "compose  Formate vers une string.");
    it.enregistrer("natsort", fnNatsort, "texte", "natsort  Tri naturel (identite ici).");
    it.enregistrer("strip", fnStrip, "texte", "strip  Retire les blancs ou un caractere, d'un cote ou des deux.");
    it.enregistrer("matlab.lang.makeValidName", fnMakeValidName, "texte",
                   "matlab.lang.makeValidName  Rend un identifiant valide.");
    it.enregistrer("matlab.lang.makeUniqueStrings", fnMakeUniqueStrings, "texte",
                   "matlab.lang.makeUniqueStrings  Rend les noms uniques.");
    it.enregistrer("isvarname", fnIsValidName, "texte",
                   "isvarname  Vrai si le texte est un nom de variable valide.");
    it.enregistrer("erase", fnErase, "texte", "erase  Retire toutes les occurrences d'un motif.");
    it.enregistrer("replace", fnReplace, "texte", "replace  Remplace un ou plusieurs motifs.");
    it.enregistrer("insertAfter", fnInsertAfter, "texte", "insertAfter  Insere apres chaque motif.");
    it.enregistrer("insertBefore", fnInsertBefore, "texte", "insertBefore  Insere avant chaque motif.");
    it.enregistrer("extractAfter", fnExtractAfter, "texte", "extractAfter  Ce qui suit le motif.");
    it.enregistrer("extractBefore", fnExtractBefore, "texte", "extractBefore  Ce qui precede le motif.");
    it.enregistrer("extractBetween", fnExtractBetween, "texte", "extractBetween  Ce qui separe deux motifs.");
    it.enregistrer("replaceBetween", fnReplaceBetween, "texte", "replaceBetween  Remplace ce qui est entre deux bornes.");
    it.enregistrer("eraseBetween", fnEraseBetween, "texte", "eraseBetween  Efface ce qui est entre deux bornes.");
    it.enregistrer("count", fnCount, "texte", "count  Nombre d'occurrences d'un motif.");
    it.enregistrer("matches", fnMatches, "texte", "matches  Le texte est-il exactement le motif.");
    it.enregistrer("regexptranslate", fnRegexptranslate, "texte",
                   "regexptranslate  Rend un texte utilisable comme motif.");
}

}  // namespace matlibre
