// Atelier.cpp — le serveur de l'atelier et son protocole.
#include "matlibre/Atelier.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <cmath>
#include <cstdio>
#include <cstring>
#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <mutex>
#include <queue>
#include <sstream>
#include <streambuf>
#include <thread>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Graphique.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Serveur.h"
#include "matlibre/Version.h"

namespace fs = std::filesystem;

namespace matlibre {
namespace {

// --- JSON : juste ce qu'il faut, écrit à la main -------------------------

std::string echapperJson(const std::string& texte) {
    std::string sortie;
    sortie.reserve(texte.size() + 16);
    for (unsigned char c : texte) {
        switch (c) {
            case '"':  sortie += "\\\""; break;
            case '\\': sortie += "\\\\"; break;
            case '\n': sortie += "\\n"; break;
            case '\r': sortie += "\\r"; break;
            case '\t': sortie += "\\t"; break;
            default:
                if (c < 0x20) {
                    char tampon[8];
                    std::snprintf(tampon, sizeof(tampon), "\\u%04x", c);
                    sortie += tampon;
                } else {
                    sortie += (char)c;
                }
        }
    }
    return sortie;
}

std::string chaineJson(const std::string& texte) { return "\"" + echapperJson(texte) + "\""; }

std::string nombreJson(double x) {
    if (std::isnan(x)) return "null";
    if (std::isinf(x)) return x > 0 ? "1e999" : "-1e999";
    std::ostringstream o;
    o.precision(17);
    o << x;
    return o.str();
}

// Lecture d'un champ de haut niveau dans un objet JSON simple. L'atelier
// n'envoie que des objets plats : c'est suffisant, et sans surprise.
std::string champJson(const std::string& json, const std::string& nom) {
    std::string cle = "\"" + nom + "\"";
    std::size_t p = json.find(cle);
    if (p == std::string::npos) return std::string();
    p = json.find(':', p + cle.size());
    if (p == std::string::npos) return std::string();
    ++p;
    while (p < json.size() && std::isspace((unsigned char)json[p])) ++p;
    if (p >= json.size()) return std::string();
    if (json[p] == '"') {
        std::string sortie;
        ++p;
        while (p < json.size() && json[p] != '"') {
            if (json[p] == '\\' && p + 1 < json.size()) {
                ++p;
                switch (json[p]) {
                    case 'n': sortie += '\n'; break;
                    case 'r': sortie += '\r'; break;
                    case 't': sortie += '\t'; break;
                    case 'u': {
                        if (p + 4 < json.size()) {
                            int code = std::stoi(json.substr(p + 1, 4), nullptr, 16);
                            if (code < 0x80) {
                                sortie += (char)code;
                            } else if (code < 0x800) {
                                sortie += (char)(0xC0 | (code >> 6));
                                sortie += (char)(0x80 | (code & 0x3F));
                            } else {
                                sortie += (char)(0xE0 | (code >> 12));
                                sortie += (char)(0x80 | ((code >> 6) & 0x3F));
                                sortie += (char)(0x80 | (code & 0x3F));
                            }
                            p += 4;
                        }
                        break;
                    }
                    default: sortie += json[p];
                }
            } else {
                sortie += json[p];
            }
            ++p;
        }
        return sortie;
    }
    std::size_t fin = p;
    while (fin < json.size() && json[fin] != ',' && json[fin] != '}' && json[fin] != ']') ++fin;
    std::string brut = json.substr(p, fin - p);
    while (!brut.empty() && std::isspace((unsigned char)brut.back())) brut.pop_back();
    return brut;
}

// --- tampon de sortie partagé -------------------------------------------

class TamponPartage : public std::streambuf {
public:
    std::string prendre() {
        std::lock_guard<std::mutex> garde(verrou_);
        std::string copie = texte_;
        texte_.clear();
        return copie;
    }
    std::string voir() {
        std::lock_guard<std::mutex> garde(verrou_);
        return texte_;
    }

protected:
    int overflow(int c) override {
        if (c != EOF) {
            std::lock_guard<std::mutex> garde(verrou_);
            texte_ += (char)c;
            if (texte_.size() > 4u * 1024u * 1024u) texte_.erase(0, texte_.size() / 2);
        }
        return c;
    }
    std::streamsize xsputn(const char* s, std::streamsize n) override {
        std::lock_guard<std::mutex> garde(verrou_);
        texte_.append(s, (std::size_t)n);
        if (texte_.size() > 4u * 1024u * 1024u) texte_.erase(0, texte_.size() / 2);
        return n;
    }

private:
    std::mutex verrou_;
    std::string texte_;
};

// --- état de l'atelier ----------------------------------------------------

struct Atelier {
    Interpreteur it;
    TamponPartage tampon;
    std::ostream sortie{&tampon};

