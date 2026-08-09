// Pilote de simulation : fait tourner le ou les firmwares et le circuit
// ensemble.
//
// Le point délicat est le rapport des échelles de temps. Le microcontrôleur
// change d'état des milliers de fois par seconde (une PWM à 490 Hz commute
// presque mille fois), alors qu'il est inutile — et hors de portée — de
// résoudre le circuit aussi souvent.
//
// La solution retenue est celle des simulateurs mixtes. simavr date chaque
// commutation au cycle d'horloge près ; on transcrit cette histoire en
// sources SPICE linéaires par morceaux, et ngspice calcule le transitoire de
// toute la trame d'un coup. Le circuit n'est donc jamais figé : les
// condensateurs se chargent, les fronts existent, et une forme d'onde
// exploitable en sort — c'est ce qui rend l'oscilloscope possible.
//
// L'état électrique se transmet d'une fenêtre à la suivante par les
// conditions initiales, sans quoi chaque trame repartirait d'un circuit
// déchargé.
//
// Plusieurs cartes peuvent coexister : chacune a son propre cœur AVR et son
// propre firmware, mais toutes partagent le même circuit et la même horloge.
// Elles avancent du même nombre de cycles à chaque trame, et leurs
// commutations sont fondues dans une seule analyse transitoire.
#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QTimer>

#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "app/schematic/SceneSchema.h"
#include "core/Netlist.h"
#include "core/engines/AvrEngine.h"
#include "core/engines/Microcontroleur.h"
#include "core/engines/MoteurNumerique.h"
#include "core/engines/NgspiceEngine.h"

class MoteurSimulation : public QObject {
    Q_OBJECT

public:
    explicit MoteurSimulation(QObject* parent = nullptr);
    ~MoteurSimulation() override;

    // --- firmwares, par carte ------------------------------------------------
    // `carte` est la référence du symbole sur le schéma (« U1 »). Vide = la
    // première carte du schéma, ce qui couvre le cas courant à une seule carte.
    bool charger_firmware(const QString& chemin, QString* erreur,
                          const QString& carte = {});
    bool compiler_et_charger(const QString& source, const QString& dossier,
                             QString* journal, const QString& carte = {});

    // Cartes présentes sur le schéma, dans l'ordre des références.
    QStringList cartes() const;
    // Celle qui recevra un firmware quand on n'en désigne aucune.
    QString carte_par_defaut() const;
    bool firmware_charge(const QString& carte = {}) const;
    // Au moins une carte a un firmware.
    bool un_firmware_au_moins() const;

    // `cartes` énumère les cartes posées sur le schéma, câblées ou non :
    // c'est elle qui fait foi, pas les broches reliées.
    void definir_circuit(coeur::Netlist netlist,
                         std::vector<LiaisonBroche> broches,
                         const QStringList& cartes);
    // Variante qui dit aussi quelle puce porte chaque carte : c'est elle que
    // l'application emploie, car un ATtiny et un Arduino ne se compilent ni
    // ne s'exécutent de la même façon.
    void definir_circuit(coeur::Netlist netlist,
                         std::vector<LiaisonBroche> broches,
                         const std::vector<CartePosee>& cartes);

    // État de la simulation, au sens où l'entend un atelier de calcul : on
    // lance, on met en pause, on reprend, on arrête. « Arrêté » remet les
    // microcontrôleurs à zéro ; « en pause » garde tout en place.
    enum class Etat { Arrete, EnMarche, EnPause };

    void demarrer();      // lance, ou reprend après une pause
    void suspendre();
    void arreter();
    Etat etat() const { return etat_simulation_; }
    bool en_marche() const { return etat_simulation_ == Etat::EnMarche; }

    double temps_ms() const;
    // Pas d'échantillonnage de l'analyse transitoire, en secondes. Plus il est
    // fin, plus l'oscilloscope est précis et plus la simulation coûte cher.
    void definir_resolution(double secondes);
    double resolution() const { return pas_; }
    double vitesse() const { return vitesse_; }
    const QString& source_spice() const { return source_spice_; }
    const coeur::Netlist& netlist() const { return netlist_; }
    const std::vector<LiaisonBroche>& broches() const { return broches_; }
    const coeur::NgspiceEngine& analogique() const { return analogique_; }
    // Cœur AVR d'une carte, pour le diagnostic. Jamais nul : renvoie un moteur
    // inerte si la carte n'existe pas.
    const coeur::Microcontroleur& mcu(const QString& carte = {}) const;

