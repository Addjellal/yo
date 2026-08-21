#include "app/MoteurSimulation.h"

#include <QDir>
#include <QElapsedTimer>
#include <QFileInfo>

#include <algorithm>

#include "coeur/Device.h"
#include "coeur/documents/Documents.h"
#include <cmath>

namespace {

constexpr int kPeriodeTrame = 25;        // ms entre deux images

// Renvoyé quand on interroge une carte qui n'est pas sur le schéma : évite un
// pointeur nul dans le code d'affichage et de diagnostic.
const coeur::Microcontroleur& moteur_inerte() {
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
    // Le moteur par défaut ; la puce du modèle le remplacera si elle demande
    // une autre architecture.
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
    // Le convertisseur ne prend plus sa valeur au bord de la fenêtre mais à
    // l'instant même de la conversion, dans la forme d'onde déjà calculée.
    cible.mcu->definir_source_adc([this, pointeur](int canal, uint64_t cycle) {
        return tension_adc_datee(*pointeur, canal, cycle);
    });
}

// Tension présentée à une voie du convertisseur à l'instant `cycle` du cœur.
//
// La forme d'onde consultée est celle de la fenêtre PRÉCÉDENTE : celle de la
// fenêtre en cours n'existe pas encore, puisque le circuit n'est résolu
// qu'après que le firmware a tourné. C'est un retard d'une fenêtre, et il est
// sans conséquence sur ce qui nous occupe : sur un régime périodique établi,
// un retard pur laisse le spectre d'amplitude inchangé.
//
// Rend -1 quand il n'y a rien à lire — première fenêtre, nœud non relevé — et
// la puce garde alors la valeur que le couplage lui a laissée.
double MoteurSimulation::tension_adc_datee(const Carte& cible, int canal,
                                           uint64_t cycle) const {
    if (onde_temps_.size() < 2 || !cible.mcu) return -1.0;

    // Quelle broche de cette carte porte cette voie, et sur quel nœud ?
    const std::string* noeud = nullptr;
    for (const LiaisonBroche& liaison : broches_) {
        if (QString::fromStdString(liaison.carte) != cible.reference) continue;
        if (cible.mcu->canal_adc(liaison.numero) != canal) continue;
        noeud = &liaison.noeud;
        break;
    }
    if (!noeud) return -1.0;
    std::string minuscule = *noeud;
    std::transform(minuscule.begin(), minuscule.end(), minuscule.begin(),
                   [](unsigned char c) { return std::tolower(c); });
    auto onde = ondes_adc_.find(minuscule);
    if (onde == ondes_adc_.end() || onde->second.size() != onde_temps_.size())
        return -1.0;

    const uint32_t frequence = cible.mcu->frequence();
    if (frequence == 0) return -1.0;
    const uint64_t depuis =
        cycle > cible.cycle_debut ? cycle - cible.cycle_debut : 0;
    double instant = static_cast<double>(depuis) / frequence;
    const double duree = onde_temps_.back() - onde_temps_.front();
    // Une fenêtre plus longue que la précédente n'a rien d'anormal : on lit
    // alors la fin de celle qu'on a.
    if (instant > duree) instant = duree;
    instant += onde_temps_.front();

    // Interpolation linéaire entre les deux points qui encadrent l'instant.
    const auto borne = std::lower_bound(onde_temps_.begin(), onde_temps_.end(),
                                        instant);
    if (borne == onde_temps_.begin()) return onde->second.front();
    if (borne == onde_temps_.end()) return onde->second.back();
    const size_t rang = static_cast<size_t>(borne - onde_temps_.begin());
    const double t0 = onde_temps_[rang - 1], t1 = onde_temps_[rang];
    if (t1 - t0 < 1e-15) return onde->second[rang];
    const double part = (instant - t0) / (t1 - t0);
    return onde->second[rang - 1]
           + part * (onde->second[rang] - onde->second[rang - 1]);
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

const coeur::Microcontroleur& MoteurSimulation::mcu(
    const QString& reference) const {
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
    // Aucune carte, ou aucune programmée : l'heure est celle du circuit.
    //
    // On rendait zéro, et la barre d'état affichait « Temps simulé : 0,000 s »
    // pendant que l'oscilloscope, lui, en était à soixante-six secondes. Un
    // montage purement analogique — générateur, filtre, redresseur — se simule
    // parfaitement sans microcontrôleur ; c'est même le cas de la moitié des
    // exemples livrés. Lui refuser une horloge parce qu'aucune puce ne la
    // porte, c'est afficher deux temps contradictoires sur le même écran.
    return instant_trame_ * 1000.0;
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
    if (!c.mcu->charger(chemin.toStdString(), c.puce, c.horloge)) {
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
    const Carte* cible = carte(reference);
    const std::string mcu = cible ? cible->puce : "atmega328p";
    return compiler_et_charger(
        coeur::Programme{{coeur::nom_principal(mcu), source.toStdString()}},
        dossier, journal_texte, reference);
}

bool MoteurSimulation::compiler_et_charger(const coeur::Programme& fichiers,
                                           const QString& dossier,
                                           QString* journal_texte,
                                           const QString& reference) {
    const QString cible = reference.isEmpty() ? carte_par_defaut() : reference;
    if (cible.isEmpty()) {
        if (journal_texte)
            *journal_texte =
                "Aucune carte programmable sur le schéma : posez une carte "
                "Arduino avant de compiler.";
        return false;
    }
    // La chaîne de compilation dépend de la puce, et le message qui manque
    // aussi : dire « installez avr-gcc » devant une carte ARM n'aiderait
    // personne.
    const Carte& puce_cible = obtenir_carte(cible);
    if (!coeur::chaine_disponible_pour(puce_cible.puce)) {
        if (journal_texte)
            *journal_texte =
                QString("Aucun compilateur trouvé pour %1.\n")
                    .arg(QString::fromStdString(puce_cible.puce))
                + (puce_cible.puce.rfind("at", 0) == 0
                       ? "Installez la chaîne AVR (paquets gcc-avr et "
                         "avr-libc)."
                       : "Installez « arm-none-eabi-gcc » ou « clang ».")
                + "\nUn fichier .elf déjà compilé peut être chargé sans rien "
                  "installer.";
        return false;
    }
    // UN DOSSIER PAR CARTE, et vidé avant chaque compilation.
    //
    // Les deux comptent. Un dossier commun mettrait les fichiers annexes de
    // toutes les cartes dans le même chemin d'inclusion : U2 pourrait alors
    // inclure « mesure.h » écrit pour U1, et cela compilerait sans un mot.
    // Et sans le vidage, un fichier retiré du programme resterait sur le
    // disque et continuerait de satisfaire son #include — le programme
    // marcherait encore, jusqu'à ce qu'on le compile ailleurs.
    const QString atelier = QDir(dossier).filePath("carte_" + cible.toLower());
    QDir(atelier).removeRecursively();
    QDir().mkpath(atelier);
    const QString fichier = QDir(atelier).filePath("firmware.elf");
    std::string compte_rendu;
    const Carte& carte_cible = puce_cible;
    // La chaîne qui convient à la puce : avr-g++ pour un ATmega, un
    // compilateur ARM pour un Cortex-M.
    // TOUTE COMPILATION DÉCHARGE D'ABORD L'ANCIEN FIRMWARE.
    //
    // Sans cela, une compilation qui échoue laisse en place le programme
    // précédent : on corrige son code, on appuie sur Compiler, le message
    // d'erreur passe inaperçu dans le journal, on lance — et c'est l'ANCIEN
    // programme qui tourne. On croit alors que ses modifications n'ont aucun
    // effet, ce qui est la pire piste possible.
    //
    // Après cet appel, ce qui s'exécute est donc toujours ce qu'on vient de
    // compiler, ou rien. Il n'y a pas de troisième cas.
    Carte& a_vider = obtenir_carte(cible);
    if (a_vider.firmware_charge) {
        a_vider.firmware_charge = false;
        a_vider.mcu->reinitialiser();
        a_vider.commutations.clear();
        emit journal("Ancien firmware de " + cible + " déchargé.");
    }

    const bool ok = coeur::compiler_pour(carte_cible.puce, fichiers,
                                         fichier.toStdString(),
                                         carte_cible.horloge, &compte_rendu);
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
                                       const std::vector<CartePosee>& cartes) {
    QStringList references;
    for (const CartePosee& posee : cartes) references << posee.reference;
    definir_circuit(std::move(netlist), std::move(broches), references);
    // Chaque carte apprend sa puce : la compilation et l'exécution en
    // dépendent, et une carte qui l'ignorerait serait traitée en Arduino.
    for (const CartePosee& posee : cartes) {
        auto it = cartes_.find(posee.reference);
        if (it == cartes_.end()) continue;
        Carte& carte = *it->second;
        // Changer de puce peut vouloir dire changer d'architecture : on ne
        // garde le moteur en place que s'il reconnaît la nouvelle.
        if (!carte.mcu || !carte.mcu->reconnait(posee.mcu)) {
            std::unique_ptr<coeur::Microcontroleur> autre =
                coeur::creer_microcontroleur(posee.mcu);
            if (autre) {
                carte.mcu = std::move(autre);
                carte.firmware_charge = false;
                brancher_rappels(carte);
            }
        }
        carte.puce = posee.mcu;
        carte.horloge = posee.horloge;
        carte.tension_logique = posee.tension_logique;
        carte.resistance_sortie = posee.resistance_sortie;
        carte.resistance_tirage = posee.resistance_tirage;
    }
}

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
    // Un composant grillé le reste tant que la simulation tourne, mais un
    // arrêt remet le montage à neuf : on repart d'un tiroir plein.
    grilles_.clear();
    etat_.clear();
    analogique_.oublier_etat();
}

// Le compte rendu du contrôle, tel qu'il doit apparaître au moment où l'on
// appuie sur « Lancer ». Une erreur se nomme : sans référence ni nœud, un
// diagnostic ne sert à rien. Les avertissements suivent, plus discrets.
void MoteurSimulation::signaler_regles() {
    const std::vector<coeur::Anomalie> anomalies =
        coeur::controler_regles(netlist_);
    int erreurs = 0, avertissements = 0;
    for (const auto& anomalie : anomalies) {
        if (anomalie.gravite == coeur::Anomalie::Gravite::Erreur) ++erreurs;
        else if (anomalie.gravite == coeur::Anomalie::Gravite::Avertissement)
            ++avertissements;
    }
    emit controle_effectue(erreurs, avertissements);
    emit anomalies_relevees(anomalies);
    if (anomalies.empty()) return;

    if (erreurs > 0)
        emit journal(QString("Contrôle du schéma : %1 erreur(s). La simulation "
                             "va tourner, mais ceci l'explique.")
                         .arg(erreurs));
    for (const auto& anomalie : anomalies) {
        const bool erreur =
            anomalie.gravite == coeur::Anomalie::Gravite::Erreur;
        const QString ou = QString::fromStdString(anomalie.reference);
        emit journal(QString("   %1 %2%3")
                         .arg(erreur ? "ERREUR  " : "attention")
                         .arg(ou.isEmpty() ? QString() : ou + " : ")
                         .arg(QString::fromStdString(anomalie.message)));
        // Le remède sur sa propre ligne, en retrait : c'est ce qui distingue
        // un diagnostic d'un reproche. Sans lui, l'élève sait qu'il a tort
        // sans savoir quoi faire — et un diagnostic non actionnable ne vaut
        // rien.
        if (!anomalie.remede.empty())
            emit journal(QString("            → %1")
                             .arg(QString::fromStdString(anomalie.remede)));
    }
}

void MoteurSimulation::envoyer_serie(const QByteArray& octets,
                                     const QString& reference) {
    Carte* cible = carte(reference);
    if (!cible || !cible->mcu) return;
    // Le firmware lit sa liaison série pendant qu'il tourne : émettre vers une
    // carte arrêtée déposerait des octets que personne ne viendra chercher.
    if (etat_simulation_ != Etat::EnMarche) {
        emit journal("La simulation est arrêtée : lancez-la avant d'émettre "
                     "sur la liaison série.");
        return;
    }
    for (char octet : octets)
        cible->mcu->envoyer_octet_serie(static_cast<uint8_t>(octet));
}

void MoteurSimulation::demarrer() {
    // Reprise après une pause : rien à réamorcer, l'état est intact.
    if (etat_simulation_ == Etat::EnPause) {
        minuterie_.start();
        etat_simulation_ = Etat::EnMarche;
        emit etat_change(etat_simulation_);
        emit journal("Simulation reprise.");
        return;
    }

    // Le contrôle des règles électriques existait, mais n'était appelé que
    // par l'export de dossier — c'est-à-dire jamais au moment où il sert.
    // Résultat : un court-circuit d'alimentation ne se manifestait que par
    // « le point de repos initial n'a pas convergé », répété à chaque pas de
    // temps, sans jamais nommer le fautif. On le passe ici, avant de lancer.
    signaler_regles();

    // Un montage sans carte reste un circuit : générateur, filtre, redresseur
    // se simulent très bien sans microcontrôleur, et c'est ce que fait
    // n'importe quel simulateur analogique.
    if (cartes_.empty()) {
        if (netlist_.instances().empty()) {
            emit journal("Le schéma ne contient aucun composant.");
            return;
        }
        minuterie_.start();
        etat_simulation_ = Etat::EnMarche;
        emit etat_change(etat_simulation_);
        emit journal("Simulation analogique démarrée (aucune carte sur le "
                     "schéma).");
        return;
    }
    if (!un_firmware_au_moins()) {
        // ON DÉMARRE QUAND MÊME. Refuser était le mauvais réflexe : le
        // circuit analogique autour de la carte est parfaitement simulable —
        // les alimentations, les résistances, un voltmètre posé sur une
        // broche —, et c'est précisément ce qu'on veut voir quand on n'a pas
        // encore de programme. La carte reste inerte, ses broches en entrée
        // haute impédance, ce qui est l'état d'un microcontrôleur non
        // programmé : c'est physiquement juste.
        //
        // Appuyer sur « Lancer » et ne rien obtenir, avec pour seule
        // explication « rien à exécuter » répété à chaque essai, laisse
        // croire que l'application est cassée. Le message dit maintenant ce
        // qui manque ET les deux façons d'y remédier.
        emit journal(
            "Aucun firmware : la carte reste inerte (broches en entrée), mais "
            "le circuit analogique est simulé.");
        emit journal(
            "   Pour exécuter un programme : compilez-le (F5) si une chaîne "
            "est installée, ou chargez un .elf déjà compilé par "
            "Simulation ▸ Charger un firmware.");
    }
    QStringList sans_firmware;
    for (const QString& reference : ordre_cartes_)
        if (!firmware_charge(reference)) sans_firmware << reference;
    if (!sans_firmware.isEmpty())
        emit journal(QString("Attention : %1 n'a pas de firmware et restera "
                             "inerte (ses broches sont en entrée).")
                         .arg(sans_firmware.join(", ")));
    minuterie_.start();
    etat_simulation_ = Etat::EnMarche;
    emit etat_change(etat_simulation_);
    emit journal("Simulation démarrée.");
}

void MoteurSimulation::suspendre() {
    if (etat_simulation_ != Etat::EnMarche) return;
    minuterie_.stop();
    etat_simulation_ = Etat::EnPause;
    emit etat_change(etat_simulation_);
    emit journal("Simulation en pause — l'état du circuit est conservé.");
}

void MoteurSimulation::arreter() {
    const bool tournait = etat_simulation_ != Etat::Arrete;
    minuterie_.stop();
    for (auto& paire : cartes_) paire.second->mcu->reinitialiser();
    remettre_a_zero();
    vitesse_ = 0.0;
    etat_simulation_ = Etat::Arrete;
    emit etat_change(etat_simulation_);
    if (tournait)
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
        const coeur::Microcontroleur& mcu = *cible->mcu;
        if (mcu.direction_sortie(liaison.numero)) {
            broche.mode = coeur::BrocheElectrique::Mode::Sortie;
            const uint32_t masque =
                au_depart ? cible->masque_debut : cible->masque;
            // La tension vient de la carte : imposer cinq volts à un Pico
            // ferait passer dans une LED presque le double du courant réel.
            broche.tension =
                (masque >> liaison.numero) & 1u ? cible->tension_logique : 0.0;
            broche.resistance = cible->resistance_sortie;
        } else if (mcu.pullup_actif(liaison.numero)) {
            broche.mode = coeur::BrocheElectrique::Mode::PullUp;
            // Le tirage remonte vers l'alimentation DE LA CARTE : 5 V sur un
            // AVR, 3,3 V sur un Pico. La confondre avec le rail du schéma
            // ferait remonter une entrée de Pico à 5 V.
            broche.tension = cible->tension_logique;
            broche.resistance = cible->resistance_tirage;
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
                {instant, it->second,
                 commutation.haut ? cible.tension_logique : 0.0});
        }
        cible.commutations.clear();
    }
    std::sort(transitions.begin(), transitions.end(),
              [](const coeur::TransitionBroche& a,
                 const coeur::TransitionBroche& b) {
                  return a.instant < b.instant;
              });

