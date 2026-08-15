#include "app/panels/PanneauPcb.h"

#include "core/pcb/Routeur.h"

#include "app/BarreDefilante.h"

#include <QApplication>
#include <QCheckBox>
#include <QComboBox>
#include <QDoubleSpinBox>
#include <QFileDialog>
#include <QFile>
#include <QFileInfo>
#include <QHBoxLayout>
#include <QKeyEvent>
#include <QLabel>
#include <QLinearGradient>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QVBoxLayout>
#include <QWheelEvent>

#include <algorithm>
#include <cmath>
#include <map>
#include <set>

namespace {

// Les couleurs d'un vrai circuit imprimé : vernis vert, cuivre étamé,
// sérigraphie blanche. On ne cherche pas la coquetterie — c'est ce code
// couleur qui rend une carte lisible d'un coup d'œil.
const QColor kFondAtelier("#15181d");
const QColor kVernis("#0f6b3c");
const QColor kVernisSombre("#0a4c2b");
const QColor kBordCarte("#d8e6c8");
const QColor kGrille("#1a8049");
const QColor kCuivrePastille("#e3b04b");
const QColor kCuivreClair("#f6d78c");
const QColor kSerigraphie("#eef4ee");
const QColor kPisteDessus("#d4523f");
const QColor kPisteDessous("#3b7bd8");
const QColor kChevelu("#a8d8bd");
const QColor kSurbrillance("#ffe9a8");

constexpr double kGrillePas = 2.54;     // le pas de tout ce qui se soude
constexpr double kAccrochage = 0.635;   // quart de pas : l'accroche du placement

double accrocher(double valeur) {
    return std::round(valeur / kAccrochage) * kAccrochage;
}

}  // namespace

// ---------------------------------------------------------------------------
// Vue
// ---------------------------------------------------------------------------
VuePcb::VuePcb(QWidget* parent) : QWidget(parent) {
    setMinimumHeight(150);
    setMouseTracking(true);
    setCursor(Qt::CrossCursor);
    setFocusPolicy(Qt::StrongFocus);
}

void VuePcb::definir_carte(coeur::CartePcb carte) {
    carte_ = std::move(carte);
    annoncer();
    update();
}

void VuePcb::definir_couche(int couche) {
    couche_ = couche;
    update();
}

void VuePcb::afficher_chevelu(bool actif) {
    chevelu_visible_ = actif;
    update();
}

void VuePcb::effacer_pistes() {
    carte_.pistes.clear();
    annoncer();
    update();
}

void VuePcb::defaire_piste() {
    if (carte_.pistes.empty()) return;
    carte_.pistes.pop_back();
    annoncer();
    update();
}

void VuePcb::recadrer() {
    zoom_ = 1.0;
    decalage_ = QPointF(0, 0);
    update();
}

void VuePcb::tourner_sous_curseur() {
    const std::string reference = composant_sous(curseur_);
    if (reference.empty()) return;
    if (coeur::ComposantPose* pose = carte_.trouver(reference)) {
        pose->rotation = std::fmod(pose->rotation + 90.0, 360.0);
        std::swap(pose->largeur, pose->hauteur);
        annoncer();
        update();
    }
}

double VuePcb::echelle() const {
    if (carte_.largeur <= 0 || carte_.hauteur <= 0) return 4.0 * zoom_;
    return std::min((width() - 24.0) / carte_.largeur,
                    (height() - 24.0) / carte_.hauteur) * zoom_;
}

QPointF VuePcb::vers_ecran(double x, double y) const {
    return QPointF(12 + decalage_.x() + x * echelle(),
                   12 + decalage_.y() + y * echelle());
}

QPointF VuePcb::vers_carte(const QPointF& ecran) const {
    const double k = echelle();
    return QPointF((ecran.x() - 12 - decalage_.x()) / k,
                   (ecran.y() - 12 - decalage_.y()) / k);
}

const coeur::PastillePosee* VuePcb::pastille_sous(
    const QPointF& position, std::vector<coeur::PastillePosee>& toutes) const {
    for (const coeur::PastillePosee& pastille : toutes) {
        if (pastille.numero == 0 && pastille.borne.empty())
            continue;    // trou de fixation : on ne s'y raccorde pas
        const double demi_x = pastille.diametre / 2 + 0.25;
        const double demi_y =
            (pastille.hauteur > 0 ? pastille.hauteur : pastille.diametre) / 2
            + 0.25;
        if (std::fabs(pastille.x - position.x()) <= demi_x
            && std::fabs(pastille.y - position.y()) <= demi_y)
            return &pastille;
    }
    return nullptr;
}

