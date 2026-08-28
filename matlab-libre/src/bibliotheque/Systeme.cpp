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
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
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
#ifndef _WIN32
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

FONCTION(fnHelp) {
    INUTILISE
    if (args.empty()) {
        it.sortie() << "MatLibre " << MATLIBRE_VERSION
                    << " — tapez « help nom » pour l'aide d'une fonction,\n"
                       "« lookfor motif » pour chercher, « ver » pour la version.\n";
        return {};
    }
    std::string nom = args[0].versTexte();
    const EntreeNative* n = it.natif(nom);
    if (n) {
        if (nargout > 0) return {Valeur::texte(n->aide)};
        it.sortie() << n->aide << "\n";
        return {};
    }
    auto f = it.fonctionFichier(nom);
    if (f && !f->aide.empty()) {
        if (nargout > 0) return {Valeur::texte(f->aide)};
        it.sortie() << f->aide;
        return {};
    }
    it.sortie() << "'" << nom << "' not found.\n";
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
    it.enregistrer("doc", fnHelp, "systeme", "doc  Aide d'une fonction.");
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
