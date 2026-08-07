// Pilote de simulation : fait tourner le firmware et le circuit ensemble.
//
// Le point délicat est le rapport des échelles de temps. Le microcontrôleur
// change d'état des milliers de fois par seconde (une PWM à 490 Hz commute
// presque mille fois), alors qu'il est inutile — et hors de portée — de
// résoudre le circuit aussi souvent.
//
// La solution retenue est celle des simulateurs mixtes : pendant une trame
// d'affichage, on note *combien de temps* le microcontrôleur a passé dans
// chaque configuration de broches ; en fin de trame on ne résout qu'une fois
// par configuration distincte, et on pondère les résultats par leur durée.
// Une LED en PWM à 25 % reçoit ainsi le courant de la pleine conduction
// pendant un quart du temps — ce qui est la réalité physique — au lieu de la
// moyenne des tensions, qui l'éteindrait à tort.
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

    // Occupation temporelle de chaque configuration de broches, sur la trame.
    std::map<uint32_t, uint64_t> occupation_;
    uint32_t masque_ = 0;
    uint64_t cycle_repere_ = 0;

    void brancher_rappels();
    void noter_changement(int broche, bool haut);
    std::vector<coeur::BrocheElectrique> broches_pour(uint32_t masque) const;
    void resoudre_trame(uint64_t cycles_ecoules);
};
