#include "app/MoteurSimulation.h"

#include <QDir>
#include <QElapsedTimer>
#include <QFileInfo>

#include <algorithm>
#include <cmath>

namespace {

constexpr int kPeriodeTrame = 25;        // ms entre deux images
constexpr size_t kEtatsMax = 8;          // résolutions par trame, au plus

}  // namespace

MoteurSimulation::MoteurSimulation(QObject* parent) : QObject(parent) {
    minuterie_.setInterval(kPeriodeTrame);
    minuterie_.setTimerType(Qt::PreciseTimer);
    connect(&minuterie_, &QTimer::timeout, this, &MoteurSimulation::trame);
    brancher_rappels();
}

void MoteurSimulation::brancher_rappels() {
    mcu_.sur_changement_broche(
        [this](int broche, bool haut) { noter_changement(broche, haut); });
    mcu_.sur_octet_serie([this](char octet) { emit octet_serie(octet); });
}

bool MoteurSimulation::charger_firmware(const QString& chemin, QString* erreur) {
    if (!mcu_.disponible()) {
        if (erreur) *erreur = "simavr n'est pas compilé dans cette version.";
        return false;
    }
    if (!mcu_.charger(chemin.toStdString())) {
        if (erreur) *erreur = QString::fromStdString(mcu_.erreur());
        firmware_charge_ = false;
        return false;
    }
    brancher_rappels();
    firmware_charge_ = true;
    masque_ = 0;
    cycle_repere_ = 0;
    occupation_.clear();
    emit journal(QString("Firmware chargé : %1")
                     .arg(QFileInfo(chemin).fileName()));
    return true;
}

bool MoteurSimulation::compiler_et_charger(const QString& source,
                                           const QString& dossier,
                                           QString* journal_texte) {
    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        if (journal_texte)
            *journal_texte =
                "avr-gcc est introuvable. Installez la chaîne de compilation "
                "AVR (paquet gcc-avr et avr-libc) pour compiler depuis "
                "l'application.";
        return false;
    }
    QDir().mkpath(dossier);
    const QString cible = QDir(dossier).filePath("firmware.elf");
    std::string compte_rendu;
    const bool ok = coeur::AvrEngine::compiler_source(
        source.toStdString(), cible.toStdString(), &compte_rendu);
    if (journal_texte) *journal_texte = QString::fromStdString(compte_rendu);
    if (!ok) return false;
    QString erreur;
    if (!charger_firmware(cible, &erreur)) {
        if (journal_texte) *journal_texte += "\n" + erreur;
        return false;
    }
    return true;
}

void MoteurSimulation::definir_circuit(coeur::Netlist netlist,
                                       std::vector<LiaisonBroche> broches) {
    netlist_ = std::move(netlist);
    broches_ = std::move(broches);
}

void MoteurSimulation::demarrer() {
    if (!firmware_charge_) {
        emit journal("Aucun firmware chargé : rien à exécuter.");
        return;
    }
    cycle_repere_ = mcu_.cycle();
    occupation_.clear();
    minuterie_.start();
    emit journal("Simulation démarrée.");
}

void MoteurSimulation::suspendre() {
    minuterie_.stop();
    emit journal("Simulation suspendue.");
}

void MoteurSimulation::arreter() {
    minuterie_.stop();
    mcu_.reinitialiser();
    masque_ = 0;
    cycle_repere_ = 0;
    occupation_.clear();
    vitesse_ = 0.0;
    emit journal("Simulation arrêtée et microcontrôleur réinitialisé.");
    emit avancement(0.0, 0.0);
}

// ---------------------------------------------------------------------------
void MoteurSimulation::noter_changement(int broche, bool haut) {
    // Combien de temps la configuration précédente a-t-elle duré ?
    const uint64_t maintenant = mcu_.cycle();
    if (maintenant > cycle_repere_)
        occupation_[masque_] += maintenant - cycle_repere_;
    cycle_repere_ = maintenant;

    if (broche >= 0 && broche < 32) {
        if (haut) masque_ |= (1u << broche);
        else masque_ &= ~(1u << broche);
    }
}

