// Vue du schéma.
//
//   molette          parcourir de haut en bas
//   Maj + molette    parcourir de gauche à droite
//   Ctrl + molette   zoom, centré sous le pointeur
//   bouton du milieu faire glisser le schéma
//
// La molette parcourt au lieu de zoomer : dans un éditeur de schéma on se
// déplace bien plus souvent qu'on ne change d'échelle, et c'est la convention
// de Simulink comme de tout traitement de texte.
#pragma once

#include <QGraphicsView>

class VueSchema : public QGraphicsView {
    Q_OBJECT

public:
    explicit VueSchema(QWidget* parent = nullptr);

    void zoomer(double facteur);
    void ajuster();

    // L'ÎLOT DE COMMANDES, POSÉ SUR LA FEUILLE.
    //
    // Le zoom vivait dans la barre d'outils, tout en haut, à un mètre visuel
    // de l'endroit qu'on regarde en zoomant. Toutes les cartes et tous les
    // logiciels de dessin l'ont descendu SUR le dessin depuis quinze ans,
    // pour la même raison : la main et l'œil sont déjà là.
    //
    // Il flotte au-dessus de la vue, en bas à droite, et se repositionne
    // seul quand la fenêtre change de taille.
    void poser_ilot(QWidget* ilot);

protected:
    void resizeEvent(QResizeEvent* evenement) override;
    void wheelEvent(QWheelEvent* evenement) override;
    void mousePressEvent(QMouseEvent* evenement) override;
    void mouseMoveEvent(QMouseEvent* evenement) override;
    void mouseReleaseEvent(QMouseEvent* evenement) override;
    void dragEnterEvent(QDragEnterEvent* evenement) override;
    void dragMoveEvent(QDragMoveEvent* evenement) override;
    void dropEvent(QDropEvent* evenement) override;

signals:
    void composant_depose(const QString& type, const QPointF& position);

private:
    // Glissement du schéma au bouton du milieu.
    bool glissement_ = false;
    QPoint depart_glissement_;
    QWidget* ilot_ = nullptr;
    void replacer_ilot();
};
