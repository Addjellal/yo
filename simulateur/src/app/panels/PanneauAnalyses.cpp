#include "app/panels/PanneauAnalyses.h"

#include <QComboBox>
#include <QDoubleSpinBox>
#include <QEvent>
#include <QHBoxLayout>
#include <QLabel>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QPushButton>
#include <QSpinBox>
#include <QStackedWidget>
#include <QVBoxLayout>

#include <algorithm>
#include <cmath>

#include "core/export/Documents.h"

namespace {

// Palette des courbes : les mêmes teintes que les voies de l'oscilloscope,
// pour qu'un signal garde sa couleur d'un instrument à l'autre.
QColor couleur(int rang) {
    static const QColor teintes[] = {QColor("#ffd24a"), QColor("#4ad2ff"),
                                     QColor("#7dff8a"), QColor("#ff7d9c"),
                                     QColor("#c79cff"), QColor("#ffa54a")};
    return teintes[rang % 6];
}

QString abrege(double valeur, const QString& unite = {}) {
    const double absolue = std::fabs(valeur);
    QString texte;
    if (absolue >= 1e9) texte = QString::number(valeur / 1e9, 'g', 4) + "G";
    else if (absolue >= 1e6) texte = QString::number(valeur / 1e6, 'g', 4) + "M";
    else if (absolue >= 1e3) texte = QString::number(valeur / 1e3, 'g', 4) + "k";
    else if (absolue >= 1 || absolue == 0)
        texte = QString::number(valeur, 'g', 4);
    else if (absolue >= 1e-3) texte = QString::number(valeur * 1e3, 'g', 4) + "m";
    else if (absolue >= 1e-6) texte = QString::number(valeur * 1e6, 'g', 4) + "µ";
    else texte = QString::number(valeur * 1e9, 'g', 4) + "n";
    return unite.isEmpty() ? texte : texte + " " + unite;
}

}  // namespace

// ---------------------------------------------------------------------------
// Zone de tracé
// ---------------------------------------------------------------------------
TraceCourbes::TraceCourbes(QWidget* parent) : QWidget(parent) {
    setMinimumHeight(240);
    setMouseTracking(true);
    setAutoFillBackground(true);
}

void TraceCourbes::definir(QVector<Serie> series, bool log_x, bool barres) {
    series_ = std::move(series);
    log_x_ = log_x;
    barres_ = barres;
    recalculer_bornes();
    update();
}

void TraceCourbes::definir_axes(const QString& x, const QString& gauche,
                                const QString& droite) {
    titre_x_ = x;
    titre_gauche_ = gauche;
    titre_droite_ = droite;
    update();
}

void TraceCourbes::vider() {
    series_.clear();
    update();
}

void TraceCourbes::recalculer_bornes() {
    x_min_ = g_min_ = d_min_ = 0;
    x_max_ = g_max_ = d_max_ = 1;
    axe_droit_utilise_ = false;
    bool premier_x = true, premier_g = true, premier_d = true;
    for (const Serie& serie : series_) {
        for (const QPointF& point : serie.points) {
            if (log_x_ && point.x() <= 0) continue;
            if (premier_x) {
                x_min_ = x_max_ = point.x();
                premier_x = false;
            } else {
                x_min_ = std::min(x_min_, point.x());
                x_max_ = std::max(x_max_, point.x());
            }
            double& mini = serie.axe_droit ? d_min_ : g_min_;
            double& maxi = serie.axe_droit ? d_max_ : g_max_;
            bool& premier = serie.axe_droit ? premier_d : premier_g;
            if (premier) {
                mini = maxi = point.y();
                premier = false;
            } else {
                mini = std::min(mini, point.y());
                maxi = std::max(maxi, point.y());
            }
        }
        if (serie.axe_droit && !serie.points.isEmpty()) axe_droit_utilise_ = true;
    }
    // Marge de 5 % pour que les extrema ne collent pas au cadre.
    auto marger = [](double& mini, double& maxi) {
        if (maxi - mini < 1e-12) {
            const double centre = 0.5 * (mini + maxi);
            mini = centre - 0.5;
            maxi = centre + 0.5;
            return;
        }
        const double marge = 0.05 * (maxi - mini);
        mini -= marge;
        maxi += marge;
    };
    // Un diagramme en raies se lit depuis zéro : une base flottante ferait
    // paraître énorme une harmonique négligeable, et la première raie se
    // confondrait avec l'axe.
    if (barres_) {
        g_min_ = 0;
        x_min_ = 0;
        x_max_ *= 1.05;
    }
    marger(g_min_, g_max_);
    marger(d_min_, d_max_);
    if (barres_) g_min_ = 0;
    if (x_max_ - x_min_ < 1e-15) x_max_ = x_min_ + 1;
}