    // Les composants numériques réagissent AVANT la résolution analogique :
    // leurs sorties deviennent des sources de la fenêtre qui suit.
    if (coeur::MoteurNumerique::circuit_numerique(netlist_)) {
        std::vector<coeur::FrontNoeud> fronts;
        fronts.reserve(transitions.size());
        for (const coeur::TransitionBroche& transition : transitions)
            fronts.push_back({transition.instant, transition.noeud,
                              transition.tension > 2.5});
        numerique_.propager(netlist_, fronts, etat_, duree);

        // L'état d'un registre vit dans son instance, et la netlist est
        // reconstruite à chaque modification du schéma : sans ce renvoi vers
        // les composants posés, le registre se réinitialiserait sans cesse.
        std::map<std::string, std::map<std::string, double>> etats;
        for (const coeur::Instance& instance : netlist_.instances()) {
            const coeur::Modele* modele =
                coeur::Catalogue::instance().modele(instance.type);
            if (!modele || !modele->reagir) continue;
            etats[instance.reference] = instance.valeurs;
        }
        if (!etats.empty()) emit etats_composants(etats);
    }

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

    coeur::Formes& formes = analogique_.formes_modifiables();

    // Les composants à état lisent ce que le circuit vient de leur faire
    // subir, et avancent leur mécanique. Un servomoteur mesure son
    // impulsion, un moteur intègre sa vitesse, un télémètre arme son écho.
    faire_evoluer(formes, duree);

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