std::string VuePcb::composant_sous(const QPointF& position) const {
    for (const coeur::ComposantPose& pose : carte_.composants) {
        if (std::fabs(position.x() - pose.x) > pose.largeur / 2) continue;
        if (std::fabs(position.y() - pose.y) > pose.hauteur / 2) continue;
        return pose.reference;
    }
    return {};
}

void VuePcb::annoncer() {
    const std::vector<coeur::CartePcb::Liaison> liaisons = carte_.chevelu();
    int restantes = 0;
    for (const auto& liaison : liaisons)
        if (!liaison.routee) ++restantes;
    const std::vector<coeur::CartePcb::AnomaliePcb> anomalies =
        carte_.controler();
    const int pourcentage =
        liaisons.empty()
            ? 100
            : static_cast<int>(
                  std::lround(100.0 * (liaisons.size() - restantes)
                              / static_cast<double>(liaisons.size())));
    emit etat_change(
        QString("%1 × %2 mm · %3 composants · %4 liaisons dont %5 à router "
                "(%6 %) · %7 pistes · %8 anomalie(s)")
            .arg(carte_.largeur, 0, 'f', 1)
            .arg(carte_.hauteur, 0, 'f', 1)
            .arg(carte_.composants.size())
            .arg(liaisons.size())
            .arg(restantes)
            .arg(pourcentage)
            .arg(carte_.pistes.size())
            .arg(anomalies.size()));
}

// ---------------------------------------------------------------------------
// Dessin
// ---------------------------------------------------------------------------
void VuePcb::dessiner_substrat(QPainter& peintre) const {
    const double k = echelle();
    const QRectF carte(vers_ecran(0, 0),
                       vers_ecran(carte_.largeur, carte_.hauteur));

    QLinearGradient vernis(carte.topLeft(), carte.bottomRight());
    vernis.setColorAt(0.0, kVernis);
    vernis.setColorAt(1.0, kVernisSombre);
    QPainterPath contour;
    contour.addRoundedRect(carte, 3 * k, 3 * k);
    peintre.fillPath(contour, vernis);

    // La grille au pas de 2,54 mm : le repère de tout ce qui se pose sur une
    // carte. Effacée quand le zoom la rendrait illisible.
    if (k * kGrillePas > 7) {
        peintre.setPen(QPen(kGrille, 0.7));
        for (double x = 0; x <= carte_.largeur; x += kGrillePas)
            for (double y = 0; y <= carte_.hauteur; y += kGrillePas)
                peintre.drawPoint(vers_ecran(x, y));
    }
    peintre.setPen(QPen(kBordCarte, 1.4));
    peintre.setBrush(Qt::NoBrush);
    peintre.drawPath(contour);
}

void VuePcb::dessiner_serigraphie(QPainter& peintre) const {
    const double k = echelle();
    peintre.setBrush(Qt::NoBrush);
    QPen plume(kSerigraphie, std::max(1.0, 0.15 * k));
    plume.setJoinStyle(Qt::MiterJoin);

    for (const coeur::ComposantPose& pose : carte_.composants) {
        peintre.setPen(plume);
        for (const coeur::TraitEmpreinte& trait :
             coeur::serigraphie_absolue(pose)) {
            switch (trait.genre) {
                case coeur::TraitEmpreinte::Genre::Ligne:
                    peintre.drawLine(vers_ecran(trait.x1, trait.y1),
                                     vers_ecran(trait.x2, trait.y2));
                    break;
                case coeur::TraitEmpreinte::Genre::Rect:
                    peintre.drawRect(QRectF(vers_ecran(trait.x1, trait.y1),
                                            vers_ecran(trait.x2, trait.y2))
                                         .normalized());
                    break;
                case coeur::TraitEmpreinte::Genre::Cercle:
                    peintre.drawEllipse(vers_ecran(trait.x1, trait.y1),
                                        trait.x2 * k, trait.x2 * k);
                    break;
            }
        }

        // La référence, sérigraphiée au-dessus du boîtier comme sur une vraie
        // carte : c'est elle qu'on lit pour savoir où souder R3.
        const double taille = std::max(6.0, std::min(13.0, 1.5 * k));
        QFont fonte("sans", 0, QFont::DemiBold);
        fonte.setPixelSize(static_cast<int>(taille));
        peintre.setFont(fonte);
        peintre.setPen(kSerigraphie);
        const QPointF ancre = vers_ecran(pose.x, pose.y - pose.hauteur / 2);
        peintre.drawText(QRectF(ancre.x() - 60, ancre.y() - taille - 3, 120,
                                taille + 2),
                         Qt::AlignHCenter | Qt::AlignBottom,
                         QString::fromStdString(pose.reference));
    }
}