double TraceCourbes::abscisse_ecran(double x, const QRectF& cadre) const {
    if (log_x_) {
        const double a = std::log10(std::max(1e-30, x_min_));
        const double b = std::log10(std::max(1e-30, x_max_));
        const double v = std::log10(std::max(1e-30, x));
        return cadre.left() + (v - a) / (b - a) * cadre.width();
    }
    return cadre.left() + (x - x_min_) / (x_max_ - x_min_) * cadre.width();
}

double TraceCourbes::abscisse_donnee(double ecran, const QRectF& cadre) const {
    const double part = (ecran - cadre.left()) / std::max(1.0, cadre.width());
    if (log_x_) {
        const double a = std::log10(std::max(1e-30, x_min_));
        const double b = std::log10(std::max(1e-30, x_max_));
        return std::pow(10.0, a + part * (b - a));
    }
    return x_min_ + part * (x_max_ - x_min_);
}

double TraceCourbes::ordonnee_ecran(double y, const QRectF& cadre,
                                    bool droite) const {
    const double mini = droite ? d_min_ : g_min_;
    const double maxi = droite ? d_max_ : g_max_;
    return cadre.bottom() - (y - mini) / (maxi - mini) * cadre.height();
}

void TraceCourbes::paintEvent(QPaintEvent*) {
    QPainter peintre(this);
    peintre.setRenderHint(QPainter::Antialiasing, true);
    peintre.fillRect(rect(), QColor("#10161c"));

    const QRectF cadre(70, 24, width() - 70 - (axe_droit_utilise_ ? 66 : 24),
                       height() - 24 - 42);
    if (cadre.width() < 40 || cadre.height() < 40) return;

    peintre.setPen(QPen(QColor("#2a3742"), 1));
    peintre.drawRect(cadre);

    // --- quadrillage et graduations
    peintre.setFont(QFont("sans", 8));
    if (log_x_) {
        const int decade_min = static_cast<int>(std::floor(std::log10(std::max(1e-30, x_min_))));
        const int decade_max = static_cast<int>(std::ceil(std::log10(std::max(1e-30, x_max_))));
        for (int d = decade_min; d <= decade_max; ++d) {
            for (int m = 1; m <= 9; ++m) {
                const double valeur = m * std::pow(10.0, d);
                if (valeur < x_min_ || valeur > x_max_) continue;
                const double x = abscisse_ecran(valeur, cadre);
                peintre.setPen(QPen(QColor(m == 1 ? "#33424f" : "#1c2731"), 1));
                peintre.drawLine(QPointF(x, cadre.top()),
                                 QPointF(x, cadre.bottom()));
                if (m == 1) {
                    peintre.setPen(QColor("#8fa3b3"));
                    peintre.drawText(QRectF(x - 40, cadre.bottom() + 4, 80, 14),
                                     Qt::AlignHCenter, abrege(valeur));
                }
            }
        }
    } else {
        for (int k = 0; k <= 10; ++k) {
            const double x = cadre.left() + k * cadre.width() / 10.0;
            peintre.setPen(QPen(QColor("#1c2731"), 1));
            peintre.drawLine(QPointF(x, cadre.top()), QPointF(x, cadre.bottom()));
            if (k % 2) continue;
            peintre.setPen(QColor("#8fa3b3"));
            peintre.drawText(QRectF(x - 40, cadre.bottom() + 4, 80, 14),
                             Qt::AlignHCenter,
                             abrege(x_min_ + k * (x_max_ - x_min_) / 10.0));
        }
    }
    for (int k = 0; k <= 8; ++k) {
        const double y = cadre.top() + k * cadre.height() / 8.0;
        peintre.setPen(QPen(QColor("#1c2731"), 1));
        peintre.drawLine(QPointF(cadre.left(), y), QPointF(cadre.right(), y));
        peintre.setPen(QColor("#8fa3b3"));
        peintre.drawText(QRectF(2, y - 8, 64, 16),
                         Qt::AlignRight | Qt::AlignVCenter,
                         abrege(g_max_ - k * (g_max_ - g_min_) / 8.0));
        if (axe_droit_utilise_) {
            peintre.setPen(QColor("#b39c6a"));
            peintre.drawText(QRectF(cadre.right() + 4, y - 8, 60, 16),
                             Qt::AlignLeft | Qt::AlignVCenter,
                             abrege(d_max_ - k * (d_max_ - d_min_) / 8.0));
        }
    }

    peintre.setPen(QColor("#8fa3b3"));
    peintre.drawText(QRectF(cadre.left(), height() - 20, cadre.width(), 16),
                     Qt::AlignHCenter, titre_x_);
    peintre.drawText(QRectF(2, 4, 200, 16), Qt::AlignLeft, titre_gauche_);
    if (axe_droit_utilise_)
        peintre.drawText(QRectF(cadre.right() - 200, 4, 200, 16),
                         Qt::AlignRight, titre_droite_);

    // --- courbes
    int rang = 0;
    for (const Serie& serie : series_) {
        peintre.setPen(QPen(couleur(rang), serie.axe_droit ? 1.2 : 1.8,
                            serie.axe_droit ? Qt::DashLine : Qt::SolidLine));
        if (barres_) {
            for (const QPointF& point : serie.points) {
                const double x = abscisse_ecran(point.x(), cadre);
                const double y = ordonnee_ecran(point.y(), cadre, serie.axe_droit);
                const double zero =
                    ordonnee_ecran(std::max(0.0, g_min_), cadre, serie.axe_droit);
                peintre.drawLine(QPointF(x, zero), QPointF(x, y));
                peintre.drawEllipse(QPointF(x, y), 2.5, 2.5);
            }
        } else {
            QPainterPath chemin;
            bool commence = false;
            for (const QPointF& point : serie.points) {
                if (log_x_ && point.x() <= 0) continue;
                const QPointF ecran(abscisse_ecran(point.x(), cadre),
                                    ordonnee_ecran(point.y(), cadre,
                                                   serie.axe_droit));
                if (!commence) {
                    chemin.moveTo(ecran);
                    commence = true;
                } else {
                    chemin.lineTo(ecran);
                }
            }
            peintre.drawPath(chemin);
        }
        // légende
        peintre.drawText(QRectF(cadre.right() - 160, cadre.top() + 4 + rang * 15,
                                156, 14),
                         Qt::AlignRight, serie.nom);
        ++rang;
    }

    // --- curseur de lecture
    if (curseur_ >= cadre.left() && curseur_ <= cadre.right()
        && !series_.isEmpty()) {
        peintre.setPen(QPen(QColor("#ffffff"), 1, Qt::DotLine));
        peintre.drawLine(QPointF(curseur_, cadre.top()),
                         QPointF(curseur_, cadre.bottom()));
        const double x = abscisse_donnee(curseur_, cadre);
        QString lecture = titre_x_ + " = " + abrege(x);
        for (const Serie& serie : series_) {
            if (serie.points.isEmpty()) continue;
            // point le plus proche : inutile d'interpoler pour une lecture
            const QPointF* meilleur = &serie.points.first();
            for (const QPointF& point : serie.points)
                if (std::fabs(point.x() - x) < std::fabs(meilleur->x() - x))
                    meilleur = &point;
            lecture += "   " + serie.nom + " = " + abrege(meilleur->y());
        }
        peintre.setPen(QColor("#e8f0f6"));
        peintre.drawText(QRectF(cadre.left(), 4, cadre.width(), 16),
                         Qt::AlignLeft, lecture);
    }
}

