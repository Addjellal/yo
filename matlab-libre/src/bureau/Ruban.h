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
#include <QMap>
#include <QString>
#include <QVector>
#include <QTabWidget>
#include <QWidget>

class QHBoxLayout;
class QToolButton;

// Un groupe du ruban : des boutons côte à côte, un titre discret dessous.
//
// Quand la fenêtre devient trop étroite, MATLAB ne rogne pas les libellés :
// il replie le groupe en un seul bouton qui ouvre la liste de ses
// commandes. C'est ce que fait « definirCompact ».
class GroupeRuban : public QWidget {
    Q_OBJECT
public:
    GroupeRuban(const QString& titre, QWidget* parent = nullptr);

    QToolButton* ajouter(const QString& libelle, const QString& dessin,
                         const QString& infobulle = QString());
    void ajouterSeparateur();

    // Replié ou déployé. Le ruban en décide selon la place disponible.
    void definirCompact(bool compact);
    bool compact() const { return compact_; }
    // Les deux largeurs, mesurées sans dépendre de l'état courant : sans
    // cela, replier un groupe changerait la mesure du suivant.
    int largeurDeployee() const;
    int largeurCompacte() const;

private:
    QString titre_;
    QHBoxLayout* boutons_;
    QWidget* rangee_;
    QToolButton* replie_ = nullptr;
    QVector<QToolButton*> liste_;
    bool compact_ = false;
};

class Ruban : public QTabWidget {
    Q_OBJECT
public:
    explicit Ruban(QWidget* parent = nullptr);

    // Rend la bande d'un onglet, où déposer les groupes.
    QWidget* pageOnglet(const QString& nom);
    void ajouterGroupe(const QString& onglet, GroupeRuban* groupe);

    // Replie ce qu'il faut pour que rien ne soit rogné. Appelé au
    // redimensionnement ; public pour qu'un test puisse le provoquer.
    void ajusterGroupes();

protected:
    void resizeEvent(QResizeEvent* evenement) override;

private:
    QMap<QString, QVector<GroupeRuban*>> groupes_;
    bool enAjustement_ = false;
};

// Dessine une icône simple à partir d'un nom symbolique : « nouveau »,
// « ouvrir », « enregistrer », « executer »… Rien n'est lu sur le disque.
QIcon iconeDessinee(const QString& nom, int taille = 28);
