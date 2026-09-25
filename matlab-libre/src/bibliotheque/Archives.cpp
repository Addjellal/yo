// Archives.cpp — ZIP et UNZIP, sans commande extérieure.
//
// Une archive ZIP est une suite d'entrées, chacune précédée d'un en-tête
// local, puis un répertoire central qui les recense, puis un
// enregistrement de fin qui dit où trouver le répertoire. On lit par la
// fin : le répertoire central porte les tailles et les décalages exacts,
// même quand l'en-tête local les a laissés à zéro. Une entrée est soit
// stockée telle quelle, soit comprimée par DEFLATE, que le décodeur de
// Compression.h sait défaire.
//
// C'est ce qui permet de lire un modèle .slx de Simulink — une archive de
// fichiers XML — partout, là où ZIP et UNZIP passaient par les commandes
// « zip » et « unzip » du système, absentes de Windows.
//
// À l'écriture, les entrées sont stockées : l'archive est valide et se
// relit avec n'importe quel outil, au prix de la place.
#include <array>
#include <cstdint>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Compression.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {

namespace fs = std::filesystem;

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

namespace {

std::uint32_t crc32(const std::string& donnees) {
    static std::array<std::uint32_t, 256> table = [] {
        std::array<std::uint32_t, 256> t{};
        for (std::uint32_t n = 0; n < 256; ++n) {
            std::uint32_t c = n;
            for (int k = 0; k < 8; ++k) c = (c & 1) ? 0xEDB88320u ^ (c >> 1) : c >> 1;
            t[n] = c;
        }
        return t;
    }();
    std::uint32_t c = 0xFFFFFFFFu;
    for (unsigned char o : donnees) c = table[(c ^ o) & 0xFF] ^ (c >> 8);
    return c ^ 0xFFFFFFFFu;
}

std::uint32_t lire16(const std::string& d, std::size_t p) {
    if (p + 2 > d.size()) erreur("MATLAB:unzip:invalidZipFile", "The ZIP archive is truncated.");
    return (std::uint32_t)(unsigned char)d[p] | ((std::uint32_t)(unsigned char)d[p + 1] << 8);
}

std::uint32_t lire32(const std::string& d, std::size_t p) {
    return lire16(d, p) | (lire16(d, p + 2) << 16);
}

void ecrire16(std::string& d, std::uint32_t v) {
    d.push_back((char)(v & 0xFF));
    d.push_back((char)((v >> 8) & 0xFF));
}

void ecrire32(std::string& d, std::uint32_t v) {
    ecrire16(d, v & 0xFFFF);
    ecrire16(d, v >> 16);
}

struct Entree {
    std::string nom;
    std::string contenu;
};

// Les entrées d'une archive, lues et décompressées, CRC vérifié.
std::vector<Entree> lireArchive(const std::string& fichier) {
    std::ifstream f(fichier, std::ios::binary);
    if (!f)
        erreur("MATLAB:unzip:invalidZipFile",
               "Unable to open file '" + fichier + "' as a ZIP archive.");
    std::ostringstream ss;
    ss << f.rdbuf();
    const std::string d = ss.str();
    // L'enregistrement de fin : 22 octets, plus un commentaire d'au plus
    // 65535 octets, à chercher en remontant depuis la fin.
    std::size_t fin = std::string::npos;
    if (d.size() >= 22) {
        const std::size_t plancher = d.size() >= 22 + 65535 ? d.size() - 22 - 65535 : 0;
        for (std::size_t p = d.size() - 22 + 1; p-- > plancher;) {
            if (lire32(d, p) == 0x06054b50u) {
                fin = p;
                break;
            }
        }
    }
    if (fin == std::string::npos)
        erreur("MATLAB:unzip:invalidZipFile",
               "'" + fichier + "' is not a ZIP archive: no end of central directory.");
    const std::size_t nombre = lire16(d, fin + 10);
    std::size_t p = lire32(d, fin + 16);
    std::vector<Entree> entrees;
    for (std::size_t k = 0; k < nombre; ++k) {
        if (lire32(d, p) != 0x02014b50u)
            erreur("MATLAB:unzip:invalidZipFile", "The ZIP central directory is corrupt.");
        const std::uint32_t methode = lire16(d, p + 10);
        const std::uint32_t crc = lire32(d, p + 16);
        const std::uint32_t taille = lire32(d, p + 20);
        const std::uint32_t tailleNette = lire32(d, p + 24);
        const std::size_t longNom = lire16(d, p + 28);
        const std::size_t longExtra = lire16(d, p + 30);
        const std::size_t longCommentaire = lire16(d, p + 32);
        const std::size_t local = lire32(d, p + 42);
        if (taille == 0xFFFFFFFFu || tailleNette == 0xFFFFFFFFu || local == 0xFFFFFFFFu)
            erreur("MATLAB:unzip:invalidZipFile",
                   "ZIP64 archives, beyond 4 GB, are not supported.");
        Entree e;
        e.nom = d.substr(p + 46, longNom);
        p += 46 + longNom + longExtra + longCommentaire;
        if (lire32(d, local) != 0x04034b50u)
            erreur("MATLAB:unzip:invalidZipFile", "A ZIP local header is corrupt.");
        const std::size_t debut = local + 30 + lire16(d, local + 26) + lire16(d, local + 28);
        if (debut + taille > d.size())
            erreur("MATLAB:unzip:invalidZipFile", "The ZIP entry '" + e.nom + "' is truncated.");
        const auto* octets = reinterpret_cast<const unsigned char*>(d.data()) + debut;
        if (methode == 0) {
            e.contenu.assign(d, debut, taille);
        } else if (methode == 8) {
            e.contenu = inflater(octets, taille, tailleNette);
        } else {
            erreur("MATLAB:unzip:invalidZipFile",
                   formater("The ZIP entry '%s' uses compression method %u, which is not "
                            "supported: only stored (0) and deflated (8) entries are.",
                            e.nom.c_str(), methode));
        }
        if (e.contenu.size() != tailleNette || crc32(e.contenu) != crc)
            erreur("MATLAB:unzip:invalidZipFile",
                   "The ZIP entry '" + e.nom + "' fails its CRC-32 check.");
        entrees.push_back(std::move(e));
    }
    return entrees;
}

// L'heure et la date au format de MS-DOS, que porte chaque en-tête.
void dateDos(std::uint32_t& heure, std::uint32_t& date) {
    std::time_t maintenant = std::time(nullptr);
    std::tm t{};
#if defined(_WIN32)
    localtime_s(&t, &maintenant);
#else
    localtime_r(&maintenant, &t);
#endif
    heure = (std::uint32_t)((t.tm_hour << 11) | (t.tm_min << 5) | (t.tm_sec / 2));
    date = (std::uint32_t)(((t.tm_year - 80) << 9) | ((t.tm_mon + 1) << 5) | t.tm_mday);
}

void ecrireArchive(const std::string& fichier, const std::vector<Entree>& entrees) {
    std::string d;
    std::string central;
    std::uint32_t heure = 0, date = 0;
    dateDos(heure, date);
    for (const Entree& e : entrees) {
        if (e.contenu.size() > 0xFFFFFFFEu || d.size() > 0xFFFFFFFEu)
            erreur("MATLAB:zip:tooLarge", "ZIP64 archives, beyond 4 GB, are not supported.");
        const std::uint32_t crc = crc32(e.contenu);
        const std::uint32_t decalage = (std::uint32_t)d.size();
        // En-tête local : version 2.0, drapeau 11 (noms en UTF-8), stocké.
        ecrire32(d, 0x04034b50u);
        ecrire16(d, 20);
        ecrire16(d, 0x0800);
        ecrire16(d, 0);
        ecrire16(d, heure);
        ecrire16(d, date);
        ecrire32(d, crc);
        ecrire32(d, (std::uint32_t)e.contenu.size());
        ecrire32(d, (std::uint32_t)e.contenu.size());
        ecrire16(d, (std::uint32_t)e.nom.size());
        ecrire16(d, 0);
        d += e.nom;
        d += e.contenu;
        // Et sa ligne du répertoire central.
        ecrire32(central, 0x02014b50u);
        ecrire16(central, 20);
        ecrire16(central, 20);
        ecrire16(central, 0x0800);
        ecrire16(central, 0);
        ecrire16(central, heure);
        ecrire16(central, date);
        ecrire32(central, crc);
        ecrire32(central, (std::uint32_t)e.contenu.size());
        ecrire32(central, (std::uint32_t)e.contenu.size());
        ecrire16(central, (std::uint32_t)e.nom.size());
        ecrire16(central, 0);
        ecrire16(central, 0);
        ecrire16(central, 0);
        ecrire16(central, 0);
        ecrire32(central, 0);
        ecrire32(central, decalage);
        central += e.nom;
    }
    const std::uint32_t debutCentral = (std::uint32_t)d.size();
    d += central;
    ecrire32(d, 0x06054b50u);
    ecrire16(d, 0);
    ecrire16(d, 0);
    ecrire16(d, (std::uint32_t)entrees.size());
    ecrire16(d, (std::uint32_t)entrees.size());
    ecrire32(d, (std::uint32_t)central.size());
    ecrire32(d, debutCentral);
    ecrire16(d, 0);
    std::ofstream f(fichier, std::ios::binary);
    if (!f) erreur("MATLAB:zip:cannotOpenFile", "Unable to write the ZIP archive '" + fichier + "'.");
    f.write(d.data(), (std::streamsize)d.size());
}

std::vector<std::string> listeDeNoms(const Valeur& v) {
    std::vector<std::string> noms;
    if (v.classe == Classe::Cellule) {
        for (const Valeur& c : v.cellules) noms.push_back(c.versTexte());
    } else if (v.estChaine()) {
        for (const auto& c : v.chaines) noms.push_back(c);
    } else {
        noms.push_back(v.versTexte());
    }
    return noms;
}

// Un nom d'entrée ne sort pas du dossier de destination : « ../x » ou un
// chemin absolu dans une archive hostile écriraient n'importe où.
bool nomSur(const std::string& nom) {
    if (nom.empty() || nom[0] == '/' || nom[0] == '\\') return false;
    if (nom.size() > 1 && nom[1] == ':') return false;
    fs::path chemin(nom);
    for (const auto& partie : chemin)
        if (partie == "..") return false;
    return true;
}

}  // namespace

