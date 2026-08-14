// Fenêtre principale de l'application.
//
// Disposition volontairement proche des ateliers de CAO électronique :
// palette de composants à gauche, schéma au centre, propriétés à droite,
// journal et console série en bas.
#pragma once

#include "core/engines/Microcontroleur.h"

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
class QTextDocument;
class QLineEdit;
class QTabBar;
class QStackedWidget;
class QDockWidget;
class QToolBar;

class ItemComposant;
#include "app/schematic/SceneSchema.h"
#include "app/MoteurSimulation.h"
class VueSchema;
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
    // Onglet du bas affiché, et son intitulé : la vérification automatique
    // doit pouvoir constater qu'un double-clic sur une carte a bien amené le
    // programme sous les yeux.
    int onglet_courant() const;
    QString titre_onglet_courant() const;
    // Programme actuellement à l'écran, et carte à qui il appartient.
    QString programme_affiche() const;
    QString carte_affichee() const { return carte_courante_; }

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
    // Pivoter et supprimer suivent la page affichée, pas le schéma par défaut.
    // Vrai quand le curseur est dans un champ de saisie : les commandes de
    // schéma portées par un « Ctrl+lettre » doivent alors s'effacer.
    bool saisie_en_cours() const;
    void pivoter_sur_page_active();
    void supprimer_sur_page_active();
    int page_courante() const;

    // Arrêt de la simulation, accessible au mode de vérification « --gestes ».
    void arreter_simulation() { arreter(); }
    // Lancement et état, pour la vérification automatique : c'est ce qui
    // permet de constater qu'un programme faux n'a PAS démarré.
    void lancer_simulation() { lancer(); }
    MoteurSimulation::Etat etat_simulation() const;
    // Remplace le programme de la carte affichée. Sert aux essais.
    void definir_programme_affiche(const QString& source);

    // Fenêtre de mesure d'un instrument (voltmètre, ampèremètre, sonde).
    void ouvrir_fenetre_instrument(ItemComposant* composant);
    // Amène le programme de cette carte sous les yeux : onglet « Programme »,
    // carte sélectionnée, curseur dans l'éditeur.
    void ouvrir_programme(ItemComposant* carte);

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
    // Compile le programme de la carte courante ; rend faux en cas d'échec.
    bool compiler_programme(bool silence_si_reussi = false);
    // Émet le contenu du champ de saisie sur la liaison série de la carte.
    void envoyer_serie();
    // Pense-bête des raccourcis, engendré depuis les QAction des menus.
    void montrer_raccourcis();
    // Le document de ce fichier de cette carte, créé au besoin. Un document
    // par fichier : c'est lui qui porte la pile d'annulation.
    QTextDocument* document_de(const QString& carte, int rang);

    void lancer();
    void suspendre();
    void arreter();
    void analyser_point_repos();

    void afficher_proprietes(ItemComposant* composant);
    void circuit_modifie();
    void changer_carte(const QString& reference);
    // Le programme d'exemple de cette carte : celui de son contrôleur.
    QString programme_par_defaut(const QString& reference) const;
    void refleter_langage(const QString& reference);

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
    QLineEdit* saisie_serie_ = nullptr;
    QLineEdit* recherche_palette_ = nullptr;
    QDockWidget* dock_palette_ = nullptr;
    QComboBox* fin_ligne_serie_ = nullptr;
    // Un QTextDocument par « carte/rang », pour que l'annulation et la
    // position du curseur survivent au changement d'onglet ou de carte.
    std::map<QString, QTextDocument*> documents_;
    std::map<QString, int> curseurs_;
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
    // Tailles des panneaux du schéma, mises de côté le temps d'aller sur la
    // carte : sans elles, la palette revient rétrécie.
    std::vector<int> tailles_docks_;
    bool carte_transferee_ = false;
    // Panneaux sortis dans leur propre fenêtre : titre et rang d'origine,
    // pour savoir où les remettre à la fermeture.
    struct PanneauDetache { QString titre; int rang = 0; };
    std::map<QWidget*, PanneauDetache> detaches_;
    std::vector<FenetreInstrument*> fenetres_instruments_;
    QComboBox* selecteur_carte_ = nullptr;
    // Programme de chaque carte : deux Arduino n'exécutent pas le même.
    // Un programme par carte, et un programme est une liste de fichiers dont
    // le premier est le principal. L'onglet affiché est `fichier_courant_`.
    std::map<QString, coeur::Programme> programmes_;
    int fichier_courant_ = 0;
    // Dernière note de langage écrite au journal : ne pas la répéter à chaque
    // recensement des cartes, qui a lieu à chaque modification du schéma.
    QString derniere_note_langage_;
    QTabBar* onglets_fichiers_ = nullptr;

    // Le programme de cette carte, créé avec son exemple s'il n'existe pas.
    coeur::Programme& programme_de(const QString& carte);
    // Range le texte affiché dans le fichier auquel il appartient. À appeler
    // avant tout ce qui lit `programmes_` — sinon la dernière frappe est
    // perdue.
    void ranger_editeur();
    void afficher_fichier(int rang);
    void rafraichir_onglets_fichiers();
    void ajouter_fichier();
    void retirer_fichier(int rang);
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
    // Repli des lignes de journal identiques : la dernière écrite, et le
    // nombre de fois qu'elle l'a été d'affilée.
    QString derniere_ligne_;
    int repetitions_ = 0;

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
    // Change d'outil et synchronise la barre du haut.
    void choisir_outil(SceneSchema::Outil outil);
    QAction* action_selection_ = nullptr;
    QAction* action_gomme_ = nullptr;
    void menu_contextuel(ItemComposant* composant, const QPoint& ecran);

    // Nœud attaqué par le générateur : référence des gains et des campagnes.
    QString noeud_generateur() const;

    void ecrire(const QString& message);
    QString dossier_travail() const;
};
