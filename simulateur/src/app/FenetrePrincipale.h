// Fenêtre principale de l'application.
//
// Disposition volontairement proche des ateliers de CAO électronique :
// palette de composants à gauche, schéma au centre, propriétés à droite,
// journal et console série en bas.
#pragma once

#include <QMainWindow>
#include <QTreeWidget>

#include <QPoint>
#include <QString>

#include <map>
#include <vector>

#include "core/engines/NgspiceEngine.h"

class QAction;
class QLabel;
class QPlainTextEdit;
class QFormLayout;
class QWidget;
class QTabWidget;
class QComboBox;
class QStackedWidget;
class QDockWidget;
class QToolBar;

class ItemComposant;
class SceneSchema;
class VueSchema;
class MoteurSimulation;
class Oscilloscope;
class PanneauAnalyses;
class FenetreInstrument;
class PanneauPcb;

// Palette : arbre catégorie -> composants, avec glisser-déposer vers le schéma.
class PaletteComposants : public QTreeWidget {
public:
    explicit PaletteComposants(QWidget* parent = nullptr);

protected:
    QMimeData* mimeData(const QList<QTreeWidgetItem*>& items) const override;
};

class FenetrePrincipale : public QMainWindow {
    Q_OBJECT

public:
    FenetrePrincipale();
    ~FenetrePrincipale() override;

    // Exemples prêts à l'emploi. Chacun pose un schéma complet et le
    // programme qui va avec : c'est la façon la plus courte de montrer ce que
    // l'application sait faire.
    enum class Exemple { Clignotant, BoutonLed, PotentiometreLed, Transistor,
                         Pwm, DeuxCartes, Servo, MoteurPuissance, FiltreRC,
                         Registre };
    void charger_exemple(Exemple exemple);
    void charger_exemple_deux_cartes();
    // Montage purement analogique : c'est celui sur lequel les analyses
    // paramétriques prennent tout leur sens (Bode, balayage, spectre).
    void charger_exemple_filtre();
    // Chenillard sur registre à décalage : la démonstration du moteur
    // numérique événementiel.
    void charger_exemple_registre();
    void charger_exemple_clignotant() { charger_exemple(Exemple::Clignotant); }

    // Compile le programme affiché puis démarre la simulation. Sert au mode
    // de vérification automatique (« --capture »).
    void demarrage_automatique();

    // Compte rendu textuel de l'état : netlist, broches, source SPICE et
    // résultats. Sert au mode « --diagnostic » et au signalement d'anomalie.
    QString diagnostic();

    // Vitesse de simulation, en multiples du temps réel.
    double vitesse() const;

    // Mesures de l'oscilloscope, en texte (vérification automatique).
    QString mesures_oscilloscope() const;

    // Analyses paramétriques. `rang` : 0 balayage continu, 1 réponse en
    // fréquence, 2 spectre. Le compte rendu textuel sert à la vérification
    // automatique (« --analyse »).
    void lancer_analyse(int rang);
    QString resume_analyse() const;

    // Documents produits par le projet. Chemin vide = boîte de dialogue.
    bool exporter_nomenclature(const QString& chemin = {});
    bool exporter_regles(const QString& chemin = {});
    bool exporter_netlist_kicad(const QString& chemin = {});
    bool exporter_courbes(const QString& chemin = {});
    bool exporter_schema(const QString& chemin = {});

    // En vérification automatique, aucune boîte de dialogue ne doit bloquer.
    void definir_mode_silencieux(bool silencieux) { silencieux_ = silencieux; }

    // Choisit l'onglet du bas (programme, journal, série, oscilloscope).
    void afficher_onglet(int rang);

    // Base de temps de l'oscilloscope, en secondes (vérification).
    void definir_base_temps(double secondes);

    // Entrée/sortie séparées des boîtes de dialogue : la lecture et
    // l'écriture d'un projet sont ainsi vérifiables sans interface.
    bool enregistrer_vers(const QString& chemin);
    bool ouvrir_depuis(const QString& chemin);

    SceneSchema* scene() const { return scene_; }
    VueSchema* vue() const { return vue_; }

    // Détache un panneau de mesure dans sa propre fenêtre, ou le remet dans
    // les onglets s'il en sort déjà. C'est l'utilisateur qui décide, par le
    // menu « Fenêtres » : rien ne s'ouvre tout seul.
    void basculer_fenetre(QWidget* panneau);
    Oscilloscope* oscilloscope() const { return oscilloscope_; }
    PanneauAnalyses* analyses() const { return analyses_; }
    PanneauPcb* pcb() const { return pcb_; }
    // Transfère le schéma vers la carte et bascule sur la page « circuit
    // imprimé ». C'est l'équivalent du « Update PCB from Schematic » de
    // KiCad ou du « Netlist to ARES » de Proteus : une étape demandée, pas un
    // effet de bord de la saisie.
    void ouvrir_pcb();
    // Bascule entre les deux pages : 0 le schéma, 1 le circuit imprimé.
    void afficher_page(int page);
    int page_courante() const;