// unzip(archive, dossier) : extrait, et rend les chemins des fichiers.
FONCTION(fnUnzip) {
    INUTILISE
    exigerArguments(args, 1, 2, "unzip");
    const std::string archive = args[0].versTexte();
    const fs::path dossier = args.size() > 1 ? fs::path(args[1].versTexte()) : fs::current_path();
    std::vector<Entree> entrees = lireArchive(archive);
    std::vector<Valeur> chemins;
    for (const Entree& e : entrees) {
        if (!nomSur(e.nom))
            erreur("MATLAB:unzip:invalidEntry",
                   "The ZIP entry '" + e.nom + "' would be written outside the output folder.");
        const fs::path cible = dossier / fs::path(e.nom);
        std::error_code ec;
        if (!e.nom.empty() && (e.nom.back() == '/' || e.nom.back() == '\\')) {
            fs::create_directories(cible, ec);
            continue;
        }
        fs::create_directories(cible.parent_path(), ec);
        std::ofstream f(cible, std::ios::binary);
        if (!f)
            erreur("MATLAB:unzip:cannotWriteFile", "Unable to write '" + cible.string() + "'.");
        f.write(e.contenu.data(), (std::streamsize)e.contenu.size());
        chemins.push_back(Valeur::texte(cible.string()));
    }
    return {Valeur::celluleLigne(chemins)};
}