void VuePcb::dessiner_pastilles(QPainter& peintre) const {
    const double k = echelle();
    const std::string net_survole = [this] {
        std::vector<coeur::PastillePosee> toutes = carte_.pastilles();
        const coeur::PastillePosee* sous = pastille_sous(curseur_, toutes);
        return sous ? sous->net : std::string();
    }();

    for (const coeur::PastillePosee& pastille : carte_.pastilles()) {
        const QPointF centre = vers_ecran(pastille.x, pastille.y);
        const double large = pastille.diametre * k;
        const double haute =
            (pastille.hauteur > 0 ? pastille.hauteur : pastille.diametre) * k;
        const bool tournee =
            (static_cast<int>(std::lround(pastille.rotation / 90.0)) & 1) != 0;
        const QRectF cadre(centre.x() - (tournee ? haute : large) / 2,
                           centre.y() - (tournee ? large : haute) / 2,
                           tournee ? haute : large, tournee ? large : haute);

        // Un trou de fixation se perce, il ne se soude pas : pas de cuivre
        // autour, juste le cercle sérigraphié qui dit où passe la vis.
        if (pastille.mecanique()) {
            peintre.setBrush(kVernisSombre);
            peintre.setPen(QPen(kSerigraphie, std::max(1.0, 0.15 * k)));
            const double trou = pastille.percage / 2 * k;
            peintre.drawEllipse(centre, trou, trou);
            peintre.drawEllipse(centre, pastille.diametre / 2 * k,
                                pastille.diametre / 2 * k);
            continue;
        }

        const bool eclairee = !net_survole.empty() && pastille.net == net_survole;
        peintre.setPen(Qt::NoPen);
        peintre.setBrush(eclairee ? kSurbrillance : kCuivrePastille);
        switch (pastille.forme) {
            case coeur::Pastille::Forme::Rectangulaire:
                peintre.drawRect(cadre);
                break;
            case coeur::Pastille::Forme::Oblongue:
                peintre.drawRoundedRect(cadre, cadre.width() / 2,
                                        cadre.height() / 2);
                break;
            case coeur::Pastille::Forme::Ronde:
                peintre.drawEllipse(cadre);
                break;
        }
        // Le liseré clair : le cuivre d'une pastille étamée accroche la
        // lumière sur son pourtour.
        if (k > 3) {
            peintre.setPen(QPen(kCuivreClair, 1.0));
            peintre.setBrush(Qt::NoBrush);
            if (pastille.forme == coeur::Pastille::Forme::Ronde)
                peintre.drawEllipse(cadre);
            else
                peintre.drawRect(cadre);
        }

        if (pastille.percage > 0) {
            peintre.setPen(Qt::NoPen);
            peintre.setBrush(kVernisSombre);
            const double trou = pastille.percage / 2 * k;
            peintre.drawEllipse(centre, trou, trou);
        }
    }
    // Le numéro de broche ne se lit pas sur la pastille — il n'y est pas
    // imprimé sur une vraie carte, et il masquerait le perçage. Il s'affiche
    // au survol, comme la mesure d'un multimètre : quand on la demande.
    peintre.setBrush(Qt::NoBrush);
}

