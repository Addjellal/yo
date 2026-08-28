// Ruban.cpp — le bandeau, ses groupes, et ses icônes dessinées.
#include "Ruban.h"

#include <QHBoxLayout>
#include <QLabel>
#include <QPainter>
#include <QFontMetrics>
#include <QFrame>
#include <QPainterPath>
#include <cmath>
#include <QToolButton>
#include <QVBoxLayout>

#include "Theme.h"

namespace {

// Les icônes de MATLAB sont colorées et lisibles à petite taille. On s'en
// tient à des formes simples, dessinées au vecteur : elles restent nettes
// à toutes les résolutions et ne demandent aucun fichier.
void dessiner(QPainter& p, const QString& nom, const QRectF& r) {
    const QColor bleu("#0072bd"), vert("#2e9e3e"), orange("#d95319"),
        gris("#606060"), jaune("#edb120"), rouge("#c0392b");
    p.setRenderHint(QPainter::Antialiasing, true);

    auto feuille = [&](const QColor& couleur) {
        QRectF f(r.left() + r.width() * 0.22, r.top() + r.height() * 0.10,
                 r.width() * 0.56, r.height() * 0.80);
        p.setPen(QPen(couleur, r.width() * 0.07));
        p.setBrush(Qt::white);
        p.drawRect(f);
        p.setPen(QPen(couleur.lighter(140), r.width() * 0.06));
        for (int k = 1; k <= 3; ++k) {
            double y = f.top() + f.height() * k / 4.0;
            p.drawLine(QPointF(f.left() + f.width() * 0.15, y),
                       QPointF(f.right() - f.width() * 0.15, y));
        }
    };

    if (nom == QLatin1String("nouveau")) {
        feuille(bleu);
        p.setPen(QPen(vert, r.width() * 0.12, Qt::SolidLine, Qt::RoundCap));
        double cx = r.right() - r.width() * 0.18, cy = r.bottom() - r.height() * 0.18;
        double b = r.width() * 0.14;
        p.drawLine(QPointF(cx - b, cy), QPointF(cx + b, cy));
        p.drawLine(QPointF(cx, cy - b), QPointF(cx, cy + b));
        return;
    }
    if (nom == QLatin1String("script")) { feuille(bleu); return; }
    if (nom == QLatin1String("ouvrir")) {
        p.setPen(QPen(orange.darker(120), r.width() * 0.07));
        p.setBrush(jaune);
        QPainterPath chemin;
        chemin.moveTo(r.left() + r.width() * 0.10, r.bottom() - r.height() * 0.18);
        chemin.lineTo(r.left() + r.width() * 0.10, r.top() + r.height() * 0.28);
        chemin.lineTo(r.left() + r.width() * 0.42, r.top() + r.height() * 0.28);
        chemin.lineTo(r.left() + r.width() * 0.50, r.top() + r.height() * 0.40);
        chemin.lineTo(r.right() - r.width() * 0.10, r.top() + r.height() * 0.40);
        chemin.lineTo(r.right() - r.width() * 0.10, r.bottom() - r.height() * 0.18);
        chemin.closeSubpath();
        p.drawPath(chemin);
        return;
    }
    if (nom == QLatin1String("enregistrer")) {
        p.setPen(QPen(bleu.darker(130), r.width() * 0.07));
        p.setBrush(bleu);
        p.drawRect(QRectF(r.left() + r.width() * 0.14, r.top() + r.height() * 0.14,
                          r.width() * 0.72, r.height() * 0.72));
        p.setBrush(Qt::white);
        p.setPen(Qt::NoPen);
        p.drawRect(QRectF(r.left() + r.width() * 0.30, r.top() + r.height() * 0.14,
                          r.width() * 0.40, r.height() * 0.26));
        p.drawRect(QRectF(r.left() + r.width() * 0.26, r.top() + r.height() * 0.52,
                          r.width() * 0.48, r.height() * 0.34));
        return;
    }
    if (nom == QLatin1String("executer")) {
        p.setPen(Qt::NoPen);
        p.setBrush(vert);
        QPainterPath t;
        t.moveTo(r.left() + r.width() * 0.24, r.top() + r.height() * 0.12);
        t.lineTo(r.right() - r.width() * 0.14, r.center().y());
        t.lineTo(r.left() + r.width() * 0.24, r.bottom() - r.height() * 0.12);
        t.closeSubpath();
        p.drawPath(t);
        return;
    }
    if (nom == QLatin1String("selection")) {
        p.setPen(Qt::NoPen);
        p.setBrush(vert);
        QPainterPath t;
        t.moveTo(r.left() + r.width() * 0.30, r.top() + r.height() * 0.16);
        t.lineTo(r.right() - r.width() * 0.20, r.center().y());
        t.lineTo(r.left() + r.width() * 0.30, r.bottom() - r.height() * 0.16);
        t.closeSubpath();
        p.drawPath(t);
        p.setPen(QPen(bleu, r.width() * 0.10));
        p.drawLine(QPointF(r.left() + r.width() * 0.14, r.top() + r.height() * 0.16),
                   QPointF(r.left() + r.width() * 0.14, r.bottom() - r.height() * 0.16));
        return;
    }
    if (nom == QLatin1String("variables")) {
        p.setPen(QPen(gris, r.width() * 0.06));
        p.setBrush(Qt::white);
        QRectF g(r.left() + r.width() * 0.10, r.top() + r.height() * 0.20,
                 r.width() * 0.80, r.height() * 0.60);
        p.drawRect(g);
        p.setBrush(bleu);
        p.setPen(Qt::NoPen);
        p.drawRect(QRectF(g.left(), g.top(), g.width(), g.height() / 3.0));
        p.setPen(QPen(gris, r.width() * 0.05));
        p.drawLine(QPointF(g.left(), g.top() + g.height() * 2 / 3.0),
                   QPointF(g.right(), g.top() + g.height() * 2 / 3.0));
        p.drawLine(QPointF(g.center().x(), g.top()), QPointF(g.center().x(), g.bottom()));
        return;
    }
    if (nom == QLatin1String("effacer")) {
        p.setPen(QPen(rouge, r.width() * 0.13, Qt::SolidLine, Qt::RoundCap));
        p.drawLine(QPointF(r.left() + r.width() * 0.24, r.top() + r.height() * 0.24),
                   QPointF(r.right() - r.width() * 0.24, r.bottom() - r.height() * 0.24));
        p.drawLine(QPointF(r.right() - r.width() * 0.24, r.top() + r.height() * 0.24),
                   QPointF(r.left() + r.width() * 0.24, r.bottom() - r.height() * 0.24));
        return;
    }
    if (nom == QLatin1String("dossier")) {
        p.setPen(QPen(orange.darker(120), r.width() * 0.07));
        p.setBrush(jaune);
        p.drawRect(QRectF(r.left() + r.width() * 0.12, r.top() + r.height() * 0.26,
                          r.width() * 0.76, r.height() * 0.52));
        return;
    }
    if (nom == QLatin1String("trace")) {
        p.setPen(QPen(gris, r.width() * 0.06));
        p.drawLine(QPointF(r.left() + r.width() * 0.16, r.top() + r.height() * 0.14),
                   QPointF(r.left() + r.width() * 0.16, r.bottom() - r.height() * 0.18));
        p.drawLine(QPointF(r.left() + r.width() * 0.16, r.bottom() - r.height() * 0.18),
                   QPointF(r.right() - r.width() * 0.10, r.bottom() - r.height() * 0.18));
        p.setPen(QPen(bleu, r.width() * 0.09));
        QPainterPath c;
        double x0 = r.left() + r.width() * 0.20, x1 = r.right() - r.width() * 0.12;
        for (int k = 0; k <= 24; ++k) {
            double t = k / 24.0;
            double x = x0 + (x1 - x0) * t;
            double y = r.center().y() - std::sin(t * 6.283) * r.height() * 0.24;
            if (k == 0) c.moveTo(x, y); else c.lineTo(x, y);
        }
        p.drawPath(c);
        return;
    }
    if (nom == QLatin1String("barres")) {
        p.setPen(Qt::NoPen);
        const double h[4] = {0.34, 0.62, 0.46, 0.74};
        const QColor couleurs[4] = {bleu, orange, jaune, vert};
        for (int k = 0; k < 4; ++k) {
            double l = r.width() * 0.17;
            double x = r.left() + r.width() * 0.12 + k * l;
            p.setBrush(couleurs[k]);
            p.drawRect(QRectF(x, r.bottom() - r.height() * 0.14 - r.height() * h[k],
                              l * 0.78, r.height() * h[k]));
        }
        return;
    }
    if (nom == QLatin1String("aide")) {
        p.setPen(Qt::NoPen);
        p.setBrush(bleu);
        p.drawEllipse(r.adjusted(r.width() * 0.10, r.height() * 0.10, -r.width() * 0.10,
                                 -r.height() * 0.10));
        QFont f = p.font();
        f.setPixelSize(int(r.height() * 0.56));
        f.setBold(true);
        p.setFont(f);
        p.setPen(Qt::white);
        p.drawText(r, Qt::AlignCenter, QStringLiteral("?"));
        return;
    }
    if (nom == QLatin1String("bureau")) {
        p.setPen(QPen(gris, r.width() * 0.06));
        p.setBrush(Qt::white);
        p.drawRect(QRectF(r.left() + r.width() * 0.10, r.top() + r.height() * 0.18,
                          r.width() * 0.80, r.height() * 0.64));
        p.setBrush(bleu);
        p.setPen(Qt::NoPen);
        p.drawRect(QRectF(r.left() + r.width() * 0.10, r.top() + r.height() * 0.18,
                          r.width() * 0.28, r.height() * 0.64));
        return;
    }
    // Par défaut : un carré neutre, plutôt qu'un bouton sans image.
    p.setPen(QPen(gris, r.width() * 0.07));
    p.setBrush(Qt::NoBrush);
    p.drawRect(r.adjusted(r.width() * 0.18, r.height() * 0.18, -r.width() * 0.18,
                          -r.height() * 0.18));
}

}  // namespace

