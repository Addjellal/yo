// Texte.cpp — chaînes de caractères, tableaux de caractères et « string ».
#include <algorithm>
#include <cctype>
#include <cmath>
#include <regex>
#include <set>
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
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
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

FONCTION(fnStrsplit) {
    INUTILISE
    exigerArguments(args, 1, 2, "strsplit");
    std::string texte = args[0].versTexte();
    std::vector<std::string> separateurs;
    if (args.size() > 1) {
        if (args[1].classe == Classe::Cellule)
            for (const auto& c : args[1].cellules) separateurs.push_back(c.versTexte());
        else separateurs.push_back(args[1].versTexte());
    } else {
        separateurs.push_back(" ");
    }
    std::vector<std::string> morceaux;
    std::string courant;
    std::size_t k = 0;
    while (k < texte.size()) {
        bool coupe = false;
        for (const auto& sep : separateurs) {
            if (!sep.empty() && texte.compare(k, sep.size(), sep) == 0) {
                morceaux.push_back(courant);
                courant.clear();
                k += sep.size();
                coupe = true;
                break;
            }
        }
        if (!coupe) courant += texte[k++];
    }
    morceaux.push_back(courant);
    Valeur r = Valeur::celluleDims({1, (int)morceaux.size()});
    for (std::size_t i = 0; i < morceaux.size(); ++i) r.cellules[i] = Valeur::texte(morceaux[i]);
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
    ListeTextes l = listeDe(args[0]);
    std::size_t largeur = 0;
    if (args.size() > 1) largeur = (std::size_t)args[1].scal();
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

std::regex compilerMotif(const std::string& motif, bool ignorerCasse) {
    auto drapeaux = std::regex::ECMAScript;
    if (ignorerCasse) drapeaux |= std::regex::icase;
    try {
        return std::regex(motif, drapeaux);
    } catch (const std::regex_error& e) {
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

FONCTION(fnIsspace) {
    INUTILISE
    Valeur v = args[0];
    Valeur r = Valeur::matriceDims(v.dims);
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < v.nelem(); ++k)
        r.re[k] = std::isspace((int)v.re[k]) ? 1 : 0;
    return {r};
}
FONCTION(fnIsletter) {
    INUTILISE
    Valeur v = args[0];
    Valeur r = Valeur::matriceDims(v.dims);
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < v.nelem(); ++k) r.re[k] = std::isalpha((int)v.re[k]) ? 1 : 0;
    return {r};
}
FONCTION(fnIsdigitTexte) {
    INUTILISE
    Valeur v = args[0];
    Valeur r = Valeur::matriceDims(v.dims);
    r.classe = Classe::Logique;
    for (std::size_t k = 0; k < v.nelem(); ++k) r.re[k] = std::isdigit((int)v.re[k]) ? 1 : 0;
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

FONCTION(fnStrtrimNombre) {
    INUTILISE
    return {args[0]};
}

FONCTION(fnNatsort) {
    INUTILISE
    return {args[0]};
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
    it.enregistrer("fliplr_str", fnFliplrTexte, "texte", "fliplr_str  Inverse un texte.");
    it.enregistrer("reverse", fnFliplrTexte, "texte", "reverse  Inverse un texte.");
    it.enregistrer("blanks", fnBlanks, "texte", "blanks  Chaine de n espaces.");
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
    it.enregistrer("strip", fnStrtrim, "texte", "strip  Retire les blancs aux deux bouts.");
    it.enregistrer("num2str_", fnStrtrimNombre, "texte", "num2str_  Reserve.");
    it.enregistrer("matlab.lang.makeValidName", fnMakeValidName, "texte",
                   "matlab.lang.makeValidName  Rend un identifiant valide.");
    it.enregistrer("matlab.lang.makeUniqueStrings", fnMakeUniqueStrings, "texte",
                   "matlab.lang.makeUniqueStrings  Rend les noms uniques.");
    it.enregistrer("isvarname", fnIsValidName, "texte",
                   "isvarname  Vrai si le texte est un nom de variable valide.");
}

}  // namespace matlibre
