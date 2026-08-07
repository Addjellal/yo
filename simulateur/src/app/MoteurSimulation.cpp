#include "app/MoteurSimulation.h"

#include <QDir>
#include <QElapsedTimer>
#include <QFileInfo>

#include <algorithm>
#include <cmath>

namespace {

constexpr int kPeriodeTrame = 25;        // ms entre deux images

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
    masque_debut_ = 0;
    cycle_debut_ = 0;
    instant_trame_ = 0.0;
    commutations_.clear();
    etat_.clear();
    analogique_.oublier_etat();
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
    masque_debut_ = 0;
    cycle_debut_ = 0;
    instant_trame_ = 0.0;
    commutations_.clear();
    etat_.clear();
    analogique_.oublier_etat();
    vitesse_ = 0.0;
    emit journal("Simulation arrêtée et microcontrôleur réinitialisé.");
    emit avancement(0.0, 0.0);
}

// ---------------------------------------------------------------------------
void MoteurSimulation::noter_changement(int broche, bool haut) {
    if (broche < 0 || broche >= 32) return;
    // On garde l'instant exact : c'est lui qui devient un point de la source
    // linéaire par morceaux, donc un front dans la forme d'onde.
    commutations_.push_back({mcu_.cycle(), broche, haut});
    if (haut) masque_ |= (1u << broche);
    else masque_ &= ~(1u << broche);
}

void MoteurSimulation::definir_resolution(double secondes) {
    if (secondes < 1e-6) secondes = 1e-6;      // 1 µs : plancher raisonnable
    if (secondes > 1e-3) secondes = 1e-3;
    pas_ = secondes;
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
    const double duree = static_cast<double>(cycles_ecoules) / mcu_.frequence();
    if (duree <= 0 || netlist_.instances().empty()) {
        commutations_.clear();
        return;
    }

    // Les broches partent de leur état en début de trame, puis suivent
    // l'histoire réellement vécue par le microcontrôleur.
    const std::vector<coeur::BrocheElectrique> broches =
        broches_pour(masque_debut_);

    std::map<int, std::string> noeud_de_broche;
    for (const LiaisonBroche& liaison : broches_)
        noeud_de_broche[liaison.numero] = liaison.noeud;

    std::vector<coeur::TransitionBroche> transitions;
    transitions.reserve(commutations_.size());
    for (const Commutation& commutation : commutations_) {
        auto it = noeud_de_broche.find(commutation.broche);
        if (it == noeud_de_broche.end()) continue;
        const double instant =
            static_cast<double>(commutation.cycle - cycle_debut_) /
            mcu_.frequence();
        transitions.push_back({instant, it->second, commutation.haut ? 5.0 : 0.0});
    }
    commutations_.clear();

    analogique_.definir_etat_initial(etat_);
    source_spice_ = QString::fromStdString(analogique_.construire_transitoire(
        netlist_, broches, transitions, duree, pas_));
    if (!analogique_.resoudre_transitoire()) {
        for (const auto& message : analogique_.erreurs())
            emit journal(QString::fromStdString(message));
        // Repartir d'un état propre plutôt que d'insister avec des conditions
        // initiales qui pourraient être la cause de la non-convergence.
        etat_.clear();
        analogique_.oublier_etat();
        return;
    }
    etat_ = analogique_.etat_final();

    const coeur::Formes& formes = analogique_.formes();
    emit trame_calculee(formes, instant_trame_);
    instant_trame_ += duree;

    // Ce qu'on affiche sur le schéma est la valeur moyenne sur la trame :
    // c'est ce qu'indiquerait un multimètre, et c'est stable à l'œil. Le
    // détail instantané, lui, est dans l'oscilloscope.
    auto moyenne = [](const std::vector<double>& courbe) {
        if (courbe.empty()) return 0.0;
        double somme = 0;
        for (double valeur : courbe) somme += valeur;
        return somme / courbe.size();
    };
    auto moyenne_absolue = [](const std::vector<double>& courbe) {
        if (courbe.empty()) return 0.0;
        double somme = 0;
        for (double valeur : courbe) somme += std::fabs(valeur);
        return somme / courbe.size();
    };

    std::map<std::string, double> courants;
    for (const auto& trace : formes.courants)
        courants[trace.first] = moyenne_absolue(trace.second);
    std::map<std::string, double> tensions;
    for (const auto& trace : formes.tensions)
        tensions[trace.first] = moyenne(trace.second);

    // Retour du circuit vers le microcontrôleur. Ici, en revanche, c'est la
    // valeur *finale* qui compte : le programme lit un niveau à un instant
    // donné, pas une moyenne.
    for (const LiaisonBroche& liaison : broches_) {
        if (mcu_.direction_sortie(liaison.numero)) continue;
        std::string noeud = liaison.noeud;
        std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        auto it = formes.tensions.find(noeud);
        if (it == formes.tensions.end() || it->second.empty()) continue;
        const double derniere = it->second.back();
        if (liaison.numero >= 14)
            mcu_.definir_tension_adc(liaison.numero - 14, derniere);
        mcu_.definir_niveau_externe(liaison.numero, derniere > 2.5);
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
    // L'état de départ doit être relevé AVANT d'exécuter : les rappels de
    // simavr vont modifier `masque_` pendant l'avancement.
    cycle_debut_ = mcu_.cycle();
    masque_debut_ = masque_;
    commutations_.clear();

    const uint64_t executes = mcu_.avancer(cycles);
    resoudre_trame(executes);

    const double reel = chronometre.nsecsElapsed() / 1e6;   // ms consommées
    const double simule = executes * 1000.0 / mcu_.frequence();
    vitesse_ = reel > 0 ? simule / reel : 0.0;
    emit avancement(mcu_.temps_ms(), vitesse_);
}
