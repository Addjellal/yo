// FenetreSimulink.h — Simulink dans le bureau, comme MATLAB l'ouvre.
//
// MATLAB donne à Simulink un bouton dans le ruban et une fenêtre à lui :
// à gauche la bibliothèque de blocs, à droite les modèles ouverts. C'est
// ce qu'on fait ici, avec la différence qui compte : un modèle MatLibre
// est une valeur de l'espace de travail, non un fichier binaire. La
// fenêtre liste donc les modèles que l'espace de travail porte, et la
// bibliothèque écrit dans l'éditeur la ligne qui pose le bloc.
//
// L'espace de travail est le même des deux côtés : un gain réglé sur « K »
// vaut ce que vaut K, et un bloc « vers l'espace de travail » y dépose son
// signal. La fenêtre ne fait donc que piloter des commandes ; il n'y a pas
// deux états à tenir d'accord.
#pragma once

#include <QMainWindow>
#include <QString>
#include <QStringList>

class QLabel;
class QListWidget;
class QPushButton;
class QTreeWidget;
class QTreeWidgetItem;

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
    // le nom choisi y est encore.
    void definirModeles(const QStringList& noms);

    // Publiés pour que la fenêtre se vérifie sans être montrée.
    QTreeWidget* bibliotheque() const { return bibliotheque_; }
    QListWidget* listeModeles() const { return modeles_; }
    QLabel* description() const { return description_; }
    QString modeleChoisi() const;
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

private slots:
    void ouvrirSchema();
    void simuler();
    void insererBloc();
    void nouveauModele();
    void montrerBloc();

private:
    void construireBibliotheque();
    void ajusterBoutons();

    QTreeWidget* bibliotheque_;
    QListWidget* modeles_;
    QLabel* description_;
    QLabel* etatModeles_;
    QPushButton* bInserer_;
    QPushButton* bOuvrir_;
    QPushButton* bSimuler_;
};
