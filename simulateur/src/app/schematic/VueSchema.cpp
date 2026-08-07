#include "app/schematic/VueSchema.h"

#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMimeData>
#include <QWheelEvent>

VueSchema::VueSchema(QWidget* parent) : QGraphicsView(parent) {
    setRenderHints(QPainter::Antialiasing | QPainter::TextAntialiasing);
    setDragMode(QGraphicsView::RubberBandDrag);
    setTransformationAnchor(QGraphicsView::AnchorUnderMouse);
    setViewportUpdateMode(QGraphicsView::SmartViewportUpdate);
    setAcceptDrops(true);
}

void VueSchema::zoomer(double facteur) {
    const double echelle = transform().m11() * facteur;
    if (echelle < 0.15 || echelle > 8.0) return;
    scale(facteur, facteur);
}

void VueSchema::ajuster() {
    if (!scene()) return;
    const QRectF contenu = scene()->itemsBoundingRect();
    if (contenu.isEmpty()) {
        resetTransform();
        centerOn(0, 0);
        return;
    }
    fitInView(contenu.adjusted(-40, -40, 40, 40), Qt::KeepAspectRatio);
}

void VueSchema::wheelEvent(QWheelEvent* evenement) {
    if (evenement->modifiers() & Qt::ControlModifier) {
        QGraphicsView::wheelEvent(evenement);
        return;
    }
    zoomer(evenement->angleDelta().y() > 0 ? 1.15 : 1.0 / 1.15);
    evenement->accept();
}

void VueSchema::dragEnterEvent(QDragEnterEvent* evenement) {
    if (evenement->mimeData()->hasFormat("application/x-composant"))
        evenement->acceptProposedAction();
}

void VueSchema::dragMoveEvent(QDragMoveEvent* evenement) {
    if (evenement->mimeData()->hasFormat("application/x-composant"))
        evenement->acceptProposedAction();
}

void VueSchema::dropEvent(QDropEvent* evenement) {
    const QMimeData* donnees = evenement->mimeData();
    if (!donnees->hasFormat("application/x-composant")) return;
    const QString type =
        QString::fromUtf8(donnees->data("application/x-composant"));
    emit composant_depose(type, mapToScene(evenement->position().toPoint()));
    evenement->acceptProposedAction();
}
