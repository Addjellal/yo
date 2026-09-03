// Systeme.cpp — environnement, fichiers, chemin de recherche, aide.
#include <algorithm>
#include <cctype>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#ifndef _WIN32
#include <unistd.h>
#endif

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Parallele.h"
#include "matlibre/Operations.h"
#include "matlibre/Version.h"

namespace fs = std::filesystem;

namespace matlibre {

std::string aideDepuisSource(const std::string& source);

namespace {

int identifiantProcessus() {
#ifdef _WIN32
    return 0;
#else
    return (int)::getpid();
#endif
}

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

FONCTION(fnPwd) {
    INUTILISE
    std::error_code ec;
    return {Valeur::texte(fs::current_path(ec).string())};
}

FONCTION(fnCd) {
    INUTILISE
    if (args.empty()) {
        std::error_code ec;
        return {Valeur::texte(fs::current_path(ec).string())};
    }
    std::error_code ec;
    fs::current_path(args[0].versTexte(), ec);
    if (ec) erreur("MATLAB:cd:NonExistentDirectory",
                   "Unable to change to directory '" + args[0].versTexte() + "'.");
    return {};
}

FONCTION(fnDir) {
    INUTILISE
    std::string motif = args.empty() ? "." : args[0].versTexte();
    fs::path base = motif;
    std::string filtre;
    std::error_code ec;
    if (!fs::is_directory(base, ec)) {
        filtre = base.filename().string();
        base = base.parent_path();
        if (base.empty()) base = ".";
    }
    auto correspond = [&](const std::string& nom) {
        if (filtre.empty()) return true;
        // Motif simple avec « * ».
        std::size_t etoile = filtre.find('*');
        if (etoile == std::string::npos) return nom == filtre;
        std::string avant = filtre.substr(0, etoile);
        std::string apres = filtre.substr(etoile + 1);
        return nom.size() >= avant.size() + apres.size() &&
               nom.compare(0, avant.size(), avant) == 0 &&
               nom.compare(nom.size() - apres.size(), apres.size(), apres) == 0;
    };
    std::vector<Valeur> entrees;
    for (const auto& e : fs::directory_iterator(base, ec)) {
        std::string nom = e.path().filename().string();
        if (!correspond(nom)) continue;
        Valeur s = Valeur::structureVide();
        s.poserChamp("name", Valeur::texte(nom));
        s.poserChamp("folder", Valeur::texte(e.path().parent_path().string()));
        s.poserChamp("isdir", Valeur::booleen(e.is_directory()));
        std::error_code e2;
        s.poserChamp("bytes",
                     Valeur::scalaire(e.is_regular_file() ? (double)fs::file_size(e.path(), e2)
                                                          : 0.0));
        entrees.push_back(s);
    }
    std::sort(entrees.begin(), entrees.end(), [](const Valeur& a, const Valeur& b) {
        return a.champ("name").versTexte() < b.champ("name").versTexte();
    });
    if (nargout == 0 && !entrees.empty()) {
        for (const auto& e : entrees) it.sortie() << e.champ("name").versTexte() << "\n";
        return {};
    }
    if (entrees.empty()) return {Valeur::videClasse(Classe::Structure)};
    return {concatener(entrees, 0)};
}

FONCTION(fnLs) {
    INUTILISE
    std::vector<Valeur> a = args;
    auto r = fnDir(it, a, 1);
    if (r.empty() || !r[0].estStructure()) return {Valeur::texte("")};
    std::string s;
    for (std::size_t k = 0; k < r[0].nelem(); ++k)
        s += r[0].champ("name", k).versTexte() + "\n";
    if (nargout == 0) {
        it.sortie() << s;
        return {};
    }
    return {Valeur::texte(s)};
}

FONCTION(fnMkdir) {
    INUTILISE
    exigerArguments(args, 1, 2, "mkdir");
    std::error_code ec;
    bool ok = fs::create_directories(args[0].versTexte(), ec);
    return {Valeur::booleen(ok || !ec)};
}

FONCTION(fnRmdir) {
    INUTILISE
    exigerArguments(args, 1, 2, "rmdir");
    std::error_code ec;
    bool recursif = args.size() > 1 && args[1].versTexte() == "s";
    if (recursif) fs::remove_all(args[0].versTexte(), ec);
    else fs::remove(args[0].versTexte(), ec);
    return {Valeur::booleen(!ec)};
}

FONCTION(fnDelete) {
    INUTILISE
    for (const auto& a : args) {
        // delete(pool) ferme le pool de travailleurs ; delete('f.txt')
        // supprime un fichier. C'est le type de l'argument qui tranche.
        if (a.estStructure() && a.aChamp("NumWorkers")) {
            definirTaillePool(0);
            continue;
        }
        std::error_code ec;
        fs::remove(a.versTexte(), ec);
    }
    return {};
}

FONCTION(fnCopyfile) {
    INUTILISE
    exigerArguments(args, 2, 3, "copyfile");
    std::error_code ec;
    fs::copy(args[0].versTexte(), args[1].versTexte(),
             fs::copy_options::overwrite_existing | fs::copy_options::recursive, ec);
    return {Valeur::booleen(!ec)};
}

FONCTION(fnMovefile) {
    INUTILISE
    exigerArguments(args, 2, 3, "movefile");
    std::error_code ec;
    fs::rename(args[0].versTexte(), args[1].versTexte(), ec);
    return {Valeur::booleen(!ec)};
}

FONCTION(fnFullfile) {
    INUTILISE
    fs::path p;
    for (const auto& a : args) {
        std::string s = a.versTexte();
        if (s.empty()) continue;
        if (p.empty()) p = s;
        else p /= s;
    }
    return {Valeur::texte(p.string())};
}

FONCTION(fnFileparts) {
    INUTILISE
    exigerArguments(args, 1, 1, "fileparts");
    fs::path p = args[0].versTexte();
    std::string dossier = p.parent_path().string();
    std::string nom = p.stem().string();
    std::string extension = p.extension().string();
    if (nargout <= 1) return {Valeur::texte(dossier)};
    if (nargout == 2) return {Valeur::texte(dossier), Valeur::texte(nom)};
    return {Valeur::texte(dossier), Valeur::texte(nom), Valeur::texte(extension)};
}

FONCTION(fnFilesep) {
    INUTILISE
#ifdef _WIN32
    return {Valeur::texte("\\")};
#else
    return {Valeur::texte("/")};
#endif
}

FONCTION(fnPathsep) {
    INUTILISE
#ifdef _WIN32
    return {Valeur::texte(";")};
#else
    return {Valeur::texte(":")};
#endif
}

FONCTION(fnTempdir) {
    INUTILISE
    std::error_code ec;
    return {Valeur::texte(fs::temp_directory_path(ec).string())};
}

FONCTION(fnTempname) {
    INUTILISE
    std::error_code ec;
    static int compteur = 0;
    fs::path p = fs::temp_directory_path(ec) /
                 formater("matlibre_%d_%d", (int)identifiantProcessus(), compteur++);
    return {Valeur::texte(p.string())};
}

FONCTION(fnGetenv) {
    INUTILISE
    exigerArguments(args, 1, 1, "getenv");
    const char* v = std::getenv(args[0].versTexte().c_str());
    return {Valeur::texte(v ? v : "")};
}

FONCTION(fnSetenv) {
    INUTILISE
    exigerArguments(args, 2, 2, "setenv");
    // Windows n'a pas setenv : _putenv_s fait la meme chose, et sans lui
    // l'appel etait un silencieux coup d'epee dans l'eau.
#ifdef _WIN32
    _putenv_s(args[0].versTexte().c_str(), args[1].versTexte().c_str());
#else
    ::setenv(args[0].versTexte().c_str(), args[1].versTexte().c_str(), 1);
#endif
    return {};
}

FONCTION(fnSystem) {
    INUTILISE
    exigerArguments(args, 1, 2, "system");
    std::string commande = args[0].versTexte();
    std::string fichier = fs::temp_directory_path().string() + "/matlibre_system.txt";
    int code = std::system((commande + " > " + fichier + " 2>&1").c_str());
    std::ifstream f(fichier);
    std::ostringstream ss;
    ss << f.rdbuf();
    std::error_code ec;
    fs::remove(fichier, ec);
    if (nargout >= 2) return {Valeur::scalaire(code), Valeur::texte(ss.str())};
    it.sortie() << ss.str();
    return {Valeur::scalaire(code)};
}

FONCTION(fnComputer) {
    INUTILISE
#if defined(_WIN32)
    std::string nom = "PCWIN64";
#elif defined(__APPLE__)
    std::string nom = "MACI64";
#else
    std::string nom = "GLNXA64";
#endif
    if (nargout >= 2) return {Valeur::texte(nom), Valeur::scalaire(2.147483647e9)};
    return {Valeur::texte(nom)};
}

FONCTION(fnVersion) {
    INUTILISE
    if (!args.empty() && args[0].versTexte() == "-release")
        return {Valeur::texte("2024b")};
    return {Valeur::texte(MATLIBRE_VERSION " (MatLibre)")};
}

FONCTION(fnVer) {
    INUTILISE
    Valeur v = Valeur::structureVide();
    v.poserChamp("Name", Valeur::texte("MatLibre"));
    v.poserChamp("Version", Valeur::texte(MATLIBRE_VERSION));
    v.poserChamp("Release", Valeur::texte("(" MATLIBRE_COMPATIBILITE ")"));
    v.poserChamp("Date", Valeur::texte(__DATE__));
    if (nargout == 0) {
        it.sortie() << "MatLibre " << MATLIBRE_VERSION << " — compatible "
                    << MATLIBRE_COMPATIBILITE << "\n";
        return {};
    }
    return {v};
}

FONCTION(fnIsunix) {
    INUTILISE
#ifdef _WIN32
    return {Valeur::booleen(false)};
#else
    return {Valeur::booleen(true)};
#endif
}
FONCTION(fnIspc) {
    INUTILISE
#ifdef _WIN32
    return {Valeur::booleen(true)};
#else
    return {Valeur::booleen(false)};
#endif
}
FONCTION(fnIsmac) {
    INUTILISE
#ifdef __APPLE__
    return {Valeur::booleen(true)};
#else
    return {Valeur::booleen(false)};
#endif
}

// ------------------------------------------------------ chemin de recherche

FONCTION(fnAddpath) {
    INUTILISE
    for (const auto& a : args) {
        std::string s = a.versTexte();
        if (s == "-end" || s == "-begin") continue;
        it.ajouterChemin(s, true);
    }
    return {};
}

FONCTION(fnRmpath) {
    INUTILISE
    for (const auto& a : args) it.retirerChemin(a.versTexte());
    return {};
}

FONCTION(fnPath) {
    INUTILISE
    if (!args.empty()) {
        for (const auto& a : args) it.ajouterChemin(a.versTexte(), false);
        return {};
    }
    std::string s;
    for (const auto& d : it.chemin()) {
        if (!s.empty()) s += ":";
        s += d;
    }
    if (nargout == 0) {
        for (const auto& d : it.chemin()) it.sortie() << "        " << d << "\n";
        return {};
    }
    return {Valeur::texte(s)};
}

FONCTION(fnRehash) {
    INUTILISE
    it.reindexerChemin();
    return {};
}

FONCTION(fnWhich) {
    INUTILISE
    exigerArguments(args, 1, 2, "which");
    std::string nom = args[0].versTexte();
    std::string reponse;
    if (it.existeVariable(nom)) reponse = nom + " is a variable.";
    else {
        auto index = it.indexFichiers();
        auto f = index.find(nom);
        if (f != index.end()) reponse = f->second;
        else if (it.natif(nom)) reponse = "built-in (" + nom + ")";
        else reponse = "'" + nom + "' not found.";
    }
    if (nargout == 0) {
        it.sortie() << reponse << "\n";
        return {};
    }
    return {Valeur::texte(reponse)};
}

FONCTION(fnWho) {
    INUTILISE
    auto noms = it.nomsVariables();
    if (nargout == 0) {
        if (noms.empty()) return {};
        it.sortie() << "Variables:\n\n";
        for (const auto& n : noms) it.sortie() << "  " << n << "\n";
        it.sortie() << "\n";
        return {};
    }
    Valeur c = Valeur::celluleDims({(int)noms.size(), 1});
    for (std::size_t k = 0; k < noms.size(); ++k) c.cellules[k] = Valeur::texte(noms[k]);
    return {c};
}

FONCTION(fnWhos) {
    INUTILISE
    // « whos -file f.mat » regarde dans un fichier au lieu de l'espace de
    // travail : c'est ce qu'on fait avant de charger, pour savoir ce qu'on
    // va charger.
    for (std::size_t k = 0; k + 1 < args.size(); ++k) {
        std::string mot = args[k].versTexte();
        for (char& c : mot) c = (char)std::tolower((unsigned char)c);
        if (mot != "-file") continue;
        std::vector<Valeur> a = {args[k + 1]};
        std::vector<Valeur> r = it.appeler("matlibre_contenu_mat", a, 1);
        if (r.empty()) return {};
        const Valeur& inventaire = r[0];
        std::size_t n = inventaire.nelem();
        if (nargout > 0) return {inventaire};
        it.sortie() << formater("%-20s %-12s %-10s\n", "Name", "Size", "Class");
        for (std::size_t j = 0; j < n; ++j) {
            Valeur nom = inventaire.champ("name", j);
            Valeur taille = inventaire.champ("size", j);
            Valeur classe = inventaire.champ("class", j);
            Dims d;
            for (double x : taille.re) d.push_back((int)x);
            it.sortie() << formater("%-20s %-12s %-10s\n", nom.versTexte().c_str(),
                                    texteDims(d).c_str(), classe.versTexte().c_str());
        }
        return {};
    }
    auto noms = it.nomsVariables();
    if (nargout == 0) {
        it.sortie() << formater("%-20s %-12s %-10s\n", "Name", "Size", "Class");
        for (const auto& n : noms) {
            Valeur v = it.lireVariable(n);
            it.sortie() << formater("%-20s %-12s %-10s\n", n.c_str(),
                                    texteDims(v.dims).c_str(), v.classeNom().c_str());
        }
        return {};
    }
    std::vector<Valeur> lignes;
    for (const auto& n : noms) {
        Valeur v = it.lireVariable(n);
        Valeur s = Valeur::structureVide();
        s.poserChamp("name", Valeur::texte(n));
        std::vector<double> d(v.dims.begin(), v.dims.end());
        s.poserChamp("size", Valeur::ligne(d));
        s.poserChamp("class", Valeur::texte(v.classeNom()));
        lignes.push_back(s);
    }
    if (lignes.empty()) return {Valeur::videClasse(Classe::Structure)};
    return {concatener(lignes, 0)};
}

FONCTION(fnClear) {
    INUTILISE
    if (args.empty()) {
        for (const auto& n : it.nomsVariables()) it.effacerVariable(n);
        return {};
    }
    for (const auto& a : args) {
        std::string n = a.versTexte();
        if (n == "all" || n == "variables") {
            for (const auto& v : it.nomsVariables()) it.effacerVariable(v);
        } else if (n == "functions") {
            it.reindexerChemin();
        } else {
            it.effacerVariable(n);
        }
    }
    return {};
}

FONCTION(fnClc) {
    INUTILISE
    // Une interface graphique n'interprete pas les sequences ANSI : elle
    // les affichait telles quelles, « [2J[H ». Quand elle a pose son
    // crochet, c'est lui qui efface ; sinon on garde la sequence, que tout
    // terminal comprend.
    if (it.effacerEcran) {
        it.effacerEcran();
        return {};
    }
    it.sortie() << "\033[2J\033[H";
    return {};
}

FONCTION(fnMore) {
    INUTILISE
    return {};
}

FONCTION(fnDiary) {
    INUTILISE
    if (args.empty()) return {};
    std::string s = args[0].versTexte();
    if (s == "off") it.fermerJournal();
    else it.ouvrirJournal(s == "on" ? "diary" : s);
    return {};
}

FONCTION(fnExit) {
    INUTILISE
    DemandeSortie s;
    s.code = args.empty() ? 0 : (int)args[0].scal();
    throw s;
}

FONCTION(fnType) {
    INUTILISE
    exigerArguments(args, 1, 1, "type");
    std::string nom = args[0].versTexte();
    auto index = it.indexFichiers();
    auto f = index.find(nom);
    std::string fichier = f != index.end() ? f->second : nom;
    std::ifstream in(fichier);
    if (!in) {
        it.sortie() << "'" << nom << "' not found.\n";
        return {};
    }
    std::string ligne;
    while (std::getline(in, ligne)) it.sortie() << ligne << "\n";
    return {};
}

// mexext : l'extension d'un fichier MEX sur cette plateforme. MatLibre ne
// compile pas de MEX, mais la fonction existe et rend la bonne extension —
// beaucoup de toolboxes s'en servent pour composer un chemin, et sans elle
// leur script d'installation s'arrete des la premiere ligne.
FONCTION(fnMexext) {
    INUTILISE
    (void)args;
#if defined(_WIN32)
    return {Valeur::texte("mexw64")};
#elif defined(__APPLE__)
    return {Valeur::texte("mexmaci64")};
#else
    return {Valeur::texte("mexa64")};
#endif
}

// --- fiches d'aide des fonctions natives ---------------------------------
//
// L'aide d'une fonction native tenait en une ligne, la ou MATLAB donne la
// syntaxe, la description, un exemple et les fonctions voisines. Les
// fiches vivent dans toolbox/aide/*.txt, une par groupe, decoupees par une
// ligne « ### nom ». Elles sont chargees a la premiere demande et gardees.
//
// Les mettre dans des fichiers plutot que dans le code garde les lignes
// d'enregistrement lisibles, et permet d'en ajouter sans recompiler.
std::map<std::string, std::string>& fichesAide(Interpreteur& it) {
    static std::map<std::string, std::string> fiches;
    static bool chargees = false;
    if (chargees) return fiches;
    chargees = true;
    std::string racine = it.racineToolbox();
    if (racine.empty()) {
        const char* env = std::getenv("MATLIBRE_TOOLBOX");
        if (env) racine = env;
    }
    if (racine.empty()) return fiches;
    std::error_code ec;
    fs::path dossier = fs::path(racine) / "aide";
    if (!fs::is_directory(dossier, ec)) return fiches;
    for (const auto& entree : fs::directory_iterator(dossier, ec)) {
        if (!entree.is_regular_file()) continue;
        if (entree.path().extension() != ".txt") continue;
        std::ifstream f(entree.path());
        if (!f) continue;
        std::string ligne, nom, corps;
        auto poser = [&]() {
            if (nom.empty()) return;
            while (!corps.empty() && corps.back() == '\n') corps.pop_back();
            fiches[nom] = corps;
            nom.clear();
            corps.clear();
        };
        while (std::getline(f, ligne)) {
            if (ligne.rfind("### ", 0) == 0) {
                poser();
                nom = ligne.substr(4);
                while (!nom.empty() && (nom.back() == ' ' || nom.back() == '\r')) nom.pop_back();
                continue;
            }
            if (!nom.empty()) {
                if (!ligne.empty() && ligne.back() == '\r') ligne.pop_back();
                corps += ligne;
                corps += '\n';
            }
        }
        poser();
    }
    return fiches;
}

// La fiche d'une fonction, ou la ligne d'enregistrement a defaut.
std::string aideNative(Interpreteur& it, const std::string& nom, const EntreeNative* n) {
    const auto& fiches = fichesAide(it);
    auto trouve = fiches.find(nom);
    if (trouve != fiches.end()) return trouve->second;
    return n ? n->aide : std::string();
}

// --- l'aide, decoupee en sections ----------------------------------------
//
// « help » rend le texte tel quel, comme MATLAB. Mais pour le presenter —
// dans le navigateur d'aide du bureau, par exemple —, il faut savoir ou
// commencent la syntaxe, les exemples et les fonctions voisines. Le
// decoupage vaut pour les fiches natives comme pour le bloc de
// commentaires d'une fonction ecrite par l'utilisateur : les deux suivent
// la meme forme, celle de MATLAB.
struct AideDecoupee {
    std::string nom;
    std::string resume;        // la premiere ligne, sans le nom en tete
    std::string description;   // le corps, avant la premiere section
    std::vector<std::string> syntaxe;
    std::vector<std::string> exemples;
    std::vector<std::string> voirAussi;
    std::string texte;         // le tout, tel quel
};

// Retire l'indentation commune d'un bloc : les fiches indentent de quatre
// espaces, les commentaires .m de deux ou trois.
std::vector<std::string> desindenter(const std::vector<std::string>& lignes) {
    std::size_t creux = std::string::npos;
    for (const std::string& l : lignes) {
        std::size_t k = l.find_first_not_of(" \t");
        if (k == std::string::npos) continue;
        creux = std::min(creux, k);
    }
    if (creux == std::string::npos || creux == 0) return lignes;
    std::vector<std::string> sortie;
    for (const std::string& l : lignes)
        sortie.push_back(l.size() >= creux ? l.substr(creux) : std::string());
    return sortie;
}

std::string sansBlancs(const std::string& s) {
    std::size_t a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) return std::string();
    std::size_t b = s.find_last_not_of(" \t\r\n");
    return s.substr(a, b - a + 1);
}

std::string enMinuscules(std::string s) {
    for (auto& c : s) c = (char)std::tolower((unsigned char)c);
    return s;
}

// Le nom d'une section, ou vide. On accepte le francais et l'anglais :
// une fonction ecrite par l'utilisateur suit souvent MATLAB a la lettre.
std::string sectionDe(const std::string& ligne) {
    std::string t = enMinuscules(sansBlancs(ligne));
    // « Exemple : » s'ecrit avec une espace avant le deux-points en
    // francais : sans ce nettoyage, l'en-tete n'etait pas reconnu et la
    // section entiere restait dans la description.
    while (!t.empty() && (t.back() == ':' || t.back() == '.' || t.back() == ' ' ||
                          t.back() == '\t'))
        t.pop_back();
    if (t == "syntaxe" || t == "syntax" || t == "syntaxes") return "syntaxe";
    if (t == "exemple" || t == "exemples" || t == "example" || t == "examples")
        return "exemples";
    if (t == "description") return "description";
    if (t == "entrees" || t == "entrées" || t == "arguments" || t == "input arguments")
        return "description";
    return std::string();
}

AideDecoupee decouperAide(const std::string& nom, const std::string& texte) {
    AideDecoupee a;
    a.nom = nom;
    a.texte = texte;
    std::vector<std::string> lignes;
    std::istringstream flux(texte);
    std::string ligne;
    while (std::getline(flux, ligne)) {
        if (!ligne.empty() && ligne.back() == '\r') ligne.pop_back();
        lignes.push_back(ligne);
    }
    if (lignes.empty()) return a;

    // La premiere ligne est le resume, precede du nom en majuscules.
    std::string tete = sansBlancs(lignes[0]);
    std::string majuscule = enMinuscules(nom);
    std::size_t espace = tete.find_first_of(" \t");
    if (espace != std::string::npos && enMinuscules(tete.substr(0, espace)) == majuscule)
        a.resume = sansBlancs(tete.substr(espace));
    else
        a.resume = tete;

    std::string courante = "description";
    std::vector<std::string> description, syntaxe, exemples;
    for (std::size_t k = 1; k < lignes.size(); ++k) {
        const std::string& l = lignes[k];
        std::string nette = sansBlancs(l);
        std::string voirAussi = enMinuscules(nette);
        if (voirAussi.rfind("voir aussi", 0) == 0 || voirAussi.rfind("see also", 0) == 0) {
            std::size_t debut = nette.find_first_of(" ");
            debut = nette.find_first_of(" ", debut + 1);
            std::string liste = debut == std::string::npos ? std::string()
                                                           : nette.substr(debut + 1);
            // Le point sert dans « containers.Map », mais il finit aussi
            // la phrase : on le garde au milieu, jamais au bout.
            std::string mot;
            auto poser = [&]() {
                while (!mot.empty() && mot.back() == '.') mot.pop_back();
                if (!mot.empty()) a.voirAussi.push_back(enMinuscules(mot));
                mot.clear();
            };
            for (char c : liste) {
                if (std::isalnum((unsigned char)c) || c == '_' || c == '.') mot += c;
                else poser();
            }
            poser();
            courante = "fin";
            continue;
        }
        std::string section = sectionDe(l);
        if (!section.empty()) {
            courante = section;
            continue;
        }
        if (courante == "description") description.push_back(l);
        else if (courante == "syntaxe") syntaxe.push_back(l);
        else if (courante == "exemples") exemples.push_back(l);
    }
    // Les lignes vides de fin ne servent a rien.
    auto tailler = [](std::vector<std::string>& v) {
        while (!v.empty() && sansBlancs(v.back()).empty()) v.pop_back();
        while (!v.empty() && sansBlancs(v.front()).empty()) v.erase(v.begin());
    };
    tailler(description);
    tailler(syntaxe);
    tailler(exemples);
    description = desindenter(description);
    a.syntaxe = desindenter(syntaxe);
    a.exemples = desindenter(exemples);
    std::ostringstream corps;
    for (std::size_t k = 0; k < description.size(); ++k) {
        if (k) corps << "\n";
        corps << description[k];
    }
    a.description = corps.str();
    return a;
}

// Le texte d'aide d'un nom, quelle qu'en soit la source : fiche native,
// commentaires d'un fichier .m, methode d'une classe. Rend aussi d'ou il
// vient, pour que le navigateur d'aide le dise.
std::string texteAide(Interpreteur& it, const std::string& nom, std::string* source,
                      std::string* fichier) {
    if (source) *source = std::string();
    if (fichier) *fichier = std::string();
    const EntreeNative* n = it.natif(nom);
    if (n) {
        if (source) *source = "native";
        std::string t = aideNative(it, nom, n);
        if (!t.empty()) return t;
    }
    auto f = it.fonctionFichier(nom);
    if (f && !f->aide.empty()) {
        if (source) *source = f->script ? "script" : "fichier";
        if (fichier) *fichier = f->fichier;
        return f->aide;
    }
    // Une classe a son bloc d'aide comme une fonction : « help tf » et
    // « doc duration » doivent le trouver.
    if (auto c = it.classeDefinie(nom)) {
        if (!c->aide.empty()) {
            if (source) *source = "classe";
            if (fichier) *fichier = c->fichier;
            return c->aide;
        }
    }
    // Une methode de classe : son bloc de commentaires est son aide,
    // comme pour une fonction ordinaire.
    if (auto c = it.classeDeMethode(nom)) {
        auto methode = c->methodes.find(nom);
        if (methode != c->methodes.end() && methode->second &&
            !methode->second->aide.empty()) {
            if (source) *source = "methode";
            if (fichier) *fichier = c->fichier;
            return methode->second->aide;
        }
    }
    if (n) return n->aide;
    return std::string();
}

// L'aide decoupee, rendue au langage : c'est ce que lit le navigateur
// d'aide du bureau, et ce qui permet a un script de fabriquer sa propre
// presentation.
FONCTION(fnAideStructuree) {
    INUTILISE
    exigerArguments(args, 1, 1, "matlibre_aide_structuree");
    std::string nom = args[0].versTexte();
    std::string source, fichier;
    std::string texte = texteAide(it, nom, &source, &fichier);
    AideDecoupee a = decouperAide(nom, texte);
    Valeur s = Valeur::structureVide();
    s.poserChamp("Nom", Valeur::texte(nom));
    s.poserChamp("Resume", Valeur::texte(a.resume));
    s.poserChamp("Description", Valeur::texte(a.description));
    auto enCellule = [](const std::vector<std::string>& v) {
        std::vector<Valeur> c;
        for (const std::string& l : v) c.push_back(Valeur::texte(l));
        return Valeur::celluleLigne(c);
    };
    s.poserChamp("Syntaxe", enCellule(a.syntaxe));
    s.poserChamp("Exemples", enCellule(a.exemples));
    s.poserChamp("VoirAussi", enCellule(a.voirAussi));
    s.poserChamp("Texte", Valeur::texte(a.texte));
    s.poserChamp("Source", Valeur::texte(source));
    s.poserChamp("Fichier", Valeur::texte(fichier));
    return {s};
}

FONCTION(fnHelp) {
    INUTILISE
    if (args.empty()) {
        // Comme MATLAB : « help » affiche, « t = help » rend le texte.
        std::ostringstream general;
        general << "MatLibre " << MATLIBRE_VERSION
                << " — tapez « help nom » pour l'aide d'une fonction,\n"
                   "« lookfor motif » pour chercher, « ver » pour la version.\n"
                   "« doc nom » ouvre la documentation complete : syntaxe, "
                   "description,\nexemples et fonctions voisines.\n";
        if (nargout > 0) return {Valeur::texte(general.str())};
        it.sortie() << general.str();
        return {};
    }
    std::string nom = args[0].versTexte();
    std::string source, fichier;
    std::string texte = texteAide(it, nom, &source, &fichier);
    if (!texte.empty()) {
        if (!texte.empty() && texte.back() != '\n') texte += "\n";
        if (nargout > 0) return {Valeur::texte(texte)};
        it.sortie() << texte;
        // Comme MATLAB, qui renvoie vers sa documentation en fin d'aide.
        it.sortie() << "\n    Documentation : doc " << nom << "\n";
        if (!fichier.empty()) it.sortie() << "    Defini dans : " << fichier << "\n";
        return {};
    }
    if (nargout > 0) return {Valeur::texte("")};
    it.sortie() << "'" << nom << "' not found.\n";
    return {};
}

// « doc nom » : sous MATLAB, la documentation s'ouvre dans une fenetre. Le
// bureau en pose une ; a la console, on affiche le meme texte, mais mis en
// page — titre, syntaxe, exemples, voisines — au lieu du bloc brut.
FONCTION(fnDoc) {
    INUTILISE
    if (args.empty()) {
        if (it.crochetDocumentation) {
            it.crochetDocumentation(std::string());
            return {};
        }
        it.sortie() << "doc  Tapez « doc nom » pour la documentation d'une fonction.\n";
        return {};
    }
    std::string nom = args[0].versTexte();
    // Le bureau ouvre son navigateur d'aide ; sans lui, on imprime.
    if (it.crochetDocumentation) {
        it.crochetDocumentation(nom);
        return {};
    }
    std::string source, fichier;
    std::string texte = texteAide(it, nom, &source, &fichier);
    if (texte.empty()) {
        it.sortie() << "'" << nom << "' not found.\n";
        return {};
    }
    AideDecoupee a = decouperAide(nom, texte);
    std::string titre = nom;
    for (auto& c : titre) c = (char)std::toupper((unsigned char)c);
    it.sortie() << "\n" << titre << "\n" << std::string(titre.size(), '=') << "\n";
    if (!a.resume.empty()) it.sortie() << a.resume << "\n";
    if (!a.description.empty()) it.sortie() << "\n" << a.description << "\n";
    if (!a.syntaxe.empty()) {
        it.sortie() << "\nSyntaxe\n";
        for (const std::string& l : a.syntaxe) it.sortie() << "   " << l << "\n";
    }
    if (!a.exemples.empty()) {
        it.sortie() << "\nExemples\n";
        for (const std::string& l : a.exemples) it.sortie() << "   " << l << "\n";
    }
    if (!a.voirAussi.empty()) {
        it.sortie() << "\nVoir aussi";
        for (std::size_t k = 0; k < a.voirAussi.size(); ++k)
            it.sortie() << (k ? ", " : " ") << a.voirAussi[k];
        it.sortie() << "\n";
    }
    if (source == "fichier" || source == "script")
        it.sortie() << "\nDefini dans : " << fichier << "\n";
    else
        it.sortie() << "\nFonction native de MatLibre.\n";
    return {};
}

FONCTION(fnLookfor) {
    INUTILISE
    exigerArguments(args, 1, 1, "lookfor");
    std::string motif = args[0].versTexte();
    for (const auto& nom : it.nomsNatifs()) {
        const EntreeNative* n = it.natif(nom);
        if (!n) continue;
        std::string aide = n->aide;
        std::string minuscule;
        for (char c : aide) minuscule += (char)std::tolower((unsigned char)c);
        std::string cible;
        for (char c : motif) cible += (char)std::tolower((unsigned char)c);
        if (minuscule.find(cible) != std::string::npos || nom.find(motif) != std::string::npos)
            it.sortie() << formater("%-16s %s\n", nom.c_str(),
                                    aide.substr(0, aide.find('\n')).c_str());
    }
    return {};
}

FONCTION(fnDocFonctions) {
    INUTILISE
    // Liste toutes les fonctions natives, par groupe : sert à la
    // documentation générée et au test de couverture.
    auto noms = it.nomsNatifs();
    Valeur c = Valeur::celluleDims({(int)noms.size(), 2});
    for (std::size_t k = 0; k < noms.size(); ++k) {
        const EntreeNative* n = it.natif(noms[k]);
        c.cellules[k] = Valeur::texte(noms[k]);
        c.cellules[k + noms.size()] = Valeur::texte(n ? n->groupe : "");
    }
    return {c};
}

FONCTION(fnMemory) {
    INUTILISE
    Valeur v = Valeur::structureVide();
    v.poserChamp("MaxPossibleArrayBytes", Valeur::scalaire(1e10));
    v.poserChamp("MemAvailableAllArrays", Valeur::scalaire(1e10));
    return {v};
}

FONCTION(fnBeep) {
    INUTILISE
    it.sortie() << "\a";
    return {};
}

FONCTION(fnGraphicsToolkit) {
    INUTILISE
    return {Valeur::texte("svg")};
}

FONCTION(fnMaxNumCompThreads) {
    INUTILISE
    return {Valeur::scalaire(1)};
}

FONCTION(fnGetpid) {
    INUTILISE
    return {Valeur::scalaire((double)identifiantProcessus())};
}


FONCTION(fnMfilename) {
    INUTILISE
    // Nom du fichier en cours : celui de la fonction si l'on est dedans,
    // sinon celui du script exécuté.
    std::string chemin;
    for (int k = it.profondeur() - 1; k >= 0; --k) {
        const Portee& p = it.porteeNumero(k);
        if (p.fonction && !p.fonction->fichier.empty()) {
            chemin = p.fonction->fichier;
            break;
        }
    }
    if (chemin.empty()) chemin = it.fichierCourant;
    std::string mode = args.empty() ? std::string() : args[0].versTexte();
    if (chemin.empty()) return {Valeur::texte("")};
    fs::path p(chemin);
    if (mode == "fullpath") {
        std::error_code ec;
        fs::path absolu = fs::absolute(p, ec);
        if (ec) absolu = p;
        absolu.replace_extension();
        return {Valeur::texte(absolu.string())};
    }
    if (mode == "class") return {Valeur::texte("")};
    return {Valeur::texte(p.stem().string())};
}


FONCTION(fnIsfolder) {
    INUTILISE
    exigerArguments(args, 1, 1, "isfolder");
    if (args[0].classe == Classe::Cellule) {
        Valeur r = Valeur::matriceDims(args[0].dims, 0.0);
        r.classe = Classe::Logique;
        for (std::size_t k = 0; k < args[0].cellules.size(); ++k) {
            std::error_code ec;
            r.re[k] = fs::is_directory(args[0].cellules[k].versTexte(), ec) ? 1.0 : 0.0;
        }
        return {r};
    }
    std::error_code ec;
    return {Valeur::booleen(fs::is_directory(args[0].versTexte(), ec))};
}

FONCTION(fnIsfile) {
    INUTILISE
    exigerArguments(args, 1, 1, "isfile");
    if (args[0].classe == Classe::Cellule) {
        Valeur r = Valeur::matriceDims(args[0].dims, 0.0);
        r.classe = Classe::Logique;
        for (std::size_t k = 0; k < args[0].cellules.size(); ++k) {
            std::error_code ec;
            r.re[k] = fs::is_regular_file(args[0].cellules[k].versTexte(), ec) ? 1.0 : 0.0;
        }
        return {r};
    }
    std::error_code ec;
    return {Valeur::booleen(fs::is_regular_file(args[0].versTexte(), ec))};
}


FONCTION(fnRacineToolbox) {
    INUTILISE
    // La racine réelle, telle que le démarrage l'a trouvée : la variable
    // d'environnement n'est pas toujours posée.
    return {Valeur::texte(it.racineToolbox())};
}

}  // namespace