    // On retient la forme d'onde des nœuds qui entrent dans un convertisseur.
    // C'est elle que la puce relira, à l'instant de sa conversion, pendant la
    // fenêtre suivante. Seuls ces nœuds-là sont gardés : le reste ne servirait
    // à rien et coûterait de la mémoire à chaque image.
    onde_temps_ = formes.temps;
    ondes_adc_.clear();
    for (const LiaisonBroche& liaison : broches_) {
        const Carte* source = carte(QString::fromStdString(liaison.carte));
        if (!source || !source->mcu) continue;
        if (source->mcu->canal_adc(liaison.numero) < 0) continue;
        std::string noeud = liaison.noeud;
        std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        if (ondes_adc_.count(noeud)) continue;
        auto trace = formes.tensions.find(noeud);
        if (trace != formes.tensions.end()) ondes_adc_[noeud] = trace->second;
    }

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
        // C'est la puce qui dit si une broche entre dans le convertisseur, et
        // sur quelle voie : A0 est la broche 14 d'un Uno et la 54 d'un Mega.
        const int canal = cible->mcu->canal_adc(liaison.numero);
        if (canal >= 0) cible->mcu->definir_tension_adc(canal, derniere);
        // Les broches sans étage numérique — A6 et A7 d'un Nano — ignorent
        // le niveau qu'on leur impose : le moteur le sait, on peut appeler
        // sans distinguer.
        cible->mcu->definir_niveau_externe(liaison.numero, derniere > 2.5);
    }

    surveiller_contraintes(formes);
    emit resultats(courants, tensions);
}