    std::mutex verrou;
    std::condition_variable signal;
    std::queue<std::string> commandes;
    std::atomic<bool> tourne{true};
    std::atomic<bool> occupe{false};
    std::atomic<bool> arrete{false};      // arrêté sur un point d'arrêt
    std::string fichierArret;
    int ligneArret = 0;
    std::atomic<long long> sequence{0};   // incrémentée à chaque fin de commande
    std::string racineWeb;

    // Le débogueur attend ici que l'interface envoie une reprise.
    std::mutex verrouDebug;
    std::condition_variable signalDebug;
    bool repriseDemandee = false;
};

Atelier* atelier = nullptr;

void crochetArretAtelier(Interpreteur& it, const std::string& fichier, int ligne) {
    if (!atelier) return;
    atelier->arrete = true;
    atelier->fichierArret = fichier;
    atelier->ligneArret = ligne;
    std::unique_lock<std::mutex> garde(atelier->verrouDebug);
    atelier->repriseDemandee = false;
    atelier->signalDebug.wait(garde, [] { return atelier->repriseDemandee || !atelier->tourne; });
    atelier->arrete = false;
    (void)it;
}

void filInterprete() {
    for (;;) {
        std::string commande;
        {
            std::unique_lock<std::mutex> garde(atelier->verrou);
            atelier->signal.wait(garde, [] {
                return !atelier->commandes.empty() || !atelier->tourne;
            });
            if (!atelier->tourne && atelier->commandes.empty()) return;
            commande = atelier->commandes.front();
            atelier->commandes.pop();
        }
        atelier->occupe = true;
        try {
            atelier->it.executerTexte(commande, "<atelier>");
        } catch (const ErreurMatlab& e) {
            atelier->sortie << "Error: " << e.message << "\n";
        } catch (const std::exception& e) {
            atelier->sortie << "Error: " << e.what() << "\n";
        }
        atelier->occupe = false;
        atelier->sequence++;
    }
}

// --- description d'une valeur pour l'explorateur -------------------------

std::string resumeValeur(Interpreteur& it, const Valeur& v) {
    std::ostringstream o;
    if (v.estScalaire() && v.estNumerique() && !v.estComplexe()) {
        o << nombreJson(v.re[0]);
        return o.str().substr(0, 64);
    }
    if (v.estTexte() && v.nlignes() <= 1) return "'" + v.versTexte().substr(0, 60) + "'";
    std::string rendu = rendreValeur(v, (int)it.format, true, 60);
    if (rendu.size() > 200) rendu = rendu.substr(0, 200) + "...";
    return rendu;
}

std::string dimensionsTexte(const Valeur& v) {
    std::ostringstream o;
    for (std::size_t k = 0; k < v.dims.size(); ++k) {
        if (k) o << "x";
        o << v.dims[k];
    }
    return o.str();
}

std::string classeTexte(const Valeur& v) {
    switch (v.classe) {
        case Classe::Double:    return "double";
        case Classe::Simple:    return "single";
        case Classe::Logique:   return "logical";
        case Classe::Caractere: return "char";
        case Classe::Chaine:    return "string";
        case Classe::Cellule:   return "cell";
        case Classe::Structure: return "struct";
        case Classe::Fonction:  return "function_handle";
        case Classe::Objet:     return v.nomObjet.empty() ? "object" : v.nomObjet;
        case Classe::Int8:      return "int8";
        case Classe::Int16:     return "int16";
        case Classe::Int32:     return "int32";
        case Classe::Int64:     return "int64";
        case Classe::UInt8:     return "uint8";
        case Classe::UInt16:    return "uint16";
        case Classe::UInt32:    return "uint32";
        case Classe::UInt64:    return "uint64";
    }
    return "double";
}

std::string jsonEspaceTravail() {
    std::ostringstream o;
    o << "[";
    bool premier = true;
    // L'espace de travail ne se lit sans risque que si le fil est au repos.
    if (!atelier->occupe || atelier->arrete) {
        for (const auto& nom : atelier->it.nomsVariables()) {
            Valeur v = atelier->it.lireVariable(nom);
            if (!premier) o << ",";
            premier = false;
            o << "{\"nom\":" << chaineJson(nom) << ",\"classe\":" << chaineJson(classeTexte(v))
              << ",\"taille\":" << chaineJson(dimensionsTexte(v))
              << ",\"valeur\":" << chaineJson(resumeValeur(atelier->it, v)) << "}";
        }
    }
    o << "]";
    return o.str();
}

std::string jsonFigures() {
    std::ostringstream o;
    o << "[";
    bool premier = true;
    for (const auto& kv : atelier->it.figures) {
        if (!premier) o << ",";
        premier = false;
        o << kv.first;
    }
    o << "]";
    return o.str();
}

std::string typeMime(const std::string& chemin) {
    auto fin = [&](const char* suffixe) {
        std::size_t n = std::strlen(suffixe);
        return chemin.size() >= n && chemin.compare(chemin.size() - n, n, suffixe) == 0;
    };
    if (fin(".html")) return "text/html; charset=utf-8";
    if (fin(".css")) return "text/css; charset=utf-8";
    if (fin(".js")) return "application/javascript; charset=utf-8";
    if (fin(".svg")) return "image/svg+xml";
    if (fin(".json")) return "application/json; charset=utf-8";
    return "text/plain; charset=utf-8";
}

Reponse json(const std::string& corps) {
    Reponse r;
    r.type = "application/json; charset=utf-8";
    r.corps = corps;
    return r;
}

// Empêche de sortir de la racine servie.
bool cheminSur(const std::string& chemin) {
    return chemin.find("..") == std::string::npos;
}

Reponse servirFichierWeb(const std::string& racine, const std::string& chemin) {
    std::string relatif = chemin == "/" ? "/index.html" : chemin;
    if (!cheminSur(relatif)) {
        Reponse r;
        r.code = 400;
        r.corps = "chemin refuse";
        return r;
    }
    fs::path fichier = fs::path(racine) / relatif.substr(1);
    std::ifstream f(fichier, std::ios::binary);
    if (!f) {
        Reponse r;
        r.code = 404;
        r.corps = "introuvable : " + relatif;
        return r;
    }
    std::ostringstream contenu;
    contenu << f.rdbuf();
    Reponse r;
    r.type = typeMime(relatif);
    r.corps = contenu.str();
    return r;
}

Reponse routeurAtelier(const Requete& requete) {
    const std::string& chemin = requete.chemin;

    if (chemin == "/api/version")
        return json("{\"version\":" + chaineJson(MATLIBRE_VERSION) + "}");

    if (chemin == "/api/executer" && requete.methode == "POST") {
        std::string code = champJson(requete.corps, "code");
        {
            std::lock_guard<std::mutex> garde(atelier->verrou);
            atelier->commandes.push(code);
        }
        atelier->signal.notify_one();
        return json("{\"ok\":true}");
    }

    if (chemin == "/api/etat") {
        std::ostringstream o;
        o << "{\"sortie\":" << chaineJson(atelier->tampon.prendre())
          << ",\"occupe\":" << (atelier->occupe ? "true" : "false")
          << ",\"arrete\":" << (atelier->arrete ? "true" : "false")
          << ",\"fichierArret\":" << chaineJson(atelier->fichierArret)
          << ",\"ligneArret\":" << atelier->ligneArret
          << ",\"sequence\":" << atelier->sequence.load()
          << ",\"variables\":" << jsonEspaceTravail()
          << ",\"figures\":" << jsonFigures() << "}";
        return json(o.str());
    }

    if (chemin == "/api/debogueur" && requete.methode == "POST") {
        std::string action = champJson(requete.corps, "action");
        if (action == "continuer") atelier->it.debogueur.action = ActionDebogueur::Continuer;
        else if (action == "pas") {
            atelier->it.debogueur.action = ActionDebogueur::PasAPas;
            atelier->it.debogueur.profondeurPause = atelier->it.profondeur();
        } else if (action == "entrer") atelier->it.debogueur.action = ActionDebogueur::EntrerDedans;
        else if (action == "sortir") {
            atelier->it.debogueur.action = ActionDebogueur::SortirDe;
            atelier->it.debogueur.profondeurPause = atelier->it.profondeur();
        } else if (action == "quitter") atelier->it.debogueur.action = ActionDebogueur::Quitter;
        {
            std::lock_guard<std::mutex> garde(atelier->verrouDebug);
            atelier->repriseDemandee = true;
        }
        atelier->signalDebug.notify_all();
        return json("{\"ok\":true}");
    }

    if (chemin == "/api/pointsarret" && requete.methode == "POST") {
        std::string fichier = champJson(requete.corps, "fichier");
        std::string ligneTexte = champJson(requete.corps, "ligne");
        std::string action = champJson(requete.corps, "action");
        int ligne = ligneTexte.empty() ? 0 : std::atoi(ligneTexte.c_str());
        if (action == "poser") atelier->it.debogueur.poser(fichier, ligne, std::string());
        else if (action == "retirer") atelier->it.debogueur.retirer(fichier, ligne);
        else atelier->it.debogueur.toutRetirer();
        std::ostringstream o;
        o << "[";
        bool premier = true;
        for (const auto& p : atelier->it.debogueur.points) {
            if (!premier) o << ",";
            premier = false;
            o << "{\"fichier\":" << chaineJson(p.fichier) << ",\"ligne\":" << p.ligne << "}";
        }
        o << "]";
        return json(o.str());
    }

    if (chemin == "/api/fichier" && requete.methode == "GET") {
        auto p = requete.parametres.find("chemin");
        if (p == requete.parametres.end()) return json("{\"erreur\":\"chemin manquant\"}");
        std::ifstream f(p->second, std::ios::binary);
        if (!f) return json("{\"erreur\":\"lecture impossible\"}");
        std::ostringstream contenu;
        contenu << f.rdbuf();
        return json("{\"contenu\":" + chaineJson(contenu.str()) + "}");
    }

    if (chemin == "/api/fichier" && requete.methode == "POST") {
        std::string nom = champJson(requete.corps, "chemin");
        std::string contenu = champJson(requete.corps, "contenu");
        std::ofstream f(nom, std::ios::binary);
        if (!f) return json("{\"erreur\":\"ecriture impossible\"}");
        f << contenu;
        return json("{\"ok\":true}");
    }

    if (chemin == "/api/dossier") {
        std::string racine = ".";
        auto p = requete.parametres.find("chemin");
        if (p != requete.parametres.end() && !p->second.empty()) racine = p->second;
        std::ostringstream o;
        o << "{\"dossier\":" << chaineJson(fs::absolute(racine).string()) << ",\"entrees\":[";
        std::error_code ec;
        std::vector<std::pair<bool, std::string>> entrees;
        for (const auto& e : fs::directory_iterator(racine, ec))
            entrees.emplace_back(e.is_directory(), e.path().filename().string());
        std::sort(entrees.begin(), entrees.end());
        bool premier = true;
        for (const auto& e : entrees) {
            if (!premier) o << ",";
            premier = false;
            o << "{\"nom\":" << chaineJson(e.second)
              << ",\"dossier\":" << (e.first ? "true" : "false") << "}";
        }
        o << "]}";
        return json(o.str());
    }

    if (chemin == "/api/figure") {
        auto p = requete.parametres.find("numero");
        int numero = p == requete.parametres.end() ? atelier->it.figureCourante
                                                   : std::atoi(p->second.c_str());
        auto f = atelier->it.figures.find(numero);
        Reponse r;
        r.type = "image/svg+xml";
        if (f == atelier->it.figures.end()) {
            r.corps = "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"10\" height=\"10\"/>";
            return r;
        }
        r.corps = rendreSVG(*f->second);
        return r;
    }


    if (chemin == "/api/ui") {
        std::ostringstream o;
        o << "[";
        bool premier = true;
        for (const auto& kv : atelier->it.composantsInterface) {
            const ComposantInterface& c = kv.second;
            if (!premier) o << ",";
            premier = false;
            o << "{\"id\":" << c.id << ",\"type\":" << chaineJson(c.type)
              << ",\"parent\":" << c.parent << ",\"texte\":" << chaineJson(c.texte)
              << ",\"position\":[";
            for (std::size_t k = 0; k < c.position.size(); ++k) {
                if (k) o << ",";
                o << nombreJson(c.position[k]);
            }
            o << "],\"items\":[";
            for (std::size_t k = 0; k < c.items.size(); ++k) {
                if (k) o << ",";
                o << chaineJson(c.items[k]);
            }
            o << "],\"minimum\":" << nombreJson(c.minimum)
              << ",\"maximum\":" << nombreJson(c.maximum)
              << ",\"actif\":" << (c.actif ? "true" : "false")
              << ",\"visible\":" << (c.visible ? "true" : "false")
              << ",\"rappel\":" << (c.rappel.classe == Classe::Fonction ? "true" : "false")
              << ",\"valeur\":";
            const Valeur& v = c.valeur;
            if (v.estTexte() || v.estChaine()) o << chaineJson(v.versTexte());
            else if (v.estScalaire() && v.estNumerique()) o << nombreJson(v.re[0]);
            else if (v.classe == Classe::Logique && v.estScalaire())
                o << (v.re[0] != 0 ? "true" : "false");
            else o << chaineJson(resumeValeur(atelier->it, v));
            o << "}";
        }
        o << "]";
        return json(o.str());
    }

    if (chemin == "/api/ui/evenement" && requete.methode == "POST") {
        std::string id = champJson(requete.corps, "id");
        std::string valeur = champJson(requete.corps, "valeur");
        std::string genre = champJson(requete.corps, "genre");
        std::ostringstream commande;
        commande << "matlibre_ui_declencher(" << id;
        if (!valeur.empty() || genre == "texte") {
            if (genre == "texte") {
                std::string echappe;
                for (char c : valeur) {
                    if (c == '\'') echappe += "''";
                    else echappe += c;
                }
                commande << ", '" << echappe << "'";
            } else {
                commande << ", " << valeur;
            }
        }
        commande << ");";
        {
            std::lock_guard<std::mutex> garde(atelier->verrou);
            atelier->commandes.push(commande.str());
        }
        atelier->signal.notify_one();
        return json("{\"ok\":true}");
    }

    if (chemin == "/api/profil") {
        std::ostringstream o;
        o << "[";
        bool premier = true;
        for (const auto& e : atelier->it.profil.classees()) {
            if (!premier) o << ",";
            premier = false;
            o << "{\"nom\":" << chaineJson(e.nom) << ",\"appels\":" << e.appels
              << ",\"total\":" << nombreJson(e.tempsTotal)
              << ",\"propre\":" << nombreJson(e.tempsPropre) << "}";
        }
        o << "]";
        return json(o.str());
    }

    if (chemin == "/api/aide") {
        auto p = requete.parametres.find("nom");
        std::string nom = p == requete.parametres.end() ? std::string() : p->second;
        const EntreeNative* n = atelier->it.natif(nom);
        std::string texte = n ? n->aide : std::string();
        if (texte.empty()) {
            auto f = atelier->it.fonctionFichier(nom);
            if (f) texte = f->aide;
        }
        return json("{\"aide\":" + chaineJson(texte) + "}");
    }

    if (chemin == "/api/fonctions") {
        std::ostringstream o;
        o << "[";
        bool premier = true;
        for (const auto& nom : atelier->it.nomsNatifs()) {
            if (!premier) o << ",";
            premier = false;
            o << chaineJson(nom);
        }
        for (const auto& kv : atelier->it.indexFichiers()) {
            o << "," << chaineJson(kv.first);
        }
        o << "]";
        return json(o.str());
    }

    if (chemin == "/api/arreter" && requete.methode == "POST") {
        atelier->tourne = false;
        atelier->signal.notify_all();
        atelier->signalDebug.notify_all();
        return json("{\"ok\":true}");
    }

    return servirFichierWeb(atelier->racineWeb, chemin);
}

}  // namespace

std::string trouverRacineWeb(const std::string& cheminExecutable) {
    const char* env = std::getenv("MATLIBRE_IDE");
    if (env && fs::is_directory(env)) return env;
    std::error_code ec;
    fs::path exe = fs::weakly_canonical(fs::path(cheminExecutable), ec);
    fs::path dossier = exe.parent_path();
    for (fs::path p : {dossier / ".." / "share" / "matlibre-ide", dossier / ".." / "ide",
                       dossier / "ide", fs::current_path(ec) / "ide"}) {
        std::error_code e2;
        if (fs::is_directory(p, e2)) return fs::weakly_canonical(p, e2).string();
    }
    return std::string();
}

int lancerAtelier(int port, const std::string& racineWeb, bool ouvrirNavigateur) {
    static Atelier instance;
    atelier = &instance;
    atelier->racineWeb = racineWeb;
    atelier->it.installerBibliotheque();
    const char* racineToolbox = std::getenv("MATLIBRE_TOOLBOX");
    if (racineToolbox) {
        atelier->it.definirRacineToolbox(racineToolbox);
        std::error_code ec;
        std::vector<std::string> dossiers;
        for (const auto& e : fs::directory_iterator(racineToolbox, ec))
            if (e.is_directory()) dossiers.push_back(e.path().string());
        std::sort(dossiers.begin(), dossiers.end());
        for (auto rit = dossiers.rbegin(); rit != dossiers.rend(); ++rit)
            atelier->it.ajouterChemin(*rit, true);
        atelier->it.ajouterChemin(racineToolbox, true);
    }
    std::error_code ec;
    atelier->it.ajouterChemin(fs::current_path(ec).string(), true);
    atelier->it.definirSortie(&atelier->sortie);
    atelier->it.crochetArret = crochetArretAtelier;
    atelier->it.modeInteractif = true;

    std::thread fil(filInterprete);
    std::string adresse = "http://127.0.0.1:" + std::to_string(port) + "/";
    std::cout << "MatLibre " << MATLIBRE_VERSION << " — atelier sur " << adresse << "\n";
    if (racineWeb.empty())
        std::cout << "Attention : les fichiers de l'atelier sont introuvables. "
                     "Posez MATLIBRE_IDE sur le dossier « ide ».\n";
    if (ouvrirNavigateur) {
#ifdef __APPLE__
        std::system(("open " + adresse + " >/dev/null 2>&1 &").c_str());
#elif defined(_WIN32)
        std::system(("start " + adresse).c_str());
#else
        std::system(("xdg-open " + adresse + " >/dev/null 2>&1 &").c_str());
#endif
    }
    bool ok = servir(port, routeurAtelier, [] { return atelier->tourne.load(); });
    atelier->tourne = false;
    atelier->signal.notify_all();
    atelier->signalDebug.notify_all();
    fil.join();
    if (!ok) {
        std::cerr << "matlibre: impossible d'ecouter sur le port " << port << "\n";
        return 1;
    }
    return 0;
}

}  // namespace matlibre