    // Résout le circuit une seule fois, sans firmware : « analyse au point de
    // repos », utile pour vérifier un montage purement analogique.
    void resoudre_une_fois();

    // Balayage paramétrique (« .dc », « .ac »). Le firmware n'intervient pas :
    // les broches sont figées dans leur état courant, comme le fait un atelier
    // de simulation analogique.
    bool executer_balayage(const QString& directive, QString* erreur);
    const coeur::Balayage& balayage() const { return analogique_.balayage(); }

signals:
    void resultats(const std::map<std::string, double>& courants,
                   const std::map<std::string, double>& tensions);
    // Formes d'onde de la trame qui vient d'être calculée, avec l'instant de
    // son début en secondes de temps simulé.
    void trame_calculee(const coeur::Formes& formes, double instant_debut);
    // Octet émis sur l'UART, avec la carte qui l'a envoyé.
    void octet_serie(char octet, const QString& carte);
    // État interne des composants à mécanique, après évolution.
    void etats_composants(
        const std::map<std::string, std::map<std::string, double>>& etats);
    void journal(const QString& message);
    void avancement(double temps_ms, double vitesse);
    // Changement d'état : c'est ce qui pilote l'apparence des commandes.
    void etat_change(Etat etat);

private slots:
    void trame();

private:
    // Une carte programmable du schéma : son cœur, son firmware, son histoire.
    struct Carte {
        QString reference;
        // Le moteur qui exécute cette carte : un cœur AVR, un Cortex-M…
        // C'est la puce du modèle qui le choisit.
        std::unique_ptr<coeur::Microcontroleur> mcu;
        // La puce de cette carte : elle décide de la compilation comme de
        // l'exécution.
        std::string puce = "atmega328p";
        uint32_t horloge = 16000000;
        bool firmware_charge = false;
        uint32_t masque = 0;         // état courant des broches
        uint32_t masque_debut = 0;   // état au début de la trame
        uint64_t cycle_debut = 0;

        struct Commutation {
            uint64_t cycle = 0;
            int broche = 0;
            bool haut = false;
        };
        std::vector<Commutation> commutations;
    };

    coeur::NgspiceEngine analogique_;
    // Troisième moteur : il propage les fronts dans les composants
    // numériques avant que le circuit analogique ne soit résolu.
    coeur::MoteurNumerique numerique_;
    coeur::Netlist netlist_;
    std::vector<LiaisonBroche> broches_;
    QTimer minuterie_;

    std::map<QString, std::unique_ptr<Carte>> cartes_;
    QStringList ordre_cartes_;      // ordre d'apparition sur le schéma

    // Durée d'un pas de couplage, en millisecondes. C'est lui qui fixe le
    // retard avec lequel le circuit est relu par le microcontrôleur — donc la
    // finesse avec laquelle deux cartes peuvent se parler. Plusieurs pas sont
    // enchaînés par image affichée : l'écran se rafraîchit à 40 Hz, le
    // couplage tourne bien plus vite.
    int pas_couplage_ms_ = 25;
    double vitesse_ = 0.0;
    QString source_spice_;
    double pas_ = 50e-6;            // résolution de l'analyse transitoire
    double instant_trame_ = 0.0;    // horloge absolue, pour l'oscilloscope
    std::map<std::string, double> etat_;   // tensions reprises d'une trame à l'autre
    Etat etat_simulation_ = Etat::Arrete;  // marche, pause, arrêt

    Carte* carte(const QString& reference);
    const Carte* carte(const QString& reference) const;
    Carte& obtenir_carte(const QString& reference);
    void brancher_rappels(Carte& carte);
    void noter_changement(Carte& carte, int broche, bool haut);
    void remettre_a_zero();

    // `au_depart` : état des broches au début du pas de couplage (analyse
    // transitoire) ou état courant (analyse au point de repos).
    std::vector<coeur::BrocheElectrique> broches_pour(bool au_depart) const;
    void resoudre_trame(uint64_t cycles_ecoules);
    // Fait avancer la mécanique des composants à état.
    void faire_evoluer(const coeur::Formes& formes, double duree);
    // Un pas de couplage complet : exécution puis résolution.
    uint64_t executer_pas(uint64_t cycles);
    // Pas de couplage réellement nécessaire pour ce schéma.
    int pas_couplage_utile() const;
};