    // Fenêtre de mesure d'un instrument (voltmètre, ampèremètre, sonde).
    void ouvrir_fenetre_instrument(ItemComposant* composant);

protected:
    void showEvent(QShowEvent* evenement) override;
    bool eventFilter(QObject* objet, QEvent* evenement) override;

private slots:
    void nouveau_projet();
    void ouvrir_projet();
    void enregistrer_projet();
    void exporter_netlist_spice();

    void ouvrir_firmware();
    void ouvrir_source_c();
    void compiler_source();

    void lancer();
    void suspendre();
    void arreter();
    void analyser_point_repos();

    void afficher_proprietes(ItemComposant* composant);
    void circuit_modifie();
    void changer_carte(const QString& reference);

private:
    // Aligne le sélecteur sur les cartes du schéma et garantit que
    // `carte_courante_` désigne toujours une carte existante.
    void synchroniser_cartes(const QStringList& cartes);

    SceneSchema* scene_ = nullptr;
    VueSchema* vue_ = nullptr;
    MoteurSimulation* moteur_ = nullptr;

    PaletteComposants* palette_ = nullptr;
    QWidget* panneau_proprietes_ = nullptr;
    QFormLayout* formulaire_ = nullptr;
    QPlainTextEdit* editeur_source_ = nullptr;
    QPlainTextEdit* console_ = nullptr;
    QPlainTextEdit* moniteur_serie_ = nullptr;
    Oscilloscope* oscilloscope_ = nullptr;
    PanneauAnalyses* analyses_ = nullptr;
    PanneauPcb* pcb_ = nullptr;
    // Dernière trame calculée : c'est sur elle que porte le spectre et les
    // mesures, comme un oscilloscope analyse ce qu'il vient d'acquérir.
    coeur::Formes dernieres_formes_;
    QTabWidget* onglets_ = nullptr;
    // Les deux pages de l'application : saisie du schéma, puis carte. Les
    // outils du schéma (palette, propriétés, onglets du bas) n'ont rien à
    // faire sur la carte, et disparaissent avec elle.
    QStackedWidget* pages_ = nullptr;
    QToolBar* barre_schema_ = nullptr;
    QAction* action_page_schema_ = nullptr;
    QAction* action_page_pcb_ = nullptr;
    std::vector<QDockWidget*> docks_schema_;
    bool carte_transferee_ = false;
    // Panneaux sortis dans leur propre fenêtre : titre et rang d'origine,
    // pour savoir où les remettre à la fermeture.
    struct PanneauDetache { QString titre; int rang = 0; };
    std::map<QWidget*, PanneauDetache> detaches_;
    std::vector<FenetreInstrument*> fenetres_instruments_;
    QComboBox* selecteur_carte_ = nullptr;
    // Programme de chaque carte : deux Arduino n'exécutent pas le même.
    std::map<QString, QString> programmes_;
    QString carte_courante_;
    QLabel* etiquette_temps_ = nullptr;
    QLabel* etiquette_vitesse_ = nullptr;
    QLabel* etiquette_moteurs_ = nullptr;
    QLabel* etiquette_etat_ = nullptr;

    QAction* action_annuler_ = nullptr;
    QAction* action_retablir_ = nullptr;
    QAction* action_marche_ = nullptr;    // lance, met en pause, reprend
    QAction* action_arreter_ = nullptr;

    ItemComposant* selection_ = nullptr;
    QString chemin_projet_;
    bool silencieux_ = false;
    bool premier_affichage_ = true;

    // Avertissement : boîte de dialogue en usage normal, journal en mode
    // silencieux.
    void avertir(const QString& titre, const QString& message);

    void construire_palette();
    void construire_docks();
    void construire_actions();
    void construire_barre_etat();
    // Aligne les commandes et la barre d'état sur l'état de la simulation :
    // un bouton doit toujours annoncer ce qu'il va faire.
    void refleter_etat();

    // Menu du clic droit, construit ici : la scène ne connaît pas les
    // actions de l'application.
    void menu_contextuel(ItemComposant* composant, const QPoint& ecran);

    // Nœud attaqué par le générateur : référence des gains et des campagnes.
    QString noeud_generateur() const;

    void ecrire(const QString& message);
    QString dossier_travail() const;
};
