// Netlist — modèle central partagé par le schéma, la simulation et (demain)
// le module PCB. C'est la « couture » du projet : le schéma la produit, les
// moteurs la consomment, le routeur PCB la consommera aussi.
#pragma once

#include <map>
#include <string>
#include <vector>

namespace coeur {

// Un nœud électrique. Deux bornes reliées par un fil partagent le même nœud.
struct Noeud {
    std::string nom;          // "GND", "5V", "D13", "N3"…
    bool masse = false;       // nœud de référence (0 V)
};

// Une borne d'un composant, rattachée à un nœud.
struct Borne {
    std::string nom;          // "A", "K", "1", "2", "curseur"…
    std::string noeud;        // nom du nœud, vide si non connectée
};

// Une instance de composant dans le circuit.
struct Instance {
    std::string reference;                        // "R1", "LED2"…
    std::string type;                             // "resistance", "led"…
    std::vector<Borne> bornes;
    std::map<std::string, double> valeurs;        // ohms, position…
    std::map<std::string, std::string> textes;    // couleur, modèle SPICE…

    // Formes d'onde imposées par un composant numérique à ses sorties, sur la
    // fenêtre de calcul : liste de (instant, tension). Elles deviennent des
    // sources linéaires par morceaux dans la netlist SPICE. Vide pour tout
    // composant qui n'est pas piloté par des événements.
    std::map<std::string, std::vector<std::pair<double, double>>> ondes;

    const Borne* borne(const std::string& nom) const;
    double valeur(const std::string& cle, double defaut = 0.0) const;
    std::string texte(const std::string& cle,
                      const std::string& defaut = {}) const;
};

class Netlist {
public:
    void vider();

    Instance& ajouter(const std::string& reference, const std::string& type);
    Instance* trouver(const std::string& reference);
    const Instance* trouver(const std::string& reference) const;
    void supprimer(const std::string& reference);

    void relier(const std::string& reference, const std::string& borne,
                const std::string& noeud);

    const std::vector<Instance>& instances() const { return instances_; }
    std::vector<Instance>& instances() { return instances_; }

    // Tous les noms de nœuds présents, masse et alimentation comprises.
    std::vector<std::string> noeuds() const;

    // Nombre de bornes rattachées à un nœud : sert à repérer les nœuds
    // flottants (une seule borne) et les nœuds inutilisés.
    int occurrences(const std::string& noeud) const;

    static const char* kMasse;   // "GND"
    static const char* kAlim;    // "5V"

private:
    std::vector<Instance> instances_;
};

}  // namespace coeur