void TraceCourbes::mouseMoveEvent(QMouseEvent* evenement) {
    curseur_ = evenement->position().x();
    update();
}

void TraceCourbes::leaveEvent(QEvent*) {
    curseur_ = -1;
    update();
}

// ---------------------------------------------------------------------------
// Panneau
// ---------------------------------------------------------------------------
PanneauAnalyses::PanneauAnalyses(QWidget* parent) : QWidget(parent) {
    construire();
}

void PanneauAnalyses::construire() {
    auto* disposition = new QVBoxLayout(this);
    disposition->setContentsMargins(6, 6, 6, 6);

    auto* barre = new QHBoxLayout;
    barre->addWidget(new QLabel("Analyse"));
    type_ = new QComboBox;
    type_->addItem("Balayage continu (.dc)");
    type_->addItem("Réponse en fréquence (.ac)");
    type_->addItem("Spectre du dernier relevé (FFT)");
    barre->addWidget(type_);

    reglages_ = new QStackedWidget;

    {   // --- balayage continu
        auto* page = new QWidget;
        auto* ligne = new QHBoxLayout(page);
        ligne->setContentsMargins(0, 0, 0, 0);
        ligne->addWidget(new QLabel("Grandeur"));
        source_ = new QComboBox;
        source_->setMinimumWidth(110);
        connect(source_, &QComboBox::currentTextChanged, this,
                &PanneauAnalyses::adapter_bornes);
        connect(source_, &QComboBox::activated, this,
                [this](int) { source_choisie_ = true; });
        ligne->addWidget(source_);
        ligne->addWidget(new QLabel("de"));
        debut_ = new QDoubleSpinBox;
        debut_->setRange(-1000, 1000);
        debut_->setValue(0);
        ligne->addWidget(debut_);
        ligne->addWidget(new QLabel("à"));
        fin_ = new QDoubleSpinBox;
        fin_->setRange(-1000, 1000);
        fin_->setValue(5);
        ligne->addWidget(fin_);
        ligne->addWidget(new QLabel("pas"));
        pas_ = new QDoubleSpinBox;
        pas_->setRange(0.001, 1000);
        pas_->setDecimals(3);
        pas_->setValue(0.1);
        ligne->addWidget(pas_);
        reglages_->addWidget(page);
    }
    {   // --- réponse en fréquence
        auto* page = new QWidget;
        auto* ligne = new QHBoxLayout(page);
        ligne->setContentsMargins(0, 0, 0, 0);
        ligne->addWidget(new QLabel("de"));
        f_debut_ = new QDoubleSpinBox;
        f_debut_->setRange(0.01, 1e9);
        f_debut_->setDecimals(2);
        f_debut_->setValue(10);
        ligne->addWidget(f_debut_);
        ligne->addWidget(new QLabel("Hz à"));
        f_fin_ = new QDoubleSpinBox;
        f_fin_->setRange(1, 1e9);
        f_fin_->setDecimals(0);
        f_fin_->setValue(1e6);
        ligne->addWidget(f_fin_);
        ligne->addWidget(new QLabel("Hz, points par décade"));
        points_ = new QSpinBox;
        points_->setRange(2, 200);
        points_->setValue(20);
        ligne->addWidget(points_);
        reglages_->addWidget(page);
    }
    {   // --- spectre
        auto* page = new QWidget;
        auto* ligne = new QHBoxLayout(page);
        ligne->setContentsMargins(0, 0, 0, 0);
        ligne->addWidget(new QLabel("Signal"));
        signal_ = new QComboBox;
        signal_->setMinimumWidth(110);
        connect(signal_, &QComboBox::activated, this,
                [this](int) { signal_choisi_ = true; });
        ligne->addWidget(signal_);
        ligne->addWidget(new QLabel("harmoniques"));
        harmoniques_ = new QSpinBox;
        harmoniques_->setRange(2, 50);
        harmoniques_->setValue(9);
        ligne->addWidget(harmoniques_);
        reglages_->addWidget(page);
    }
    barre->addWidget(reglages_, 1);

    auto* lancer = new QPushButton("Lancer l'analyse");
    connect(lancer, &QPushButton::clicked, this, &PanneauAnalyses::lancer);
    barre->addWidget(lancer);
    connect(type_, &QComboBox::currentIndexChanged, reglages_,
            &QStackedWidget::setCurrentIndex);
    disposition->addLayout(barre);

    trace_ = new TraceCourbes;
    disposition->addWidget(trace_, 1);

    resume_widget_ = new QLabel("Choisissez une analyse puis lancez-la.");
    resume_widget_->setWordWrap(true);
    QFont fonte("monospace");
    fonte.setStyleHint(QFont::TypeWriter);
    resume_widget_->setFont(fonte);
    disposition->addWidget(resume_widget_);
}

