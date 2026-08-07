// Fenêtre principale de l'application.
//
// Disposition volontairement proche des ateliers de CAO électronique :
// palette de composants à gauche, schéma au centre, propriétés à droite,
// journal et console série en bas.
#pragma once

#include <QMainWindow>
#include <QTreeWidget>

#include <QString>

class QAction;
class QLabel;
class QPlainTextEdit;
class QFormLayout;
class QWidget;

class ItemComposant;
class SceneSchema;
class VueSchema;
class MoteurSimulation;

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
    enum class Exemple { Clignotant, BoutonLed, PotentiometreLed, Transistor };
    void charger_exemple(Exemple exemple);
    void charger_exemple_clignotant() { charger_exemple(Exemple::Clignotant); }

    // Compile le programme affiché puis démarre la simulation. Sert au mode
    // de vérification automatique (« --capture »).
    void demarrage_automatique();

    // Compte rendu textuel de l'état : netlist, broches, source SPICE et
    // résultats. Sert au mode « --diagnostic » et au signalement d'anomalie.
    QString diagnostic();

    // En vérification automatique, aucune boîte de dialogue ne doit bloquer.
    void definir_mode_silencieux(bool silencieux) { silencieux_ = silencieux; }

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

private:
    SceneSchema* scene_ = nullptr;
    VueSchema* vue_ = nullptr;
    MoteurSimulation* moteur_ = nullptr;

    PaletteComposants* palette_ = nullptr;
    QWidget* panneau_proprietes_ = nullptr;
    QFormLayout* formulaire_ = nullptr;
    QPlainTextEdit* editeur_source_ = nullptr;
    QPlainTextEdit* console_ = nullptr;
    QPlainTextEdit* moniteur_serie_ = nullptr;
    QLabel* etiquette_temps_ = nullptr;
    QLabel* etiquette_vitesse_ = nullptr;
    QLabel* etiquette_moteurs_ = nullptr;

    QAction* action_lancer_ = nullptr;
    QAction* action_pause_ = nullptr;
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

    void ecrire(const QString& message);
    QString dossier_travail() const;
};
