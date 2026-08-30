// FichierMat.cpp — le format MAT, tel que MathWorks le documente.
//
// Un fichier de niveau 5 tient en peu de choses : un en-tête de cent
// vingt-huit octets, puis une suite d'éléments. Chaque élément porte une
// étiquette de huit octets — un type sur quatre, une longueur sur quatre
// — et son contenu, complété jusqu'au multiple de huit suivant. Une
// variable est un élément de type miMATRIX, dont le contenu est
// lui-même une suite d'éléments : les drapeaux, les dimensions, le nom,
// puis les valeurs.
//
// Le reste n'est que la liste des types et des classes, et le soin de ne
// jamais lire au-delà de ce que la longueur annonce : un fichier abîmé ne
// doit pas faire tomber le programme.
#include "matlibre/FichierMat.h"

#include <cstdint>
#include <cstring>
#include <ctime>
#include <fstream>
#include <map>

#include "matlibre/Compression.h"
#include "matlibre/Erreur.h"
#include "matlibre/Version.h"

namespace matlibre {

namespace {

// --- types d'éléments (« mi ») ---
enum : std::uint32_t {
    miINT8 = 1, miUINT8 = 2, miINT16 = 3, miUINT16 = 4, miINT32 = 5, miUINT32 = 6,
    miSINGLE = 7, miDOUBLE = 9, miINT64 = 12, miUINT64 = 13, miMATRIX = 14,
    miCOMPRESSED = 15, miUTF8 = 16, miUTF16 = 17, miUTF32 = 18
};

// --- classes de tableaux (« mx ») ---
enum : std::uint8_t {
    mxCELL = 1, mxSTRUCT = 2, mxOBJECT = 3, mxCHAR = 4, mxSPARSE = 5, mxDOUBLE = 6,
    mxSINGLE = 7, mxINT8 = 8, mxUINT8 = 9, mxINT16 = 10, mxUINT16 = 11, mxINT32 = 12,
    mxUINT32 = 13, mxINT64 = 14, mxUINT64 = 15, mxFONCTION = 16, mxOPAQUE = 17,
    mxOBJET_NOUVEAU = 18
};

const std::uint32_t DRAPEAU_COMPLEXE = 0x0800;
const std::uint32_t DRAPEAU_GLOBAL = 0x0400;
const std::uint32_t DRAPEAU_LOGIQUE = 0x0200;

[[noreturn]] void abime(const std::string& quoi) {
    erreur("MATLAB:load:fichierAbime",
           "Unable to read the MAT-file: " + quoi);
}

std::uint8_t classeMx(Classe c) {
    switch (c) {
        case Classe::Double: return mxDOUBLE;
        case Classe::Simple: return mxSINGLE;
        case Classe::Logique: return mxUINT8;   // avec le drapeau « logique »
        case Classe::Caractere: return mxCHAR;
        case Classe::Cellule: return mxCELL;
        case Classe::Structure: return mxSTRUCT;
        // Un objet garde sa classe : le format la porte, dans la forme que
        // MATLAB employait pour ses classes avant MCOS et qu'il relit
        // toujours. La relire nous rend l'objet, et non une structure.
        case Classe::Objet: return mxOBJECT;
        case Classe::Int8: return mxINT8;
        case Classe::Int16: return mxINT16;
        case Classe::Int32: return mxINT32;
        case Classe::Int64: return mxINT64;
        case Classe::UInt8: return mxUINT8;
        case Classe::UInt16: return mxUINT16;
        case Classe::UInt32: return mxUINT32;
        case Classe::UInt64: return mxUINT64;
        default: return mxDOUBLE;
    }
}

Classe classeDepuisMx(std::uint8_t mx, bool logique) {
    if (logique) return Classe::Logique;
    switch (mx) {
        case mxSINGLE: return Classe::Simple;
        case mxCHAR: return Classe::Caractere;
        case mxCELL: return Classe::Cellule;
        case mxSTRUCT:
        case mxOBJECT: return Classe::Structure;
        case mxINT8: return Classe::Int8;
        case mxINT16: return Classe::Int16;
        case mxINT32: return Classe::Int32;
        case mxINT64: return Classe::Int64;
        case mxUINT8: return Classe::UInt8;
        case mxUINT16: return Classe::UInt16;
        case mxUINT32: return Classe::UInt32;
        case mxUINT64: return Classe::UInt64;
        default: return Classe::Double;
    }
}

// Le type d'élément qui porte les nombres d'une classe donnée. On écrit
// toujours en pleine largeur : le format autorise à rétrécir les entiers,
// mais rien ne l'exige et cela ne se relit qu'au prix d'un cas de plus.
std::uint32_t typeDonnees(Classe c) {
    switch (c) {
        case Classe::Simple: return miSINGLE;
        case Classe::Logique: return miUINT8;
        case Classe::Caractere: return miUINT16;
        case Classe::Int8: return miINT8;
        case Classe::Int16: return miINT16;
        case Classe::Int32: return miINT32;
        case Classe::Int64: return miINT64;
        case Classe::UInt8: return miUINT8;
        case Classe::UInt16: return miUINT16;
        case Classe::UInt32: return miUINT32;
        case Classe::UInt64: return miUINT64;
        default: return miDOUBLE;
    }
}

std::size_t tailleType(std::uint32_t type) {
    switch (type) {
        case miINT8: case miUINT8: case miUTF8: return 1;
        case miINT16: case miUINT16: case miUTF16: return 2;
        case miINT32: case miUINT32: case miSINGLE: case miUTF32: return 4;
        case miINT64: case miUINT64: case miDOUBLE: return 8;
        default: return 0;
    }
}

// ------------------------------------------------------------ écriture

class Ecrivain {
public:
    std::string tampon;

