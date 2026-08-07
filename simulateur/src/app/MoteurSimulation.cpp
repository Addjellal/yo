#include "app/MoteurSimulation.h"

#include <QDir>
#include <QElapsedTimer>
#include <QFileInfo>

#include <algorithm>
#include <cmath>

namespace {

constexpr int kPeriodeTrame = 25;        // ms entre deux images

// Renvoyé quand on interroge une carte qui n'est pas sur le schéma : évite un
// pointeur nul dans le code d'affichage et de diagnostic.
const coeur::AvrEngine& moteur_inerte() {
    static coeur::AvrEngine unique;
    return unique;
}

}  // namespace

MoteurSimulation::MoteurSimulation(QObject* parent) : QObject(parent) {
    minuterie_.setInterval(kPeriodeTrame);
    minuterie_.setTimerType(Qt::PreciseTimer);
    connect(&minuterie_, &QTimer::timeout, this, &MoteurSimulation::trame);
}

MoteurSimulation::~MoteurSimulation() = default;

// ---------------------------------------------------------------------------
// Cartes
// ---------------------------------------------------------------------------
MoteurSimulation::Carte* MoteurSimulation::carte(const QString& reference) {
    const QString cible = reference.isEmpty() ? carte_par_defaut() : reference;
    auto it = cartes_.find(cible);
    return it == cartes_.end() ? nullptr : it->second.get();
}

const MoteurSimulation::Carte* MoteurSimulation::carte(
    const QString& reference) const {
    const QString cible = reference.isEmpty() ? carte_par_defaut() : reference;
    auto it = cartes_.find(cible);
    return it == cartes_.end() ? nullptr : it->second.get();
}

MoteurSimulation::Carte& MoteurSimulation::obtenir_carte(
    const QString& reference) {
    auto it = cartes_.find(reference);
    if (it != cartes_.end()) return *it->second;

    auto nouvelle = std::make_unique<Carte>();
    nouvelle->reference = reference;
    nouvelle->mcu = std::make_unique<coeur::AvrEngine>();
    Carte& resultat = *nouvelle;
    cartes_[reference] = std::move(nouvelle);
    if (!ordre_cartes_.contains(reference)) ordre_cartes_ << reference;
    brancher_rappels(resultat);
    return resultat;
}

void MoteurSimulation::brancher_rappels(Carte& cible) {
    Carte* pointeur = &cible;
    cible.mcu->sur_changement_broche([this, pointeur](int broche, bool haut) {
        noter_changement(*pointeur, broche, haut);
    });
    const QString reference = cible.reference;
    cible.mcu->sur_octet_serie([this, reference](char octet) {
        emit octet_serie(octet, reference);
    });
}

QStringList MoteurSimulation::cartes() const { return ordre_cartes_; }

QString MoteurSimulation::carte_par_defaut() const {
    return ordre_cartes_.isEmpty() ? QString() : ordre_cartes_.first();
}

bool MoteurSimulation::firmware_charge(const QString& reference) const {
    const Carte* cible = carte(reference);
    return cible && cible->firmware_charge;
}

bool MoteurSimulation::un_firmware_au_moins() const {
    for (const auto& paire : cartes_)
        if (paire.second->firmware_charge) return true;
    return false;
}

const coeur::AvrEngine& MoteurSimulation::mcu(const QString& reference) const {
    const Carte* cible = carte(reference);
    return cible && cible->mcu ? *cible->mcu : moteur_inerte();
}

double MoteurSimulation::temps_ms() const {
    // Toutes les cartes avancent du même nombre de cycles : n'importe laquelle
    // donne l'heure.
    for (const QString& reference : ordre_cartes_) {
        const Carte* cible = carte(reference);
        if (cible && cible->firmware_charge) return cible->mcu->temps_ms();
    }
    return 0.0;
}

