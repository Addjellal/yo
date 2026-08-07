// Vue du schéma : zoom à la molette, déplacement au bouton du milieu,
// dépôt d'un composant tiré depuis la palette.
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
    void dragEnterEvent(QDragEnterEvent* evenement) override;
    void dragMoveEvent(QDragMoveEvent* evenement) override;
    void dropEvent(QDropEvent* evenement) override;

signals:
    void composant_depose(const QString& type, const QPointF& position);
};
