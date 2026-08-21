#include "app/schema/VueSchema.h"

#include <QDragEnterEvent>
#include <QDropEvent>
#include <QMimeData>
#include <QScrollBar>
#include <QWheelEvent>

VueSchema::VueSchema(QWidget* parent) : QGraphicsView(parent) {
    setRenderHints(QPainter::Antialiasing | QPainter::TextAntialiasing);
    setDragMode(QGraphicsView::RubberBandDrag);
    setTransformationAnchor(QGraphicsView::AnchorUnderMouse);
    // Rafraîchissement complet, et non « intelligent ». Le mode intelligent
    // ne repeint que ce qu'on lui déclare abîmé : la moindre imprécision dans
    // le cadre d'un objet — ou un fil dont le tracé change sans qu'on l'ait
    // annoncé assez tôt — laisse alors des traînées à l'écran quand on
    // déplace un composant. La scène compte quelques dizaines d'objets et se
    // repeint déjà entièrement à chaque image pendant la simulation : la
    // dépense est sans commune mesure avec la gêne.
    setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
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

// La molette DÉPLACE, elle ne zoome pas.
//
// C'est l'inverse de ce que faisait cette vue, et l'inverse se défend : dans
// un éditeur de schéma on parcourt bien plus souvent qu'on ne change
// d'échelle. C'est aussi la convention de Simulink, de Visio et de tout
// traitement de texte — la molette suit le document.
//
//   molette          : haut et bas
//   Maj + molette    : gauche et droite
//   Ctrl + molette   : zoom, centré sous le pointeur
void VueSchema::wheelEvent(QWheelEvent* evenement) {
    if (evenement->modifiers() & Qt::ControlModifier) {
        zoomer(evenement->angleDelta().y() > 0 ? 1.15 : 1.0 / 1.15);
        evenement->accept();
        return;
    }
    QGraphicsView::wheelEvent(evenement);
}

// Le bouton du milieu fait glisser le schéma, où qu'on l'attrape — y compris
// sur un composant. C'est le geste attendu dès qu'un schéma dépasse l'écran,
// et il évite d'avoir à viser les barres de défilement.
void VueSchema::mousePressEvent(QMouseEvent* evenement) {
    if (evenement->button() == Qt::MiddleButton) {
        glissement_ = true;
        depart_glissement_ = evenement->position().toPoint();
        setCursor(Qt::ClosedHandCursor);
        evenement->accept();
        return;
    }
    QGraphicsView::mousePressEvent(evenement);
}

void VueSchema::mouseMoveEvent(QMouseEvent* evenement) {
    if (glissement_) {
        const QPoint maintenant = evenement->position().toPoint();
        const QPoint ecart = maintenant - depart_glissement_;
        depart_glissement_ = maintenant;
        horizontalScrollBar()->setValue(horizontalScrollBar()->value()
                                        - ecart.x());
        verticalScrollBar()->setValue(verticalScrollBar()->value() - ecart.y());
        evenement->accept();
        return;
    }
    QGraphicsView::mouseMoveEvent(evenement);
}

void VueSchema::mouseReleaseEvent(QMouseEvent* evenement) {
    if (glissement_ && evenement->button() == Qt::MiddleButton) {
        glissement_ = false;
        unsetCursor();
        evenement->accept();
        return;
    }
    QGraphicsView::mouseReleaseEvent(evenement);
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

void VueSchema::poser_ilot(QWidget* ilot) {
    ilot_ = ilot;
    if (!ilot_) return;
    ilot_->setParent(this);
    ilot_->raise();
    ilot_->show();
    replacer_ilot();
}

void VueSchema::replacer_ilot() {
    if (!ilot_) return;
    const int marge = 14;
    ilot_->adjustSize();
    ilot_->move(width() - ilot_->width() - marge,
                height() - ilot_->height() - marge);
}

void VueSchema::resizeEvent(QResizeEvent* evenement) {
    QGraphicsView::resizeEvent(evenement);
    replacer_ilot();
}