void PanneauAnalyses::proposer_signaux(const QStringList& signaux) {
    const QString choisi = signal_->currentText();
    // Les rails d'alimentation sont constants : proposer « 5V » comme signal
    // par défaut n'aurait aucun sens pour un spectre.
    static const QStringList rails = {"GND", "5V", "3V3", "VIN"};
    // Tensions de nœuds d'abord, courants ensuite : c'est une tension qu'on
    // veut voir en premier quand on ouvre un analyseur de spectre.
    QStringList tensions, courants;
    for (const QString& signal : signaux) {
        if (rails.contains(signal, Qt::CaseInsensitive)) continue;
        (signal.startsWith("I(") ? courants : tensions) << signal;
    }
    const QStringList utiles = tensions + courants;
    signal_->clear();
    signal_->addItems(utiles);
    if (signal_choisi_ && utiles.contains(choisi))
        signal_->setCurrentText(choisi);
    else if (!utiles.isEmpty())
        signal_->setCurrentIndex(0);
}

void PanneauAnalyses::proposer_sources(const QStringList& sources) {
    const QString choisie = source_->currentText();
    source_->clear();
    source_->addItems(sources);
    // Le choix de l'utilisateur prime, mais seulement s'il en a fait un : la
    // liste se remplit au fur et à mesure que le schéma se construit, et la
    // première entrée arrivée ne doit pas rester sélectionnée pour toujours.
    if (source_choisie_ && sources.contains(choisie))
        source_->setCurrentText(choisie);
    else if (!sources.isEmpty())
        source_->setCurrentIndex(0);
    adapter_bornes(source_->currentText());
}

