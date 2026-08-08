#include "app/panels/PanneauPcb.h"

#include <QComboBox>
#include <QDoubleSpinBox>
#include <QFileDialog>
#include <QFile>
#include <QFileInfo>
#include <QHBoxLayout>
#include <QLabel>
#include <QMouseEvent>
#include <QPainter>
#include <QPushButton>
#include <QVBoxLayout>

#include <algorithm>
#include <cmath>

namespace {

const QColor kFond("#0e1a12");
const QColor kContour("#d8d8b0");
const QColor kPastille("#c9a227");
const QColor kPercage("#0e1a12");
const QColor kCuivreDessus("#e05a4a");
const QColor kCuivreDessous("#4a7fe0");
const QColor kChevelu("#3f7f5f");
const QColor kChevelu_routee("#2f4f3f");

}  // namespace

// ---------------------------------------------------------------------------
// Vue
// ---------------------------------------------------------------------------
VuePcb::VuePcb(QWidget* parent) : QWidget(parent) {
    setMinimumHeight(320);
    setMouseTracking(true);
    setCursor(Qt::CrossCursor);
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

double VuePcb::echelle() const {
    if (carte_.largeur <= 0 || carte_.hauteur <= 0) return 4.0;
    return std::min((width() - 24.0) / carte_.largeur,
                    (height() - 24.0) / carte_.hauteur);
}

QPointF VuePcb::vers_ecran(double x, double y) const {
    return QPointF(12 + x * echelle(), 12 + y * echelle());
}

QPointF VuePcb::vers_carte(const QPointF& ecran) const {
    const double k = echelle();
    return QPointF((ecran.x() - 12) / k, (ecran.y() - 12) / k);
}

const coeur::PastillePosee* VuePcb::pastille_sous(
    const QPointF& position, std::vector<coeur::PastillePosee>& toutes) const {
    for (const coeur::PastillePosee& pastille : toutes) {
        const double distance =
            std::hypot(pastille.x - position.x(), pastille.y - position.y());
        if (distance <= pastille.diametre / 2 + 0.3) return &pastille;
    }
    return nullptr;
}

void VuePcb::annoncer() {
    const std::vector<coeur::CartePcb::Liaison> liaisons = carte_.chevelu();
    int restantes = 0;
    for (const auto& liaison : liaisons)
        if (!liaison.routee) ++restantes;
    const std::vector<coeur::CartePcb::AnomaliePcb> anomalies =
        carte_.controler();
    emit etat_change(
        QString("%1 composants · %2 liaisons dont %3 à router · %4 pistes · "
                "%5 anomalie(s)")
            .arg(carte_.composants.size())
            .arg(liaisons.size())
            .arg(restantes)
            .arg(carte_.pistes.size())
            .arg(anomalies.size()));
}

void VuePcb::paintEvent(QPaintEvent*) {
    QPainter peintre(this);
    peintre.setRenderHint(QPainter::Antialiasing, true);
    peintre.fillRect(rect(), kFond);
    const double k = echelle();

    // --- contour de la carte
    peintre.setPen(QPen(kContour, 1.2));
    peintre.drawRect(QRectF(vers_ecran(0, 0),
                            vers_ecran(carte_.largeur, carte_.hauteur)));

    // --- chevelu : ce qu'il reste à relier
    for (const coeur::CartePcb::Liaison& liaison : carte_.chevelu()) {
        peintre.setPen(QPen(liaison.routee ? kChevelu_routee : kChevelu, 0.8,
                            Qt::DotLine));
        peintre.drawLine(vers_ecran(liaison.x1, liaison.y1),
                         vers_ecran(liaison.x2, liaison.y2));
    }

    // --- pistes, la couche courante en tête
    for (int passe = 0; passe < 2; ++passe) {
        for (const coeur::Piste& piste : carte_.pistes) {
            const bool courante = piste.couche == couche_;
            if ((passe == 0) == courante) continue;
            QColor couleur = piste.couche == 0 ? kCuivreDessus : kCuivreDessous;
            if (!courante) couleur.setAlpha(110);
            peintre.setPen(QPen(couleur, std::max(1.0, piste.largeur * k),
                                Qt::SolidLine, Qt::RoundCap));
            peintre.drawLine(vers_ecran(piste.x1, piste.y1),
                             vers_ecran(piste.x2, piste.y2));
        }
    }

    // --- piste en cours de tracé
    if (routage_) {
        QColor couleur = couche_ == 0 ? kCuivreDessus : kCuivreDessous;
        couleur.setAlpha(160);
        peintre.setPen(QPen(couleur, std::max(1.0, largeur_piste_ * k),
                            Qt::DashLine, Qt::RoundCap));
        peintre.drawLine(vers_ecran(depart_x_, depart_y_),
                         vers_ecran(curseur_.x(), curseur_.y()));
    }

    // --- empreintes et pastilles
    peintre.setFont(QFont("sans", 7));
    for (const coeur::ComposantPose& pose : carte_.composants) {
        peintre.setPen(QPen(QColor("#7f8f7f"), 0.8));
        const QRectF cadre(vers_ecran(pose.x - pose.largeur / 2,
                                      pose.y - pose.hauteur / 2),
                           vers_ecran(pose.x + pose.largeur / 2,
                                      pose.y + pose.hauteur / 2));
        peintre.drawRect(cadre);
        peintre.setPen(QColor("#b9c9b9"));
        peintre.drawText(cadre.adjusted(0, -14, 0, -14), Qt::AlignCenter,
                         QString::fromStdString(pose.reference));
    }
    for (const coeur::PastillePosee& pastille : carte_.pastilles()) {
        const QPointF centre = vers_ecran(pastille.x, pastille.y);
        const double rayon = pastille.diametre / 2 * k;
        peintre.setPen(Qt::NoPen);
        peintre.setBrush(kPastille);
        peintre.drawEllipse(centre, rayon, rayon);
        if (pastille.percage > 0) {
            peintre.setBrush(kPercage);
            const double trou = pastille.percage / 2 * k;
            peintre.drawEllipse(centre, trou, trou);
        }
    }
    peintre.setBrush(Qt::NoBrush);
}

void VuePcb::mousePressEvent(QMouseEvent* evenement) {
    const QPointF position = vers_carte(evenement->position());
    std::vector<coeur::PastillePosee> toutes = carte_.pastilles();

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
            }
            routage_ = false;
        }
        update();
        return;
    }

    // Pas de pastille : on saisit le composant sous le curseur pour le placer.
    routage_ = false;
    for (const coeur::ComposantPose& pose : carte_.composants) {
        if (std::fabs(position.x() - pose.x) > pose.largeur / 2) continue;
        if (std::fabs(position.y() - pose.y) > pose.hauteur / 2) continue;
        composant_saisi_ = pose.reference;
        ecart_saisie_ = QPointF(position.x() - pose.x, position.y() - pose.y);
        break;
    }
}