// ---------------------------------------------------------------------------
// Firmwares
// ---------------------------------------------------------------------------
bool MoteurSimulation::charger_firmware(const QString& chemin, QString* erreur,
                                        const QString& reference) {
    const QString cible =
        reference.isEmpty() ? carte_par_defaut() : reference;
    if (cible.isEmpty()) {
        if (erreur)
            *erreur =
                "Aucune carte programmable sur le schéma : posez une carte "
                "Arduino avant de charger un firmware.";
        return false;
    }
    Carte& c = obtenir_carte(cible);
    if (!c.mcu->disponible()) {
        if (erreur) *erreur = "simavr n'est pas compilé dans cette version.";
        return false;
    }
    if (!c.mcu->charger(chemin.toStdString())) {
        if (erreur) *erreur = QString::fromStdString(c.mcu->erreur());
        c.firmware_charge = false;
        return false;
    }
    // `charger` réinitialise le cœur : il faut rebrancher les rappels.
    brancher_rappels(c);
    c.firmware_charge = true;
    // Seule cette carte repart de zéro. Effacer les masques des autres les
    // ferait paraître à 0 V jusqu'à leur prochaine écriture sur un port —
    // soit, dans l'exemple à deux cartes, jusqu'à 300 ms de LED éteinte à
    // tort.
    c.masque = 0;
    c.masque_debut = 0;
    c.cycle_debut = 0;
    c.commutations.clear();
    emit journal(QString("Firmware chargé sur %1 : %2")
                     .arg(cible, QFileInfo(chemin).fileName()));
    return true;
}

bool MoteurSimulation::compiler_et_charger(const QString& source,
                                           const QString& dossier,
                                           QString* journal_texte,
                                           const QString& reference) {
    if (!coeur::AvrEngine::avr_gcc_disponible()) {
        if (journal_texte)
            *journal_texte =
                "avr-gcc est introuvable. Installez la chaîne de compilation "
                "AVR (paquet gcc-avr et avr-libc) pour compiler depuis "
                "l'application.";
        return false;
    }
    const QString cible = reference.isEmpty() ? carte_par_defaut() : reference;
    if (cible.isEmpty()) {
        if (journal_texte)
            *journal_texte =
                "Aucune carte programmable sur le schéma : posez une carte "
                "Arduino avant de compiler.";
        return false;
    }
    QDir().mkpath(dossier);
    // Un fichier par carte : deux cartes ne doivent pas se disputer le même
    // binaire.
    const QString fichier =
        QDir(dossier).filePath("firmware_" + cible.toLower() + ".elf");
    std::string compte_rendu;
    const bool ok = coeur::AvrEngine::compiler_source(
        source.toStdString(), fichier.toStdString(), &compte_rendu);
    if (journal_texte) *journal_texte = QString::fromStdString(compte_rendu);
    if (!ok) return false;
    QString erreur;
    if (!charger_firmware(fichier, &erreur, cible)) {
        if (journal_texte) *journal_texte += "\n" + erreur;
        return false;
    }
    return true;
}

// ---------------------------------------------------------------------------
void MoteurSimulation::definir_circuit(coeur::Netlist netlist,
                                       std::vector<LiaisonBroche> broches,
                                       const QStringList& cartes) {
    netlist_ = std::move(netlist);
    broches_ = std::move(broches);

    // Les cartes du schéma peuvent avoir changé. On crée celles qui
    // apparaissent, on retire celles qui ont disparu — mais on garde le
    // firmware déjà chargé sur celles qui restent.
    for (const QString& reference : cartes)
        if (!reference.isEmpty()) obtenir_carte(reference);
    for (auto it = cartes_.begin(); it != cartes_.end();) {
        if (cartes.contains(it->first)) {
            ++it;
            continue;
        }
        it = cartes_.erase(it);
    }
    // Ordre stable : celui des références, pour que « la première carte »
    // veuille dire quelque chose.
    ordre_cartes_ = cartes;
    ordre_cartes_.sort();
}

void MoteurSimulation::remettre_a_zero() {
    for (auto& paire : cartes_) {
        paire.second->masque = 0;
        paire.second->masque_debut = 0;
        paire.second->cycle_debut = 0;
        paire.second->commutations.clear();
    }
    instant_trame_ = 0.0;
    etat_.clear();
    analogique_.oublier_etat();
}

void MoteurSimulation::demarrer() {
    if (cartes_.empty()) {
        emit journal("Aucune carte programmable sur le schéma.");
        return;
    }
    if (!un_firmware_au_moins()) {
        emit journal("Aucun firmware chargé : rien à exécuter.");
        return;
    }
    QStringList sans_firmware;
    for (const QString& reference : ordre_cartes_)
        if (!firmware_charge(reference)) sans_firmware << reference;
    if (!sans_firmware.isEmpty())
        emit journal(QString("Attention : %1 n'a pas de firmware et restera "
                             "inerte (ses broches sont en entrée).")
                         .arg(sans_firmware.join(", ")));
    minuterie_.start();
    emit journal("Simulation démarrée.");
}