// Balayer une tension et balayer une résistance n'ont pas les mêmes ordres de
// grandeur : proposer « 0 à 5 » pour une résistance conduirait à un circuit
// singulier dès le premier point. Les bornes suivent donc la grandeur choisie.
void PanneauAnalyses::adapter_bornes(const QString& grandeur) {
    if (!debut_ || !fin_ || !pas_) return;
    const bool resistance = grandeur.startsWith('R');
    debut_->setRange(resistance ? 1.0 : -1000.0, 1e6);
    fin_->setRange(resistance ? 1.0 : -1000.0, 1e6);
    pas_->setRange(resistance ? 1.0 : 0.001, 1e5);
    debut_->setSuffix(resistance ? " Ω" : " V");
    fin_->setSuffix(resistance ? " Ω" : " V");
    pas_->setSuffix(resistance ? " Ω" : " V");
    pas_->setDecimals(resistance ? 0 : 3);
    debut_->setValue(resistance ? 100.0 : 0.0);
    fin_->setValue(resistance ? 10000.0 : 5.0);
    pas_->setValue(resistance ? 100.0 : 0.1);
}

void PanneauAnalyses::choisir_analyse(int rang) {
    type_->setCurrentIndex(rang);
    reglages_->setCurrentIndex(rang);
}