// Ce qui aurait grillé.
//
// Le solveur ne connaît que des équations : une résistance d'un quart de watt
// qui en dissipe trois donne un résultat parfaitement convergé, et le montage
// a l'air de marcher. Sur la paillasse il fume. Cette fonction relit les
// formes d'onde de la fenêtre qui vient d'être calculée et compare, pour
// chaque composant, ce qu'il a encaissé à ce qu'il supporte.
//
// On prend la **crête**, pas la moyenne : c'est une crête de courant qui ouvre
// une piste de LED, et un composant ne se répare pas ensuite. Une fois marqué,
// il le reste jusqu'à l'arrêt de la simulation — c'est le comportement du
// vrai : on ne dégrille pas.
void MoteurSimulation::surveiller_contraintes(const coeur::Formes& formes) {
    auto crete = [](const std::vector<double>& courbe) {
        double maxi = 0;
        for (double valeur : courbe) maxi = std::max(maxi, std::fabs(valeur));
        return maxi;
    };
    auto en_minuscules = [](std::string texte) {
        std::transform(texte.begin(), texte.end(), texte.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        return texte;
    };

    for (const coeur::Instance& instance : netlist_.instances()) {
        const QString reference = QString::fromStdString(instance.reference);
        if (grilles_.contains(reference)) continue;   // déjà signalé
        const coeur::Modele* modele =
            coeur::Catalogue::instance().modele(instance.type);
        if (!modele) continue;
        if (modele->puissance_max <= 0 && modele->courant_max <= 0
            && modele->tension_max <= 0)
            continue;

        auto trace = formes.courants.find(en_minuscules(instance.reference));
        const std::vector<double>* courant =
            trace == formes.courants.end() ? nullptr : &trace->second;

        // La tension aux bornes, instant par instant : la différence des deux
        // premiers nœuds du composant. Un composant à trois bornes — un
        // transistor — se juge entre la première et la dernière, ce qui est
        // collecteur-émetteur dans l'ordre où le catalogue les déclare.
        std::vector<double> aux_bornes;
        if (instance.bornes.size() >= 2) {
            const auto a = formes.tensions.find(
                en_minuscules(instance.bornes.front().noeud));
            const auto b = formes.tensions.find(
                en_minuscules(instance.bornes.back().noeud));
            const bool a_ok = a != formes.tensions.end();
            const bool b_ok = b != formes.tensions.end();
            const size_t n = a_ok ? a->second.size()
                                  : (b_ok ? b->second.size() : 0);
            for (size_t k = 0; k < n; ++k) {
                // Un nœud absent des relevés est la masse : zéro volt.
                const double va = a_ok && k < a->second.size() ? a->second[k] : 0;
                const double vb = b_ok && k < b->second.size() ? b->second[k] : 0;
                aux_bornes.push_back(va - vb);
            }
        }

        QString faute;
        const double i_max = instance.valeur("amperes_max", modele->courant_max);
        if (courant && i_max > 0) {
            const double mesure = crete(*courant);
            if (mesure > i_max)
                faute = QString("%1 mA de crête pour %2 mA admissibles")
                            .arg(mesure * 1000, 0, 'f', 1)
                            .arg(i_max * 1000, 0, 'f', 0);
        }
        const double v_max = instance.valeur("volts_max", modele->tension_max);
        if (faute.isEmpty() && !aux_bornes.empty() && v_max > 0) {
            const double mesure = crete(aux_bornes);
            if (mesure > v_max)
                faute = QString("%1 V de crête à ses bornes pour %2 V de "
                                "service")
                            .arg(mesure, 0, 'f', 1)
                            .arg(v_max, 0, 'f', 0);
        }
        const double p_max = instance.valeur("watts", modele->puissance_max);
        if (faute.isEmpty() && courant && !aux_bornes.empty() && p_max > 0) {
            // La puissance se calcule instant par instant, pas en multipliant
            // deux crêtes : sur un régime alternatif elles ne tombent pas au
            // même moment, et le produit des maximums surestime largement.
            double maxi = 0;
            const size_t n = std::min(courant->size(), aux_bornes.size());
            for (size_t k = 0; k < n; ++k)
                maxi = std::max(maxi, std::fabs((*courant)[k] * aux_bornes[k]));
            if (maxi > p_max)
                faute = QString("%1 W dissipés pour %2 W admissibles")
                            .arg(maxi, 0, 'f', 2)
                            .arg(p_max, 0, 'f', 2);
        }

        if (faute.isEmpty()) continue;
        grilles_.insert(reference);
        emit journal(QString("GRILLÉ  %1 (%2) : %3.")
                         .arg(reference)
                         .arg(QString::fromStdString(modele->libelle))
                         .arg(faute));
        emit composant_grille(reference);
    }
}

// Donne à chaque composant à état les formes d'onde de ses propres bornes.
void MoteurSimulation::faire_evoluer(coeur::Formes& formes, double duree) {
    auto minuscules = [](std::string texte) {
        std::transform(texte.begin(), texte.end(), texte.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        return texte;
    };

    std::map<std::string, std::map<std::string, double>> etats;
    for (coeur::Instance& instance : netlist_.instances()) {
        const coeur::Modele* modele =
            coeur::Catalogue::instance().modele(instance.type);
        if (!modele || !modele->evoluer) continue;

        coeur::Evolution evolution;
        evolution.duree = duree;
        evolution.temps = &formes.temps;
        evolution.tension = [&](const std::string& borne)
            -> const std::vector<double>* {
            const coeur::Borne* b = instance.borne(borne);
            if (!b || b->noeud.empty()) return nullptr;
            if (b->noeud == coeur::Netlist::kMasse) return nullptr;
            auto it = formes.tensions.find(minuscules(b->noeud));
            return it == formes.tensions.end() ? nullptr : &it->second;
        };
        evolution.courant = [&]() -> const std::vector<double>* {
            auto it = formes.courants.find(minuscules(instance.reference));
            return it == formes.courants.end() ? nullptr : &it->second;
        };
        modele->evoluer(instance, evolution);
        etats[instance.reference] = instance.valeurs;

        // LES GRANDEURS DÉCLARÉES DEVIENNENT DES COURBES.
        //
        // Une valeur par fenêtre, tenue sur toute sa durée : `evoluer` ne
        // rend qu'un état final, pas une trajectoire. Répéter la valeur est
        // honnête — c'est un échantillonnage bloqué — là où interpoler
        // inventerait des points que personne n'a calculés.
        for (const coeur::Grandeur& grandeur : modele->grandeurs) {
            auto valeur = instance.valeurs.find(grandeur.cle);
            if (valeur == instance.valeurs.end()) continue;
            formes.grandeurs[instance.reference + "." + grandeur.cle] =
                std::vector<double>(formes.temps.size(), valeur->second);
        }
    }
    if (!etats.empty()) emit etats_composants(etats);
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

bool MoteurSimulation::executer_balayage(const QString& directive,
                                         QString* erreur) {
    if (netlist_.instances().empty()) {
        if (erreur) *erreur = "Le schéma ne contient aucun composant.";
        return false;
    }
    source_spice_ = QString::fromStdString(analogique_.construire_analyse(
        netlist_, broches_pour(false), directive.toStdString()));
    if (!analogique_.resoudre_analyse()) {
        QString messages;
        for (const auto& message : analogique_.erreurs()) {
            emit journal(QString::fromStdString(message));
            if (!messages.isEmpty()) messages += "\n";
            messages += QString::fromStdString(message);
        }
        // La directive fait partie du diagnostic : c'est elle qu'on relit
        // quand ngspice refuse l'analyse.
        if (erreur)
            *erreur = "« " + directive + " » : "
                      + (messages.isEmpty() ? "aucun résultat" : messages);
        return false;
    }
    emit journal("Analyse « " + directive + " » effectuée : "
                 + QString::number(analogique_.balayage().abscisse.size())
                 + " points.");
    return true;
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
    // Un montage purement analogique — un filtre, un générateur de signaux —
    // n'a aucune carte pour donner le tempo. Le temps doit tout de même
    // avancer, sinon le circuit resterait figé et l'oscilloscope vide.
    if (executes == 0) executes = cycles;
    resoudre_trame(executes);
    return executes;
}

void MoteurSimulation::avancer_simule(double secondes) {
    if (secondes <= 0) return;
    const uint32_t frequence =
        cartes_.empty() ? 16000000 : cartes_.begin()->second->mcu->frequence();
    pas_couplage_ms_ = pas_couplage_utile();
    const uint64_t cycles_par_pas =
        static_cast<uint64_t>(frequence) * pas_couplage_ms_ / 1000;
    if (cycles_par_pas == 0) return;
    const uint64_t total = static_cast<uint64_t>(secondes * frequence);
    for (uint64_t faits = 0; faits < total;)
        faits += std::max<uint64_t>(1, executer_pas(cycles_par_pas));
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
