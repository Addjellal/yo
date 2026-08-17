#include "app/schematic/ItemComposant.h"

#include <QGraphicsScene>

#include "app/schematic/ItemFil.h"

#include <QFont>
#include <QPainter>
#include <QPolygonF>
#include <QStyleOptionGraphicsItem>
#include <QTransform>

#include <cmath>

#include "core/Device.h"

namespace {

QPointF vers_qt(const coeur::PointSymbole& p) { return QPointF(p.x, p.y); }

QColor couleur_de(const std::string& texte, QColor defaut) {
    QColor c(QString::fromStdString(texte));
    return c.isValid() ? c : defaut;
}

// Couleurs d'émission des LED, par nom de couleur du catalogue.
QColor couleur_lumiere(const std::string& nom) {
    if (nom == "vert") return QColor(60, 220, 90);
    if (nom == "jaune") return QColor(245, 210, 60);
    if (nom == "bleu") return QColor(80, 150, 255);
    if (nom == "blanc") return QColor(255, 255, 235);
    return QColor(235, 70, 60);
}

}  // namespace

ItemComposant::ItemComposant(const coeur::Modele* modele, QString reference)
    : modele_(modele), reference_(std::move(reference)) {
    setFlags(ItemIsSelectable | ItemIsMovable | ItemSendsGeometryChanges);
    setAcceptHoverEvents(true);
    if (modele_) {
        for (const auto& propriete : modele_->proprietes) {
            if (propriete.genre == coeur::Propriete::Genre::Choix)
                textes[propriete.cle] = propriete.defaut_texte;
            else
                valeurs[propriete.cle] = propriete.defaut;
        }
    }
    recalculer_cadre();
}

void ItemComposant::definir_reference(QString reference) {
    reference_ = std::move(reference);
    update();
}

void ItemComposant::recalculer_cadre() {
    QRectF boite;
    auto etendre = [&boite](QPointF p) {
        if (boite.isNull())
            boite = QRectF(p, QSizeF(0.01, 0.01));
        else {
            boite.setLeft(std::min(boite.left(), p.x()));
            boite.setRight(std::max(boite.right(), p.x()));
            boite.setTop(std::min(boite.top(), p.y()));
            boite.setBottom(std::max(boite.bottom(), p.y()));
        }
    };
    if (modele_) {
        for (const auto& borne : modele_->bornes) etendre(vers_qt(borne.position));
        for (const auto& trait : modele_->symbole) {
            for (const auto& point : trait.points) {
                etendre(vers_qt(point));
                if (trait.genre == coeur::TraitSymbole::Genre::Cercle) {
                    etendre(vers_qt(point) + QPointF(trait.mesure, trait.mesure));
                    etendre(vers_qt(point) - QPointF(trait.mesure, trait.mesure));
                }
            }
        }
    }
    if (boite.isNull()) boite = QRectF(-30, -20, 60, 40);
    // marge pour la référence au-dessus et l'étiquette en dessous
    // marge basse plus large : la valeur, puis la mesure en simulation
    cadre_ = boite.adjusted(-8, -22, 8, 42);

    // Le cadre de dessin, lui, doit couvrir TOUT ce que `paint` touche, sans
    // quoi Qt ne réefface pas ce qu'il a peint : en déplaçant le composant on
    // laissait derrière soi une traînée de références et de mesures.
    //
    // Les textes sont tracés dans le repère non tourné (paint annule la
    // rotation) : sur un composant pivoté, ils sortent donc par un autre côté.
    // Comme les rotations sont des quarts de tour, il suffit d'ajouter au
    // cadre sa propre version transposée.
    const QRectF textes(-90, cadre_.top() - 4, 180, cadre_.height() + 20);
    const QRectF transpose(textes.top(), textes.left(), textes.height(),
                           textes.width());
    cadre_peint_ = cadre_ | textes | transpose;

    // Le marqueur ERC est posé À CÔTÉ de la borne, donc HORS de la boîte des
    // bornes : treize unités vers l'extérieur, plus la demi-largeur du
    // triangle. Sur un boîtier dont les bornes touchent le bord — l'ATtiny85
    // les porte à x = ±90 —, `cadre_` ne réservait que huit unités et le
    // triangle sortait du cadre de dessin : Qt n'efface que ce qu'on lui
    // déclare, et ces pixels-là restaient à l'écran quand la puce bougeait.
    //
    // Le même oubli avait déjà coûté un correctif sur le halo d'ItemJonction.
    // C'est le genre de défaut qu'aucun test de logique n'attrape : il faut
    // peindre pour de bon et compter les pixels.
    if (modele_ && !modele_->bornes.empty()) {
        constexpr double kPortee = 13.0 + 7.5;   // pose + demi-triangle
        QRectF autour_bornes;
        for (const auto& borne : modele_->bornes) {
            const QPointF p = vers_qt(borne.position);
            const QRectF cellule(p.x() - kPortee, p.y() - kPortee, 2 * kPortee,
                                 2 * kPortee);
            autour_bornes =
                autour_bornes.isNull() ? cellule : autour_bornes.united(cellule);
        }
        cadre_peint_ = cadre_peint_ | autour_bornes;
    }
}