void PanneauAnalyses::lancer() {
    switch (type_->currentIndex()) {
        case 0: {
            if (source_->currentText().isEmpty()) {
                signaler("Aucune source à balayer : posez une pile ou un "
                         "générateur de signaux sur le schéma.");
                return;
            }
            const QString directive =
                QString(".dc %1 %2 %3 %4")
                    .arg(source_->currentText())
                    .arg(debut_->value())
                    .arg(fin_->value())
                    .arg(pas_->value() > 0 ? pas_->value() : 0.1);
            derniere_directive_ = directive;
            emit balayage_demande(directive, false);
            break;
        }
        case 1: {
            const QString directive = QString(".ac dec %1 %2 %3")
                                          .arg(points_->value())
                                          .arg(f_debut_->value())
                                          .arg(f_fin_->value());
            derniere_directive_ = directive;
            emit balayage_demande(directive, true);
            break;
        }
        default:
            if (signal_->currentText().isEmpty()) {
                signaler("Aucun signal relevé : lancez d'abord la simulation.");
                return;
            }
            emit spectre_demande(signal_->currentText(), harmoniques_->value());
            break;
    }
}

void PanneauAnalyses::afficher_balayage(const coeur::Balayage& balayage,
                                        bool bode, const QString& reference) {
    dernier_balayage_ = balayage;
    dernier_spectre_ = {};
    if (balayage.vide()) {
        signaler("L'analyse n'a produit aucun point.");
        return;
    }

    QVector<TraceCourbes::Serie> series;
    QString texte;
    if (bode) {
        // Diagramme de Bode : gain en décibels à gauche, phase à droite.
        // La référence est l'entrée quand elle est identifiable.
        const coeur::Courbe* entree =
            balayage.courbe(reference.isEmpty() ? "in"
                                                : reference.toLower().toStdString());
        for (const coeur::Courbe& courbe : balayage.courbes) {
            if (!courbe.complexe()) continue;
            if (entree && &courbe == entree) continue;
            // Les courants ne se lisent pas en décibels de tension : on les
            // laisse au balayage continu et au CSV.
            if (courbe.nom.rfind("I(", 0) == 0) continue;
            const std::vector<double> gains =
                coeur::gain_decibels(courbe, entree);
            TraceCourbes::Serie gain;
            gain.nom = QString::fromStdString(courbe.nom) + " (dB)";
            TraceCourbes::Serie phase;
            phase.nom = QString::fromStdString(courbe.nom) + " (°)";
            phase.axe_droit = true;
            for (size_t k = 0; k < balayage.abscisse.size(); ++k) {
                gain.points.append(QPointF(balayage.abscisse[k], gains[k]));
                double valeur = courbe.phases[k];
                if (entree && k < entree->phases.size())
                    valeur -= entree->phases[k];
                phase.points.append(QPointF(balayage.abscisse[k], valeur));
            }
            series.append(gain);
            series.append(phase);

            const double coupure =
                coeur::frequence_coupure(balayage, courbe, entree);
            texte += QString("%1 : gain max %2 dB")
                         .arg(QString::fromStdString(courbe.nom))
                         .arg(coeur::gain_maximal(courbe, entree), 0, 'f', 2);
            if (coupure > 0)
                texte += QString(", coupure −3 dB à %1 Hz")
                             .arg(coupure, 0, 'f', 1);
            texte += "\n";
        }
        trace_->definir_axes("Fréquence (Hz)", "Gain (dB)", "Phase (°)");
        trace_->definir(series, true, false);
    } else {
        for (const coeur::Courbe& courbe : balayage.courbes) {
            TraceCourbes::Serie serie;
            serie.nom = QString::fromStdString(courbe.nom);
            for (size_t k = 0; k < balayage.abscisse.size()
                              && k < courbe.valeurs.size();
                 ++k)
                serie.points.append(
                    QPointF(balayage.abscisse[k], courbe.valeurs[k]));
            if (!serie.points.isEmpty()) series.append(serie);
            if (!courbe.valeurs.empty())
                texte += QString("%1 : de %2 à %3\n")
                             .arg(QString::fromStdString(courbe.nom))
                             .arg(courbe.valeurs.front(), 0, 'g', 4)
                             .arg(courbe.valeurs.back(), 0, 'g', 4);
        }
        trace_->definir_axes(QString::fromStdString(balayage.grandeur),
                             "Valeur", "");
        trace_->definir(series, false, false);
    }

    resume_ = QString("%1 : %2 points, %3 courbes\n")
                  .arg(derniere_directive_)
                  .arg(balayage.abscisse.size())
                  .arg(series.size())
              + texte;
    resume_widget_->setText(resume_.trimmed());
}

