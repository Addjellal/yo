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
    // Le bloc choisi, ou le premier d'entre eux quand il y en a plusieurs.
    QString blocChoisi() const;
    // Tous les blocs choisis, dans l'ordre du modèle.
    QStringList blocsChoisis() const;
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
    // Des blocs ont été déplacés : leurs nouvelles places, en unités du
    // schéma. Plusieurs à la fois quand plusieurs sont choisis.
    void blocsDeplaces(const QStringList& noms, const QVector<QRectF>& places);
    // Un fil a été tiré d'une sortie vers une entrée. SORTIE est le port
    // de sortie de la source : un Demux en a plusieurs.
    void lienDemande(const QString& source, const QString& cible, int port, int sortie);
    // « Suppr » sur ce qui est choisi.
    void blocsSupprimes(const QStringList& noms);
    void lienSupprime(const QString& source, const QString& cible, int port, int sortie);
    // Un double-clic : on veut régler le bloc.
    void blocOuvert(const QString& nom);
    // Quelque chose a été lâché sur la toile depuis la bibliothèque.
    void blocDepose(const QPointF& place);
    // Ctrl+Z, Ctrl+Y : défaire et refaire.
    void annulationDemandee();
    void retablissementDemande();
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
        int entrees = -1, sorties = 1;   // -1 : le type en décide
        QRectF cadre;   // en unités du schéma, l'ordonnée vers le bas
    };
    struct LienToile {
        int source = 0, cible = 0, port = 1, sortie = 1;
        bool retour = false;
    };

    QPointF versEcran(const QPointF& point) const;
    QPointF versSchema(const QPointF& point) const;
    QRectF cadreEcran(const QRectF& cadre) const;
    int blocSous(const QPointF& ecran) const;
    int lienSous(const QPointF& ecran) const;
    int portVise(int bloc, const QPointF& ecran) const;
    int sortieVisee(int bloc, const QPointF& ecran) const;
    int entreesDe(int bloc) const;
    QPointF pointEntree(int bloc, int port) const;
    QPointF pointSortie(int bloc, int sortie = 1) const;
    void dessinerBloc(QPainter& peintre, const BlocToile& bloc, bool choisi) const;
    void dessinerFil(QPainter& peintre, const LienToile& lien, double basRetour) const;
    void annoncerChoix();

    QString modele_;
    QVector<BlocToile> blocs_;
    QVector<LienToile> liens_;
    double hauteurType_ = 1.0;

    double echelle_ = 40.0;
    QPointF origine_{0.0, 0.0};   // le point du schéma peint en haut à gauche

    QVector<int> choisis_;    // les blocs choisis, rangs dans blocs_
    int lienChoisi_ = -1;     // lien choisi
    int saisi_ = -1;          // bloc par lequel on tient le lot
    QPointF saisiDepart_;     // là où la souris a pris le bloc, en schéma
    QVector<QRectF> saisiCadres_;   // les cadres au moment de la prise
    // Le rectangle d'élastique, quand on trace une sélection sur le vide.
    bool elastique_ = false;
    QPointF elastiqueDe_, elastiqueA_;
    int filDepuis_ = -1;      // bloc d'où part le fil en cours
    int filSortie_ = 1;       // et le port de sortie qu'on y a pris
    QPointF filVers_;         // le bout libre du fil, à l'écran
    bool deplacementFait_ = false;
};