QRectF ItemComposant::boundingRect() const { return cadre_peint_; }

QVariant ItemComposant::itemChange(GraphicsItemChange changement,
                                   const QVariant& valeur) {
    // Le tracé d'un fil se calcule à partir de la position de ses deux
    // composants : il change donc en même temps que celui-ci, sans que Qt en
    // sache rien. Il faut le lui dire AVANT le déplacement — pour qu'il
    // efface l'ancien tracé — et APRÈS — pour qu'il peigne le nouveau.
    const bool geometrie = changement == ItemPositionChange
                           || changement == ItemPositionHasChanged
                           || changement == ItemRotationChange
                           || changement == ItemRotationHasChanged
                           || changement == ItemTransformChange
                           || changement == ItemTransformHasChanged;
    if (geometrie && scene()) {
        for (QGraphicsItem* item : scene()->items()) {
            if (item->type() != ItemFil::Type) continue;
            auto* fil = static_cast<ItemFil*>(item);
            if (fil->touche(this)) fil->rafraichir();
        }
    }
    return QGraphicsItem::itemChange(changement, valeur);
}

QPainterPath ItemComposant::shape() const {
    // Ce qui répond au clic reste le symbole et ses étiquettes proches : un
    // cadre de dessin élargi ne doit pas rendre la sélection approximative.
    QPainterPath forme;
    forme.addRect(cadre_);
    return forme;
}

int ItemComposant::nb_bornes() const {
    return modele_ ? static_cast<int>(modele_->bornes.size()) : 0;
}

QString ItemComposant::nom_borne(int index) const {
    if (!modele_ || index < 0 || index >= nb_bornes()) return {};
    return QString::fromStdString(modele_->bornes[index].nom);
}

QPointF ItemComposant::position_borne(int index) const {
    if (!modele_ || index < 0 || index >= nb_bornes()) return {};
    return mapToScene(vers_qt(modele_->bornes[index].position));
}

int ItemComposant::borne_proche(const QPointF& point, double rayon) const {
    int meilleur = -1;
    double distance_min = rayon;
    for (int k = 0; k < nb_bornes(); ++k) {
        const QPointF delta = position_borne(k) - point;
        const double distance = std::hypot(delta.x(), delta.y());
        if (distance <= distance_min) {
            distance_min = distance;
            meilleur = k;
        }
    }
    return meilleur;
}

void ItemComposant::tourner() {
    setRotation(std::fmod(rotation() + 90.0, 360.0));
}

void ItemComposant::definir_eclat_segment(const std::string& suffixe,
                                          double eclat) {
    double& memoire = eclats_segments_[suffixe];
    if (std::fabs(eclat - memoire) < 0.01) return;
    memoire = eclat;
    update();
}

double ItemComposant::eclat_segment(const std::string& suffixe) const {
    auto it = eclats_segments_.find(suffixe);
    return it == eclats_segments_.end() ? 0.0 : it->second;
}

void ItemComposant::definir_eclat(double eclat) {
    eclat = std::max(0.0, std::min(1.0, eclat));
    if (std::fabs(eclat - eclat_) < 0.01) return;
    eclat_ = eclat;
    update();
}

void ItemComposant::definir_grille(bool grille) {
    if (grille_ == grille) return;
    grille_ = grille;
    update();
}

void ItemComposant::definir_bornes_allumees(std::vector<int> bornes) {
    if (bornes_allumees_ == bornes) return;
    bornes_allumees_ = std::move(bornes);
    update();
}

