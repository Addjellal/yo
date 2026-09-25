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
#include <QPointF>
#include <QRectF>
#include <QVector>
#include <QString>
#include <QStringList>

#include "Moteur.h"

class QAction;
class QComboBox;
class QLabel;
class QLineEdit;
class QListWidget;
class QDockWidget;
class QPushButton;
class QTreeWidget;
class QTreeWidgetItem;
class ToileSimulink;

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
    QComboBox* choixSolveur() const { return solveur_; }
    QLineEdit* champDuree() const { return duree_; }
    QAction* actionConfiguration() const { return aConfiguration_; }
    QAction* actionSousMasque() const { return aSousMasque_; }
    QTreeWidget* explorateur() const { return explorateur_; }
    ToileSimulink* toile() const { return toile_; }
    QLabel* description() const { return description_; }
    QString modeleChoisi() const;
    QString modeleAffiche() const { return affiche_; }
    // Le chemin ouvert dans le modèle : vide en surface, « boite » ou
    // « boite/interne » quand on est descendu dans un sous-système.
    QString cheminOuvert() const { return chemin_; }
    const SchemaSimulink& schemaAffiche() const { return dernier_; }
    // Le modèle et le chemin réunis, tels que le moteur les attend.
    QString ancreAffichee() const;
    // Remonter d'un cran dans les sous-systèmes ouverts.
    void remonter();
    // La ligne qu'insérerait « Insérer », pour le bloc choisi.
    QString ligneInsertion() const;
    // Le squelette d'un modèle neuf, tel que « Nouveau modèle » l'écrit.
    static QString squeletteModele();

    // Les trois chemins, sans boite de dialogue : c'est par la que le
    // test passe, et les boutons ne font que leur choisir un fichier.
    void enregistrerVers(const QString& chemin);
    void genererVers(const QString& chemin);
    void ouvrirDepuis(const QString& chemin);

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
    void genererProgramme();
    void ouvrirModele();
    void montrerBloc();
    void surModeleChoisi();
    // Les gestes de la toile, traduits en commandes sur le modele.
    void surBlocsDeplaces(const QStringList& noms, const QVector<QRectF>& places);
    void surLienDemande(const QString& source, const QString& cible, int port, int sortie);
    void surBlocsSupprimes(const QStringList& noms);
    void surAnnulation();
    void surRetablissement();
    void surLienSupprime(const QString& source, const QString& cible, int port, int sortie);
    void surBlocOuvert(const QString& nom);
    void surRemontee();
    void surBlocDepose(const QPointF& place);
    void ajusterVue();
    // Ctrl+E : les paramètres de configuration du modèle.
    void ouvrirConfiguration();
    void regarderSousMasque();
    // Le solveur choisi dans la barre se pose sur le modèle, comme dans
    // la boîte de configuration.
    void surSolveurChoisi(int rang);
    void surDureeChangee();


private:
    void construireBibliotheque();
    // Toute modification part par ici : une seule ligne, precedee de la
    // mise en reserve de l etat courant pour Ctrl+Z.
    void envoyerModification(const QString& corps, const QString& annonce);
    // La variable sur laquelle les gestes travaillent : le modèle
    // lui-même en surface, une variable de passage dans un sous-système.
    QString cibleModele() const;
    // Le fil d'Ariane, et le bouton qui remonte.
    void majChemin();
    void construireBarre();
    void ajusterBoutons();
    void poserEtat(const QString& texte);

    QTreeWidget* bibliotheque_;
    QListWidget* modeles_;
    QTreeWidget* explorateur_;
    ToileSimulink* toile_;
    QLabel* description_;
    QLabel* etatModeles_;
    QLabel* titreToile_;
    QLineEdit* duree_;
    // Le solveur du modèle : la liste suit son réglage Solver, et le
    // changer le pose sur le modèle.
    QComboBox* solveur_ = nullptr;
    // Vrai pendant que la fenêtre met la liste et la durée à jour d'après
    // le modèle : ce n'est pas un choix de l'utilisateur, rien ne part.
    bool majReglages_ = false;
    QAction* aConfiguration_ = nullptr;
    QAction* aSousMasque_ = nullptr;
    QDockWidget* dockBibliotheque_;
    QPushButton* bInserer_;
    QAction* aOuvrir_ = nullptr;
    QAction* aSimuler_ = nullptr;
    QAction* aEnregistrer_ = nullptr;
    QAction* aProgramme_ = nullptr;
    QAction* aRemonter_ = nullptr;
    // Le chemin des sous-systèmes ouverts, « boite/interne ». Vide en
    // surface.
    QString chemin_;
    // Le modèle dont la toile porte le schéma. Sert à savoir s'il faut le
    // redemander quand l'espace de travail change.
    QString affiche_;
    // Le dernier schema recu : c'est la qu'on retrouve les reglages d'un
    // bloc quand on double-clique dessus.
    SchemaSimulink dernier_;
    // Le compte des blocs posés depuis la bibliothèque : de quoi donner
    // un nom neuf à chacun sans écraser le précédent.
    int poses_ = 0;
};