void enregistrerSysteme(Interpreteur& it) {
    it.enregistrer("pwd", fnPwd, "systeme", "pwd  Dossier courant.");
    it.enregistrer("cd", fnCd, "systeme", "cd  Change de dossier.");
    it.enregistrer("dir", fnDir, "systeme", "dir  Liste un dossier.");
    it.enregistrer("ls", fnLs, "systeme", "ls  Liste un dossier.");
    it.enregistrer("mkdir", fnMkdir, "systeme", "mkdir  Cree un dossier.");
    it.enregistrer("rmdir", fnRmdir, "systeme", "rmdir  Supprime un dossier.");
    it.enregistrer("delete", fnDelete, "systeme", "delete  Supprime des fichiers.");
    it.enregistrer("isfolder", fnIsfolder, "systeme", "isfolder  Vrai pour un dossier.");
    it.enregistrer("matlibre_racine", fnRacineToolbox, "systeme",
                   "matlibre_racine  Dossier racine des toolboxes.");
    it.enregistrer("isfile", fnIsfile, "systeme", "isfile  Vrai pour un fichier ordinaire.");
    it.enregistrer("mfilename", fnMfilename, "systeme",
                   "mfilename  Nom du fichier en cours d'execution.");
    it.enregistrer("copyfile", fnCopyfile, "systeme", "copyfile  Copie un fichier.");
    it.enregistrer("movefile", fnMovefile, "systeme", "movefile  Deplace un fichier.");
    it.enregistrer("fullfile", fnFullfile, "systeme", "fullfile  Assemble un chemin.");
    it.enregistrer("fileparts", fnFileparts, "systeme", "fileparts  Decompose un chemin.");
    it.enregistrer("filesep", fnFilesep, "systeme", "filesep  Separateur de chemin.");
    it.enregistrer("pathsep", fnPathsep, "systeme", "pathsep  Separateur de liste de chemins.");
    it.enregistrer("tempdir", fnTempdir, "systeme", "tempdir  Dossier temporaire.");
    it.enregistrer("tempname", fnTempname, "systeme", "tempname  Nom de fichier temporaire.");
    it.enregistrer("getenv", fnGetenv, "systeme", "getenv  Variable d'environnement.");
    it.enregistrer("setenv", fnSetenv, "systeme", "setenv  Pose une variable d'environnement.");
    it.enregistrer("system", fnSystem, "systeme", "system  Execute une commande du systeme.");
    it.enregistrer("unix", fnSystem, "systeme", "unix  Execute une commande du systeme.");
    it.enregistrer("dos", fnSystem, "systeme", "dos  Execute une commande du systeme.");
    it.enregistrer("computer", fnComputer, "systeme", "computer  Plateforme d'execution.");
    it.enregistrer("mexext", fnMexext, "systeme",
                   "mexext  Extension des fichiers MEX de cette plateforme.");
    it.enregistrer("version", fnVersion, "systeme", "version  Version de l'interpreteur.");
    it.enregistrer("ver", fnVer, "systeme", "ver  Version detaillee.");
    it.enregistrer("isunix", fnIsunix, "systeme", "isunix  Systeme de type UNIX ?");
    it.enregistrer("ispc", fnIspc, "systeme", "ispc  Systeme Windows ?");
    it.enregistrer("ismac", fnIsmac, "systeme", "ismac  Systeme macOS ?");
    it.enregistrer("addpath", fnAddpath, "systeme", "addpath  Ajoute au chemin de recherche.");
    it.enregistrer("rmpath", fnRmpath, "systeme", "rmpath  Retire du chemin de recherche.");
    it.enregistrer("path", fnPath, "systeme", "path  Chemin de recherche.");
    it.enregistrer("rehash", fnRehash, "systeme", "rehash  Reconstruit l'index du chemin.");
    it.enregistrer("which", fnWhich, "systeme", "which  Ou se trouve une fonction.");
    it.enregistrer("who", fnWho, "systeme", "who  Liste les variables.");
    it.enregistrer("whos", fnWhos, "systeme", "whos  Liste detaillee des variables.");
    it.enregistrer("clear", fnClear, "systeme", "clear  Efface des variables.");
    it.enregistrer("clc", fnClc, "systeme", "clc  Efface l'ecran.");
    it.enregistrer("more", fnMore, "systeme", "more  Pagination (sans effet).");
    it.enregistrer("diary", fnDiary, "systeme", "diary  Journalise la session.");
    it.enregistrer("exit", fnExit, "systeme", "exit  Quitte l'interpreteur.");
    it.enregistrer("quit", fnExit, "systeme", "quit  Quitte l'interpreteur.");
    it.enregistrer("type", fnType, "systeme", "type  Affiche le source d'un fichier.");
    it.enregistrer("help", fnHelp, "systeme", "help  Aide d'une fonction.");
    it.enregistrer("doc", fnDoc, "systeme",
                   "doc  Documentation d'une fonction, mise en page.");
    it.enregistrer("matlibre_aide_structuree", fnAideStructuree, "systeme",
                   "matlibre_aide_structuree  Aide decoupee en sections.");
    it.enregistrer("lookfor", fnLookfor, "systeme", "lookfor  Cherche dans les aides.");
    it.enregistrer("matlibre_fonctions", fnDocFonctions, "systeme",
                   "matlibre_fonctions  Liste des fonctions natives et de leur groupe.");
    it.enregistrer("memory", fnMemory, "systeme", "memory  Memoire disponible.");
    it.enregistrer("beep", fnBeep, "systeme", "beep  Emet un bip.");
    it.enregistrer("graphics_toolkit", fnGraphicsToolkit, "systeme",
                   "graphics_toolkit  Moteur graphique utilise.");
    it.enregistrer("maxNumCompThreads", fnMaxNumCompThreads, "systeme",
                   "maxNumCompThreads  Nombre de fils de calcul.");
    it.enregistrer("getpid", fnGetpid, "systeme", "getpid  Identifiant du processus.");
}

}  // namespace matlibre
