// Pilote de simulation : fait tourner le firmware et le circuit ensemble.
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
#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

#include <cstdint>
#include <map>
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

    bool charger_firmware(const QString& chemin, QString* erreur);
    bool compiler_et_charger(const QString& source, const QString& dossier,
                             QString* journal);

    void definir_circuit(coeur::Netlist netlist,
                         std::vector<LiaisonBroche> broches);

    void demarrer();
    void suspendre();
    void arreter();
    bool en_marche() const { return minuterie_.isActive(); }
    bool firmware_charge() const { return firmware_charge_; }

    double temps_ms() const { return mcu_.temps_ms(); }
    // Pas d'échantillonnage de l'analyse transitoire, en secondes. Plus il est
    // fin, plus l'oscilloscope est précis et plus la simulation coûte cher.
    void definir_resolution(double secondes);
    double resolution() const { return pas_; }
    double vitesse() const { return vitesse_; }
    const QString& source_spice() const { return source_spice_; }
    const coeur::Netlist& netlist() const { return netlist_; }
    const std::vector<LiaisonBroche>& broches() const { return broches_; }
    const coeur::NgspiceEngine& analogique() const { return analogique_; }
    const coeur::AvrEngine& mcu() const { return mcu_; }

    // Résout le circuit une seule fois, sans firmware : « analyse au point de
    // repos », utile pour vérifier un montage purement analogique.
    void resoudre_une_fois();

signals:
    void resultats(const std::map<std::string, double>& courants,
                   const std::map<std::string, double>& tensions);
    // Formes d'onde de la trame qui vient d'être calculée, avec l'instant de
    // son début en secondes de temps simulé.
    void trame_calculee(const coeur::Formes& formes, double instant_debut);
    void octet_serie(char octet);
    void journal(const QString& message);
    void avancement(double temps_ms, double vitesse);

private slots:
    void trame();

private:
    coeur::AvrEngine mcu_;
    coeur::NgspiceEngine analogique_;
    coeur::Netlist netlist_;
    std::vector<LiaisonBroche> broches_;
    QTimer minuterie_;

    bool firmware_charge_ = false;
    double vitesse_ = 0.0;
    QString source_spice_;

    // Histoire des commutations de la trame en cours, datée au cycle près.
    struct Commutation {
        uint64_t cycle = 0;
        int broche = 0;
        bool haut = false;
    };
    std::vector<Commutation> commutations_;
    uint32_t masque_ = 0;          // état courant des broches
    uint32_t masque_debut_ = 0;    // état au début de la trame
    uint64_t cycle_debut_ = 0;
    double pas_ = 50e-6;           // résolution de l'analyse transitoire
    double instant_trame_ = 0.0;   // horloge absolue, pour l'oscilloscope
    std::map<std::string, double> etat_;   // tensions reprises d'une trame à l'autre

    void brancher_rappels();
    void noter_changement(int broche, bool haut);
    std::vector<coeur::BrocheElectrique> broches_pour(uint32_t masque) const;
    void resoudre_trame(uint64_t cycles_ecoules);
};
