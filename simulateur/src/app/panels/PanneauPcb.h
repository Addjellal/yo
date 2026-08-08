// Page « circuit imprimé ».
//
// C'est une page à part entière, pas un onglet du bas — comme Pcbnew est une
// application distincte d'Eeschema chez KiCad, et ARES une fenêtre distincte
// d'ISIS chez Proteus. On n'y arrive pas par hasard : il faut demander
// explicitement le transfert du schéma vers la carte, et c'est ce transfert
// qui apporte les composants et les nets.
//
// Le câblage, lui, est entièrement refait ici : les fils du schéma disent
// seulement QUI doit être relié à QUI (le chevelu), les pistes disent COMMENT.
#pragma once

#include <QStringList>
#include <QWidget>

#include "core/Netlist.h"
#include "core/pcb/Pcb.h"

class QLabel;
class QComboBox;
class QDoubleSpinBox;
class QPlainTextEdit;
class QCheckBox;

// Zone de dessin : substrat, sérigraphie, pastilles, chevelu, pistes.
class VuePcb : public QWidget {
    Q_OBJECT

public:
    explicit VuePcb(QWidget* parent = nullptr);

    void definir_carte(coeur::CartePcb carte);
    const coeur::CartePcb& carte() const { return carte_; }
    coeur::CartePcb& carte() { return carte_; }

    void definir_couche(int couche);
    void definir_largeur_piste(double millimetres) { largeur_piste_ = millimetres; }
    void afficher_chevelu(bool actif);
    void effacer_pistes();
    // Retire la dernière piste tracée : le geste le plus fréquent après une
    // erreur de routage.
    void defaire_piste();
    void recadrer();
    // Fait tourner d'un quart de tour le composant sous le curseur.
    void tourner_sous_curseur();

signals:
    void etat_change(const QString& resume);
    void survol(const QString& description);

protected:
    void paintEvent(QPaintEvent* evenement) override;
    void mousePressEvent(QMouseEvent* evenement) override;
    void mouseMoveEvent(QMouseEvent* evenement) override;
    void mouseReleaseEvent(QMouseEvent* evenement) override;
    void wheelEvent(QWheelEvent* evenement) override;
    void keyPressEvent(QKeyEvent* evenement) override;
    void resizeEvent(QResizeEvent* evenement) override;

private:
    coeur::CartePcb carte_;
    int couche_ = 0;
    double largeur_piste_ = 0.4;
    bool chevelu_visible_ = true;

    // Cadrage : facteur de zoom sur l'échelle d'ajustement, et translation.
    double zoom_ = 1.0;
    QPointF decalage_{0, 0};
    bool glisse_vue_ = false;
    QPointF depart_glisse_;

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
    std::string composant_sous(const QPointF& carte_xy) const;
    void annoncer();
    void dessiner_substrat(QPainter& peintre) const;
    void dessiner_serigraphie(QPainter& peintre) const;
    void dessiner_pastilles(QPainter& peintre) const;
};

class PanneauPcb : public QWidget {
    Q_OBJECT

public:
    explicit PanneauPcb(QWidget* parent = nullptr);

    // Transfert du schéma vers la carte : ajoute les composants nouveaux,
    // retire ceux qui ont disparu, met les nets à jour. Le placement et les
    // pistes déjà faits sont conservés — c'est tout l'intérêt de refaire le
    // transfert plutôt que de repartir de zéro.
    // Renvoie le compte rendu, comme le fait « Update PCB from Schematic ».
    QString construire_depuis(const coeur::Netlist& netlist);
    VuePcb* vue() const { return vue_; }

    // Compte rendu textuel : sert à la vérification automatique.
    QString resume() const;
    void afficher_rapport(const QString& texte);
    // Dernier compte rendu affiché (transfert ou contrôle des règles).
    QString rapport() const;
    // Contrôle des règles de fabrication, et compte rendu dans la page.
    void controler();
    // Écriture des fichiers de fabrication sans boîte de dialogue.
    QStringList exporter_vers(const QString& base);

signals:
    void journal(const QString& message);
    void mise_a_jour_demandee();
    void retour_schema_demande();

private:
    VuePcb* vue_ = nullptr;
    QLabel* etat_ = nullptr;
    QLabel* survol_ = nullptr;
    QComboBox* couche_ = nullptr;
    QDoubleSpinBox* largeur_ = nullptr;
    QPlainTextEdit* rapport_ = nullptr;
    QCheckBox* chevelu_ = nullptr;

    void exporter();
};