    void octets(const void* p, std::size_t n) {
        tampon.append((const char*)p, n);
    }
    void u16(std::uint16_t v) { octets(&v, 2); }
    void u32(std::uint32_t v) { octets(&v, 4); }
    void completer() {
        while (tampon.size() % 8) tampon.push_back('\0');
    }
};

void ecrireElement(Ecrivain& e, std::uint32_t type, const void* donnees, std::size_t octets) {
    e.u32(type);
    e.u32((std::uint32_t)octets);
    e.octets(donnees, octets);
    e.completer();
}

// Les nombres d'un tableau, convertis dans le type de sa classe.
void ecrireNombres(Ecrivain& e, Classe classe, const std::vector<double>& v) {
    std::uint32_t type = typeDonnees(classe);
    std::size_t largeur = tailleType(type);
    std::string donnees;
    donnees.resize(v.size() * largeur);
    char* p = donnees.empty() ? nullptr : &donnees[0];
    for (std::size_t k = 0; k < v.size(); ++k) {
        double x = v[k];
        switch (type) {
            case miDOUBLE: { double t = x; std::memcpy(p + k * 8, &t, 8); break; }
            case miSINGLE: { float t = (float)x; std::memcpy(p + k * 4, &t, 4); break; }
            case miINT8: { std::int8_t t = (std::int8_t)x; std::memcpy(p + k, &t, 1); break; }
            case miUINT8: { std::uint8_t t = (std::uint8_t)x; std::memcpy(p + k, &t, 1); break; }
            case miINT16: { std::int16_t t = (std::int16_t)x; std::memcpy(p + k * 2, &t, 2); break; }
            case miUINT16: { std::uint16_t t = (std::uint16_t)x; std::memcpy(p + k * 2, &t, 2); break; }
            case miINT32: { std::int32_t t = (std::int32_t)x; std::memcpy(p + k * 4, &t, 4); break; }
            case miUINT32: { std::uint32_t t = (std::uint32_t)x; std::memcpy(p + k * 4, &t, 4); break; }
            case miINT64: { std::int64_t t = (std::int64_t)x; std::memcpy(p + k * 8, &t, 8); break; }
            default: { std::uint64_t t = (std::uint64_t)x; std::memcpy(p + k * 8, &t, 8); break; }
        }
    }
    ecrireElement(e, type, donnees.data(), donnees.size());
}

void ecrireMatrice(Ecrivain& sortie, const std::string& nom, const Valeur& v, bool globale);

// Le corps d'un miMATRIX, sans son étiquette : c'est lui qu'on mesure
// avant d'écrire la longueur.
void ecrireCorpsMatrice(Ecrivain& e, const std::string& nom, const Valeur& v, bool globale) {
    const bool creux = v.estCreux();
    std::uint8_t classe = creux ? (std::uint8_t)mxSPARSE : classeMx(v.classe);
    std::uint32_t drapeaux = 0;
    if (v.estComplexe() || (creux && !v.creux->imaginaire.empty()))
        drapeaux |= DRAPEAU_COMPLEXE;
    if (globale) drapeaux |= DRAPEAU_GLOBAL;
    if (v.classe == Classe::Logique) drapeaux |= DRAPEAU_LOGIQUE;
    std::uint32_t nzmax = creux ? (std::uint32_t)v.creux->valeur.size() : 0;

    std::uint32_t motDrapeaux[2] = {drapeaux | classe, nzmax};
    ecrireElement(e, miUINT32, motDrapeaux, 8);

    Dims d = v.dims;
    while (d.size() < 2) d.push_back(1);
    std::vector<std::int32_t> dims32(d.begin(), d.end());
    ecrireElement(e, miINT32, dims32.data(), dims32.size() * 4);

    ecrireElement(e, miINT8, nom.data(), nom.size());

    // Le nom de la classe suit celui de la variable, et lui seul : c'est ce
    // qui distingue un objet d'une structure dans le format.
    if (classe == (std::uint8_t)mxOBJECT)
        ecrireElement(e, miINT8, v.nomObjet.data(), v.nomObjet.size());

    if (creux) {
        std::vector<std::int32_t> ir(v.creux->ligne.begin(), v.creux->ligne.end());
        std::vector<std::int32_t> jc(v.creux->debutColonne.begin(), v.creux->debutColonne.end());
        ecrireElement(e, miINT32, ir.data(), ir.size() * 4);
        ecrireElement(e, miINT32, jc.data(), jc.size() * 4);
        ecrireElement(e, miDOUBLE, v.creux->valeur.data(), v.creux->valeur.size() * 8);
        if (!v.creux->imaginaire.empty())
            ecrireElement(e, miDOUBLE, v.creux->imaginaire.data(),
                          v.creux->imaginaire.size() * 8);
        return;
    }

    if (v.classe == Classe::Cellule) {
        for (const Valeur& c : v.cellules) ecrireMatrice(e, "", c, false);
        return;
    }
    if (v.estStructure()) {
        std::vector<std::string> champs = v.st ? v.st->ordre : std::vector<std::string>();
        std::size_t largeur = 1;
        for (const std::string& c : champs) largeur = std::max(largeur, c.size() + 1);
        // MATLAB borne les noms de champs à soixante-quatre caractères.
        if (largeur > 64) largeur = 64;
        std::int32_t largeur32 = (std::int32_t)largeur;
        ecrireElement(e, miINT32, &largeur32, 4);
        std::string noms(champs.size() * largeur, '\0');
        for (std::size_t k = 0; k < champs.size(); ++k) {
            std::size_t n = std::min(champs[k].size(), largeur - 1);
            std::memcpy(&noms[k * largeur], champs[k].data(), n);
        }
        ecrireElement(e, miINT8, noms.data(), noms.size());
        std::size_t elements = v.nelem();
        for (std::size_t i = 0; i < elements; ++i)
            for (const std::string& c : champs) {
                const auto it = v.st->champs.find(c);
                Valeur valeur;
                if (it != v.st->champs.end() && i < it->second.size()) valeur = it->second[i];
                ecrireMatrice(e, "", valeur, false);
            }
        return;
    }
    if (v.classe == Classe::Chaine) {
        // Un tableau de chaînes n'existe pas au niveau 5 : MATLAB le range
        // dans son sous-système. On le sauve en cellule de caractères, qui
        // se relit partout, et l'on note la conversion dans l'aide.
        Valeur cellule = Valeur::celluleDims(v.dims);
        for (std::size_t k = 0; k < v.chaines.size() && k < cellule.cellules.size(); ++k)
            cellule.cellules[k] = Valeur::texte(v.chaines[k]);
        ecrireCorpsMatrice(e, nom, cellule, globale);
        return;
    }
    ecrireNombres(e, v.classe, v.re);
    if (v.estComplexe()) ecrireNombres(e, v.classe, v.im);
}

void ecrireMatrice(Ecrivain& sortie, const std::string& nom, const Valeur& v, bool globale) {
    Ecrivain corps;
    if (v.classe == Classe::Chaine) {
        Valeur cellule = Valeur::celluleDims(v.dims);
        for (std::size_t k = 0; k < v.chaines.size() && k < cellule.cellules.size(); ++k)
            cellule.cellules[k] = Valeur::texte(v.chaines[k]);
        ecrireCorpsMatrice(corps, nom, cellule, globale);
    } else {
        ecrireCorpsMatrice(corps, nom, v, globale);
    }
    sortie.u32(miMATRIX);
    sortie.u32((std::uint32_t)corps.tampon.size());
    sortie.octets(corps.tampon.data(), corps.tampon.size());
    sortie.completer();
}

// ------------------------------------------------------------- lecture

// Un curseur sur un bloc d'octets, qui refuse de sortir de ses bornes.
class Lecteur {
public:
    Lecteur(const unsigned char* d, std::size_t n, bool inverser)
        : d_(d), n_(n), inverser_(inverser) {}

