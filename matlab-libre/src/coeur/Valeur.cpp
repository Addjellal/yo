#include "matlibre/Valeur.h"

#include <algorithm>
#include <cmath>
#include <memory>

#include "matlibre/Erreur.h"

namespace matlibre {

const char* nomClasse(Classe c) {
    switch (c) {
        case Classe::Double: return "double";
        case Classe::Simple: return "single";
        case Classe::Logique: return "logical";
        case Classe::Caractere: return "char";
        case Classe::Chaine: return "string";
        case Classe::Cellule: return "cell";
        case Classe::Structure: return "struct";
        case Classe::Fonction: return "function_handle";
        case Classe::Objet: return "object";
        case Classe::Int8: return "int8";
        case Classe::Int16: return "int16";
        case Classe::Int32: return "int32";
        case Classe::Int64: return "int64";
        case Classe::UInt8: return "uint8";
        case Classe::UInt16: return "uint16";
        case Classe::UInt32: return "uint32";
        case Classe::UInt64: return "uint64";
    }
    return "double";
}

bool classeEntiere(Classe c) {
    switch (c) {
        case Classe::Int8: case Classe::Int16: case Classe::Int32: case Classe::Int64:
        case Classe::UInt8: case Classe::UInt16: case Classe::UInt32: case Classe::UInt64:
            return true;
        default: return false;
    }
}

bool classeNumerique(Classe c) {
    return c == Classe::Double || c == Classe::Simple || classeEntiere(c);
}

double borneBasse(Classe c) {
    switch (c) {
        case Classe::Int8: return -128.0;
        case Classe::Int16: return -32768.0;
        case Classe::Int32: return -2147483648.0;
        case Classe::Int64: return -9223372036854775808.0;
        default: return 0.0;
    }
}

double borneHaute(Classe c) {
    switch (c) {
        case Classe::Int8: return 127.0;
        case Classe::Int16: return 32767.0;
        case Classe::Int32: return 2147483647.0;
        case Classe::Int64: return 9223372036854775807.0;
        case Classe::UInt8: return 255.0;
        case Classe::UInt16: return 65535.0;
        case Classe::UInt32: return 4294967295.0;
        case Classe::UInt64: return 18446744073709551615.0;
        default: return 0.0;
    }
}

double saturer(double v, Classe c) {
    if (!classeEntiere(c)) {
        if (c == Classe::Simple) return (double)(float)v;
        return v;
    }
    if (std::isnan(v)) return 0.0;
    double r = (v < 0) ? -std::floor(-v + 0.5) : std::floor(v + 0.5);
    // MATLAB arrondit au plus loin de zéro pour les demi-entiers : c'est ce
    // que fait floor(|v|+0.5) ci-dessus.
    double lo = borneBasse(c), hi = borneHaute(c);
    if (r < lo) return lo;
    if (r > hi) return hi;
    return r;
}

std::size_t produitDims(const Dims& d) {
    std::size_t n = 1;
    for (int x : d) {
        if (x < 0) return 0;
        n *= (std::size_t)x;
    }
    return d.empty() ? 0 : n;
}

Dims dimsDe(int l, int c) { return Dims{l, c}; }

bool memeDims(const Dims& a, const Dims& b) {
    Dims x = a, y = b;
    while (x.size() > 2 && x.back() == 1) x.pop_back();
    while (y.size() > 2 && y.back() == 1) y.pop_back();
    return x == y;
}

std::string texteDims(const Dims& d) {
    std::string s;
    for (std::size_t i = 0; i < d.size(); ++i) {
        if (i) s += "x";
        s += std::to_string(d[i]);
    }
    return s;
}

// ---------------------------------------------------------------- fabriques

Valeur Valeur::scalaire(double v) {
    Valeur x;
    x.dims = {1, 1};
    x.re = {v};
    return x;
}

Valeur Valeur::complexe(double r, double i) {
    Valeur x;
    x.dims = {1, 1};
    x.re = {r};
    x.im = {i};
    return x;
}

Valeur Valeur::booleen(bool b) {
    Valeur x;
    x.classe = Classe::Logique;
    x.dims = {1, 1};
    x.re = {b ? 1.0 : 0.0};
    return x;
}

Valeur Valeur::vide() {
    Valeur x;
    x.dims = {0, 0};
    return x;
}

Valeur Valeur::videClasse(Classe c) {
    Valeur x;
    x.classe = c;
    x.dims = {0, 0};
    if (c == Classe::Structure) x.st = std::make_shared<ChampsStructure>();
    return x;
}

Valeur Valeur::texte(const std::string& s) {
    Valeur x;
    x.classe = Classe::Caractere;
    x.dims = {s.empty() ? 0 : 1, (int)s.size()};
    x.re.reserve(s.size());
    for (unsigned char c : s) x.re.push_back((double)c);
    return x;
}

Valeur Valeur::chaine(const std::string& s) {
    Valeur x;
    x.classe = Classe::Chaine;
    x.dims = {1, 1};
    x.chaines = {s};
    return x;
}

Valeur Valeur::matrice(int l, int c, double remplissage) {
    Valeur x;
    x.dims = {l, c};
    x.re.assign((std::size_t)std::max(0, l) * (std::size_t)std::max(0, c), remplissage);
    return x;
}

Valeur Valeur::matriceDims(const Dims& d, double remplissage) {
    Valeur x;
    x.dims = d.empty() ? Dims{0, 0} : d;
    x.re.assign(produitDims(x.dims), remplissage);
    return x;
}

Valeur Valeur::ligne(const std::vector<double>& v) {
    Valeur x;
    x.dims = {v.empty() ? 0 : 1, (int)v.size()};
    x.re = v;
    return x;
}

Valeur Valeur::colonne(const std::vector<double>& v) {
    Valeur x;
    x.dims = {(int)v.size(), v.empty() ? 0 : 1};
    x.re = v;
    return x;
}

Valeur Valeur::celluleDims(const Dims& d) {
    Valeur x;
    x.classe = Classe::Cellule;
    x.dims = d.empty() ? Dims{0, 0} : d;
    x.cellules.assign(produitDims(x.dims), Valeur::vide());
    return x;
}

Valeur Valeur::celluleLigne(const std::vector<Valeur>& v) {
    Valeur x;
    x.classe = Classe::Cellule;
    x.dims = {v.empty() ? 0 : 1, (int)v.size()};
    x.cellules = v;
    return x;
}

Valeur Valeur::structureVide() {
    Valeur x;
    x.classe = Classe::Structure;
    x.dims = {1, 1};
    x.st = std::make_shared<ChampsStructure>();
    return x;
}

Valeur Valeur::poignee(std::shared_ptr<Fonction> f) {
    Valeur x;
    x.classe = Classe::Fonction;
    x.dims = {1, 1};
    x.fn = std::move(f);
    return x;
}

// ------------------------------------------------------------ interrogation

std::size_t Valeur::nelem() const {
    if (classe == Classe::Structure || classe == Classe::Objet) return produitDims(dims);
    return produitDims(dims);
}

int Valeur::ncolonnes() const {
    if (dims.size() < 2) return 0;
    std::size_t n = 1;
    for (std::size_t i = 1; i < dims.size(); ++i) n *= (std::size_t)dims[i];
    return (int)n;
}

bool Valeur::estVecteur() const {
    return dims.size() == 2 && (dims[0] == 1 || dims[1] == 1) && nelem() >= 1;
}

double Valeur::scal() const {
    if (classe == Classe::Chaine) {
        if (chaines.empty()) erreur("MATLAB:badsubscript", "Index exceeds array bounds.");
        return std::atof(chaines[0].c_str());
    }
    if (re.empty()) erreur("MATLAB:badsubscript", "Index exceeds the number of array elements.");
    return re[0];
}

double Valeur::scalIm() const { return im.empty() ? 0.0 : im[0]; }

bool Valeur::vrai() const {
    if (classe == Classe::Cellule)
        erreur("MATLAB:invalidConversion",
               "Conversion to logical from cell is not possible.");
    if (classe == Classe::Chaine) {
        if (chaines.empty()) return false;
        for (const auto& s : chaines)
            if (s.empty()) return false;
        return true;
    }
    if (re.empty()) return false;
    for (std::size_t i = 0; i < re.size(); ++i) {
        double m = re[i];
        double mi = im.empty() ? 0.0 : im[i];
        if (m == 0.0 && mi == 0.0) return false;
        if (std::isnan(m)) return false;
    }
    return true;
}

std::string Valeur::versTexte() const {
    if (classe == Classe::Chaine) return chaines.empty() ? std::string() : chaines[0];
    std::string s;
    s.reserve(re.size());
    for (double d : re) s.push_back((char)(int)d);
    return s;
}

std::string Valeur::classeNom() const {
    if (classe == Classe::Objet) return nomObjet;
    return nomClasse(classe);
}

void Valeur::compacter() {
    if (im.empty()) return;
    for (double v : im)
        if (v != 0.0) return;
    im.clear();
}

void Valeur::normaliserDims() {
    while (dims.size() > 2 && dims.back() == 1) dims.pop_back();
    if (dims.size() < 2) dims.resize(2, 1);
}

void Valeur::redimensionner(const Dims& d) {
    dims = d;
    normaliserDims();
}

void Valeur::assurerImaginaire() {
    if (im.size() != re.size()) im.assign(re.size(), 0.0);
}

void Valeur::assurerTaille(std::size_t n) {
    if (re.size() < n) re.resize(n, 0.0);
    if (!im.empty() && im.size() < n) im.resize(n, 0.0);
}

const std::vector<std::string>& Valeur::champs() const {
    static const std::vector<std::string> vide;
    return st ? st->ordre : vide;
}

bool Valeur::aChamp(const std::string& nom) const {
    return st && st->champs.count(nom) > 0;
}

Valeur Valeur::champ(const std::string& nom, std::size_t idx) const {
    if (!st) erreur("MATLAB:nonStrucReference", "Field reference on a non-structure.");
    auto it = st->champs.find(nom);
    if (it == st->champs.end())
        erreur("MATLAB:nonExistentField",
               "Unrecognized field name \"" + nom + "\".");
    if (idx >= it->second.size()) return Valeur::vide();
    return it->second[idx];
}

void Valeur::detacherStructure() {
    if (!st) {
        st = std::make_shared<ChampsStructure>();
        return;
    }
    // Une classe « handle » partage son état : ses copies doivent voir la
    // modification, on ne détache donc pas.
    if (poigneeObjet) return;
    if (st.use_count() > 1) st = std::make_shared<ChampsStructure>(*st);
}

void Valeur::poserChamp(const std::string& nom, Valeur v, std::size_t idx) {
    detacherStructure();
    if (classe != Classe::Objet) classe = Classe::Structure;
    if (produitDims(dims) == 0) dims = {1, 1};
    std::size_t n = produitDims(dims);
    if (idx >= n) {
        n = idx + 1;
        dims = {1, (int)n};
        for (auto& kv : st->champs) kv.second.resize(n, Valeur::vide());
    }
    auto it = st->champs.find(nom);
    if (it == st->champs.end()) {
        st->ordre.push_back(nom);
        st->champs[nom] = std::vector<Valeur>(n, Valeur::vide());
        it = st->champs.find(nom);
    }
    if (it->second.size() < n) it->second.resize(n, Valeur::vide());
    it->second[idx] = std::move(v);
}

void Valeur::retirerChamp(const std::string& nom) {
    if (!st) return;
    detacherStructure();
    st->champs.erase(nom);
    st->ordre.erase(std::remove(st->ordre.begin(), st->ordre.end(), nom), st->ordre.end());
}

Valeur versDouble(const Valeur& v) {
    Valeur r = v;
    if (r.classe == Classe::Chaine) {
        Valeur t = Valeur::texte(r.chaines.empty() ? std::string() : r.chaines[0]);
        r = t;
    }
    r.classe = Classe::Double;
    r.chaines.clear();
    return r;
}

Valeur appliquerClasse(Valeur v, Classe c) {
    if (c == Classe::Logique) {
        for (auto& x : v.re) x = (x != 0.0) ? 1.0 : 0.0;
        v.im.clear();
    } else if (classeEntiere(c) || c == Classe::Simple) {
        for (auto& x : v.re) x = saturer(x, c);
        if (classeEntiere(c)) v.im.clear();
        else for (auto& x : v.im) x = saturer(x, c);
    }
    v.classe = c;
    return v;
}

}  // namespace matlibre