void VuePcb::paintEvent(QPaintEvent*) {
    QPainter peintre(this);
    peintre.setRenderHint(QPainter::Antialiasing, true);
    peintre.fillRect(rect(), kFondAtelier);
    const double k = echelle();

    dessiner_substrat(peintre);

    // --- chevelu : ce qu'il reste à relier
    if (chevelu_visible_) {
        for (const coeur::CartePcb::Liaison& liaison : carte_.chevelu()) {
            if (liaison.routee) continue;   // une liaison routée n'est plus un dû
            QColor couleur = kChevelu;
            couleur.setAlpha(150);
            peintre.setPen(QPen(couleur, 0.9));
            peintre.drawLine(vers_ecran(liaison.x1, liaison.y1),
                             vers_ecran(liaison.x2, liaison.y2));
        }
    }

    // --- pistes : la couche opposée d'abord, la courante par-dessus
    for (int passe = 0; passe < 2; ++passe) {
        for (const coeur::Piste& piste : carte_.pistes) {
            const bool courante = piste.couche == couche_;
            if ((passe == 0) == courante) continue;
            QColor couleur = piste.couche == 0 ? kPisteDessus : kPisteDessous;
            if (!courante) couleur.setAlpha(120);
            peintre.setPen(QPen(couleur, std::max(1.0, piste.largeur * k),
                                Qt::SolidLine, Qt::RoundCap));
            peintre.drawLine(vers_ecran(piste.x1, piste.y1),
                             vers_ecran(piste.x2, piste.y2));
        }
    }

    // --- piste en cours de tracé
    if (routage_) {
        QColor couleur = couche_ == 0 ? kPisteDessus : kPisteDessous;
        couleur.setAlpha(170);
        peintre.setPen(QPen(couleur, std::max(1.0, largeur_piste_ * k),
                            Qt::DashLine, Qt::RoundCap));
        peintre.drawLine(vers_ecran(depart_x_, depart_y_),
                         vers_ecran(curseur_.x(), curseur_.y()));
    }

    dessiner_serigraphie(peintre);
    dessiner_pastilles(peintre);

    if (carte_.composants.empty()) {
        peintre.setPen(QColor("#9fb0a4"));
        QFont fonte("sans");
        fonte.setPixelSize(15);
        peintre.setFont(fonte);
        peintre.drawText(rect(), Qt::AlignCenter,
                         "Aucune carte.\nUtilisez « Transférer le schéma vers "
                         "la carte » (F8).");
    } else if (carte_.pistes.empty()) {
        // Tant qu'aucune piste n'existe, « Défaire » et « Tout dérouter » n'ont
        // rien à faire — ils sont d'ailleurs grisés. Ce qui manque alors, c'est
        // de savoir comment on en trace une : ce n'est écrit nulle part
        // ailleurs, et personne ne devine qu'il faut cliquer deux pastilles.
        QFont fonte("sans");
        fonte.setPixelSize(13);
        peintre.setFont(fonte);
        const QString aide =
            "Les traits fins sont le chevelu : ce qu'il reste à relier.\n"
            "Cliquez une pastille, puis l'autre bout du trait, pour tirer "
            "la piste.";
        // Le texte tombe sur le vernis vert comme sur le fond sombre : sans
        // fond à lui, il serait illisible une fois sur deux.
        QRectF cadre = peintre.boundingRect(
            QRectF(rect()), Qt::AlignHCenter | Qt::AlignBottom, aide);
        cadre.adjust(-10, -6, 10, 6);
        cadre.translate(0, -12);
        peintre.setPen(Qt::NoPen);
        peintre.setBrush(QColor(18, 24, 20, 205));
        peintre.drawRoundedRect(cadre, 5, 5);
        peintre.setPen(QColor("#cfe0d4"));
        peintre.drawText(cadre, Qt::AlignCenter, aide);
    }
}

// ---------------------------------------------------------------------------
// Gestes
// ---------------------------------------------------------------------------
void VuePcb::mousePressEvent(QMouseEvent* evenement) {
    setFocus(Qt::MouseFocusReason);
    const QPointF position = vers_carte(evenement->position());
    std::vector<coeur::PastillePosee> toutes = carte_.pastilles();

    if (evenement->button() == Qt::MiddleButton) {
        glisse_vue_ = true;
        depart_glisse_ = evenement->position() - decalage_;
        return;
    }
    if (evenement->button() == Qt::RightButton) {
        // Le clic droit abandonne le routage en cours, comme partout ailleurs.
        routage_ = false;
        update();
        return;
    }

    if (const coeur::PastillePosee* pastille = pastille_sous(position, toutes)) {
        if (!routage_) {
            routage_ = true;
            depart_x_ = pastille->x;
            depart_y_ = pastille->y;
            net_depart_ = pastille->net;
            curseur_ = position;
        } else {
            // Une piste ne se tire qu'entre pastilles d'un même net : relier
            // deux nets différents serait un court-circuit, pas un oubli.
            if (pastille->net == net_depart_ && !net_depart_.empty()) {
                carte_.pistes.push_back({net_depart_, depart_x_, depart_y_,
                                         pastille->x, pastille->y,
                                         largeur_piste_, couche_});
                annoncer();
                // On enchaîne : le point d'arrivée devient le point de départ,
                // comme dans tout routeur manuel.
                depart_x_ = pastille->x;
                depart_y_ = pastille->y;
            } else {
                routage_ = false;
            }
        }
        update();
        return;
    }

    // Pas de pastille : on saisit le composant sous le curseur pour le placer.
    routage_ = false;
    const std::string reference = composant_sous(position);
    if (reference.empty()) return;
    const coeur::ComposantPose* pose = nullptr;
    for (const coeur::ComposantPose& candidat : carte_.composants)
        if (candidat.reference == reference) pose = &candidat;
    if (!pose) return;
    composant_saisi_ = reference;
    ecart_saisie_ = QPointF(position.x() - pose->x, position.y() - pose->y);
}

