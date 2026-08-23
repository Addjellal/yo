// Serveur.h — serveur HTTP minimal, sans dépendance.
//
// Il ne sert qu'à l'atelier local : une seule machine, un seul utilisateur,
// des requêtes courtes. Pas de TLS, pas de HTTP/2 — et l'écoute est
// volontairement limitée à la boucle locale.
#pragma once

#include <functional>
#include <map>
#include <string>

namespace matlibre {

struct Requete {
    std::string methode;
    std::string chemin;                          // sans la requête
    std::map<std::string, std::string> parametres;  // ?a=1&b=2
    std::map<std::string, std::string> entetes;
    std::string corps;
};

struct Reponse {
    int code = 200;
    std::string type = "text/plain; charset=utf-8";
    std::string corps;
    std::map<std::string, std::string> entetes;
};

using Routeur = std::function<Reponse(const Requete&)>;

// Écoute sur 127.0.0.1:port. Rend faux si le port ne peut pas être pris.
// La boucle ne rend la main que lorsque « continuer » devient faux.
bool servir(int port, const Routeur& routeur, const std::function<bool()>& continuer);

// Décodage des séquences %XX et du « + » d'une chaîne de requête.
std::string decoderUrl(const std::string& texte);

}  // namespace matlibre