    bool fini() const { return position_ >= n_; }
    std::size_t reste() const { return n_ - position_; }
    std::size_t position() const { return position_; }

    void avancer(std::size_t n) {
        if (position_ + n > n_) abime("an element extends past the end of the file");
        position_ += n;
    }

    const unsigned char* prendre(std::size_t n) {
        if (position_ + n > n_) abime("an element extends past the end of the file");
        const unsigned char* p = d_ + position_;
        position_ += n;
        return p;
    }

    std::uint32_t u32() {
        const unsigned char* p = prendre(4);
        std::uint32_t v;
        std::memcpy(&v, p, 4);
        return inverser_ ? echanger32(v) : v;
    }

    std::uint16_t u16() {
        const unsigned char* p = prendre(2);
        std::uint16_t v;
        std::memcpy(&v, p, 2);
        return inverser_ ? (std::uint16_t)((v >> 8) | (v << 8)) : v;
    }

    bool inverse() const { return inverser_; }

    // La taille du flux : elle borne ce qu'un element peut annoncer.
    std::size_t total() const { return n_; }

    static std::uint32_t echanger32(std::uint32_t v) {
        return ((v & 0xFFu) << 24) | ((v & 0xFF00u) << 8) | ((v >> 8) & 0xFF00u) |
               ((v >> 24) & 0xFFu);
    }

private:
    const unsigned char* d_;
    std::size_t n_;
    std::size_t position_ = 0;
    bool inverser_;
};

struct Element {
    std::uint32_t type = 0;
    const unsigned char* donnees = nullptr;
    std::size_t octets = 0;
};

// Lit une étiquette et son contenu, forme longue comme forme courte : le
// format autorise à loger les éléments d'au plus quatre octets dans
// l'étiquette elle-même, et MATLAB s'en sert abondamment.
Element lireElement(Lecteur& l) {
    Element e;
    std::uint32_t premier = l.u32();
    std::uint16_t petiteLongueur = (std::uint16_t)(premier >> 16);
    if (petiteLongueur != 0) {
        e.type = premier & 0xFFFFu;
        e.octets = petiteLongueur;
        e.donnees = l.prendre(4);
        return e;
    }
    e.type = premier;
    e.octets = l.u32();
    e.donnees = l.prendre(e.octets);
    // Le remplissage jusqu'au multiple de huit vaut pour les elements
    // ordinaires. Un element compresse, lui, n'est pas complete : sa
    // longueur est exacte et le suivant commence tout de suite. Sauter
    // des octets qui n'existent pas desalignait tout ce qui suivait.
    if (e.type != miCOMPRESSED) {
        std::size_t reste = e.octets % 8;
        if (reste) l.avancer(8 - reste);
    }
    return e;
}

double lireNombre(const unsigned char* p, std::uint32_t type, std::size_t k, bool inverser) {
    std::size_t largeur = tailleType(type);
    if (largeur == 0) return 0.0;
    unsigned char tampon[8];
    std::memcpy(tampon, p + k * largeur, largeur);
    if (inverser)
        for (std::size_t a = 0, b = largeur - 1; a < b; ++a, --b)
            std::swap(tampon[a], tampon[b]);
    switch (type) {
        case miDOUBLE: { double v; std::memcpy(&v, tampon, 8); return v; }
        case miSINGLE: { float v; std::memcpy(&v, tampon, 4); return (double)v; }
        case miINT8: return (double)*(const std::int8_t*)tampon;
        case miUINT8: case miUTF8: return (double)*(const std::uint8_t*)tampon;
        case miINT16: { std::int16_t v; std::memcpy(&v, tampon, 2); return (double)v; }
        case miUINT16: case miUTF16: { std::uint16_t v; std::memcpy(&v, tampon, 2); return (double)v; }
        case miINT32: { std::int32_t v; std::memcpy(&v, tampon, 4); return (double)v; }
        case miUINT32: case miUTF32: { std::uint32_t v; std::memcpy(&v, tampon, 4); return (double)v; }
        case miINT64: { std::int64_t v; std::memcpy(&v, tampon, 8); return (double)v; }
        case miUINT64: { std::uint64_t v; std::memcpy(&v, tampon, 8); return (double)v; }
        default: return 0.0;
    }
}

// Le nombre d'elements qu'annoncent les dimensions.
//
// Un fichier abime — ou un element qu'on a mal interprete, ce qui revient
// au meme — donne des dimensions folles : « 1919251317 x 1214606444 »
// demandait deux mille milliards d'elements, et le programme tombait sur
// std::bad_alloc avant meme d'avoir lu la moindre valeur. Or aucun tableau
// ne peut avoir plus d'elements que le flux n'a d'octets : le plus petit
// des elements, un caractere ou un booleen, en occupe un. Au-dela, le
// fichier ment.
std::size_t nombreElements(const Dims& d, const Lecteur& l) {
    std::size_t limite = l.total();
    std::size_t elements = 1;
    for (int x : d) {
        if (x < 0) abime("a dimension is negative");
        std::size_t n = (std::size_t)x;
        if (n != 0 && elements > limite / n) abime("the dimensions exceed the file");
        elements *= n;
    }
    if (elements > limite) abime("the dimensions exceed the file");
    return elements;
}

std::size_t nombreDe(const Element& e) {
    std::size_t largeur = tailleType(e.type);
    return largeur ? e.octets / largeur : 0;
}

void remplir(std::vector<double>& v, const Element& e, bool inverser) {
    std::size_t n = nombreDe(e);
    v.resize(n);
    for (std::size_t k = 0; k < n; ++k) v[k] = lireNombre(e.donnees, e.type, k, inverser);
}

Valeur lireMatrice(Lecteur& l, std::string* nom, bool* globale,
                   std::string* avertissement = nullptr);

Valeur lireCorpsMatrice(Lecteur& l, std::string* nom, bool* globale,
                        std::string* avertissement = nullptr) {
    Element drapeaux = lireElement(l);
    if (drapeaux.octets < 8) abime("array flags are too short");
    std::uint32_t mot;
    std::memcpy(&mot, drapeaux.donnees, 4);
    if (l.inverse()) mot = Lecteur::echanger32(mot);
    std::uint8_t classe = (std::uint8_t)(mot & 0xFFu);
    bool complexe = (mot & DRAPEAU_COMPLEXE) != 0;
    bool logique = (mot & DRAPEAU_LOGIQUE) != 0;
    if (globale) *globale = (mot & DRAPEAU_GLOBAL) != 0;

    // Un objet de classe MATLAB « nouveau style » (MCOS) n'a ni dimensions
    // ni nom a cet endroit : viennent d'abord trois chaines — le nom de la
    // variable, le systeme de types, le nom de la classe — puis une
    // reference vers les donnees, rangees ailleurs dans le fichier. On lit
    // cette structure pour ne pas se desaligner sur la suite, et on rend un
    // temoin : MatLibre ne reconstruit pas encore l'objet.
    if (classe == (std::uint8_t)mxOPAQUE) {
        Element nomVariable = lireElement(l);
        Element systeme = lireElement(l);
        Element nomClasse = lireElement(l);
        lireMatrice(l, nullptr, nullptr);   // la reference, dont on n'a que faire
        std::string classeTexte((const char*)nomClasse.donnees, nomClasse.octets);
        std::string systemeTexte((const char*)systeme.donnees, systeme.octets);
        if (nom) nom->assign((const char*)nomVariable.donnees, nomVariable.octets);
        Valeur v = Valeur::structureVide();
        v.poserChamp("ClassName", Valeur::texte(classeTexte));
        v.poserChamp("TypeSystem", Valeur::texte(systemeTexte));
        if (avertissement)
            *avertissement = "an object of class '" + classeTexte +
                             "' was saved by MATLAB in its MCOS format, which MatLibre "
                             "cannot rebuild yet; it was loaded as a placeholder "
                             "structure. Re-save it as a structure — for a model, "
                             "with SSDATA or TFDATA — to carry it over.";
        return v;
    }
    // Une poignee de fonction : le corps est une matrice imbriquee.
    if (classe == (std::uint8_t)mxFONCTION) {
        Valeur corps = lireMatrice(l, nom, nullptr);
        if (avertissement)
            *avertissement = "a function handle was saved in this file; MatLibre "
                             "loaded its description, not the handle itself.";
        return corps;
    }

    Element dims = lireElement(l);
    Dims d;
    std::size_t nd = nombreDe(dims);
    for (std::size_t k = 0; k < nd; ++k)
        d.push_back((int)lireNombre(dims.donnees, dims.type, k, l.inverse()));
    while (d.size() < 2) d.push_back(1);

    Element etiquette = lireElement(l);
    if (nom) nom->assign((const char*)etiquette.donnees, etiquette.octets);

    if (classe == (std::uint8_t)mxSPARSE) {
        std::uint32_t nzmaxMot;
        std::memcpy(&nzmaxMot, drapeaux.donnees + 4, 4);
        if (l.inverse()) nzmaxMot = Lecteur::echanger32(nzmaxMot);
        Element ir = lireElement(l);
        Element jc = lireElement(l);
        Element pr = lireElement(l);
        Valeur v;
        v.classe = Classe::Double;
        v.dims = d;
        v.creux = std::make_shared<DonneesCreuses>();
        std::size_t nnz = nombreDe(ir);
        for (std::size_t k = 0; k < nnz; ++k)
            v.creux->ligne.push_back((int)lireNombre(ir.donnees, ir.type, k, l.inverse()));
        std::size_t ncol = nombreDe(jc);
        for (std::size_t k = 0; k < ncol; ++k)
            v.creux->debutColonne.push_back(
                (int)lireNombre(jc.donnees, jc.type, k, l.inverse()));
        remplir(v.creux->valeur, pr, l.inverse());
        v.creux->valeur.resize(v.creux->ligne.size());
        if (complexe) {
            Element pi = lireElement(l);
            remplir(v.creux->imaginaire, pi, l.inverse());
            v.creux->imaginaire.resize(v.creux->ligne.size());
        }
        return v;
    }

    if (classe == (std::uint8_t)mxCELL) {
        nombreElements(d, l);
        Valeur v = Valeur::celluleDims(d);
        for (std::size_t k = 0; k < v.cellules.size() && !l.fini(); ++k)
            v.cellules[k] = lireMatrice(l, nullptr, nullptr, avertissement);
        return v;
    }

    if (classe == (std::uint8_t)mxSTRUCT || classe == (std::uint8_t)mxOBJECT) {
        std::string nomClasseObjet;
        if (classe == (std::uint8_t)mxOBJECT) {
            Element nomClasse = lireElement(l);
            nomClasseObjet.assign((const char*)nomClasse.donnees, nomClasse.octets);
        }
        Element largeurNom = lireElement(l);
        int largeur = largeurNom.octets ? (int)lireNombre(largeurNom.donnees, largeurNom.type,
                                                          0, l.inverse())
                                        : 1;
        if (largeur <= 0) abime("field name length is not positive");
        Element noms = lireElement(l);
        std::vector<std::string> champs;
        for (std::size_t k = 0; k + (std::size_t)largeur <= noms.octets;
             k += (std::size_t)largeur) {
            const char* p = (const char*)noms.donnees + k;
            std::size_t n = 0;
            while (n < (std::size_t)largeur && p[n]) ++n;
            champs.emplace_back(p, n);
        }
        Valeur v = Valeur::structureVide();
        v.dims = d;
        std::size_t elements = nombreElements(d, l);
        v.st = std::make_shared<ChampsStructure>();
        v.st->ordre = champs;
        for (const std::string& c : champs)
            v.st->champs[c] = std::vector<Valeur>(elements, Valeur::vide());
        for (std::size_t i = 0; i < elements; ++i)
            for (const std::string& c : champs) {
                if (l.fini()) break;
                v.st->champs[c][i] = lireMatrice(l, nullptr, nullptr, avertissement);
            }
        if (classe == (std::uint8_t)mxOBJECT && !nomClasseObjet.empty()) {
            v.classe = Classe::Objet;
            v.nomObjet = nomClasseObjet;
        }
        return v;
    }

    Element pr = lireElement(l);
    Valeur v;
    v.classe = classeDepuisMx(classe, logique);
    v.dims = d;
    remplir(v.re, pr, l.inverse());
    std::size_t attendus = nombreElements(d, l);
    v.re.resize(attendus, 0.0);
    if (complexe) {
        Element pi = lireElement(l);
        remplir(v.im, pi, l.inverse());
        v.im.resize(attendus, 0.0);
    }
    return v;
}

Valeur lireMatrice(Lecteur& l, std::string* nom, bool* globale,
                   std::string* avertissement) {
    Element e = lireElement(l);
    if (e.type != miMATRIX) {
        if (nom) nom->clear();
        return Valeur::vide();
    }
    Lecteur interne(e.donnees, e.octets, l.inverse());
    return lireCorpsMatrice(interne, nom, globale, avertissement);
}

std::string lireFichier(const std::string& chemin) {
    std::ifstream f(chemin, std::ios::binary);
    if (!f)
        erreur("MATLAB:load:couldNotReadFile",
               "Unable to read file '" + chemin + "'. No such file or directory.");
    return std::string((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

// --- niveau 4 ---------------------------------------------------------
//
// Un fichier de niveau 4 n'a pas d'en-tête : il enchaîne des variables,
// chacune précédée de cinq entiers de trente-deux bits. Le premier code à
// la fois l'ordre des octets, la précision et la nature du tableau.
bool ressembleAuNiveau4(const std::string& brut) {
    if (brut.size() < 20) return false;
    std::uint32_t mopt;
    std::memcpy(&mopt, brut.data(), 4);
    if (mopt > 5000) return false;
    std::uint32_t t = mopt % 10;
    std::uint32_t p = (mopt / 10) % 10;
    std::uint32_t o = (mopt / 100) % 10;
    return t <= 2 && p <= 5 && o == 0;
}

std::vector<VariableMat> lireNiveau4(const std::string& brut) {
    std::vector<VariableMat> sortie;
    Lecteur l((const unsigned char*)brut.data(), brut.size(), false);
    while (l.reste() >= 20) {
        std::uint32_t mopt = l.u32();
        std::uint32_t lignes = l.u32();
        std::uint32_t colonnes = l.u32();
        std::uint32_t imaginaire = l.u32();
        std::uint32_t longueurNom = l.u32();
        std::uint32_t p = (mopt / 10) % 10;
        std::uint32_t t = mopt % 10;
        static const std::uint32_t TYPES[6] = {miDOUBLE, miSINGLE, miINT32,
                                               miINT16, miUINT16, miUINT8};
        if (p > 5) abime("unknown precision in a level 4 file");
        std::uint32_t type = TYPES[p];
        if (longueurNom == 0) abime("a level 4 variable has no name");
        const unsigned char* nom = l.prendre(longueurNom);
        VariableMat variable;
        variable.nom.assign((const char*)nom, longueurNom - 1);
        std::size_t n = (std::size_t)lignes * colonnes;
        std::size_t largeur = tailleType(type);
        const unsigned char* pr = l.prendre(n * largeur);
        Valeur v;
        v.dims = {(int)lignes, (int)colonnes};
        v.re.resize(n);
        for (std::size_t k = 0; k < n; ++k) v.re[k] = lireNombre(pr, type, k, false);
        if (imaginaire) {
            const unsigned char* pi = l.prendre(n * largeur);
            v.im.resize(n);
            for (std::size_t k = 0; k < n; ++k) v.im[k] = lireNombre(pi, type, k, false);
        }
        if (t == 1) v.classe = Classe::Caractere;
        if (t == 2) {
            // Le format creux du niveau 4 : trois colonnes — lignes,
            // colonnes, valeurs — et une dernière ligne qui porte les
            // dimensions.
            Valeur plein = v;
            if (plein.ncolonnes() >= 3 && plein.nlignes() >= 1) {
                int m = plein.nlignes();
                int nl = (int)plein.re[(std::size_t)m - 1];
                int nc = (int)plein.re[(std::size_t)m - 1 + (std::size_t)m];
                v = Valeur::matrice(nl, nc);
                for (int k = 0; k + 1 < m; ++k) {
                    int i = (int)plein.re[(std::size_t)k] - 1;
                    int j = (int)plein.re[(std::size_t)k + (std::size_t)m] - 1;
                    double x = plein.re[(std::size_t)k + 2 * (std::size_t)m];
                    if (i >= 0 && i < nl && j >= 0 && j < nc)
                        v.re[(std::size_t)i + (std::size_t)j * nl] = x;
                }
            }
        }
        variable.valeur = v;
        sortie.push_back(variable);
    }
    return sortie;
}

std::vector<VariableMat> lireContenu(const std::string& brut, bool inventaireSeulement) {
    (void)inventaireSeulement;
    if (brut.size() < 4) abime("the file is empty");
    if (ressembleAuNiveau4(brut)) return lireNiveau4(brut);
    if (brut.size() < 128) abime("the header is truncated");
    // Le niveau 7.3 n'est plus le format MAT : c'est un fichier HDF5, dont
    // la signature suit l'en-tete de cinq cent douze octets que la norme
    // reserve. On le dit clairement plutot que de lire du charabia.
    static const char SIGNATURE_HDF5[8] = {'\x89', 'H', 'D', 'F', '\r', '\n', '\x1a', '\n'};
    bool hdf5 = brut.size() >= 520 && std::memcmp(brut.data() + 512, SIGNATURE_HDF5, 8) == 0;
    if (!hdf5) hdf5 = std::memcmp(brut.data(), SIGNATURE_HDF5, 8) == 0;
    if (!hdf5) hdf5 = brut.compare(0, 116, std::string("MATLAB 7.3 MAT-file"), 0, 19) == 0;
    if (hdf5)
        erreur("MATLAB:load:unsupportedVersion",
               "This is a version 7.3 MAT-file, which is an HDF5 file and not the "
               "MAT format MatLibre reads. Save it again from MATLAB with "
               "save('nom.mat', '-v7') and it will load.");
    // L'indicateur d'ordre des octets : « IM » quand le fichier est en
    // petit-boutien, « MI » sinon.
    bool inverser = brut[126] == 'M' && brut[127] == 'I';
    if (!((brut[126] == 'I' && brut[127] == 'M') || inverser))
        abime("the endian indicator is neither 'IM' nor 'MI'");

    std::vector<VariableMat> sortie;
    Lecteur l((const unsigned char*)brut.data() + 128, brut.size() - 128, inverser);
    std::vector<std::string> decompresses;
    while (!l.fini() && l.reste() >= 8) {
        std::size_t depart = l.position();
        Element e = lireElement(l);
        if (e.type == miCOMPRESSED) {
            decompresses.push_back(inflaterZlib(e.donnees, e.octets));
            const std::string& clair = decompresses.back();
            Lecteur interne((const unsigned char*)clair.data(), clair.size(), inverser);
            while (!interne.fini() && interne.reste() >= 8) {
                VariableMat variable;
                variable.valeur = lireMatrice(interne, &variable.nom, &variable.globale,
                                              &variable.avertissement);
                if (variable.nom.empty()) break;
                sortie.push_back(variable);
            }
            continue;
        }
        if (e.type != miMATRIX) {
            if (l.position() == depart) break;   // rien consommé : on s'arrête
            continue;
        }
        Lecteur interne(e.donnees, e.octets, inverser);
        VariableMat variable;
        variable.valeur = lireCorpsMatrice(interne, &variable.nom, &variable.globale,
                                           &variable.avertissement);
        if (!variable.nom.empty()) sortie.push_back(variable);
    }
    return sortie;
}

}  // namespace

std::vector<VariableMat> lireMat(const std::string& chemin) {
    return lireContenu(lireFichier(chemin), false);
}

std::vector<VariableMat> inventaireMat(const std::string& chemin) {
    return lireContenu(lireFichier(chemin), true);
}

void ecrireMat(const std::string& chemin, const std::vector<VariableMat>& variables,
               bool compresser) {
    std::string entete(116, ' ');
    std::time_t maintenant = std::time(nullptr);
    char date[64] = {0};
    std::strftime(date, sizeof date, "%a %b %d %H:%M:%S %Y", std::localtime(&maintenant));
    std::string texte = std::string("MATLAB 5.0 MAT-file, Platform: MATLIBRE, Created by: "
                                    "MatLibre ") +
                        MATLIBRE_VERSION + ", Created on: " + date;
    if (texte.size() > 116) texte.resize(116);
    std::memcpy(&entete[0], texte.data(), texte.size());

    std::string sortie = entete;
    sortie.append(8, '\0');            // décalage du sous-système : aucun
    sortie.push_back((char)0x00);      // version 0x0100, petit-boutien
    sortie.push_back((char)0x01);
    sortie.push_back('I');
    sortie.push_back('M');

    for (const VariableMat& v : variables) {
        Ecrivain e;
        ecrireMatrice(e, v.nom, v.valeur, v.globale);
        if (compresser) {
            std::string comprime = emballerZlib(e.tampon);
            Ecrivain enveloppe;
            enveloppe.u32(miCOMPRESSED);
            enveloppe.u32((std::uint32_t)comprime.size());
            enveloppe.octets(comprime.data(), comprime.size());
            sortie += enveloppe.tampon;
        } else {
            sortie += e.tampon;
        }
    }

    std::ofstream f(chemin, std::ios::binary);
    if (!f)
        erreur("MATLAB:save:permissionDenied",
               "Unable to write file '" + chemin + "'.");
    f.write(sortie.data(), (std::streamsize)sortie.size());
    if (!f)
        erreur("MATLAB:save:permissionDenied",
               "Unable to write file '" + chemin + "'.");
}

}  // namespace matlibre