QIcon iconeDessinee(const QString& nom, int taille) {
    QPixmap image(taille, taille);
    image.fill(Qt::transparent);
    QPainter p(&image);
    dessiner(p, nom, QRectF(0, 0, taille, taille));
    p.end();
    return QIcon(image);
}

GroupeRuban::GroupeRuban(const QString& titre, QWidget* parent) : QWidget(parent) {
    auto* vertical = new QVBoxLayout(this);
    vertical->setContentsMargins(6, 3, 6, 2);
    vertical->setSpacing(1);
    boutons_ = new QHBoxLayout;
    boutons_->setContentsMargins(0, 0, 0, 0);
    boutons_->setSpacing(1);
    vertical->addLayout(boutons_, 1);
    auto* etiquette = new QLabel(titre.toUpper());
    QFont police = etiquette->font();
    police.setPointSizeF(police.pointSizeF() - 1.5);
    etiquette->setFont(police);
    etiquette->setAlignment(Qt::AlignHCenter);
    etiquette->setStyleSheet(
        QStringLiteral("color:%1;").arg(theme::texteEteint().name()));
    vertical->addWidget(etiquette);
}

QToolButton* GroupeRuban::ajouter(const QString& libelle, const QString& dessin,
                                  const QString& infobulle) {
    auto* bouton = new QToolButton;
    bouton->setToolButtonStyle(Qt::ToolButtonTextUnderIcon);
    bouton->setIcon(iconeDessinee(dessin));
    bouton->setIconSize(QSize(28, 28));
    bouton->setText(libelle);
    bouton->setAutoRaise(true);
    if (!infobulle.isEmpty()) bouton->setToolTip(infobulle);
    // Assez large pour le plus long des deux mots d'un libellé sur deux
    // lignes : sinon Qt élide, et « Nouveau script » sort en « ouveau scrip ».
    QFontMetrics metrique(bouton->font());
    int large = 0;
    for (const QString& mot : libelle.split(QLatin1Char('\n')))
        large = qMax(large, metrique.horizontalAdvance(mot));
    bouton->setMinimumWidth(qMax(58, large + 16));
    boutons_->addWidget(bouton);
    return bouton;
}

