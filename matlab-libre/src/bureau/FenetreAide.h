// FenetreAide.h — le navigateur de documentation, comme celui de MATLAB.
//
// MATLAB n'affiche pas « doc fft » dans la fenêtre de commandes : il ouvre
// un navigateur, avec la liste des fonctions à gauche, la page à droite,
// une barre de recherche, et des renvois cliquables vers les fonctions
// voisines. C'est ce qu'on fait ici, avec les fiches que l'interpréteur
// sait déjà découper.
#pragma once

#include <QMainWindow>
#include <QStringList>
#include <QVector>

#include "Moteur.h"

class QLineEdit;
class QListWidget;
class QTextBrowser;
class QLabel;
class QAction;

class FenetreAide : public QMainWindow {
    Q_OBJECT
public:
    explicit FenetreAide(QWidget* parent = nullptr);

    // Demande une page. Le contenu arrive par « poserFiche ».
    void afficher(const QString& nom);
    void poserFiche(const FicheAide& fiche);
    void poserIndex(const QVector<EntreeIndexAide>& entrees);

    // Publiés pour que la fenêtre se vérifie sans être montrée.
    QTextBrowser* page() const { return page_; }
    QListWidget* liste() const { return liste_; }
    QLineEdit* recherche() const { return recherche_; }
    QString nomCourant() const { return nomCourant_; }

signals:
    // La fenêtre ne parle pas au moteur : elle demande, la fenêtre
    // principale transmet.
    void pageDemandee(const QString& nom);

private slots:
    void filtrer(const QString& motif);
    void ouvrirDepuisListe();
    void reculer();
    void avancer();

private:
    void poserPageAccueil();
    void naviguerVers(const QString& nom, bool empiler);

    QLineEdit* recherche_;
    QListWidget* liste_;
    QTextBrowser* page_;
    QLabel* etat_;
    QAction* aReculer_ = nullptr;
    QAction* aAvancer_ = nullptr;
    QVector<EntreeIndexAide> index_;
    QStringList historique_;
    int positionHistorique_ = -1;
    QString nomCourant_;
};
