// Panneau de circuit imprimé.
//
// La carte se construit depuis la netlist du schéma : mêmes composants,
// mêmes nets. On y place les empreintes à la souris, on tire les pistes d'une
// pastille à l'autre, on contrôle les règles, et on exporte les fichiers de
// fabrication.
//
// Le tracé reste manuel. Un auto-routeur donnerait un résultat qu'il faudrait
// de toute façon reprendre, et la valeur pédagogique du routage est
// justement dans le geste.
#pragma once

#include <QStringList>
#include <QWidget>

#include "core/Netlist.h"
#include "core/pcb/Pcb.h"

class QLabel;
class QComboBox;
class QDoubleSpinBox;

// Zone de dessin : contour, pastilles, chevelu, pistes.
class VuePcb : public QWidget {
    Q_OBJECT

public:
    explicit VuePcb(QWidget* parent = nullptr);

    void definir_carte(coeur::CartePcb carte);
    const coeur::CartePcb& carte() const { return carte_; }
    coeur::CartePcb& carte() { return carte_; }

    void definir_couche(int couche);
    void definir_largeur_piste(double millimetres) { largeur_piste_ = millimetres; }
    void effacer_pistes();
    // Retire la dernière piste tracée : le geste le plus fréquent après une
    // erreur de routage.
    void defaire_piste();

signals:
    void etat_change(const QString& resume);

protected:
    void paintEvent(QPaintEvent* evenement) override;
    void mousePressEvent(QMouseEvent* evenement) override;
    void mouseMoveEvent(QMouseEvent* evenement) override;
    void mouseReleaseEvent(QMouseEvent* evenement) override;

private:
    coeur::CartePcb carte_;
    int couche_ = 0;
    double largeur_piste_ = 0.4;

    // Placement en cours : composant saisi et écart au point de saisie.
    std::string composant_saisi_;
    QPointF ecart_saisie_;
    // Routage en cours : pastille de départ.
    bool routage_ = false;
    double depart_x_ = 0, depart_y_ = 0;
    std::string net_depart_;
    QPointF curseur_;

    double echelle() const;    // pixels par millimètre
    QPointF vers_ecran(double x, double y) const;
    QPointF vers_carte(const QPointF& ecran) const;
    // Pastille sous le curseur, ou nullptr.
    const coeur::PastillePosee* pastille_sous(const QPointF& carte_xy,
                                              std::vector<coeur::PastillePosee>&
                                                  toutes) const;
    void annoncer();
};

class PanneauPcb : public QWidget {
    Q_OBJECT

public:
    explicit PanneauPcb(QWidget* parent = nullptr);

    // Reconstruit la carte depuis une netlist. Le placement déjà fait est
    // conservé quand les composants n'ont pas changé.
    void construire_depuis(const coeur::Netlist& netlist);
    VuePcb* vue() const { return vue_; }

    // Compte rendu textuel : sert à la vérification automatique.
    QString resume() const;
    // Écriture des fichiers de fabrication sans boîte de dialogue.
    QStringList exporter_vers(const QString& base);

signals:
    void journal(const QString& message);

private:
    VuePcb* vue_ = nullptr;
    QLabel* etat_ = nullptr;
    QComboBox* couche_ = nullptr;
    QDoubleSpinBox* largeur_ = nullptr;

    void exporter();
};