void GroupeRuban::ajouterSeparateur() { boutons_->addSpacing(6); }

Ruban::Ruban(QWidget* parent) : QTabWidget(parent) {
    setDocumentMode(true);
    setFixedHeight(112);
}

QWidget* Ruban::pageOnglet(const QString& nom) {
    for (int k = 0; k < count(); ++k)
        if (tabText(k) == nom) return widget(k);
    auto* page = new QWidget;
    auto* disposition = new QHBoxLayout(page);
    disposition->setContentsMargins(4, 2, 4, 2);
    disposition->setSpacing(0);
    disposition->addStretch(1);
    addTab(page, nom);
    return page;
}

void Ruban::ajouterGroupe(const QString& onglet, GroupeRuban* groupe) {
    QWidget* page = pageOnglet(onglet);
    auto* disposition = qobject_cast<QHBoxLayout*>(page->layout());
    if (!disposition) return;
    // Le trait qui sépare deux groupes, comme dans le ruban de MATLAB.
    if (disposition->count() > 1) {
        auto* trait = new QFrame;
        trait->setFrameShape(QFrame::VLine);
        trait->setStyleSheet(QStringLiteral("color:%1;").arg(theme::bordure().name()));
        disposition->insertWidget(disposition->count() - 1, trait);
    }
    disposition->insertWidget(disposition->count() - 1, groupe);
}
