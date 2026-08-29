// Ruban.cpp — le bandeau, ses groupes, et ses icônes dessinées.
#include "Ruban.h"

#include <QAction>
#include <QHBoxLayout>
#include <QMenu>
#include <QLabel>
#include <QPainter>
#include <QFontMetrics>
#include <QFrame>
#include <QFont>
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
    // --- le panneau « Dossier courant » ----------------------------------
    //
    // Un dossier a la forme d'une chemise, un fichier celle d'une feuille
    // au coin replié ; la couleur dit la famille, comme dans le panneau de
    // MATLAB — bleu pour le code, violet pour les données, vert pour les
    // images, gris pour le reste.
    auto chemise = [&](const QColor& couleur) {
        p.setPen(QPen(couleur.darker(130), r.width() * 0.06));
        p.setBrush(couleur);
        QPainterPath c;
        double g = r.left() + r.width() * 0.08, d = r.right() - r.width() * 0.08;
        double h = r.top() + r.height() * 0.22, b = r.bottom() - r.height() * 0.16;
        c.moveTo(g, b);
        c.lineTo(g, h);
        c.lineTo(g + (d - g) * 0.34, h);
        c.lineTo(g + (d - g) * 0.46, h + r.height() * 0.11);
        c.lineTo(d, h + r.height() * 0.11);
        c.lineTo(d, b);
        c.closeSubpath();
        p.drawPath(c);
    };
    // Une feuille au coin replié, avec une pastille de couleur : c'est
    // elle qui distingue un .m d'un .mat d'un coup d'œil.
    auto document = [&](const QColor& couleur, const QString& etiquette) {
        double g = r.left() + r.width() * 0.20, d = r.right() - r.width() * 0.16;
        double h = r.top() + r.height() * 0.08, b = r.bottom() - r.height() * 0.08;
        double pli = r.width() * 0.22;
        QPainterPath f;
        f.moveTo(g, b);
        f.lineTo(g, h);
        f.lineTo(d - pli, h);
        f.lineTo(d, h + pli);
        f.lineTo(d, b);
        f.closeSubpath();
        p.setPen(QPen(gris.lighter(120), r.width() * 0.05));
        p.setBrush(Qt::white);
        p.drawPath(f);
        // Le coin replié.
        QPainterPath coin;
        coin.moveTo(d - pli, h);
        coin.lineTo(d - pli, h + pli);
        coin.lineTo(d, h + pli);
        coin.closeSubpath();
        p.setBrush(gris.lighter(170));
        p.drawPath(coin);
        // La pastille, et sa lettre quand la place le permet.
        QRectF pastille(g, b - r.height() * 0.34, (d - g) * 0.86, r.height() * 0.26);
        p.setPen(Qt::NoPen);
        p.setBrush(couleur);
        p.drawRoundedRect(pastille, r.width() * 0.05, r.width() * 0.05);
        if (!etiquette.isEmpty() && r.width() >= 20) {
            QFont police = p.font();
            police.setBold(true);
            police.setPixelSize((int)(r.height() * 0.22));
            p.setFont(police);
            p.setPen(Qt::white);
            p.drawText(pastille, Qt::AlignCenter, etiquette);
        }
    };
    if (nom == QLatin1String("dossier-plein")) { chemise(jaune); return; }
    if (nom == QLatin1String("dossier-parent")) {
        chemise(jaune.darker(115));
        p.setPen(QPen(Qt::white, r.width() * 0.10, Qt::SolidLine, Qt::RoundCap));
        double cx = r.center().x(), cy = r.center().y() + r.height() * 0.06;
        p.drawLine(QPointF(cx, cy + r.height() * 0.14), QPointF(cx, cy - r.height() * 0.12));
        p.drawLine(QPointF(cx - r.width() * 0.12, cy), QPointF(cx, cy - r.height() * 0.12));
        p.drawLine(QPointF(cx + r.width() * 0.12, cy), QPointF(cx, cy - r.height() * 0.12));
        return;
    }
    if (nom == QLatin1String("fichier-m")) { document(bleu, QStringLiteral("m")); return; }
    if (nom == QLatin1String("fichier-mlx")) {
        document(QColor("#7b3fa0"), QStringLiteral("mlx"));
        return;
    }
    if (nom == QLatin1String("fichier-donnees")) {
        document(orange, QStringLiteral("mat"));
        return;
    }
    if (nom == QLatin1String("fichier-image")) {
        document(vert, QString());
        return;
    }
    if (nom == QLatin1String("fichier-texte")) {
        document(gris, QString());
        return;
    }
    if (nom == QLatin1String("fichier-autre")) {
        document(gris.lighter(130), QString());
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
    // --- le débogueur : les gestes de MATLAB, dessinés ----------------
    //
    // Un triangle qui repart, un pas au-dessus d'une barre, une flèche qui
    // entre, une flèche qui sort, un carré qui arrête, une pastille rouge
    // pour le point d'arrêt. Rien n'est repris : ce sont les formes
    // ordinaires d'un débogueur, redessinées.
    auto triangle = [&](const QColor& couleur, double gauche, double largeur) {
        QPainterPath t;
        double x = r.left() + r.width() * gauche;
        t.moveTo(x, r.top() + r.height() * 0.18);
        t.lineTo(x + r.width() * largeur, r.center().y());
        t.lineTo(x, r.bottom() - r.height() * 0.18);
        t.closeSubpath();
        p.setPen(Qt::NoPen);
        p.setBrush(couleur);
        p.drawPath(t);
    };
    auto barre = [&](const QColor& couleur, double centre) {
        p.setPen(Qt::NoPen);
        p.setBrush(couleur);
        p.drawRect(QRectF(r.left() + r.width() * centre, r.top() + r.height() * 0.18,
                          r.width() * 0.12, r.height() * 0.64));
    };
    if (nom == QLatin1String("continuer")) {
        // Le « continuer » de MATLAB : la barre du point d'arrêt, puis on
        // repart.
        barre(vert.darker(120), 0.14);
        triangle(vert, 0.36, 0.50);
        return;
    }
    if (nom == QLatin1String("pasapas")) {
        triangle(vert, 0.10, 0.44);
        barre(gris, 0.68);
        return;
    }
    if (nom == QLatin1String("entrer")) {
        // Une flèche qui plonge vers la ligne appelée : on entre dedans.
        p.setPen(QPen(vert, r.width() * 0.11, Qt::SolidLine, Qt::RoundCap));
        p.drawLine(QPointF(r.center().x(), r.top() + r.height() * 0.14),
                   QPointF(r.center().x(), r.bottom() - r.height() * 0.42));
        p.setPen(Qt::NoPen);
        p.setBrush(vert);
        QPainterPath pointe;
        pointe.moveTo(r.center().x() - r.width() * 0.16, r.bottom() - r.height() * 0.46);
        pointe.lineTo(r.center().x() + r.width() * 0.16, r.bottom() - r.height() * 0.46);
        pointe.lineTo(r.center().x(), r.bottom() - r.height() * 0.22);
        pointe.closeSubpath();
        p.drawPath(pointe);
        p.setPen(QPen(gris, r.width() * 0.08, Qt::SolidLine, Qt::RoundCap));
        p.drawLine(QPointF(r.left() + r.width() * 0.18, r.bottom() - r.height() * 0.12),
                   QPointF(r.right() - r.width() * 0.18, r.bottom() - r.height() * 0.12));
        return;
    }
    if (nom == QLatin1String("sortir")) {
        p.setPen(QPen(orange, r.width() * 0.11, Qt::SolidLine, Qt::RoundCap));
        p.drawLine(QPointF(r.center().x(), r.bottom() - r.height() * 0.14),
                   QPointF(r.center().x(), r.top() + r.height() * 0.36));
        p.setPen(Qt::NoPen);
        p.setBrush(orange);
        QPainterPath pointe;
        pointe.moveTo(r.center().x() - r.width() * 0.14, r.top() + r.height() * 0.44);
        pointe.lineTo(r.center().x() + r.width() * 0.14, r.top() + r.height() * 0.44);
        pointe.lineTo(r.center().x(), r.top() + r.height() * 0.20);
        pointe.closeSubpath();
        p.drawPath(pointe);
        return;
    }
    if (nom == QLatin1String("arret")) {
        p.setPen(Qt::NoPen);
        p.setBrush(rouge);
        p.drawRoundedRect(r.adjusted(r.width() * 0.20, r.height() * 0.20,
                                     -r.width() * 0.20, -r.height() * 0.20),
                          r.width() * 0.08, r.width() * 0.08);
        return;
    }
    if (nom == QLatin1String("pointarret")) {
        p.setPen(Qt::NoPen);
        p.setBrush(rouge);
        p.drawEllipse(r.adjusted(r.width() * 0.20, r.height() * 0.20, -r.width() * 0.20,
                                 -r.height() * 0.20));
        return;
    }
    if (nom == QLatin1String("chronometre")) {
        // « Exécuter et chronométrer » : un chronomètre, aiguille en biais.
        QRectF cadran = r.adjusted(r.width() * 0.14, r.height() * 0.22, -r.width() * 0.14,
                                   -r.height() * 0.08);
        p.setPen(QPen(gris, r.width() * 0.08));
        p.setBrush(Qt::white);
        p.drawEllipse(cadran);
        p.setPen(QPen(gris, r.width() * 0.10, Qt::SolidLine, Qt::RoundCap));
        p.drawLine(QPointF(cadran.center().x() - cadran.width() * 0.16,
                           cadran.top() - r.height() * 0.10),
                   QPointF(cadran.center().x() + cadran.width() * 0.16,
                           cadran.top() - r.height() * 0.10));
        p.drawLine(QPointF(cadran.center().x(), cadran.top() - r.height() * 0.10),
                   QPointF(cadran.center().x(), cadran.top()));
        p.setPen(QPen(orange, r.width() * 0.08, Qt::SolidLine, Qt::RoundCap));
        p.drawLine(cadran.center(),
                   QPointF(cadran.center().x() + cadran.width() * 0.28,
                           cadran.center().y() - cadran.height() * 0.26));
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

QIcon iconeEntree(const QString& suffixe, bool dossier, int taille) {
    if (dossier) return iconeDessinee(QStringLiteral("dossier-plein"), taille);
    const QString s = suffixe.toLower();
    if (s == QLatin1String("m")) return iconeDessinee(QStringLiteral("fichier-m"), taille);
    if (s == QLatin1String("mlx") || s == QLatin1String("mlapp"))
        return iconeDessinee(QStringLiteral("fichier-mlx"), taille);
    if (s == QLatin1String("mat") || s == QLatin1String("csv") ||
        s == QLatin1String("xlsx") || s == QLatin1String("xls") ||
        s == QLatin1String("json") || s == QLatin1String("dat"))
        return iconeDessinee(QStringLiteral("fichier-donnees"), taille);
    if (s == QLatin1String("png") || s == QLatin1String("jpg") ||
        s == QLatin1String("jpeg") || s == QLatin1String("bmp") ||
        s == QLatin1String("gif") || s == QLatin1String("svg") ||
        s == QLatin1String("fig") || s == QLatin1String("pdf"))
        return iconeDessinee(QStringLiteral("fichier-image"), taille);
    if (s == QLatin1String("txt") || s == QLatin1String("md") ||
        s == QLatin1String("log") || s == QLatin1String("c") ||
        s == QLatin1String("h") || s == QLatin1String("cpp") ||
        s == QLatin1String("py") || s == QLatin1String("xml") ||
        s == QLatin1String("html"))
        return iconeDessinee(QStringLiteral("fichier-texte"), taille);
    return iconeDessinee(QStringLiteral("fichier-autre"), taille);
}

GroupeRuban::GroupeRuban(const QString& titre, QWidget* parent)
    : QWidget(parent), titre_(titre) {
    auto* vertical = new QVBoxLayout(this);
    vertical->setContentsMargins(6, 3, 6, 2);
    vertical->setSpacing(1);
    // La rangée de boutons vit dans son propre widget : replier le groupe
    // revient alors à la cacher et à montrer le bouton unique.
    rangee_ = new QWidget;
    boutons_ = new QHBoxLayout(rangee_);
    boutons_->setContentsMargins(0, 0, 0, 0);
    boutons_->setSpacing(1);
    vertical->addWidget(rangee_, 1);
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
    liste_.push_back(bouton);
    if (replie_) {
        // Le groupe est déjà replié : la nouvelle commande doit entrer
        // dans son menu, sinon elle serait injoignable.
        delete replie_;
        replie_ = nullptr;
        if (compact_) definirCompact(true);
    }
    return bouton;
}

void GroupeRuban::ajouterSeparateur() { boutons_->addSpacing(6); }

// Largeur que le groupe demanderait déployé : la somme des boutons, plus
// les marges. Mesurée ainsi et non par sizeHint(), qui vaudrait celle du
// bouton replié quand le groupe l'est.
int GroupeRuban::largeurDeployee() const {
    int total = 12;  // marges gauche et droite
    for (QToolButton* b : liste_)
        total += qMax(b->minimumWidth(), b->sizeHint().width()) + boutons_->spacing();
    QFontMetrics metrique(font());
    return qMax(total, metrique.horizontalAdvance(titre_.toUpper()) + 20);
}

int GroupeRuban::largeurCompacte() const {
    QFontMetrics metrique(font());
    // Un groupe d'un seul bouton au libellé court est déjà plus étroit que
    // son propre titre : le replier ne gagnerait rien, et coûterait un
    // clic. On ne prétend donc jamais gagner de la place là où il n'y en a
    // pas à gagner.
    return qMin(largeurDeployee(), metrique.horizontalAdvance(titre_.toUpper()) + 52);
}

// Replier : un seul bouton, l'icône du premier, le titre du groupe, et un
// menu qui porte toutes les commandes. C'est ce que fait MATLAB quand sa
// fenêtre devient trop étroite — il ne rogne jamais un libellé.
void GroupeRuban::definirCompact(bool compact) {
    if (compact == compact_ && (!compact || replie_)) return;
    compact_ = compact;
    if (!compact) {
        rangee_->setVisible(true);
        if (replie_) replie_->setVisible(false);
        setMaximumWidth(QWIDGETSIZE_MAX);
        return;
    }
    if (!replie_) {
        replie_ = new QToolButton(this);
        replie_->setToolButtonStyle(Qt::ToolButtonTextUnderIcon);
        replie_->setIconSize(QSize(28, 28));
        replie_->setAutoRaise(true);
        replie_->setPopupMode(QToolButton::InstantPopup);
        replie_->setText(titre_);
        if (!liste_.isEmpty()) replie_->setIcon(liste_.front()->icon());
        auto* menu = new QMenu(replie_);
        for (QToolButton* b : liste_) {
            QString texte = b->text();
            texte.replace(QLatin1Char('\n'), QLatin1Char(' '));
            QAction* entree = menu->addAction(b->icon(), texte);
            entree->setToolTip(b->toolTip());
            connect(entree, &QAction::triggered, b, &QToolButton::click);
        }
        // Une commande grisée doit l'être aussi dans le menu : les
        // commandes du débogueur ne s'allument qu'à l'arrêt.
        connect(menu, &QMenu::aboutToShow, this, [this, menu] {
            const QList<QAction*> entrees = menu->actions();
            for (int k = 0; k < entrees.size() && k < liste_.size(); ++k)
                entrees[k]->setEnabled(liste_[k]->isEnabled());
        });
        replie_->setMenu(menu);
        // Il occupe la place de la rangée, dans la même disposition.
        auto* vertical = qobject_cast<QVBoxLayout*>(layout());
        if (vertical) vertical->insertWidget(0, replie_, 1);
    }
    rangee_->setVisible(false);
    replie_->setVisible(true);
    setMaximumWidth(largeurCompacte());
}

Ruban::Ruban(QWidget* parent) : QTabWidget(parent) {
    setDocumentMode(true);
    // Assez haut pour deux lignes de libellé sous l'icône : à 112, le
    // jambage de « variables » était rogné.
    setFixedHeight(118);
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
    groupes_[onglet].push_back(groupe);
    ajusterGroupes();
}

void Ruban::resizeEvent(QResizeEvent* evenement) {
    QTabWidget::resizeEvent(evenement);
    ajusterGroupes();
}

// Ce que fait MATLAB quand la fenêtre rétrécit : plutôt que de rogner les
// libellés, il replie les groupes, en commençant par la droite — les
// commandes les plus courantes sont à gauche. On replie tant que ça ne
// tient pas, et on redéploie dès qu'il y a de nouveau la place.
void Ruban::ajusterGroupes() {
    if (enAjustement_) return;
    enAjustement_ = true;
    const int disponible = width() - 32;  // marges de la page et du cadre
    for (auto it = groupes_.begin(); it != groupes_.end(); ++it) {
        const QVector<GroupeRuban*>& groupes = it.value();
        // Largeur si tout est déployé, séparateurs compris.
        int total = 8 * qMax(0, groupes.size() - 1);
        for (GroupeRuban* g : groupes) total += g->largeurDeployee();
        // On replie depuis la droite — les commandes les plus courantes
        // sont à gauche — et seulement tant qu'il manque de la place. Un
        // groupe qui ne gagnerait rien à être replié reste déployé.
        QVector<bool> replie(groupes.size(), false);
        for (int k = groupes.size() - 1; k >= 0 && total > disponible; --k) {
            int gain = groupes[k]->largeurDeployee() - groupes[k]->largeurCompacte();
            if (gain <= 0) continue;
            replie[k] = true;
            total -= gain;
        }
        // La passe précédente replie depuis la droite, et peut en replier
        // un de trop : le dernier gain dépasse souvent ce qui manquait. On
        // redéploie donc, en partant de la gauche, tout ce qui rentre
        // encore — les groupes les plus utilisés retrouvent leurs boutons.
        for (int k = 0; k < groupes.size(); ++k) {
            if (!replie[k]) continue;
            int gain = groupes[k]->largeurDeployee() - groupes[k]->largeurCompacte();
            if (total + gain > disponible) continue;
            replie[k] = false;
            total += gain;
        }
        for (int k = 0; k < groupes.size(); ++k) groupes[k]->definirCompact(replie[k]);
    }
    enAjustement_ = false;
}