void MoteurSimulation::suspendre() {
    minuterie_.stop();
    emit journal("Simulation suspendue.");
}

void MoteurSimulation::arreter() {
    minuterie_.stop();
    for (auto& paire : cartes_) paire.second->mcu->reinitialiser();
    remettre_a_zero();
    vitesse_ = 0.0;
    emit journal("Simulation arrêtée et microcontrôleurs réinitialisés.");
    emit avancement(0.0, 0.0);
}

// ---------------------------------------------------------------------------
void MoteurSimulation::noter_changement(Carte& cible, int broche, bool haut) {
    if (broche < 0 || broche >= 32) return;
    // On garde l'instant exact : c'est lui qui devient un point de la source
    // linéaire par morceaux, donc un front dans la forme d'onde.
    cible.commutations.push_back({cible.mcu->cycle(), broche, haut});
    if (haut) cible.masque |= (1u << broche);
    else cible.masque &= ~(1u << broche);
}

void MoteurSimulation::definir_resolution(double secondes) {
    if (secondes < 1e-6) secondes = 1e-6;      // 1 µs : plancher raisonnable
    if (secondes > 1e-3) secondes = 1e-3;
    pas_ = secondes;
}

std::vector<coeur::BrocheElectrique> MoteurSimulation::broches_pour(
    bool au_depart) const {
    std::vector<coeur::BrocheElectrique> resultat;
    resultat.reserve(broches_.size());
    for (const LiaisonBroche& liaison : broches_) {
        const Carte* cible = carte(QString::fromStdString(liaison.carte));
        coeur::BrocheElectrique broche;
        broche.noeud = liaison.noeud;
        // Une carte sans firmware ne pilote rien : ses broches restent en
        // entrée haute impédance, ce qui est l'état d'un microcontrôleur au
        // repos.
        if (!cible || !cible->firmware_charge) {
            broche.mode = coeur::BrocheElectrique::Mode::Entree;
            resultat.push_back(broche);
            continue;
        }
        const coeur::AvrEngine& mcu = *cible->mcu;
        if (mcu.direction_sortie(liaison.numero)) {
            broche.mode = coeur::BrocheElectrique::Mode::Sortie;
            const uint32_t masque =
                au_depart ? cible->masque_debut : cible->masque;
            broche.tension = (masque >> liaison.numero) & 1u ? 5.0 : 0.0;
            broche.resistance = 25.0;      // résistance de sortie d'un AVR
        } else if (mcu.pullup_actif(liaison.numero)) {
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
    const uint32_t frequence =
        cartes_.empty() ? 16000000 : cartes_.begin()->second->mcu->frequence();
    const double duree = static_cast<double>(cycles_ecoules) / frequence;
    // Un circuit sans composant reste simulable dès qu'il porte des broches :
    // c'est le cas de deux cartes reliées directement l'une à l'autre.
    if (duree <= 0 || (netlist_.instances().empty() && broches_.empty())) {
        for (auto& paire : cartes_) paire.second->commutations.clear();
        return;
    }

    const std::vector<coeur::BrocheElectrique> broches = broches_pour(true);

    // Les commutations de toutes les cartes sont fondues dans une seule
    // analyse : elles partagent le circuit, donc elles partagent la fenêtre.
    std::map<std::pair<QString, int>, std::string> noeud_de_broche;
    for (const LiaisonBroche& liaison : broches_)
        noeud_de_broche[{QString::fromStdString(liaison.carte),
                         liaison.numero}] = liaison.noeud;

    std::vector<coeur::TransitionBroche> transitions;
    for (auto& paire : cartes_) {
        Carte& cible = *paire.second;
        for (const Carte::Commutation& commutation : cible.commutations) {
            auto it = noeud_de_broche.find({cible.reference, commutation.broche});
            if (it == noeud_de_broche.end()) continue;
            const double instant =
                static_cast<double>(commutation.cycle - cible.cycle_debut) /
                frequence;
            transitions.push_back(
                {instant, it->second, commutation.haut ? 5.0 : 0.0});
        }
        cible.commutations.clear();
    }
    std::sort(transitions.begin(), transitions.end(),
              [](const coeur::TransitionBroche& a,
                 const coeur::TransitionBroche& b) {
                  return a.instant < b.instant;
              });

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

    // Retour du circuit vers les microcontrôleurs. Ici, en revanche, c'est la
    // valeur *finale* qui compte : le programme lit un niveau à un instant
    // donné, pas une moyenne.
    for (const LiaisonBroche& liaison : broches_) {
        Carte* cible = carte(QString::fromStdString(liaison.carte));
        if (!cible || !cible->firmware_charge) continue;
        if (cible->mcu->direction_sortie(liaison.numero)) continue;
        std::string noeud = liaison.noeud;
        std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        auto it = formes.tensions.find(noeud);
        if (it == formes.tensions.end() || it->second.empty()) continue;
        const double derniere = it->second.back();
        if (liaison.numero >= 14)
            cible->mcu->definir_tension_adc(liaison.numero - 14, derniere);
        cible->mcu->definir_niveau_externe(liaison.numero, derniere > 2.5);
    }

    emit resultats(courants, tensions);
}

void MoteurSimulation::resoudre_une_fois() {
    if (netlist_.instances().empty()) {
        emit journal("Le schéma ne contient aucun composant simulable.");
        return;
    }
    source_spice_ = QString::fromStdString(
        // Point de repos : c'est l'état actuel qui compte, pas celui du
        // début du dernier pas de couplage.
        analogique_.construire(netlist_, broches_pour(false)));
    if (!analogique_.resoudre()) {
        for (const auto& message : analogique_.erreurs())
            emit journal(QString::fromStdString(message));
        return;
    }
    emit resultats(analogique_.tous_courants(), analogique_.toutes_tensions());
    emit journal("Analyse au point de repos effectuée.");
}

// Le pas de couplage ne sert qu'au retour du circuit vers le microcontrôleur.
// Si toutes les broches sont en sortie, le programme n'a rien à relire : on
// peut alors traiter la trame entière d'un bloc, et c'est bien plus rapide.
// Dès qu'une broche est lue — un bouton, un capteur, une autre carte — on
// resserre le pas pour que la réponse ne traîne pas.
int MoteurSimulation::pas_couplage_utile() const {
    constexpr int kLarge = 25;    // aucune lecture : une résolution par image
    constexpr int kFin = 5;       // lecture en jeu : cinq fois plus réactif

    if (cartes_.size() > 1) return kFin;
    for (const LiaisonBroche& liaison : broches_) {
        const Carte* cible = carte(QString::fromStdString(liaison.carte));
        if (!cible || !cible->firmware_charge) continue;
        if (!cible->mcu->direction_sortie(liaison.numero)) return kFin;
    }
    return kLarge;
}

uint64_t MoteurSimulation::executer_pas(uint64_t cycles) {
    // L'état de départ doit être relevé AVANT d'exécuter : les rappels de
    // simavr vont modifier les masques pendant l'avancement.
    uint64_t executes = 0;
    for (auto& paire : cartes_) {
        Carte& cible = *paire.second;
        cible.cycle_debut = cible.mcu->cycle();
        cible.masque_debut = cible.masque;
        cible.commutations.clear();
        if (!cible.firmware_charge) continue;
        // Toutes les cartes reçoivent le même nombre de cycles : c'est ce qui
        // les garde sur la même horloge.
        executes = std::max(executes, cible.mcu->avancer(cycles));
    }
    resoudre_trame(executes);
    return executes;
}

void MoteurSimulation::trame() {
    QElapsedTimer chronometre;
    chronometre.start();

    const uint32_t frequence =
        cartes_.empty() ? 16000000 : cartes_.begin()->second->mcu->frequence();
    pas_couplage_ms_ = pas_couplage_utile();
    const uint64_t cycles_par_pas =
        static_cast<uint64_t>(frequence) * pas_couplage_ms_ / 1000;
    const int pas = std::max(1, kPeriodeTrame / std::max(1, pas_couplage_ms_));

    uint64_t executes = 0;
    for (int k = 0; k < pas; ++k) executes += executer_pas(cycles_par_pas);

    const double reel = chronometre.nsecsElapsed() / 1e6;   // ms consommées
    const double simule = executes * 1000.0 / frequence;
    vitesse_ = reel > 0 ? simule / reel : 0.0;
    emit avancement(temps_ms(), vitesse_);
}