void ItemComposant::definir_anomalies(std::vector<MarqueurErc> marqueurs) {
    if (anomalies_ == marqueurs) return;
    anomalies_ = std::move(marqueurs);
    update();
}

void ItemComposant::definir_mesure(const QString& mesure) {
    if (mesure_ == mesure) return;
    mesure_ = mesure;
    update();
}

QString ItemComposant::etiquette() const {
    if (!modele_ || modele_->proprietes.empty()) return {};
    const auto& p = modele_->proprietes.front();
    if (p.genre == coeur::Propriete::Genre::Choix) {
        auto it = textes.find(p.cle);
        return it == textes.end() ? QString()
                                  : QString::fromStdString(it->second);
    }
    auto it = valeurs.find(p.cle);
    if (it == valeurs.end()) return {};
    double v = it->second;
    QString unite = QString::fromStdString(p.unite);
    if (unite == "Ω") {
        if (v >= 1e6) return QString("%1 MΩ").arg(v / 1e6, 0, 'g', 3);
        if (v >= 1e3) return QString("%1 kΩ").arg(v / 1e3, 0, 'g', 3);
        return QString("%1 Ω").arg(v, 0, 'g', 3);
    }
    if (unite == "F") {
        if (v >= 1e-6) return QString("%1 µF").arg(v * 1e6, 0, 'g', 3);
        if (v >= 1e-9) return QString("%1 nF").arg(v * 1e9, 0, 'g', 3);
        return QString("%1 pF").arg(v * 1e12, 0, 'g', 3);
    }
    return QString("%1 %2").arg(v, 0, 'g', 3).arg(unite);
}

