// Mat.cpp — save, load et leurs compagnons.
//
// « save » et « load » sont les deux fonctions par lesquelles un travail
// survit à la session. Elles écrivent et relisent le format MAT, décrit
// dans FichierMat.cpp ; ici on ne s'occupe que de leurs arguments, qui
// sont ceux de MATLAB : la liste des variables, les motifs, les drapeaux
// de version, « -append », « -struct », « -ascii ».
#include <algorithm>
#include <cctype>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <map>
#include <regex>
#include <set>
#include <sstream>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/FichierMat.h"
#include "matlibre/Interpreteur.h"

namespace fs = std::filesystem;

namespace matlibre {

namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

bool estDrapeau(const std::string& t) { return !t.empty() && t[0] == '-'; }

std::string enMinuscules(std::string s) {
    for (char& c : s) c = (char)std::tolower((unsigned char)c);
    return s;
}

// « essai » devient « essai.mat » ; « essai.mat » et « essai.txt » restent.
std::string avecExtension(const std::string& nom) {
    fs::path p(nom);
    if (p.has_extension()) return nom;
    return nom + ".mat";
}

// Les motifs de MATLAB : « save f a* » sauve tout ce qui commence par a.
// Le joker devient une expression régulière ancrée aux deux bouts.
std::regex motifVersRegex(const std::string& motif) {
    std::string r = "^";
    for (char c : motif) {
        if (c == '*') r += ".*";
        else if (c == '?') r += '.';
        else if (std::strchr("\\^$.|+()[]{}", c)) { r += '\\'; r += c; }
        else r += c;
    }
    r += "$";
    return std::regex(r);
}

// L'écriture en texte de « -ascii » : les nombres, séparés par des
// espaces, une ligne par ligne de la matrice. MATLAB y perd les noms.
void ecrireAscii(const std::string& chemin, const std::vector<VariableMat>& variables,
                 bool huitChiffres, bool ajouter) {
    std::ofstream f(chemin, ajouter ? std::ios::app : std::ios::trunc);
    if (!f)
        erreur("MATLAB:save:permissionDenied", "Unable to write file '" + chemin + "'.");
    for (const VariableMat& v : variables) {
        const Valeur& x = v.valeur;
        if (!x.estNumerique() && x.classe != Classe::Logique && !x.estTexte())
            erreur("MATLAB:save:noParent",
                   "Only numeric arrays can be written with the '-ascii' option.");
        int l = x.nlignes(), c = x.ncolonnes();
        for (int i = 0; i < l; ++i) {
            for (int j = 0; j < c; ++j) {
                double val = x.re[(std::size_t)i + (std::size_t)j * l];
                f << (j ? "   " : "   ")
                  << formater(huitChiffres ? "%.15e" : "%.7e", val);
            }
            f << "\n";
        }
    }
}

// La lecture d'un fichier texte : des nombres séparés par des blancs, le
// même nombre par ligne. C'est ce que rend « load essai.txt ».
Valeur lireAscii(const std::string& chemin) {
    std::ifstream f(chemin);
    if (!f)
        erreur("MATLAB:load:couldNotReadFile",
               "Unable to read file '" + chemin + "'. No such file or directory.");
    std::vector<std::vector<double>> lignes;
    std::string ligne;
    while (std::getline(f, ligne)) {
        // Les lignes vides et les commentaires « % » ou « # » sont sautés.
        std::size_t debut = ligne.find_first_not_of(" \t\r");
        if (debut == std::string::npos) continue;
        if (ligne[debut] == '%' || ligne[debut] == '#') continue;
        std::istringstream flux(ligne);
        std::vector<double> valeurs;
        double x;
        while (flux >> x) {
            valeurs.push_back(x);
            // Les virgules servent aussi de séparateur.
            if (flux.peek() == ',') flux.get();
        }
        if (valeurs.empty()) continue;
        if (!lignes.empty() && valeurs.size() != lignes[0].size())
            erreur("MATLAB:load:numColumnsMustMatch",
                   "Number of columns on line " + std::to_string(lignes.size() + 1) +
                       " of the ASCII file must be the same as previous lines.");
        lignes.push_back(valeurs);
    }
    int l = (int)lignes.size();
    int c = l ? (int)lignes[0].size() : 0;
    Valeur v = Valeur::matrice(l, c);
    for (int i = 0; i < l; ++i)
        for (int j = 0; j < c; ++j)
            v.re[(std::size_t)i + (std::size_t)j * l] = lignes[(std::size_t)i][(std::size_t)j];
    return v;
}

// Un nom de variable acceptable : c'est ce que MATLAB exige d'un champ
// comme d'une variable.
bool nomValide(const std::string& n) {
    if (n.empty() || !(std::isalpha((unsigned char)n[0]) || n[0] == '_')) return false;
    for (char c : n)
        if (!(std::isalnum((unsigned char)c) || c == '_')) return false;
    return true;
}

// Le nom d'un fichier, comme celui d'une variable, s'écrit en texte :
// « save(1) » fabriquait un fichier au nom fait du caractère de code 1.
std::string argNom(const Valeur& v, const char* quoi) {
    if (!v.estTexte() && !v.estChaine())
        erreur("MATLAB:save:invalidArgument",
               formater("Argument must be a character vector or a string ('%s').", quoi));
    return v.versTexte();
}

FONCTION(fnSave) {
    INUTILISE
    if (args.empty())
        erreur("MATLAB:minrhs", "Not enough input arguments.");
    std::string fichier = avecExtension(argNom(args[0], "filename"));

    bool ascii = false, ajouter = false, compresser = false, huitChiffres = false;
    bool parRegex = false, depuisStruct = false;
    std::vector<std::string> motifs;
    for (std::size_t k = 1; k < args.size(); ++k) {
        std::string t = argNom(args[k], "variable name");
        if (estDrapeau(t)) {
            std::string d = enMinuscules(t);
            if (d == "-ascii") ascii = true;
            else if (d == "-append") ajouter = true;
            else if (d == "-double") huitChiffres = true;
            else if (d == "-tabs" || d == "-nocompression") { /* sans effet ici */ }
            else if (d == "-regexp") parRegex = true;
            else if (d == "-struct") depuisStruct = true;
            else if (d == "-v4" || d == "-v6" || d == "-v7" || d == "-v7.3") {
                // « -v7 » et « -v7.3 » demandent la compression ; on la
                // fournit en blocs stockés, ce que tout lecteur zlib
                // accepte. « -v4 » et « -v6 » n'en veulent pas.
                compresser = (d == "-v7" || d == "-v7.3");
            } else {
                erreur("MATLAB:save:invalidOption", "Unrecognized option '" + t + "'.");
            }
            continue;
        }
        motifs.push_back(t);
    }

    std::vector<VariableMat> aEcrire;
    if (depuisStruct) {
        // « save f -struct s » écrit chaque champ de s comme une variable.
        if (motifs.empty())
            erreur("MATLAB:save:noStructVariable",
                   "The '-struct' option requires the name of a structure.");
        Valeur s = it.lireVariable(motifs[0]);
        if (!s.estStructure() || !s.st)
            erreur("MATLAB:save:notAStruct",
                   "The variable named by '-struct' must be a scalar structure.");
        std::set<std::string> voulus(motifs.begin() + 1, motifs.end());
        for (const std::string& champ : s.st->ordre) {
            if (!voulus.empty() && !voulus.count(champ)) continue;
            aEcrire.push_back({champ, s.champ(champ, 0), false});
        }
    } else if (motifs.empty()) {
        for (const std::string& nom : it.nomsVariables())
            aEcrire.push_back({nom, it.lireVariable(nom), false});
    } else {
        std::vector<std::string> noms = it.nomsVariables();
        std::set<std::string> deja;
        for (const std::string& motif : motifs) {
            if (!parRegex && nomValide(motif) && motif.find('*') == std::string::npos &&
                motif.find('?') == std::string::npos) {
                if (!it.existeVariable(motif))
                    erreur("MATLAB:save:variableNotFound",
                           "Variable '" + motif + "' not found.");
                if (deja.insert(motif).second)
                    aEcrire.push_back({motif, it.lireVariable(motif), false});
                continue;
            }
            std::regex r = parRegex ? std::regex(motif) : motifVersRegex(motif);
            for (const std::string& nom : noms)
                if (std::regex_search(nom, r) && deja.insert(nom).second)
                    aEcrire.push_back({nom, it.lireVariable(nom), false});
        }
    }

    if (ascii) {
        ecrireAscii(fichier, aEcrire, huitChiffres, ajouter);
        return {};
    }
    if (ajouter && fs::exists(fichier)) {
        // On relit ce qui est déjà là, et l'on remplace les homonymes.
        std::vector<VariableMat> anciennes = lireMat(fichier);
        std::set<std::string> neuves;
        for (const VariableMat& v : aEcrire) neuves.insert(v.nom);
        std::vector<VariableMat> tout;
        for (const VariableMat& v : anciennes)
            if (!neuves.count(v.nom)) tout.push_back(v);
        for (const VariableMat& v : aEcrire) tout.push_back(v);
        aEcrire.swap(tout);
    }
    ecrireMat(fichier, aEcrire, compresser);
    return {};
}

FONCTION(fnLoad) {
    INUTILISE
    if (args.empty())
        erreur("MATLAB:minrhs", "Not enough input arguments.");
    std::string demande = argNom(args[0], "filename");
    std::string fichier = demande;
    if (!fs::exists(fichier)) fichier = avecExtension(demande);
    if (!fs::exists(fichier))
        erreur("MATLAB:load:couldNotReadFile",
               "Unable to read file '" + demande + "'. No such file or directory.");

    bool ascii = false, forcerMat = false, parRegex = false;
    std::vector<std::string> motifs;
    for (std::size_t k = 1; k < args.size(); ++k) {
        std::string t = argNom(args[k], "variable name");
        if (estDrapeau(t)) {
            std::string d = enMinuscules(t);
            if (d == "-ascii") ascii = true;
            else if (d == "-mat") forcerMat = true;
            else if (d == "-regexp") parRegex = true;
            else erreur("MATLAB:load:invalidOption", "Unrecognized option '" + t + "'.");
            continue;
        }
        motifs.push_back(t);
    }

    if (ascii || (!forcerMat && fs::path(fichier).extension() != ".mat" &&
                  fs::path(fichier).extension() != ".MAT")) {
        // Un fichier qui n'est pas un .mat : on essaie le texte, sauf s'il
        // commence par l'en-tête d'un fichier MAT.
        std::ifstream sonde(fichier, std::ios::binary);
        std::string debut(6, '\0');
        sonde.read(&debut[0], 6);
        bool ressembleMat = debut.rfind("MATLAB", 0) == 0;
        if (ascii || !ressembleMat) {
            Valeur v = lireAscii(fichier);
            if (nargout >= 1) return {v};
            // Le nom de la variable est celui du fichier, nettoyé.
            std::string nom = fs::path(fichier).stem().string();
            for (char& c : nom)
                if (!(std::isalnum((unsigned char)c) || c == '_')) c = '_';
            if (nom.empty() || std::isdigit((unsigned char)nom[0])) nom = "X" + nom;
            it.ecrireVariable(nom, v);
            return {};
        }
    }

    std::vector<VariableMat> variables = lireMat(fichier);
    if (!motifs.empty()) {
        std::vector<VariableMat> gardees;
        for (const std::string& motif : motifs) {
            std::regex r = parRegex ? std::regex(motif) : motifVersRegex(motif);
            bool trouve = false;
            for (const VariableMat& v : variables)
                if (std::regex_search(v.nom, r)) {
                    gardees.push_back(v);
                    trouve = true;
                }
            if (!trouve && !parRegex)
                erreur("MATLAB:load:couldNotReadFile",
                       "Variable '" + motif + "' not found in the file.");
        }
        variables.swap(gardees);
    }

    if (nargout >= 1) {
        Valeur s = Valeur::structureVide();
        for (const VariableMat& v : variables) s.poserChamp(v.nom, v.valeur);
        return {s};
    }
    for (const VariableMat& v : variables) it.ecrireVariable(v.nom, v.valeur);
    return {};
}

// « whos -file f.mat » : ce que le fichier contient, sans le charger dans
// l'espace de travail.
FONCTION(fnContenuMat) {
    INUTILISE
    exigerArguments(args, 1, 1, "matlibre_contenu_mat");
    std::string fichier = avecExtension(argNom(args[0], "filename"));
    std::vector<VariableMat> variables = inventaireMat(fichier);
    Valeur s = Valeur::structureVide();
    s.st = std::make_shared<ChampsStructure>();
    s.st->ordre = {"name", "size", "bytes", "class", "global", "complex"};
    s.dims = {(int)variables.size(), 1};
    for (const auto& champ : s.st->ordre)
        s.st->champs[champ] = std::vector<Valeur>(variables.size(), Valeur::vide());
    for (std::size_t k = 0; k < variables.size(); ++k) {
        const Valeur& v = variables[k].valeur;
        s.st->champs["name"][k] = Valeur::texte(variables[k].nom);
        std::vector<double> dims(v.dims.begin(), v.dims.end());
        s.st->champs["size"][k] = Valeur::ligne(dims);
        s.st->champs["bytes"][k] =
            Valeur::scalaire((double)(v.re.size() + v.im.size()) * 8.0);
        s.st->champs["class"][k] = Valeur::texte(v.classeNom());
        s.st->champs["global"][k] = Valeur::booleen(variables[k].globale);
        s.st->champs["complex"][k] = Valeur::booleen(v.estComplexe());
    }
    if (variables.empty()) s.dims = {0, 1};
    return {s};
}

}  // namespace

void enregistrerMat(Interpreteur& it) {
    it.enregistrer("save", fnSave, "es",
                   "save  Ecrit des variables dans un fichier MAT.");
    it.enregistrer("load", fnLoad, "es",
                   "load  Relit des variables depuis un fichier MAT ou texte.");
    it.enregistrer("matlibre_contenu_mat", fnContenuMat, "es",
                   "matlibre_contenu_mat  Inventaire d'un fichier MAT.");
}

}  // namespace matlibre