void VuePcb::mouseMoveEvent(QMouseEvent* evenement) {
    if (glisse_vue_) {
        decalage_ = evenement->position() - depart_glisse_;
        update();
        return;
    }
    const QPointF position = vers_carte(evenement->position());
    curseur_ = position;

    if (!composant_saisi_.empty()) {
        // Accrochage au quart de pas : un composant posé de travers se
        // rattrape mal, et les pastilles doivent retomber sur la grille.
        carte_.deplacer(composant_saisi_,
                        accrocher(position.x() - ecart_saisie_.x()),
                        accrocher(position.y() - ecart_saisie_.y()));
        update();
        return;
    }

    std::vector<coeur::PastillePosee> toutes = carte_.pastilles();
    if (const coeur::PastillePosee* pastille = pastille_sous(position, toutes)) {
        emit survol(QString("%1 broche %2 — net %3")
                        .arg(QString::fromStdString(pastille->composant))
                        .arg(pastille->numero > 0
                                 ? QString::number(pastille->numero)
                                 : QString::fromStdString(pastille->borne))
                        .arg(pastille->net.empty()
                                 ? QString("aucun")
                                 : QString::fromStdString(pastille->net)));
    } else {
        const std::string reference = composant_sous(position);
        emit survol(reference.empty()
                        ? QString("%1 ; %2 mm")
                              .arg(position.x(), 0, 'f', 1)
                              .arg(position.y(), 0, 'f', 1)
                        : QString::fromStdString(reference));
    }
    update();
}

void VuePcb::mouseReleaseEvent(QMouseEvent*) {
    glisse_vue_ = false;
    if (composant_saisi_.empty()) return;
    composant_saisi_.clear();
    carte_.ajuster_contour();
    annoncer();
    update();
}

void VuePcb::wheelEvent(QWheelEvent* evenement) {
    // Une seule règle pour les deux pages.
    //
    // La molette zoomait ici et déplaçait sur la page Schéma : on changeait
    // de convention en changeant d'onglet, sans le moindre avertissement.
    // C'est la page Schéma qui a raison, pour une raison qui ne se voit pas
    // à la souris — sur un pavé tactile de précision, le glissement à deux
    // doigts arrive à l'application sous forme d'événements de molette. La
    // molette-déplacement donne donc le déplacement à deux doigts sans une
    // ligne de code, et c'est ce qui compte pour un public sur portable.
    const int pas = evenement->angleDelta().y();
    if (evenement->modifiers() & Qt::ControlModifier) {
        const QPointF avant = vers_carte(evenement->position());
        // Zoom continu plutôt que par crans fixes : un pavé tactile envoie
        // des dizaines de petits deltas par seconde là où une molette en
        // envoie un gros. Le pas fixe faisait donc partir le pincement en
        // vrille — défaut invisible tant qu'on ne teste qu'à la souris.
        const double facteur = std::pow(1.0015, static_cast<double>(pas));
        zoom_ = std::max(0.4, std::min(24.0, zoom_ * facteur));
        const QPointF apres = vers_carte(evenement->position());
        decalage_ += QPointF((apres.x() - avant.x()) * echelle(),
                             (apres.y() - avant.y()) * echelle());
    } else if (evenement->modifiers() & Qt::ShiftModifier) {
        decalage_ += QPointF(pas, 0);
    } else {
        decalage_ += QPointF(evenement->angleDelta().x(), pas);
    }
    update();
}

void VuePcb::keyPressEvent(QKeyEvent* evenement) {
    switch (evenement->key()) {
        case Qt::Key_R: tourner_sous_curseur(); return;
        case Qt::Key_Escape: routage_ = false; update(); return;
        case Qt::Key_Backspace: defaire_piste(); return;
        case Qt::Key_Space: recadrer(); return;
        default: QWidget::keyPressEvent(evenement);
    }
}

void VuePcb::resizeEvent(QResizeEvent* evenement) {
    QWidget::resizeEvent(evenement);
    update();
}

