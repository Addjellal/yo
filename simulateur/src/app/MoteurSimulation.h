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

    void definir_circuit(coeur::Netlist netlist,
                         std::vector<LiaisonBroche> broches);

    void demarrer();
    void suspendre();
    void arreter();
    bool en_marche() const { return minuterie_.isActive(); }

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
    const coeur::AvrEngine& mcu(const QString& carte = {}) const;

    // Résout le circuit une seule fois, sans firmware : « analyse au point de
    // repos », utile pour vérifier un montage purement analogique.
    void resoudre_une_fois();

signals:
    void resultats(const std::map<std::string, double>& courants,
                   const std::map<std::string, double>& tensions);
    // Formes d'onde de la trame qui vient d'être calculée, avec l'instant de
    // son début en secondes de temps simulé.
    void trame_calculee(const coeur::Formes& formes, double instant_debut);
    // Octet émis sur l'UART, avec la carte qui l'a envoyé.
    void octet_serie(char octet, const QString& carte);
    void journal(const QString& message);
    void avancement(double temps_ms, double vitesse);

private slots:
    void trame();

private:
    // Une carte programmable du schéma : son cœur, son firmware, son histoire.
    struct Carte {
        QString reference;
        std::unique_ptr<coeur::AvrEngine> mcu;
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

    Carte* carte(const QString& reference);
    const Carte* carte(const QString& reference) const;
    Carte& obtenir_carte(const QString& reference);
    void brancher_rappels(Carte& carte);
    void noter_changement(Carte& carte, int broche, bool haut);
    void remettre_a_zero();

    std::vector<coeur::BrocheElectrique> broches_au_depart() const;
    void resoudre_trame(uint64_t cycles_ecoules);
    // Un pas de couplage complet : exécution puis résolution.
    uint64_t executer_pas(uint64_t cycles);
    // Pas de couplage réellement nécessaire pour ce schéma.
    int pas_couplage_utile() const;
};