void VuePcb::mouseMoveEvent(QMouseEvent* evenement) {
    const QPointF position = vers_carte(evenement->position());
    if (!composant_saisi_.empty()) {
        carte_.deplacer(composant_saisi_, position.x() - ecart_saisie_.x(),
                        position.y() - ecart_saisie_.y());
        update();
        return;
    }
    if (routage_) {
        curseur_ = position;
        update();
    }
}

void VuePcb::mouseReleaseEvent(QMouseEvent*) {
    if (composant_saisi_.empty()) return;
    composant_saisi_.clear();
    annoncer();
    update();
}

// ---------------------------------------------------------------------------
// Panneau
// ---------------------------------------------------------------------------
PanneauPcb::PanneauPcb(QWidget* parent) : QWidget(parent) {
    auto* colonne = new QVBoxLayout(this);
    colonne->setContentsMargins(6, 6, 6, 6);

    auto* barre = new QHBoxLayout;
    barre->addWidget(new QLabel("Couche"));
    couche_ = new QComboBox;
    couche_->addItem("Dessus");
    couche_->addItem("Dessous");
    barre->addWidget(couche_);

    barre->addWidget(new QLabel("Largeur"));
    largeur_ = new QDoubleSpinBox;
    largeur_->setRange(0.1, 5.0);
    largeur_->setSingleStep(0.1);
    largeur_->setValue(0.4);
    largeur_->setSuffix(" mm");
    barre->addWidget(largeur_);

    auto* defaire = new QPushButton("Défaire la dernière piste");
    auto* effacer = new QPushButton("Tout dérouter");
    auto* exporter = new QPushButton("Exporter Gerber et perçages…");
    barre->addWidget(defaire);
    barre->addWidget(effacer);
    barre->addStretch(1);
    barre->addWidget(exporter);
    colonne->addLayout(barre);

    vue_ = new VuePcb;
    colonne->addWidget(vue_, 1);

    etat_ = new QLabel("Aucune carte : générez-la depuis le schéma.");
    QFont fonte("monospace");
    fonte.setStyleHint(QFont::TypeWriter);
    etat_->setFont(fonte);
    colonne->addWidget(etat_);

    connect(couche_, &QComboBox::currentIndexChanged, vue_,
            &VuePcb::definir_couche);
    connect(largeur_, &QDoubleSpinBox::valueChanged, vue_,
            &VuePcb::definir_largeur_piste);
    connect(defaire, &QPushButton::clicked, vue_, &VuePcb::defaire_piste);
    connect(effacer, &QPushButton::clicked, vue_, &VuePcb::effacer_pistes);
    connect(exporter, &QPushButton::clicked, this, &PanneauPcb::exporter);
    connect(vue_, &VuePcb::etat_change, this,
            [this](const QString& resume) { etat_->setText(resume); });
}

void PanneauPcb::construire_depuis(const coeur::Netlist& netlist) {
    coeur::CartePcb nouvelle = coeur::CartePcb::depuis_netlist(netlist);
    // Le placement déjà fait est précieux : on le reprend pour les composants
    // qui existaient avant, plutôt que de tout remettre en grille.
    for (coeur::ComposantPose& pose : nouvelle.composants) {
        const coeur::ComposantPose* ancien = nullptr;
        for (const coeur::ComposantPose& precedent : vue_->carte().composants)
            if (precedent.reference == pose.reference) ancien = &precedent;
        if (!ancien) continue;
        pose.x = ancien->x;
        pose.y = ancien->y;
        pose.rotation = ancien->rotation;
    }
    // Les pistes survivent aussi : elles appartiennent à des nets, pas à des
    // positions d'écran.
    nouvelle.pistes = vue_->carte().pistes;
    vue_->definir_carte(std::move(nouvelle));
}

QString PanneauPcb::resume() const { return etat_->text(); }

QStringList PanneauPcb::exporter_vers(const QString& base) {
    struct Sortie { QString suffixe; std::string contenu; };
    const std::vector<Sortie> fichiers = {
        {"-dessus.gbr", vue_->carte().gerber(0)},
        {"-dessous.gbr", vue_->carte().gerber(1)},
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
    emit journal("Fabrication exportée : " + exporter_vers(base).join(", "));
}
