// Fenêtre principale de l'application.
//
// Disposition volontairement proche des ateliers de CAO électronique :
// palette de composants à gauche, schéma au centre, propriétés à droite,
// journal et console série en bas.
#pragma once

#include <QMainWindow>
#include <QTreeWidget>

#include <QString>

#include <map>

#include "core/engines/NgspiceEngine.h"

class QAction;
class QLabel;
class QPlainTextEdit;
class QFormLayout;
class QWidget;
class QTabWidget;
class QComboBox;

class ItemComposant;
class SceneSchema;
class VueSchema;
class MoteurSimulation;
class Oscilloscope;
class PanneauAnalyses;

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
                         Pwm, DeuxCartes, Servo, MoteurPuissance, FiltreRC };
    void charger_exemple(Exemple exemple);
    void charger_exemple_deux_cartes();
    // Montage purement analogique : c'est celui sur lequel les analyses
    // paramétriques prennent tout leur sens (Bode, balayage, spectre).
    void charger_exemple_filtre();
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

protected:
    void showEvent(QShowEvent* evenement) override;

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
    // Dernière trame calculée : c'est sur elle que porte le spectre et les
    // mesures, comme un oscilloscope analyse ce qu'il vient d'acquérir.
    coeur::Formes dernieres_formes_;
    QTabWidget* onglets_ = nullptr;
    QComboBox* selecteur_carte_ = nullptr;
    // Programme de chaque carte : deux Arduino n'exécutent pas le même.
    std::map<QString, QString> programmes_;
    QString carte_courante_;
    QLabel* etiquette_temps_ = nullptr;
    QLabel* etiquette_vitesse_ = nullptr;
    QLabel* etiquette_moteurs_ = nullptr;
    QLabel* etiquette_etat_ = nullptr;

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

    void ecrire(const QString& message);
    QString dossier_travail() const;
};