void ItemComposant::paint(QPainter* peintre,
                          const QStyleOptionGraphicsItem* option, QWidget*) {
    if (!modele_) return;
    peintre->setRenderHint(QPainter::Antialiasing, true);

    const bool selectionne = option->state & QStyle::State_Selected;
    const QColor trait_couleur = selectionne ? QColor(0, 120, 215)
                                             : QColor(25, 25, 30);
    QPen crayon(trait_couleur, selectionne ? 2.4 : 1.8);
    crayon.setJoinStyle(Qt::RoundJoin);
    crayon.setCapStyle(Qt::RoundCap);

    // Halo lumineux : rendu du courant réellement calculé par ngspice.
    if (modele_->lumineux && eclat_ > 0.02 && !grille_) {
        auto it = textes.find("couleur");
        const QColor lumiere =
            couleur_lumiere(it == textes.end() ? "rouge" : it->second);
        for (int couche = 3; couche >= 1; --couche) {
            QColor c = lumiere;
            c.setAlphaF(0.10 * eclat_ * couche);
            peintre->setPen(Qt::NoPen);
            peintre->setBrush(c);
            peintre->drawEllipse(QPointF(0, 0), 10.0 * couche, 10.0 * couche);
        }
    }

    QColor corps = couleur_de(modele_->couleur_corps, QColor(200, 200, 200));
    // Grillé : le corps prend la couleur du composant brûlé, et n'obéit plus
    // au courant — il ne s'allumera plus.
    if (grille_) corps = QColor(58, 44, 40);

    for (const auto& trait : modele_->symbole) {
        peintre->setPen(crayon);
        QColor remplissage = corps;
        // UN SEGMENT ALLUMÉ SE VOIT, ÉTEINT IL RESTE VISIBLE MAIS TERNE.
        //
        // Éteint, il ne disparaît pas : un afficheur dont les segments
        // éteints s'effacent ne se lit plus comme un afficheur, et l'élève ne
        // peut pas anticiper le chiffre qu'il obtiendra. C'est ce que fait un
        // vrai afficheur, dont on devine les segments morts.
        if (!trait.lumiere.empty() && !grille_) {
            const double eclat = eclat_segment(trait.lumiere);
            auto couleur = textes.find("couleur");
            const QColor vive =
                couleur_lumiere(couleur == textes.end() ? "rouge"
                                                        : couleur->second);
            QPen crayon_segment(
                eclat > 0.02 ? vive : QColor(206, 200, 198),
                eclat > 0.02 ? 5.0 : 3.5);
            crayon_segment.setCapStyle(Qt::RoundCap);
            peintre->setPen(crayon_segment);
        } else if (modele_->lumineux && !grille_) {
            // le corps s'éclaire proportionnellement au courant
            auto it = textes.find("couleur");
            const QColor lumiere =
                couleur_lumiere(it == textes.end() ? "rouge" : it->second);
            remplissage = QColor(
                static_cast<int>(corps.red() + (255 - corps.red()) * eclat_),
                static_cast<int>(corps.green() +
                                 (lumiere.green() - corps.green()) * eclat_),
                static_cast<int>(corps.blue() +
                                 (lumiere.blue() - corps.blue()) * eclat_));
        }
        peintre->setBrush(trait.rempli ? QBrush(remplissage) : Qt::NoBrush);

        switch (trait.genre) {
            case coeur::TraitSymbole::Genre::Ligne:
                if (trait.points.size() >= 2)
                    peintre->drawLine(vers_qt(trait.points[0]),
                                      vers_qt(trait.points[1]));
                break;
            case coeur::TraitSymbole::Genre::Rect:
                if (trait.points.size() >= 2)
                    peintre->drawRect(
                        QRectF(vers_qt(trait.points[0]),
                               vers_qt(trait.points[1]))
                            .normalized());
                break;
            case coeur::TraitSymbole::Genre::Cercle:
                if (!trait.points.empty())
                    peintre->drawEllipse(vers_qt(trait.points[0]), trait.mesure,
                                         trait.mesure);
                break;
            case coeur::TraitSymbole::Genre::Polygone: {
                QPolygonF polygone;
                for (const auto& point : trait.points)
                    polygone << vers_qt(point);
                peintre->drawPolygon(polygone);
                break;
            }
            case coeur::TraitSymbole::Genre::Texte: {
                QFont police = peintre->font();
                police.setPointSizeF(trait.mesure > 0 ? trait.mesure : 9.0);
                peintre->setFont(police);
                peintre->setPen(QPen(trait_couleur, 1));
                if (!trait.points.empty())
                    peintre->drawText(vers_qt(trait.points[0]),
                                      QString::fromStdString(trait.texte));
                break;
            }
        }
    }

    // Grillé : une croix par-dessus le symbole. Elle se lit d'un coup d'œil,
    // à n'importe quel niveau de zoom, et sur n'importe quel composant — c'est
    // ce qu'on veut d'un montage qui a fumé.
    if (grille_) {
        const QRectF croix = cadre_.adjusted(4, 4, -4, -4);
        peintre->setBrush(Qt::NoBrush);
        peintre->setPen(QPen(QColor(190, 30, 25), 2.6, Qt::SolidLine,
                             Qt::RoundCap));
        peintre->drawLine(croix.topLeft(), croix.bottomRight());
        peintre->drawLine(croix.topRight(), croix.bottomLeft());
    }

    // Le halo des bornes du nœud survolé, sous les disques de borne.
    if (!bornes_allumees_.empty()) {
        peintre->setPen(Qt::NoPen);
        peintre->setBrush(QColor(255, 233, 168));
        for (int index : bornes_allumees_) {
            if (index < 0 || index >= static_cast<int>(modele_->bornes.size()))
                continue;
            peintre->drawEllipse(vers_qt(modele_->bornes[index].position), 7.5,
                                 7.5);
        }
    }

    // Bornes : un petit disque, repère visuel pour tirer un fil.
    peintre->setPen(QPen(QColor(200, 60, 30), 1.2));
    peintre->setBrush(QColor(255, 245, 235));
    for (const auto& borne : modele_->bornes)
        peintre->drawEllipse(vers_qt(borne.position), 3.0, 3.0);

    // Référence et valeur, redressées pour rester lisibles après rotation.
    peintre->save();
    peintre->rotate(-rotation());
    QFont police = peintre->font();
    police.setPointSizeF(9.0);
    police.setBold(true);
    peintre->setFont(police);
    peintre->setPen(QPen(QColor(20, 90, 160), 1));
    peintre->drawText(QRectF(-70, cadre_.top() - 2, 140, 16),
                      Qt::AlignHCenter | Qt::AlignVCenter, reference_);
    police.setBold(false);
    peintre->setFont(police);
    peintre->setPen(QPen(QColor(70, 70, 70), 1));
    // L'étiquette est le réglage du composant, la mesure est ce qu'il fait.
    // Sur un servomoteur, l'angle est les deux à la fois : l'afficher deux
    // fois n'apprend rien et fait douter de ce qu'on lit.
    if (etiquette() != mesure_)
        peintre->drawText(QRectF(-70, cadre_.bottom() - 18, 140, 16),
                          Qt::AlignHCenter | Qt::AlignVCenter, etiquette());
    if (!mesure_.isEmpty()) {
        police.setBold(true);
        peintre->setFont(police);
        peintre->setPen(QPen(QColor(180, 83, 9), 1));
        peintre->drawText(QRectF(-90, cadre_.bottom() - 2, 180, 16),
                          Qt::AlignHCenter | Qt::AlignVCenter, mesure_);
    }
    peintre->restore();

    dessiner_anomalies(peintre);
}

