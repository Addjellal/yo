// ToileSimulink.cpp — la toile de l'éditeur Simulink.
#include "ToileSimulink.h"

#include <QDragEnterEvent>
#include <QDropEvent>
#include <QKeyEvent>
#include <QKeySequence>
#include <QMimeData>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QResizeEvent>
#include <QWheelEvent>
#include <algorithm>
#include <cmath>

namespace {

const QColor kTrait(0x26, 0x26, 0x26);
const QColor kChoix(0x00, 0x72, 0xbd);
const QColor kGrille(0xe8, 0xe8, 0xe8);

// La largeur en unités du schéma qu'occupe la zone sensible d'un port de
// sortie : au-delà du bord droit du bloc, on tire un fil plutôt que de
// déplacer le bloc.
const double kZonePort = 0.22;

}  // namespace

ToileSimulink::ToileSimulink(QWidget* parent) : QWidget(parent) {
    setFocusPolicy(Qt::StrongFocus);
    setMouseTracking(true);
    setAcceptDrops(true);
    setAutoFillBackground(true);
    QPalette fond = palette();
    fond.setColor(QPalette::Window, Qt::white);
    setPalette(fond);
}

int ToileSimulink::nombreEntrees(const QString& type, const QString& signes) {
    if (type == QLatin1String("sum")) return qMax(1, signes.size());
    if (type == QLatin1String("switch")) return 3;
    if (type == QLatin1String("product") || type == QLatin1String("minmax") ||
        type == QLatin1String("logic") || type == QLatin1String("relational"))
        return 2;
    // Les sources n'ont pas d'entrée : un fil ne s'y raccroche pas.
    if (type == QLatin1String("constant") || type == QLatin1String("step") ||
        type == QLatin1String("ramp") || type == QLatin1String("sine") ||
        type == QLatin1String("inport") || type == QLatin1String("fromworkspace"))
        return 0;
    return 1;
}

void ToileSimulink::definirSchema(const SchemaSimulink& schema) {
    const bool memeModele = (schema.nom == modele_);
    modele_ = schema.nom;
    hauteurType_ = schema.hauteurType > 0 ? schema.hauteurType : 1.0;
    const QStringList choisisAvant = blocsChoisis();
    blocs_.clear();
    liens_.clear();
    for (const BlocSchema& b : schema.blocs) {
        BlocToile t;
        t.nom = b.nom;
        t.type = b.type;
        t.etiquette = b.etiquette;
        t.signes = b.signes;
        t.cadre = QRectF(QPointF(b.gauche, b.haut), QPointF(b.droite, b.bas));
        blocs_.push_back(t);
    }
    for (const LienSchema& l : schema.liens) {
        LienToile t;
        t.source = l.source;
        t.cible = l.cible;
        t.port = l.port;
        t.retour = l.retour;
        liens_.push_back(t);
    }
    // Le choix survit à une remise à jour du même modèle : sans cela,
    // ajouter un bloc à la console ferait perdre ce qu'on tenait.
    choisis_.clear();
    if (memeModele && !choisisAvant.isEmpty())
        for (int k = 0; k < blocs_.size(); ++k)
            if (choisisAvant.contains(blocs_[k].nom)) choisis_.push_back(k);
    lienChoisi_ = -1;
    if (!memeModele) ajusterVue();
    update();
    annoncerChoix();
}

void ToileSimulink::vider() {
    modele_.clear();
    blocs_.clear();
    liens_.clear();
    choisis_.clear();
    lienChoisi_ = -1;
    update();
}

QString ToileSimulink::blocChoisi() const {
    if (choisis_.isEmpty()) return QString();
    const int k = choisis_.first();
    return (k >= 0 && k < blocs_.size()) ? blocs_[k].nom : QString();
}

QStringList ToileSimulink::blocsChoisis() const {
    QStringList noms;
    for (int k : choisis_)
        if (k >= 0 && k < blocs_.size()) noms << blocs_[k].nom;
    return noms;
}