void PanneauAnalyses::afficher_spectre(const coeur::Spectre& spectre,
                                       const QString& signal) {
    dernier_spectre_ = spectre;
    dernier_balayage_.vider();
    if (!spectre.valide) {
        signaler("Signal trop court ou non périodique : le spectre demande au "
                 "moins une période complète.");
        return;
    }

    TraceCourbes::Serie raies;
    raies.nom = signal;
    for (const coeur::RaieSpectre& raie : spectre.raies)
        raies.points.append(QPointF(raie.frequence, raie.amplitude));
    trace_->definir_axes("Fréquence (Hz)", "Amplitude", "");
    trace_->definir({raies}, false, true);

    resume_ = QString("%1 : fondamentale %2 Hz, continu %3 V, efficace %4 V, "
                      "distorsion %5 %\n")
                  .arg(signal)
                  .arg(spectre.fondamentale, 0, 'f', 1)
                  .arg(spectre.continu, 0, 'f', 3)
                  .arg(spectre.efficace, 0, 'f', 3)
                  .arg(spectre.thd, 0, 'f', 2);
    for (const coeur::RaieSpectre& raie : spectre.raies)
        resume_ += QString("  H%1  %2 Hz  %3 V  (%4 %)\n")
                       .arg(raie.rang)
                       .arg(raie.frequence, 0, 'f', 1)
                       .arg(raie.amplitude, 0, 'f', 4)
                       .arg(raie.amplitude_relative, 0, 'f', 1);
    resume_widget_->setText(resume_.trimmed());
}

void PanneauAnalyses::afficher_mesures(const coeur::Mesures& mesures,
                                       const QString& signal) {
    if (!mesures.valide) return;
    resume_ += QString("\n%1 : min %2 V, max %3 V, moyenne %4 V, efficace %5 V, "
                       "%6 Hz, rapport cyclique %7 %, montée %8 µs")
                   .arg(signal)
                   .arg(mesures.minimum, 0, 'f', 3)
                   .arg(mesures.maximum, 0, 'f', 3)
                   .arg(mesures.moyenne, 0, 'f', 3)
                   .arg(mesures.efficace, 0, 'f', 3)
                   .arg(mesures.frequence, 0, 'f', 1)
                   .arg(mesures.rapport_cyclique, 0, 'f', 1)
                   .arg(mesures.temps_montee * 1e6, 0, 'f', 2);
    resume_widget_->setText(resume_.trimmed());
}

void PanneauAnalyses::signaler(const QString& message) {
    resume_ = message;
    resume_widget_->setText(message);
    trace_->vider();
}

QString PanneauAnalyses::csv() const {
    if (!dernier_balayage_.vide())
        return QString::fromStdString(coeur::balayage_csv(dernier_balayage_));
    if (!dernier_spectre_.valide) return {};
    QString texte = "rang;frequence;amplitude;pourcentage\n";
    for (const coeur::RaieSpectre& raie : dernier_spectre_.raies)
        texte += QString("%1;%2;%3;%4\n")
                     .arg(raie.rang)
                     .arg(raie.frequence)
                     .arg(raie.amplitude)
                     .arg(raie.amplitude_relative);
    return texte;
}
