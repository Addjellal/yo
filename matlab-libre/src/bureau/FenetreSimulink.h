// FenetreSimulink.h — l'éditeur Simulink, dans sa propre fenêtre.
//
// MATLAB n'ouvre pas Simulink dans un panneau du bureau : c'est une
// fenêtre entière, avec sa barre d'outils, la bibliothèque de blocs sur
// le côté et le schéma au milieu — le bureau MATLAB, lui, reste où il
// est. C'est ce qu'on reproduit, avec la différence qui compte : un
// modèle MatLibre est une valeur de l'espace de travail, non un fichier
// binaire. La fenêtre liste donc les modèles que l'espace de travail
// porte, et la bibliothèque écrit dans l'éditeur la ligne qui pose le
// bloc.
//
// L'espace de travail est le même des deux côtés : un gain réglé sur « K »
// vaut ce que vaut K, et un bloc « vers l'espace de travail » y dépose son
// signal. La fenêtre ne fait donc que piloter des commandes ; il n'y a pas
// deux états à tenir d'accord. Le schéma se redessine à chaque changement
// du modèle, y compris quand il vient de la console.
#pragma once

#include <QMainWindow>
#include <QString>
#include <QStringList>

#include "Moteur.h"

class QAction;
class QLabel;
class QLineEdit;
class QListWidget;
class QDockWidget;
class QPushButton;
class QTreeWidget;
class QTreeWidgetItem;
class VueFigure;

// Un bloc de la bibliothèque : sa famille, son type, ce qu'il fait, et
// les paramètres qu'ADD_BLOCK lui reconnaît.
struct BlocBibliotheque {
    const char* famille;
    const char* type;
    const char* resume;
    const char* parametres;   // « Nom, VALEUR » prêts pour ADD_BLOCK
};

// La bibliothèque entière, terminée par une entrée à famille nulle. Elle
// est publique pour que le test la parcoure sans ouvrir de fenêtre.
const BlocBibliotheque* bibliothequeSimulink();

class FenetreSimulink : public QMainWindow {
    Q_OBJECT
public:
    explicit FenetreSimulink(QWidget* parent = nullptr);

    // La liste des modèles que porte l'espace de travail. Le moteur la
    // publie après chaque commande ; la fenêtre garde la sélection quand
    // le nom choisi y est encore, et redemande son schéma.
    void definirModeles(const QStringList& noms);
    // Le schéma relevé par le moteur : la toile, et l'inventaire du modèle.
    void definirSchema(const SchemaSimulink& schema);

    // Publiés pour que la fenêtre se vérifie sans être montrée.
    QTreeWidget* bibliotheque() const { return bibliotheque_; }
    QListWidget* listeModeles() const { return modeles_; }
    QTreeWidget* explorateur() const { return explorateur_; }
    VueFigure* toile() const { return toile_; }
    QLabel* description() const { return description_; }
    QString modeleChoisi() const;
    QString modeleAffiche() const { return affiche_; }
    // La ligne qu'insérerait « Insérer », pour le bloc choisi.
    QString ligneInsertion() const;
    // Le squelette d'un modèle neuf, tel que « Nouveau modèle » l'écrit.
    static QString squeletteModele();

signals:
    // Une commande à exécuter dans la console.
    void commandeDemandee(const QString& commande);
    // Une ligne à insérer dans l'éditeur, ou à défaut dans la console.
    void insertionDemandee(const QString& ligne);
    // Un modèle neuf à ouvrir dans un onglet d'éditeur.
    void nouveauModeleDemande(const QString& squelette);
    // Le schéma d'un modèle : c'est le moteur qui le trace.
    void schemaDemande(const QString& nom);

private slots:
    void ouvrirSchema();
    void simuler();
    void insererBloc();
    void nouveauModele();
    void enregistrerModele();
    void montrerBloc();
    void surModeleChoisi();

protected:
    // La zone de dessin prévient de ses changements de taille : c'est elle
    // qui commande le placement de la toile, non la fenêtre — dont le
    // redimensionnement précède la mise en page de ses enfants.
    bool eventFilter(QObject* objet, QEvent* evenement) override;

private:
    void construireBibliotheque();
    // Donne à la toile les proportions du schéma : sans cela « axis equal »
    // ajuste l'échelle au côté le plus contraint et laisse le reste en
    // blanc — un schéma en long se retrouvait en bandeau au milieu.
    void ajusterToile();
    void construireBarre();
    void ajusterBoutons();
    void poserEtat(const QString& texte);

    QTreeWidget* bibliotheque_;
    QListWidget* modeles_;
    QTreeWidget* explorateur_;
    VueFigure* toile_;
    QLabel* description_;
    QLabel* etatModeles_;
    QLabel* titreToile_;
    QWidget* zoneToile_;
    QLineEdit* duree_;
    QDockWidget* dockBibliotheque_;
    QPushButton* bInserer_;
    QAction* aOuvrir_ = nullptr;
    QAction* aSimuler_ = nullptr;
    QAction* aEnregistrer_ = nullptr;
    // Le modèle dont la toile porte le schéma. Sert à savoir s'il faut le
    // redemander quand l'espace de travail change.
    QString affiche_;
    // Largeur sur hauteur du schéma affiché, telle qu'OPEN_SYSTEM l'a
    // voulue. Zéro tant qu'aucun schéma n'est peint.
    double aspect_ = 0.0;
};