void ToileSimulink::annoncerChoix() {
    emit choixChange();
    if (choisis_.size() > 1) {
        emit etatChange(QStringLiteral("%1 blocs choisis. Les déplacer les déplace "
                                       "tous ; « Suppr » les enlève tous.")
                            .arg(choisis_.size()));
    } else if (choisis_.size() == 1) {
        const BlocToile& b = blocs_[choisis_.first()];
        emit etatChange(QStringLiteral("%1 — %2. Tirez son bord droit pour "
                                       "cabler, « Suppr » pour l'enlever, "
                                       "double-cliquez pour le régler.")
                            .arg(b.nom, b.type));
    } else if (lienChoisi_ >= 0) {
        emit etatChange(QStringLiteral("Lien choisi. « Suppr » l'enlève."));
    }
}

// --- la vue ---------------------------------------------------------------

QPointF ToileSimulink::versEcran(const QPointF& point) const {
    return QPointF((point.x() - origine_.x()) * echelle_,
                   (point.y() - origine_.y()) * echelle_);
}

QPointF ToileSimulink::versSchema(const QPointF& point) const {
    return QPointF(point.x() / echelle_ + origine_.x(),
                   point.y() / echelle_ + origine_.y());
}

QRectF ToileSimulink::cadreEcran(const QRectF& cadre) const {
    return QRectF(versEcran(cadre.topLeft()), versEcran(cadre.bottomRight()));
}

QRectF ToileSimulink::cadreEcranDe(const QString& nom) const {
    for (const BlocToile& b : blocs_)
        if (b.nom == nom) return cadreEcran(b.cadre);
    return QRectF();
}

void ToileSimulink::ajusterVue() {
    if (blocs_.isEmpty()) {
        echelle_ = 40.0;
        origine_ = QPointF(-width() / 80.0, -height() / 80.0);
        return;
    }
    QRectF etendue = blocs_[0].cadre;
    for (const BlocToile& b : blocs_) etendue = etendue.united(b.cadre);
    // De la place sous le schéma pour les contre-réactions, et autour
    // pour les noms de blocs.
    int retours = 0;
    for (const LienToile& l : liens_)
        if (l.retour) ++retours;
    etendue.adjust(-1.2, -0.8, 1.2, hauteurType_ * (1.6 + 0.7 * qMax(0, retours - 1)));
    const double disponibleL = qMax(40, width() - 20);
    const double disponibleH = qMax(40, height() - 20);
    echelle_ = qMin(disponibleL / etendue.width(), disponibleH / etendue.height());
    echelle_ = qBound(6.0, echelle_, 90.0);
    origine_ = QPointF(etendue.center().x() - width() / (2 * echelle_),
                       etendue.center().y() - height() / (2 * echelle_));
}

void ToileSimulink::zoomer(double facteur) {
    const QPointF centre = versSchema(QPointF(width() / 2.0, height() / 2.0));
    echelle_ = qBound(6.0, echelle_ * facteur, 200.0);
    origine_ = QPointF(centre.x() - width() / (2 * echelle_),
                       centre.y() - height() / (2 * echelle_));
    update();
}

void ToileSimulink::resizeEvent(QResizeEvent* evenement) {
    QWidget::resizeEvent(evenement);
    ajusterVue();
}

void ToileSimulink::wheelEvent(QWheelEvent* evenement) {
    if (evenement->angleDelta().y() == 0) return;
    zoomer(evenement->angleDelta().y() > 0 ? 1.15 : 1 / 1.15);
    evenement->accept();
}

// --- la peinture ----------------------------------------------------------

