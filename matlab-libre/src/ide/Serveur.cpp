// Serveur.cpp — implémentation du serveur HTTP minimal.
#include "matlibre/Serveur.h"

#include <cstring>
#include <sstream>
#include <thread>
#include <vector>

#ifdef _WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
using Prise = SOCKET;
static const Prise PRISE_INVALIDE = INVALID_SOCKET;
#define FERMER closesocket
#else
#include <arpa/inet.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <unistd.h>
using Prise = int;
static const Prise PRISE_INVALIDE = -1;
#define FERMER close
#endif

namespace matlibre {
namespace {

int nombreHex(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

bool lireLigne(std::string& tampon, std::string& ligne) {
    std::size_t p = tampon.find("\r\n");
    if (p == std::string::npos) return false;
    ligne = tampon.substr(0, p);
    tampon.erase(0, p + 2);
    return true;
}

void envoyer(Prise prise, const std::string& donnees) {
    std::size_t envoye = 0;
    while (envoye < donnees.size()) {
        long n = (long)send(prise, donnees.data() + envoye, (int)(donnees.size() - envoye), 0);
        if (n <= 0) return;
        envoye += (std::size_t)n;
    }
}

std::string texteCode(int code) {
    switch (code) {
        case 200: return "OK";
        case 204: return "No Content";
        case 400: return "Bad Request";
        case 404: return "Not Found";
        case 405: return "Method Not Allowed";
        case 500: return "Internal Server Error";
        default:  return "OK";
    }
}

}  // namespace

std::string decoderUrl(const std::string& texte) {
    std::string sortie;
    for (std::size_t k = 0; k < texte.size(); ++k) {
        if (texte[k] == '+') {
            sortie += ' ';
        } else if (texte[k] == '%' && k + 2 < texte.size()) {
            int haut = nombreHex(texte[k + 1]);
            int bas = nombreHex(texte[k + 2]);
            if (haut >= 0 && bas >= 0) {
                sortie += (char)(haut * 16 + bas);
                k += 2;
            } else {
                sortie += texte[k];
            }
        } else {
            sortie += texte[k];
        }
    }
    return sortie;
}

bool servir(int port, const Routeur& routeur, const std::function<bool()>& continuer) {
#ifdef _WIN32
    WSADATA wsa;
    if (WSAStartup(MAKEWORD(2, 2), &wsa) != 0) return false;
#endif
    Prise ecoute = socket(AF_INET, SOCK_STREAM, 0);
    if (ecoute == PRISE_INVALIDE) return false;
    int oui = 1;
    setsockopt(ecoute, SOL_SOCKET, SO_REUSEADDR, (const char*)&oui, sizeof(oui));
    sockaddr_in adresse{};
    adresse.sin_family = AF_INET;
    adresse.sin_port = htons((unsigned short)port);
    // Boucle locale seulement : l'atelier n'est pas exposé au réseau.
    adresse.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
    if (bind(ecoute, (sockaddr*)&adresse, sizeof(adresse)) != 0) {
        FERMER(ecoute);
        return false;
    }
    if (listen(ecoute, 16) != 0) {
        FERMER(ecoute);
        return false;
    }
    while (continuer()) {
        sockaddr_in client{};
#ifdef _WIN32
        int taille = sizeof(client);
#else
        socklen_t taille = sizeof(client);
#endif
        Prise prise = accept(ecoute, (sockaddr*)&client, &taille);
        if (prise == PRISE_INVALIDE) continue;

        std::string tampon;
        std::string ligne;
        char morceau[8192];
        // En-tête.
        while (tampon.find("\r\n\r\n") == std::string::npos) {
            long n = (long)recv(prise, morceau, sizeof(morceau), 0);
            if (n <= 0) break;
            tampon.append(morceau, (std::size_t)n);
        }
        if (tampon.empty()) {
            FERMER(prise);
            continue;
        }
        Requete requete;
        if (lireLigne(tampon, ligne)) {
            std::istringstream flux(ligne);
            std::string version;
            flux >> requete.methode >> requete.chemin >> version;
        }
        std::size_t interrogation = requete.chemin.find('?');
        if (interrogation != std::string::npos) {
            std::string requeteTexte = requete.chemin.substr(interrogation + 1);
            requete.chemin = requete.chemin.substr(0, interrogation);
            std::istringstream flux(requeteTexte);
            std::string paire;
            while (std::getline(flux, paire, '&')) {
                std::size_t egal = paire.find('=');
                if (egal == std::string::npos) continue;
                requete.parametres[decoderUrl(paire.substr(0, egal))] =
                    decoderUrl(paire.substr(egal + 1));
            }
        }
        std::size_t longueur = 0;
        while (lireLigne(tampon, ligne) && !ligne.empty()) {
            std::size_t deuxPoints = ligne.find(':');
            if (deuxPoints == std::string::npos) continue;
            std::string nom = ligne.substr(0, deuxPoints);
            std::string valeur = ligne.substr(deuxPoints + 1);
            while (!valeur.empty() && (valeur.front() == ' ' || valeur.front() == '\t'))
                valeur.erase(valeur.begin());
            for (auto& c : nom) c = (char)tolower((unsigned char)c);
            requete.entetes[nom] = valeur;
            if (nom == "content-length") longueur = (std::size_t)std::stoul(valeur);
        }
        requete.corps = tampon;
        while (requete.corps.size() < longueur) {
            long n = (long)recv(prise, morceau, sizeof(morceau), 0);
            if (n <= 0) break;
            requete.corps.append(morceau, (std::size_t)n);
        }

        Reponse reponse;
        try {
            reponse = routeur(requete);
        } catch (const std::exception& e) {
            reponse.code = 500;
            reponse.corps = std::string("erreur interne : ") + e.what();
        } catch (...) {
            reponse.code = 500;
            reponse.corps = "erreur interne";
        }
        std::ostringstream sortie;
        sortie << "HTTP/1.1 " << reponse.code << " " << texteCode(reponse.code) << "\r\n";
        sortie << "Content-Type: " << reponse.type << "\r\n";
        sortie << "Content-Length: " << reponse.corps.size() << "\r\n";
        sortie << "Cache-Control: no-store\r\n";
        for (const auto& kv : reponse.entetes) sortie << kv.first << ": " << kv.second << "\r\n";
        sortie << "Connection: close\r\n\r\n";
        sortie << reponse.corps;
        envoyer(prise, sortie.str());
        FERMER(prise);
    }
    FERMER(ecoute);
#ifdef _WIN32
    WSACleanup();
#endif
    return true;
}

}  // namespace matlibre