// ---------------------------------------------------------------------------
// Panneau
// ---------------------------------------------------------------------------
PanneauPcb::PanneauPcb(QWidget* parent) : QWidget(parent) {
    auto* colonne = new QVBoxLayout(this);
    colonne->setContentsMargins(6, 6, 6, 6);

    auto* barre = new QHBoxLayout;
    auto* retour = new QPushButton("← Schéma");
    retour->setToolTip("Revenir à la saisie du schéma (Ctrl+1)");
    barre->addWidget(retour);
    auto* transfert = new QPushButton("Transférer le schéma vers la carte");
    transfert->setToolTip(
        "Reprend les composants et les nets du schéma (F8).\n"
        "Le placement et les pistes déjà faits sont conservés.");
    barre->addWidget(transfert);
    barre->addSpacing(16);

    barre->addWidget(new QLabel("Couche"));
    couche_ = new QComboBox;
    couche_->addItem("Dessus (rouge)");
    couche_->addItem("Dessous (bleu)");
    barre->addWidget(couche_);

    auto* titre_largeur = new QLabel("Largeur");
    barre->addWidget(titre_largeur);
    largeur_ = new QDoubleSpinBox;
    largeur_->setRange(0.1, 5.0);
    largeur_->setSingleStep(0.1);
    largeur_->setValue(0.4);
    largeur_->setSuffix(" mm");
    const QString explication_largeur =
        "Largeur du cuivre des PROCHAINES pistes tracées.\n"
        "Les pistes déjà posées gardent la leur.\n"
        "0,4 mm passe environ 1 A ; en dessous de 0,15 mm, le contrôle de "
        "fabrication refuse.";
    largeur_->setToolTip(explication_largeur);
    titre_largeur->setToolTip(explication_largeur);
    barre->addWidget(largeur_);

    chevelu_ = new QCheckBox("Chevelu");
    chevelu_->setChecked(true);
    barre->addWidget(chevelu_);

    defaire_ = new QPushButton("Défaire la piste");
    defaire_->setToolTip("Retire la dernière piste tracée. Raccourci : "
                         "Retour arrière.");
    effacer_ = new QPushButton("Tout dérouter");
    effacer_->setToolTip("Retire toutes les pistes et repart du chevelu. Le "
                         "placement des composants, lui, est conservé.");
    auto* auto_router = new QPushButton("Router automatiquement");
    auto_router->setToolTip(
        "Trace les pistes qui manquent, en contournant le cuivre déjà posé.\n"
        "Les pistes tirées à la main sont conservées : on route d'abord ce "
        "qui compte — masses, puissance —, la machine fait le reste.\n"
        "Le compte rendu dit ce qu'elle n'a pas su relier.");

    auto* regles = new QPushButton("Contrôler (DRC)");
    regles->setToolTip("Vérifie isolation, largeur minimale et débordement du "
                       "contour, comme le ferait le fabricant.");
    auto* exporter = new QPushButton("Exporter la fabrication…");
    exporter->setToolTip("Écrit les fichiers Gerber (cuivre, sérigraphie, "
                         "contour) et le fichier de perçage Excellon.");
    barre->addWidget(defaire_);
    barre->addWidget(effacer_);
    barre->addWidget(auto_router);
    barre->addStretch(1);
    barre->addWidget(regles);
    barre->addWidget(exporter);
    // Défilante : dix commandes en ligne exigeaient 1271 pixels, et la page
    // du circuit imprimé imposait cette largeur au schéma lui-même — les deux
    // pages étant empilées, leurs minimums s'additionnent à celui des docks.
    colonne->addWidget(ihm::barre_defilante(barre));

    vue_ = new VuePcb;
    colonne->addWidget(vue_, 1);

    auto* pied = new QHBoxLayout;
    etat_ = new QLabel("Aucune carte : transférez le schéma.");
    QFont fonte("monospace");
    fonte.setStyleHint(QFont::TypeWriter);
    etat_->setFont(fonte);
    survol_ = new QLabel("Molette : zoom · clic milieu : déplacer · R : "
                         "tourner · Échap : annuler le tracé");
    survol_->setFont(fonte);
    survol_->setStyleSheet("color:#7f8f7f");
    // Ces deux étiquettes changent de texte à chaque geste ; sans cela, leur
    // largeur imposerait une largeur minimale à toute la page — et, la page
    // étant empilée avec le schéma, la palette du schéma se retrouvait
    // rétrécie au retour.
    for (QLabel* etiquette : {etat_, survol_})
        etiquette->setSizePolicy(QSizePolicy::Ignored, QSizePolicy::Preferred);
    // Les deux étiquettes se partagent la ligne et acceptent d'être
    // rétrécies : c'est ce qui les empêche d'imposer une largeur au reste.
    pied->addWidget(etat_, 3);
    pied->addWidget(survol_, 2, Qt::AlignRight);
    colonne->addLayout(pied);

    rapport_ = new QPlainTextEdit;
    rapport_->setReadOnly(true);
    rapport_->setFont(fonte);
    rapport_->setMinimumHeight(48);
    rapport_->setMaximumHeight(110);
    rapport_->setPlaceholderText(
        "Compte rendu du transfert schéma → carte et du contrôle des règles.");
    colonne->addWidget(rapport_);

    connect(retour, &QPushButton::clicked, this,
            &PanneauPcb::retour_schema_demande);
    connect(transfert, &QPushButton::clicked, this,
            &PanneauPcb::mise_a_jour_demandee);
    connect(couche_, &QComboBox::currentIndexChanged, vue_,
            &VuePcb::definir_couche);
    connect(largeur_, &QDoubleSpinBox::valueChanged, vue_,
            &VuePcb::definir_largeur_piste);
    connect(chevelu_, &QCheckBox::toggled, vue_, &VuePcb::afficher_chevelu);
    connect(defaire_, &QPushButton::clicked, vue_, &VuePcb::defaire_piste);
    connect(effacer_, &QPushButton::clicked, vue_, &VuePcb::effacer_pistes);
    connect(auto_router, &QPushButton::clicked, this, &PanneauPcb::router_tout);
    connect(regles, &QPushButton::clicked, this, &PanneauPcb::controler);
    connect(exporter, &QPushButton::clicked, this, &PanneauPcb::exporter);
    connect(vue_, &VuePcb::etat_change, this, [this](const QString& resume) {
        etat_->setText(resume);
        refleter_pistes();
    });
    refleter_pistes();
    connect(vue_, &VuePcb::survol, this,
            [this](const QString& texte) { survol_->setText(texte); });
}