std::vector<coeur::BrocheElectrique> MoteurSimulation::broches_pour(
    uint32_t masque) const {
    std::vector<coeur::BrocheElectrique> resultat;
    resultat.reserve(broches_.size());
    for (const LiaisonBroche& liaison : broches_) {
        coeur::BrocheElectrique broche;
        broche.noeud = liaison.noeud;
        if (mcu_.direction_sortie(liaison.numero)) {
            broche.mode = coeur::BrocheElectrique::Mode::Sortie;
            broche.tension = (masque >> liaison.numero) & 1u ? 5.0 : 0.0;
            broche.resistance = 25.0;      // résistance de sortie d'un AVR
        } else if (mcu_.pullup_actif(liaison.numero)) {
            broche.mode = coeur::BrocheElectrique::Mode::PullUp;
            broche.resistance = 35000.0;   // pull-up interne : 20 à 50 kΩ
        } else {
            broche.mode = coeur::BrocheElectrique::Mode::Entree;
        }
        resultat.push_back(broche);
    }
    return resultat;
}

void MoteurSimulation::resoudre_trame(uint64_t cycles_ecoules) {
    // Ferme la dernière configuration de la trame.
    const uint64_t maintenant = mcu_.cycle();
    if (maintenant > cycle_repere_)
        occupation_[masque_] += maintenant - cycle_repere_;
    cycle_repere_ = maintenant;
    if (occupation_.empty()) occupation_[masque_] = cycles_ecoules;

    // On ne garde que les configurations les plus occupées : au-delà, leur
    // contribution est négligeable et le coût de résolution ne l'est pas.
    std::vector<std::pair<uint32_t, uint64_t>> etats(occupation_.begin(),
                                                     occupation_.end());
    std::sort(etats.begin(), etats.end(),
              [](const auto& a, const auto& b) { return a.second > b.second; });
    if (etats.size() > kEtatsMax) etats.resize(kEtatsMax);

    uint64_t total = 0;
    for (const auto& etat : etats) total += etat.second;
    occupation_.clear();
    if (total == 0 || netlist_.instances().empty()) return;

    std::map<std::string, double> courants;
    std::map<std::string, double> tensions;
    bool premier = true;
    for (const auto& etat : etats) {
        const double poids = static_cast<double>(etat.second) / total;
        const std::string source =
            analogique_.construire(netlist_, broches_pour(etat.first));
        if (premier) {
            source_spice_ = QString::fromStdString(source);
            premier = false;
        }
        if (!analogique_.resoudre()) {
            for (const auto& message : analogique_.erreurs())
                emit journal(QString::fromStdString(message));
            return;
        }
        for (const auto& mesure : analogique_.tous_courants())
            courants[mesure.first] += mesure.second * poids;
        for (const auto& mesure : analogique_.toutes_tensions())
            tensions[mesure.first] += mesure.second * poids;
    }

    // Retour du circuit vers le microcontrôleur : c'est ce qui rend la boucle
    // complète. Sans cela, un bouton ou un capteur ne serait jamais lu.
    for (const LiaisonBroche& liaison : broches_) {
        std::string noeud = liaison.noeud;
        std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        auto it = tensions.find(noeud);
        if (it == tensions.end()) continue;
        if (mcu_.direction_sortie(liaison.numero)) continue;
        if (liaison.numero >= 14)
            mcu_.definir_tension_adc(liaison.numero - 14, it->second);
        mcu_.definir_niveau_externe(liaison.numero, it->second > 2.5);
    }

    emit resultats(courants, tensions);
}

void MoteurSimulation::resoudre_une_fois() {
    if (netlist_.instances().empty()) {
        emit journal("Le schéma ne contient aucun composant simulable.");
        return;
    }
    source_spice_ =
        QString::fromStdString(analogique_.construire(netlist_,
                                                      broches_pour(masque_)));
    if (!analogique_.resoudre()) {
        for (const auto& message : analogique_.erreurs())
            emit journal(QString::fromStdString(message));
        return;
    }
    emit resultats(analogique_.tous_courants(), analogique_.toutes_tensions());
    emit journal("Analyse au point de repos effectuée.");
}

void MoteurSimulation::trame() {
    QElapsedTimer chronometre;
    chronometre.start();

    const uint64_t cycles = static_cast<uint64_t>(mcu_.frequence()) *
                            kPeriodeTrame / 1000;
    const uint64_t executes = mcu_.avancer(cycles);
    resoudre_trame(executes);

    const double reel = chronometre.nsecsElapsed() / 1e6;   // ms consommées
    const double simule = executes * 1000.0 / mcu_.frequence();
    vitesse_ = reel > 0 ? simule / reel : 0.0;
    emit avancement(mcu_.temps_ms(), vitesse_);
}