// Le marqueur ERC : un triangle d'avertissement POSÉ À CÔTÉ.
//
// Il ne touche ni au trait ni au remplissage du symbole. C'est la condition
// pour qu'il ne se confonde pas avec le noirci-barré du composant grillé, qui
// dit tout autre chose : l'un signale un schéma incomplet, l'autre un
// composant détruit par le courant qu'on lui a fait passer.
void ItemComposant::dessiner_anomalies(QPainter* peintre) const {
    if (anomalies_.empty() || !modele_) return;

    for (const MarqueurErc& marqueur : anomalies_) {
        // Où poser le marqueur : à côté de la borne visée, sinon au coin du
        // symbole. « À côté » veut dire vers l'extérieur — un marqueur posé
        // vers le centre recouvrirait le symbole qu'il commente.
        QPointF point;
        if (marqueur.borne >= 0
            && marqueur.borne < static_cast<int>(modele_->bornes.size())) {
            const QPointF borne = vers_qt(modele_->bornes[marqueur.borne].position);
            const double norme = std::hypot(borne.x(), borne.y());
            const QPointF sortant =
                norme > 1e-6 ? borne / norme : QPointF(0, -1);
            point = borne + sortant * 13.0;
        } else {
            point = QPointF(cadre_.right() - 6, cadre_.top() + 10);
        }

        // Redressé : le triangle et son point d'exclamation restent lisibles
        // quel que soit le quart de tour subi par le composant. Le point de
        // pose, lui, a tourné avec le symbole — d'où la rotation directe
        // appliquée à ses coordonnées avant d'annuler celle du peintre.
        peintre->save();
        peintre->rotate(-rotation());
        QPointF ancre = QTransform().rotate(rotation()).map(point);

        // Le marqueur ne se pose JAMAIS sur la référence.
        //
        // Elle s'écrit en bandeau au-dessus du symbole, centrée. Une borne
        // située en haut au centre — le curseur d'un potentiomètre est à
        // (0, −25) — y projetait son triangle en plein milieu du texte : on
        // lisait « P⚠T1 ». Le test se fait ICI, dans le repère redressé, qui
        // est celui où la référence est écrite ; le faire avant la rotation
        // le rendrait faux dès qu'on pivote le composant.
        const QRectF bandeau(-70, cadre_.top() - 2, 140, 16);
        const QRectF boite(ancre.x() - 7, ancre.y() - 8, 14, 14);
        if (boite.intersects(bandeau)) {
            // Sous le bandeau, et décalé du côté où il y a de la place.
            ancre.setY(bandeau.bottom() + 9);
            ancre.setX(ancre.x() + (ancre.x() >= 0 ? 15.0 : -15.0));
        }

        const QColor teinte = marqueur.erreur ? QColor(198, 40, 40)
                                              : QColor(230, 145, 20);
        QPolygonF triangle;
        triangle << ancre + QPointF(0, -7) << ancre + QPointF(6.5, 4.5)
                 << ancre + QPointF(-6.5, 4.5);
        peintre->setPen(QPen(teinte.darker(130), 1.2, Qt::SolidLine,
                             Qt::RoundCap, Qt::RoundJoin));
        peintre->setBrush(marqueur.erreur ? QColor(255, 226, 226)
                                          : QColor(255, 243, 214));
        peintre->drawPolygon(triangle);

        QFont police = peintre->font();
        police.setPointSizeF(7.0);
        police.setBold(true);
        peintre->setFont(police);
        peintre->setPen(QPen(teinte, 1));
        peintre->drawText(QRectF(ancre.x() - 6, ancre.y() - 5.5, 12, 11),
                          Qt::AlignCenter, "!");
        peintre->restore();
    }
}