// Le routage automatique, tel qu'on s'en sert vraiment : il complète le
// travail au lieu de le remplacer, et il rend des comptes. Un routeur qui
// dirait seulement « terminé » laisserait l'utilisateur chercher lui-même ce
// qui manque.
void PanneauPcb::router_tout() {
    if (!vue_) return;
    if (vue_->carte().composants.empty()) {
        afficher_rapport("Aucune carte : transférez d'abord le schéma.");
        return;
    }
    coeur::ReglagesRoutage reglages;
    reglages.largeur = largeur_ ? largeur_->value() : 0.4;

    QApplication::setOverrideCursor(Qt::WaitCursor);
    const coeur::CompteRenduRoutage rendu =
        coeur::router(vue_->carte(), reglages);
    QApplication::restoreOverrideCursor();

    vue_->definir_carte(vue_->carte());     // recadre et rafraîchit l'affichage
    refleter_pistes();
    const QString compte_rendu =
        "Routage automatique — " + QString::fromStdString(rendu.resume());
    afficher_rapport(compte_rendu);
    emit journal(compte_rendu);
}

QString PanneauPcb::construire_depuis(const coeur::Netlist& netlist) {
    const coeur::CartePcb ancienne = vue_->carte();
    // Le placement croît en carré du nombre de composants : sur un gros
    // schéma il gèle l'interface le temps qu'il faut. Le routage voisin pose
    // déjà son sablier ; ne pas le faire ici laissait croire à un plantage.
    QApplication::setOverrideCursor(Qt::WaitCursor);
    coeur::CartePcb nouvelle = coeur::CartePcb::depuis_netlist(netlist);
    QApplication::restoreOverrideCursor();

    // Le placement déjà fait est précieux : on le reprend pour les composants
    // qui existaient avant, plutôt que de tout remettre en grille. C'est ce
    // que fait « Update PCB from Schematic » — mettre à jour, pas recommencer.
    QStringList ajoutes, retires, deplaces;
    for (coeur::ComposantPose& pose : nouvelle.composants) {
        const coeur::ComposantPose* ancien = nullptr;
        for (const coeur::ComposantPose& precedent : ancienne.composants)
            if (precedent.reference == pose.reference) ancien = &precedent;
        if (!ancien) {
            ajoutes << QString::fromStdString(pose.reference);
            continue;
        }
        pose.x = ancien->x;
        pose.y = ancien->y;
        if (ancien->rotation != 0) {
            pose.rotation = ancien->rotation;
            if (static_cast<int>(std::lround(pose.rotation / 90.0)) & 1)
                std::swap(pose.largeur, pose.hauteur);
        }
        if (ancien->empreinte != pose.empreinte)
            deplaces << QString("%1 : empreinte %2 → %3")
                            .arg(QString::fromStdString(pose.reference),
                                 QString::fromStdString(ancien->empreinte),
                                 QString::fromStdString(pose.empreinte));
    }
    for (const coeur::ComposantPose& precedent : ancienne.composants) {
        bool survit = false;
        for (const coeur::ComposantPose& pose : nouvelle.composants)
            if (pose.reference == precedent.reference) survit = true;
        if (!survit) retires << QString::fromStdString(precedent.reference);
    }

    // Les nets du schéma font foi. Une piste dont le net a disparu n'a plus
    // de raison d'être : la garder, c'est laisser un court-circuit invisible.
    std::set<std::string> nets;
    for (const coeur::PastillePosee& pastille : nouvelle.pastilles())
        if (!pastille.net.empty()) nets.insert(pastille.net);
    int abandonnees = 0;
    for (const coeur::Piste& piste : ancienne.pistes) {
        if (nets.count(piste.net)) {
            nouvelle.pistes.push_back(piste);
        } else {
            ++abandonnees;
        }
    }
    nouvelle.ajuster_contour();

    QStringList compte_rendu;
    compte_rendu << QString("Transfert du schéma vers la carte : %1 composants, "
                            "%2 nets.")
                        .arg(nouvelle.composants.size())
                        .arg(nets.size());
    if (!ajoutes.isEmpty())
        compte_rendu << "  ajoutés  : " + ajoutes.join(", ");
    if (!retires.isEmpty())
        compte_rendu << "  retirés  : " + retires.join(", ");
    for (const QString& ligne : deplaces) compte_rendu << "  " + ligne;
    if (abandonnees > 0)
        compte_rendu << QString("  %1 piste(s) abandonnée(s) : leur net "
                                "n'existe plus au schéma.")
                            .arg(abandonnees);
    if (ajoutes.isEmpty() && retires.isEmpty() && deplaces.isEmpty()
        && abandonnees == 0 && !ancienne.composants.empty())
        compte_rendu << "  la carte était déjà à jour.";

    vue_->definir_carte(std::move(nouvelle));
    const QString texte = compte_rendu.join("\n");
    afficher_rapport(texte);
    return texte;
}

