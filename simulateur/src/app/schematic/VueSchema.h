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

protected:
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
};