// L'allure de ce que produit un bloc, dessinée dans son cadre. C'est la
// même que celle du tracé : un dessin dit d'un coup ce qu'un nom demande
// de lire, et la toile ne doit pas montrer autre chose que la figure.
static bool dessinerAllure(QPainter& peintre, const QString& type, const QRectF& r) {
    const double a = r.width() * 0.32, b = r.height() * 0.28;
    const double x = r.center().x(), y = r.center().y();
    auto ligne = [&](std::initializer_list<QPointF> points) {
        QPainterPath chemin;
        bool premier = true;
        for (const QPointF& p : points) {
            if (premier) chemin.moveTo(p);
            else chemin.lineTo(p);
            premier = false;
        }
        peintre.drawPath(chemin);
    };
    // L'ordonnée descend à l'écran : un signal qui monte s'y dessine vers
    // le haut, donc vers les y décroissants.
    if (type == QLatin1String("step")) {
        ligne({{x - a, y + b}, {x, y + b}, {x, y - b}, {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("ramp")) {
        ligne({{x - a, y + b}, {x, y + b}, {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("sine")) {
        QPainterPath chemin;
        for (int k = 0; k <= 40; ++k) {
            const double t = -M_PI + 2 * M_PI * k / 40.0;
            const QPointF p(x + a * t / M_PI, y - b * std::sin(t));
            if (k == 0) chemin.moveTo(p);
            else chemin.lineTo(p);
        }
        peintre.drawPath(chemin);
        return true;
    }
    if (type == QLatin1String("saturation")) {
        ligne({{x - a, y + b}, {x - a / 2, y + b}, {x + a / 2, y - b}, {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("relay")) {
        ligne({{x - a, y + b}, {x, y + b}, {x, y - b}, {x + a, y - b}});
        ligne({{x - a, y - b}, {x - a / 3, y - b}, {x - a / 3, y + b}});
        return true;
    }
    if (type == QLatin1String("deadzone")) {
        ligne({{x - a, y + b}, {x - a / 3, y}, {x + a / 3, y}, {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("quantizer")) {
        ligne({{x - a, y + b}, {x - a / 3, y + b}, {x - a / 3, y},
               {x + a / 3, y}, {x + a / 3, y - b}, {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("sign")) {
        ligne({{x - a, y + b}, {x - a / 8, y + b}, {x - a / 8, y},
               {x + a / 8, y}, {x + a / 8, y - b}, {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("ratelimiter")) {
        ligne({{x - a, y + b}, {x, y - b}, {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("zoh")) {
        ligne({{x - a, y + b}, {x - a / 3, y + b}, {x - a / 3, y - b / 2},
               {x + a / 3, y - b / 2}, {x + a / 3, y + b / 2}, {x + a, y + b / 2}});
        return true;
    }
    if (type == QLatin1String("lookup")) {
        ligne({{x - a, y + b}, {x - a / 3, y - b / 3}, {x + a / 4, y + b / 4},
               {x + a, y - b}});
        return true;
    }
    if (type == QLatin1String("scope")) {
        ligne({{x - a, y - b}, {x - a, y + b}, {x + a, y + b}});
        QPainterPath courbe;
        for (int k = 0; k <= 20; ++k) {
            const double t = k / 20.0;
            const QPointF p(x - a + 2 * a * t, y + b - 1.6 * b * t * t);
            if (k == 0) courbe.moveTo(p);
            else courbe.lineTo(p);
        }
        peintre.drawPath(courbe);
        return true;
    }
    return false;
}

void ToileSimulink::dessinerBloc(QPainter& peintre, const BlocToile& bloc,
                                 bool choisi) const {
    const QRectF r = cadreEcran(bloc.cadre);
    peintre.setBrush(Qt::white);
    peintre.setPen(QPen(choisi ? kChoix : kTrait, choisi ? 2.0 : 1.2));

    if (bloc.type == QLatin1String("gain")) {
        QPainterPath triangle;
        triangle.moveTo(r.left(), r.top());
        triangle.lineTo(r.right(), r.center().y());
        triangle.lineTo(r.left(), r.bottom());
        triangle.closeSubpath();
        peintre.drawPath(triangle);
        peintre.setPen(kTrait);
        peintre.drawText(QRectF(r.left(), r.top(), r.width() * 0.7, r.height()),
                         Qt::AlignCenter, bloc.etiquette);
    } else if (bloc.type == QLatin1String("sum")) {
        peintre.drawEllipse(r);
        peintre.setPen(kTrait);
        const QString signes = bloc.signes.isEmpty() ? QStringLiteral("++") : bloc.signes;
        for (int k = 0; k < signes.size(); ++k) {
            const double part =
                signes.size() == 1 ? 0.5 : double(k) / (signes.size() - 1);
            const double y = r.top() + r.height() * (0.26 + 0.48 * part);
            peintre.drawText(QRectF(r.left() + r.width() * 0.10, y - 8,
                                    r.width() * 0.42, 16),
                             Qt::AlignCenter, signes.mid(k, 1));
        }
    } else if (bloc.type == QLatin1String("inport") ||
               bloc.type == QLatin1String("outport")) {
        const double pointe = r.width() * 0.22;
        QPainterPath pentagone;
        if (bloc.type == QLatin1String("inport")) {
            pentagone.moveTo(r.left(), r.top());
            pentagone.lineTo(r.right() - pointe, r.top());
            pentagone.lineTo(r.right(), r.center().y());
            pentagone.lineTo(r.right() - pointe, r.bottom());
            pentagone.lineTo(r.left(), r.bottom());
        } else {
            pentagone.moveTo(r.left() + pointe, r.top());
            pentagone.lineTo(r.right(), r.top());
            pentagone.lineTo(r.right(), r.bottom());
            pentagone.lineTo(r.left() + pointe, r.bottom());
            pentagone.lineTo(r.left(), r.center().y());
        }
        pentagone.closeSubpath();
        peintre.drawPath(pentagone);
        peintre.setPen(kTrait);
        peintre.drawText(r, Qt::AlignCenter, bloc.etiquette);
    } else {
        peintre.drawRect(r);
        peintre.setPen(kTrait);
        if (!dessinerAllure(peintre, bloc.type, r))
            peintre.drawText(r, Qt::AlignCenter, bloc.etiquette);
    }

    // Le nom va dessous, hors du cadre : c'est là que Simulink le met, et
    // cela laisse l'intérieur à ce que le bloc calcule.
    peintre.setPen(kTrait);
    peintre.drawText(QRectF(r.left() - 40, r.bottom() + 2, r.width() + 80, 16),
                     Qt::AlignHCenter | Qt::AlignTop, bloc.nom);
}

QPointF ToileSimulink::pointSortie(int bloc) const {
    const QRectF r = blocs_[bloc].cadre;
    return QPointF(r.right(), r.center().y());
}

QPointF ToileSimulink::pointEntree(int bloc, int port) const {
    const BlocToile& b = blocs_[bloc];
    const int entrees = nombreEntrees(b.type, b.signes);
    const QRectF r = b.cadre;
    if (entrees <= 1) return QPointF(r.left(), r.center().y());
    const int rang = qBound(1, port, entrees);
    // Les entrées se répartissent sur le bord gauche, dans l'ordre :
    // sans cela, deux liaisons arriveraient au même point et l'on ne
    // saurait plus laquelle est laquelle.
    const double part = double(rang - 1) / (entrees - 1);
    return QPointF(r.left(), r.top() + r.height() * (0.22 + 0.56 * part));
}

void ToileSimulink::dessinerFil(QPainter& peintre, const LienToile& lien,
                                double basRetour) const {
    if (lien.source < 1 || lien.source > blocs_.size()) return;
    if (lien.cible < 1 || lien.cible > blocs_.size()) return;
    const QPointF depart = pointSortie(lien.source - 1);
    const QPointF arrivee = pointEntree(lien.cible - 1, lien.port);
    const double marge = 0.45;
    QVector<QPointF> points;
    const bool devant = arrivee.x() - marge >= depart.x() + marge;
    if (lien.retour || !devant) {
        points = {depart,
                  {depart.x() + marge, depart.y()},
                  {depart.x() + marge, basRetour},
                  {arrivee.x() - marge, basRetour},
                  {arrivee.x() - marge, arrivee.y()},
                  arrivee};
    } else if (std::fabs(depart.y() - arrivee.y()) < 1e-9) {
        points = {depart, arrivee};
    } else {
        const double milieu = (depart.x() + arrivee.x()) / 2;
        points = {depart, {milieu, depart.y()}, {milieu, arrivee.y()}, arrivee};
    }
    QPainterPath chemin;
    chemin.moveTo(versEcran(points[0]));
    for (int k = 1; k < points.size(); ++k) chemin.lineTo(versEcran(points[k]));
    peintre.drawPath(chemin);

    // La pointe, qui dit le sens : sans elle un schéma ne dit pas où va
    // l'information, et c'est précisément ce qu'il sert à dire.
    const QPointF bout = versEcran(arrivee);
    const double longueur = qMax(5.0, 0.22 * echelle_);
    const double demi = longueur / 2;
    QPainterPath pointe;
    pointe.moveTo(bout);
    pointe.lineTo(bout.x() - longueur, bout.y() - demi);
    pointe.lineTo(bout.x() - longueur, bout.y() + demi);
    pointe.closeSubpath();
    const QBrush ancien = peintre.brush();
    peintre.setBrush(peintre.pen().color());
    peintre.drawPath(pointe);
    peintre.setBrush(ancien);
}

void ToileSimulink::paintEvent(QPaintEvent*) {
    QPainter peintre(this);
    peintre.setRenderHint(QPainter::Antialiasing, true);
    peintre.fillRect(rect(), Qt::white);

    // Une grille légère, comme la feuille de Simulink : elle donne l'échelle
    // et rend visible qu'on est sur une surface de travail, non sur une
    // image.
    const double pas = echelle_;
    if (pas > 12) {
        peintre.setPen(QPen(kGrille, 1.0));
        const double x0 = -std::fmod(origine_.x() * echelle_, pas);
        const double y0 = -std::fmod(origine_.y() * echelle_, pas);
        for (double x = x0; x < width(); x += pas)
            peintre.drawLine(QPointF(x, 0), QPointF(x, height()));
        for (double y = y0; y < height(); y += pas)
            peintre.drawLine(QPointF(0, y), QPointF(width(), y));
    }

    if (blocs_.isEmpty()) {
        peintre.setPen(QColor(0x80, 0x80, 0x80));
        peintre.drawText(rect(), Qt::AlignCenter,
                         modele_.isEmpty()
                             ? QStringLiteral("Aucun modèle choisi.")
                             : QStringLiteral("« %1 » ne porte encore aucun bloc.\n"
                                              "Glissez-en un depuis la bibliothèque.")
                                   .arg(modele_));
        return;
    }

    // Le couloir des contre-réactions : sous le plus bas des blocs.
    double basRetour = blocs_[0].cadre.bottom();
    for (const BlocToile& b : blocs_) basRetour = qMax(basRetour, b.cadre.bottom());
    basRetour += hauteurType_ * 1.4;

    peintre.setPen(QPen(kTrait, 1.2));
    peintre.setBrush(Qt::NoBrush);
    for (int k = 0; k < liens_.size(); ++k) {
        peintre.setPen(QPen(k == lienChoisi_ ? kChoix : kTrait,
                            k == lienChoisi_ ? 2.2 : 1.2));
        dessinerFil(peintre, liens_[k], basRetour);
    }
    for (int k = 0; k < blocs_.size(); ++k)
        dessinerBloc(peintre, blocs_[k], choisis_.contains(k));

    // Le rectangle qu'on trace pour choisir plusieurs blocs d'un coup.
    if (elastique_) {
        peintre.setPen(QPen(kChoix, 1.0, Qt::DashLine));
        QColor voile = kChoix;
        voile.setAlphaF(0.10);
        peintre.setBrush(voile);
        peintre.drawRect(QRectF(elastiqueDe_, elastiqueA_).normalized());
        peintre.setBrush(Qt::NoBrush);
    }

    // Le fil qu'on est en train de tirer.
    if (filDepuis_ >= 0) {
        peintre.setPen(QPen(kChoix, 1.6, Qt::DashLine));
        peintre.drawLine(versEcran(pointSortie(filDepuis_)), filVers_);
    }
}

// --- les gestes -----------------------------------------------------------

int ToileSimulink::blocSous(const QPointF& ecran) const {
    // Du dernier au premier : celui qui est dessiné par-dessus l'emporte.
    for (int k = blocs_.size() - 1; k >= 0; --k)
        if (cadreEcran(blocs_[k].cadre).contains(ecran)) return k;
    return -1;
}

int ToileSimulink::lienSous(const QPointF& ecran) const {
    double basRetour = 0;
    for (const BlocToile& b : blocs_) basRetour = qMax(basRetour, b.cadre.bottom());
    basRetour += hauteurType_ * 1.4;
    const QPointF schema = versSchema(ecran);
    const double tolerance = 6.0 / echelle_;
    for (int k = 0; k < liens_.size(); ++k) {
        const LienToile& l = liens_[k];
        if (l.source < 1 || l.source > blocs_.size()) continue;
        if (l.cible < 1 || l.cible > blocs_.size()) continue;
        const QPointF depart = pointSortie(l.source - 1);
        const QPointF arrivee = pointEntree(l.cible - 1, l.port);
        const double marge = 0.45;
        QVector<QPointF> points;
        const bool devant = arrivee.x() - marge >= depart.x() + marge;
        if (l.retour || !devant) {
            points = {depart,
                      {depart.x() + marge, depart.y()},
                      {depart.x() + marge, basRetour},
                      {arrivee.x() - marge, basRetour},
                      {arrivee.x() - marge, arrivee.y()},
                      arrivee};
        } else {
            const double milieu = (depart.x() + arrivee.x()) / 2;
            points = {depart, {milieu, depart.y()}, {milieu, arrivee.y()}, arrivee};
        }
        for (int i = 1; i < points.size(); ++i) {
            const QPointF a = points[i - 1], b = points[i];
            // Les segments sont horizontaux ou verticaux : la distance se
            // mesure sans racine carrée.
            const bool dedansX = schema.x() >= qMin(a.x(), b.x()) - tolerance &&
                                 schema.x() <= qMax(a.x(), b.x()) + tolerance;
            const bool dedansY = schema.y() >= qMin(a.y(), b.y()) - tolerance &&
                                 schema.y() <= qMax(a.y(), b.y()) + tolerance;
            if (!dedansX || !dedansY) continue;
            const double ecart = std::fabs(a.x() - b.x()) < 1e-9
                                     ? std::fabs(schema.x() - a.x())
                                     : std::fabs(schema.y() - a.y());
            if (ecart <= tolerance) return k;
        }
    }
    return -1;
}

int ToileSimulink::portVise(int bloc, const QPointF& ecran) const {
    const BlocToile& b = blocs_[bloc];
    const int entrees = nombreEntrees(b.type, b.signes);
    if (entrees <= 1) return 1;
    const QRectF r = cadreEcran(b.cadre);
    if (r.height() <= 0) return 1;
    const double part = qBound(0.0, (ecran.y() - r.top()) / r.height(), 1.0);
    return qBound(1, int(part * entrees) + 1, entrees);
}

void ToileSimulink::mousePressEvent(QMouseEvent* evenement) {
    setFocus();
    const QPointF ecran = evenement->position();
    const int sous = blocSous(ecran);
    if (evenement->button() != Qt::LeftButton) {
        QWidget::mousePressEvent(evenement);
        return;
    }
    const bool ajoute = evenement->modifiers().testFlag(Qt::ControlModifier) ||
                        evenement->modifiers().testFlag(Qt::ShiftModifier);
    if (sous >= 0) {
        // Ctrl ou Maj ajoute au lot, comme partout ailleurs ; un clic nu
        // sur un bloc déjà du lot le garde, pour qu'on puisse déplacer
        // plusieurs blocs en en prenant un.
        if (ajoute) {
            if (choisis_.contains(sous)) choisis_.removeAll(sous);
            else choisis_.push_back(sous);
        } else if (!choisis_.contains(sous)) {
            choisis_ = {sous};
        }
        lienChoisi_ = -1;
        const QRectF r = cadreEcran(blocs_[sous].cadre);
        // Près du bord droit, on tire un fil ; ailleurs, on déplace le
        // bloc. C'est le geste de Simulink, et il évite un mode à choisir.
        if (!ajoute && ecran.x() >= r.right() - qMax(6.0, kZonePort * echelle_)) {
            filDepuis_ = sous;
            filVers_ = ecran;
            emit etatChange(QStringLiteral("Tirez jusqu'à l'entrée d'un bloc."));
        } else if (!ajoute) {
            saisi_ = sous;
            saisiDepart_ = versSchema(ecran);
            saisiCadres_.clear();
            for (int k : choisis_) saisiCadres_.push_back(blocs_[k].cadre);
            deplacementFait_ = false;
        }
        annoncerChoix();
        update();
        return;
    }
    if (!ajoute) choisis_.clear();
    lienChoisi_ = lienSous(ecran);
    if (lienChoisi_ < 0) {
        // Sur le vide : on trace un rectangle, et ce qu'il touche est pris.
        elastique_ = true;
        elastiqueDe_ = ecran;
        elastiqueA_ = ecran;
    }
    annoncerChoix();
    update();
}

void ToileSimulink::mouseMoveEvent(QMouseEvent* evenement) {
    const QPointF ecran = evenement->position();
    if (filDepuis_ >= 0) {
        filVers_ = ecran;
        update();
        return;
    }
    if (saisi_ >= 0) {
        const QPointF maintenant = versSchema(ecran);
        const QPointF ecart = maintenant - saisiDepart_;
        for (int i = 0; i < choisis_.size() && i < saisiCadres_.size(); ++i)
            blocs_[choisis_[i]].cadre = saisiCadres_[i].translated(ecart);
        deplacementFait_ = true;
        update();
        return;
    }
    if (elastique_) {
        elastiqueA_ = ecran;
        update();
        return;
    }
    // Le curseur dit ce qu'un clic ferait : c'est ce qui rend le bord
    // droit d'un bloc découvrable sans avoir à le lire quelque part.
    const int sous = blocSous(ecran);
    if (sous >= 0) {
        const QRectF r = cadreEcran(blocs_[sous].cadre);
        setCursor(ecran.x() >= r.right() - qMax(6.0, kZonePort * echelle_)
                      ? Qt::CrossCursor
                      : Qt::SizeAllCursor);
    } else {
        setCursor(Qt::ArrowCursor);
    }
    QWidget::mouseMoveEvent(evenement);
}

void ToileSimulink::mouseReleaseEvent(QMouseEvent* evenement) {
    const QPointF ecran = evenement->position();
    if (filDepuis_ >= 0) {
        const int cible = blocSous(ecran);
        const int depuis = filDepuis_;
        filDepuis_ = -1;
        update();
        if (cible < 0 || cible == depuis) {
            emit etatChange(QStringLiteral("Le fil n'aboutit nulle part."));
            return;
        }
        if (nombreEntrees(blocs_[cible].type, blocs_[cible].signes) == 0) {
            emit etatChange(QStringLiteral("« %1 » est une source : elle n'a pas "
                                           "d'entrée.").arg(blocs_[cible].nom));
            return;
        }
        emit lienDemande(blocs_[depuis].nom, blocs_[cible].nom,
                         portVise(cible, ecran));
        return;
    }
    if (saisi_ >= 0) {
        saisi_ = -1;
        if (deplacementFait_) {
            QStringList noms;
            QVector<QRectF> places;
            for (int k : choisis_) {
                noms << blocs_[k].nom;
                places << blocs_[k].cadre;
            }
            emit blocsDeplaces(noms, places);
        }
        deplacementFait_ = false;
        return;
    }
    if (elastique_) {
        elastique_ = false;
        const QRectF pris = QRectF(elastiqueDe_, elastiqueA_).normalized();
        // Un rectangle d'un pixel est un clic, non une sélection : sans
        // ce garde-fou, cliquer sur le vide prendrait ce qui est dessous.
        if (pris.width() > 3 && pris.height() > 3)
            for (int k = 0; k < blocs_.size(); ++k)
                if (pris.intersects(cadreEcran(blocs_[k].cadre)) &&
                    !choisis_.contains(k))
                    choisis_.push_back(k);
        std::sort(choisis_.begin(), choisis_.end());
        annoncerChoix();
        update();
        return;
    }
    QWidget::mouseReleaseEvent(evenement);
}

void ToileSimulink::mouseDoubleClickEvent(QMouseEvent* evenement) {
    const int sous = blocSous(evenement->position());
    if (sous >= 0) {
        choisis_ = {sous};
        update();
        emit blocOuvert(blocs_[sous].nom);
        return;
    }
    QWidget::mouseDoubleClickEvent(evenement);
}

void ToileSimulink::keyPressEvent(QKeyEvent* evenement) {
    if (evenement->matches(QKeySequence::Undo)) {
        emit annulationDemandee();
        return;
    }
    if (evenement->matches(QKeySequence::Redo)) {
        emit retablissementDemande();
        return;
    }
    if (evenement->matches(QKeySequence::SelectAll)) {
        choisis_.clear();
        for (int k = 0; k < blocs_.size(); ++k) choisis_.push_back(k);
        lienChoisi_ = -1;
        annoncerChoix();
        update();
        return;
    }
    if (evenement->key() == Qt::Key_Delete || evenement->key() == Qt::Key_Backspace) {
        if (!choisis_.isEmpty()) {
            emit blocsSupprimes(blocsChoisis());
            return;
        }
        if (lienChoisi_ >= 0 && lienChoisi_ < liens_.size()) {
            const LienToile& l = liens_[lienChoisi_];
            if (l.source >= 1 && l.source <= blocs_.size() && l.cible >= 1 &&
                l.cible <= blocs_.size())
                emit lienSupprime(blocs_[l.source - 1].nom, blocs_[l.cible - 1].nom,
                                  l.port);
            return;
        }
    }
    if (evenement->key() == Qt::Key_Escape) {
        choisis_.clear();
        lienChoisi_ = -1;
        filDepuis_ = -1;
        elastique_ = false;
        update();
        annoncerChoix();
        return;
    }
    QWidget::keyPressEvent(evenement);
}

void ToileSimulink::dragEnterEvent(QDragEnterEvent* evenement) {
    // Ce qui vient de la bibliothèque : Qt y met le texte de l'entrée.
    if (evenement->mimeData()->hasText() ||
        evenement->mimeData()->hasFormat(
            QStringLiteral("application/x-qabstractitemmodeldatalist")))
        evenement->acceptProposedAction();
}

void ToileSimulink::dropEvent(QDropEvent* evenement) {
    emit blocDepose(versSchema(evenement->position()));
    evenement->acceptProposedAction();
}