void PanneauPcb::refleter_pistes() {
    const bool des_pistes = vue_ && !vue_->carte().pistes.empty();
    if (defaire_) defaire_->setEnabled(des_pistes);
    if (effacer_) effacer_->setEnabled(des_pistes);
}

QString PanneauPcb::resume() const { return etat_->text(); }

QString PanneauPcb::rapport() const {
    return rapport_ ? rapport_->toPlainText() : QString();
}

void PanneauPcb::afficher_rapport(const QString& texte) {
    if (rapport_) rapport_->setPlainText(texte);
}

void PanneauPcb::controler() {
    const auto anomalies = vue_->carte().controler();
    if (anomalies.empty()) {
        afficher_rapport("Contrôle des règles de fabrication : aucune anomalie "
                         "(isolation 0,2 mm, largeur minimale 0,15 mm).");
        emit journal("Règles de fabrication : aucune anomalie.");
        return;
    }
    QString rapport = QString("Contrôle des règles de fabrication : %1 "
                              "anomalie(s)\n")
                          .arg(anomalies.size());
    for (const auto& anomalie : anomalies)
        rapport += QString("  %1 (en %2 ; %3 mm)\n")
                       .arg(QString::fromStdString(anomalie.message))
                       .arg(anomalie.x, 0, 'f', 1)
                       .arg(anomalie.y, 0, 'f', 1);
    afficher_rapport(rapport);
    emit journal(QString("Règles de fabrication : %1 anomalie(s) — voir la "
                         "page Circuit imprimé.")
                     .arg(anomalies.size()));
}

QStringList PanneauPcb::exporter_vers(const QString& base) {
    struct Sortie { QString suffixe; std::string contenu; };
    const std::vector<Sortie> fichiers = {
        {"-dessus.gbr", vue_->carte().gerber(0)},
        {"-dessous.gbr", vue_->carte().gerber(1)},
        {"-serigraphie.gbr", vue_->carte().gerber_serigraphie()},
        {"-contour.gbr", vue_->carte().gerber_contour()},
        {"-percages.drl", vue_->carte().excellon()}};

    QStringList ecrits;
    for (const Sortie& sortie : fichiers) {
        QFile fichier(base + sortie.suffixe);
        if (!fichier.open(QIODevice::WriteOnly | QIODevice::Text)) continue;
        fichier.write(QByteArray::fromStdString(sortie.contenu));
        ecrits << QFileInfo(fichier).fileName();
    }
    return ecrits;
}

void PanneauPcb::exporter() {
    const QString base = QFileDialog::getSaveFileName(
        this, "Exporter les fichiers de fabrication", "carte",
        "Préfixe des fichiers (*)");
    if (base.isEmpty()) return;
    const QStringList ecrits = exporter_vers(base);
    afficher_rapport("Fichiers de fabrication écrits :\n  "
                     + ecrits.join("\n  "));
    emit journal("Fabrication exportée : " + ecrits.join(", "));
}