// zip(archive, fichiers, racine) : les fichiers — ou les dossiers, pris
// avec leur contenu — sont rangés sous leur chemin relatif à la racine.
FONCTION(fnZip) {
    INUTILISE
    exigerArguments(args, 2, 3, "zip");
    std::string archive = args[0].versTexte();
    if (fs::path(archive).extension().empty()) archive += ".zip";
    const fs::path racine = args.size() > 2 ? fs::path(args[2].versTexte()) : fs::current_path();
    std::vector<Entree> entrees;
    std::vector<Valeur> noms;
    auto ajouter = [&](const fs::path& chemin, const std::string& nom) {
        std::ifstream f(chemin, std::ios::binary);
        if (!f) erreur("MATLAB:zip:fileNotFound", "File '" + chemin.string() + "' not found.");
        std::ostringstream ss;
        ss << f.rdbuf();
        entrees.push_back({nom, ss.str()});
        noms.push_back(Valeur::texte(nom));
    };
    for (const std::string& demande : listeDeNoms(args[1])) {
        fs::path chemin = fs::path(demande);
        if (chemin.is_relative()) chemin = racine / chemin;
        std::error_code ec;
        if (fs::is_directory(chemin, ec)) {
            for (const auto& e : fs::recursive_directory_iterator(chemin, ec)) {
                if (!e.is_regular_file()) continue;
                ajouter(e.path(), fs::relative(e.path(), racine, ec).generic_string());
            }
            continue;
        }
        if (!fs::exists(chemin, ec))
            erreur("MATLAB:zip:fileNotFound", "File '" + demande + "' not found.");
        std::string nom = fs::relative(chemin, racine, ec).generic_string();
        if (nom.empty() || !nomSur(nom)) nom = chemin.filename().generic_string();
        ajouter(chemin, nom);
    }
    ecrireArchive(archive, entrees);
    return {Valeur::celluleLigne(noms)};
}

void enregistrerArchives(Interpreteur& it) {
    it.enregistrer("unzip", fnUnzip, "es", "unzip  Extrait une archive ZIP.");
    it.enregistrer("zip", fnZip, "es", "zip  Fabrique une archive ZIP.");
}

}  // namespace matlibre
