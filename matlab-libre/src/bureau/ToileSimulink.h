// ToileSimulink.h — la toile de l'éditeur : on y pose, déplace et câble.
//
// Simulink ne montre pas une image : il montre une feuille sur laquelle on
// travaille. Un bloc se prend et se déplace, un fil se tire d'une sortie
// vers une entrée, la touche « Suppr » enlève ce qui est choisi, et un
// double-clic ouvre les réglages. C'est ce que fait cette toile.
//
// Elle ne modifie rien elle-même. Chaque geste devient une commande sur le
// modèle — ADD_BLOCK, ADD_LINE, SET_PARAM, DELETE_BLOCK, DELETE_LINE — que
// la console exécute. L'espace de travail reste donc l'unique état : ce
// qu'on voit est ce que la variable porte, et une modification à la souris
// se relit au clavier.
//
// La géométrie vient de MATLIBRE_SL_GEOMETRIE, la même que celle dont
// OPEN_SYSTEM tire sa figure : la toile et la figure s'accordent.
#pragma once

#include <QPointF>
#include <QRectF>
#include <QVector>
#include <QWidget>

#include "Moteur.h"

class ToileSimulink : public QWidget {
    Q_OBJECT
public:
    explicit ToileSimulink(QWidget* parent = nullptr);

    void definirSchema(const SchemaSimulink& schema);
    void vider();
    const QString& modele() const { return modele_; }
    // Le bloc choisi, ou une chaîne vide. Publié pour la vérification.
    QString blocChoisi() const;
    int lienChoisi() const { return lienChoisi_; }
    // Le rectangle qu'occupe un bloc à l'écran, pour qu'un test puisse y
    // viser sans deviner.
    QRectF cadreEcranDe(const QString& nom) const;
    // Le nombre d'entrées qu'un type de bloc accepte : c'est ce qui
    // décide du port où un fil se raccroche.
    static int nombreEntrees(const QString& type, const QString& signes);

    void zoomer(double facteur);
    void ajusterVue();
    double echelle() const { return echelle_; }

signals:
    // Un bloc a été déplacé : sa nouvelle place, en unités du schéma.
    void blocDeplace(const QString& nom, const QRectF& place);
    // Un fil a été tiré d'une sortie vers une entrée.
    void lienDemande(const QString& source, const QString& cible, int port);
    // « Suppr » sur ce qui est choisi.
    void blocSupprime(const QString& nom);
    void lienSupprime(const QString& source, const QString& cible, int port);
    // Un double-clic : on veut régler le bloc.
    void blocOuvert(const QString& nom);
    // Quelque chose a été lâché sur la toile depuis la bibliothèque.
    void blocDepose(const QPointF& place);
    // De quoi renseigner la barre d'état.
    void etatChange(const QString& texte);
    void choixChange();

protected:
    void paintEvent(QPaintEvent* evenement) override;
    void mousePressEvent(QMouseEvent* evenement) override;
    void mouseMoveEvent(QMouseEvent* evenement) override;
    void mouseReleaseEvent(QMouseEvent* evenement) override;
    void mouseDoubleClickEvent(QMouseEvent* evenement) override;
    void keyPressEvent(QKeyEvent* evenement) override;
    void wheelEvent(QWheelEvent* evenement) override;
    void resizeEvent(QResizeEvent* evenement) override;
    void dragEnterEvent(QDragEnterEvent* evenement) override;
    void dropEvent(QDropEvent* evenement) override;

private:
    struct BlocToile {
        QString nom, type, etiquette, signes;
        QRectF cadre;   // en unités du schéma, l'ordonnée vers le bas
    };
    struct LienToile {
        int source = 0, cible = 0, port = 1;
        bool retour = false;
    };

    QPointF versEcran(const QPointF& point) const;
    QPointF versSchema(const QPointF& point) const;
    QRectF cadreEcran(const QRectF& cadre) const;
    int blocSous(const QPointF& ecran) const;
    int lienSous(const QPointF& ecran) const;
    int portVise(int bloc, const QPointF& ecran) const;
    QPointF pointEntree(int bloc, int port) const;
    QPointF pointSortie(int bloc) const;
    void dessinerBloc(QPainter& peintre, const BlocToile& bloc, bool choisi) const;
    void dessinerFil(QPainter& peintre, const LienToile& lien, double basRetour) const;
    void annoncerChoix();

    QString modele_;
    QVector<BlocToile> blocs_;
    QVector<LienToile> liens_;
    double hauteurType_ = 1.0;

    double echelle_ = 40.0;
    QPointF origine_{0.0, 0.0};   // le point du schéma peint en haut à gauche

    int choisi_ = -1;         // bloc choisi
    int lienChoisi_ = -1;     // lien choisi
    int saisi_ = -1;          // bloc en cours de déplacement
    QPointF saisiDepart_;     // là où la souris a pris le bloc, en schéma
    QRectF saisiCadre_;       // le cadre du bloc au moment de la prise
    int filDepuis_ = -1;      // bloc d'où part le fil en cours
    QPointF filVers_;         // le bout libre du fil, à l'écran
    bool deplacementFait_ = false;
};
