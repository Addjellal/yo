// Ruban.h — le bandeau d'outils de MATLAB.
//
// MATLAB n'a pas une barre d'outils mais un ruban : des onglets
// (ACCUEIL, TRACÉS, APPS), et dans chacun des groupes nommés dont les
// boutons portent leur libellé sous une icône. C'est ce qui donne au
// bureau sa silhouette reconnaissable, et c'est ce qu'on reproduit ici.
//
// Les icônes sont dessinées, pas chargées : aucune ressource à installer,
// et elles suivent la taille du texte.
#pragma once

#include <QIcon>
#include <QString>
#include <QTabWidget>
#include <QWidget>

class QHBoxLayout;
class QToolButton;

// Un groupe du ruban : des boutons côte à côte, un titre discret dessous.
class GroupeRuban : public QWidget {
    Q_OBJECT
public:
    GroupeRuban(const QString& titre, QWidget* parent = nullptr);

    QToolButton* ajouter(const QString& libelle, const QString& dessin,
                         const QString& infobulle = QString());
    void ajouterSeparateur();

private:
    QHBoxLayout* boutons_;
};

class Ruban : public QTabWidget {
    Q_OBJECT
public:
    explicit Ruban(QWidget* parent = nullptr);

    // Rend la bande d'un onglet, où déposer les groupes.
    QWidget* pageOnglet(const QString& nom);
    void ajouterGroupe(const QString& onglet, GroupeRuban* groupe);
};

// Dessine une icône simple à partir d'un nom symbolique : « nouveau »,
// « ouvrir », « enregistrer », « executer »… Rien n'est lu sur le disque.
QIcon iconeDessinee(const QString& nom, int taille = 28);
