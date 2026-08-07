#include "app/Oscilloscope.h"

#include <QCheckBox>
#include <QComboBox>
#include <QGridLayout>
#include <QLabel>
#include <QPainter>
#include <QPainterPath>
#include <QVBoxLayout>

#include <algorithm>
#include <cmath>

namespace {

// Couleurs des voies, dans l'ordre traditionnel des oscilloscopes.
const QColor kCouleurs[TraceOscilloscope::kVoies] = {
    QColor(240, 200, 40),    // jaune
    QColor(80, 190, 255),    // cyan
    QColor(240, 110, 200),   // magenta
    QColor(120, 230, 130)};  // vert

const QColor kFond(18, 22, 28);
const QColor kGrille(52, 62, 72);
const QColor kGrilleAxe(86, 100, 112);

// Bases de temps proposées, en secondes de fenêtre entière.
const double kFenetres[] = {0.002, 0.005, 0.01, 0.02, 0.05, 0.1,
                            0.25,  0.5,   1.0,  2.0,  5.0};

}  // namespace

// ---------------------------------------------------------------------------
TraceOscilloscope::TraceOscilloscope(QWidget* parent) : QWidget(parent) {
    setMinimumHeight(200);
    setAutoFillBackground(false);
}

QColor TraceOscilloscope::couleur_voie(int voie) {
    return kCouleurs[std::clamp(voie, 0, kVoies - 1)];
}

void TraceOscilloscope::definir_signal(int voie, const QString& designation) {
    if (voie < 0 || voie >= kVoies) return;
    if (voies_[voie].designation == designation) return;
    voies_[voie].designation = designation;
    voies_[voie].valeurs.assign(temps_.size(), 0.0f);   // reste aligné
    update();
}

QString TraceOscilloscope::signal_voie(int voie) const {
    if (voie < 0 || voie >= kVoies) return {};
    return voies_[voie].designation;
}

void TraceOscilloscope::definir_fenetre(double secondes) {
    fenetre_ = std::clamp(secondes, 1e-3, kMemoire);
    update();
}

void TraceOscilloscope::definir_echelle(double volts_par_division) {
    volts_par_division_ = std::max(0.01, volts_par_division);
    update();
}

bool TraceOscilloscope::voie_active(int voie) const {
    return voie >= 0 && voie < kVoies && !voies_[voie].designation.isEmpty();
}

double TraceOscilloscope::derniere_valeur(int voie) const {
    if (!voie_active(voie) || voies_[voie].valeurs.empty()) return 0.0;
    return voies_[voie].valeurs.back();
}

// Les deux mesures sont calculées en un seul balayage, et à l'envers : le
// tampon est trié dans le temps, on s'arrête donc dès qu'on sort de la
// fenêtre visible au lieu de relire les cinq secondes de mémoire.
void TraceOscilloscope::mesurer(int voie, double& moyenne, double& maximum) const {
    moyenne = 0;
    maximum = 0;
    if (!voie_active(voie) || voies_[voie].valeurs.size() != temps_.size()) return;

    const float debut = static_cast<float>(dernier_instant_ - fenetre_);
    double somme = 0;
    size_t compte = 0;
    for (size_t k = temps_.size(); k-- > 0;) {
        if (temps_[k] < debut) break;
        const float valeur = voies_[voie].valeurs[k];
        somme += valeur;
        if (valeur > maximum) maximum = valeur;
        ++compte;
    }
    if (compte) moyenne = somme / compte;
}

const std::vector<double>* TraceOscilloscope::courbe_pour(
    const coeur::Formes& formes, const QString& designation) {
    if (designation.isEmpty()) return nullptr;
    if (designation.startsWith("I(") && designation.endsWith(")")) {
        const std::string reference =
            designation.mid(2, designation.size() - 3).toLower().toStdString();
        auto it = formes.courants.find(reference);
        return it == formes.courants.end() ? nullptr : &it->second;
    }
    auto it = formes.tensions.find(designation.toLower().toStdString());
    return it == formes.tensions.end() ? nullptr : &it->second;
}

void TraceOscilloscope::ajouter(const coeur::Formes& formes,
                                double instant_debut) {
    if (gele_ || formes.vide()) return;

    // Les courbes sont recherchées une seule fois par trame, pas par point.
    const std::vector<double>* courbes[kVoies] = {};
    for (int v = 0; v < kVoies; ++v)
        courbes[v] = courbe_pour(formes, voies_[v].designation);

    for (size_t k = 0; k < formes.temps.size(); ++k) {
        temps_.push_back(static_cast<float>(instant_debut + formes.temps[k]));
        for (int v = 0; v < kVoies; ++v) {
            const std::vector<double>* courbe = courbes[v];
            const double valeur =
                (courbe && k < courbe->size()) ? (*courbe)[k] : 0.0;
            voies_[v].valeurs.push_back(static_cast<float>(valeur));
        }
    }
    dernier_instant_ = temps_.empty() ? 0.0 : temps_.back();
    purger();
    update();
}

void TraceOscilloscope::purger() {
    const float limite = static_cast<float>(dernier_instant_ - kMemoire);
    while (!temps_.empty() && temps_.front() < limite) {
        temps_.pop_front();
        for (auto& voie : voies_)
            if (!voie.valeurs.empty()) voie.valeurs.pop_front();
    }
}

void TraceOscilloscope::vider() {
    temps_.clear();
    for (auto& voie : voies_) voie.valeurs.clear();
    dernier_instant_ = 0.0;
    update();
}

void TraceOscilloscope::paintEvent(QPaintEvent*) {
    QPainter peintre(this);
    peintre.setRenderHint(QPainter::Antialiasing, true);
    const QRectF zone = rect().adjusted(46, 8, -8, -22);
    peintre.fillRect(rect(), kFond);

    // --- grille : 10 divisions en temps, 8 en tension
    peintre.setPen(QPen(kGrille, 0.8, Qt::DotLine));
    for (int k = 1; k < 10; ++k) {
        const double x = zone.left() + zone.width() * k / 10.0;
        peintre.drawLine(QPointF(x, zone.top()), QPointF(x, zone.bottom()));
    }
    for (int k = 1; k < 8; ++k) {
        const double y = zone.top() + zone.height() * k / 8.0;
        peintre.drawLine(QPointF(zone.left(), y), QPointF(zone.right(), y));
    }
    peintre.setPen(QPen(kGrilleAxe, 1.0));
    peintre.drawRect(zone);
    const double y_zero = zone.bottom();

    // --- axes chiffrés
    QFont police = peintre.font();
    police.setPointSizeF(8.0);
    peintre.setFont(police);
    peintre.setPen(QPen(QColor(150, 165, 178), 1));
    for (int k = 0; k <= 8; k += 2) {
        const double y = zone.bottom() - zone.height() * k / 8.0;
        peintre.drawText(QRectF(0, y - 8, 42, 16),
                         Qt::AlignRight | Qt::AlignVCenter,
                         QString("%1 V").arg(k * volts_par_division_, 0, 'g', 3));
    }
    const double debut = dernier_instant_ - fenetre_;
    for (int k = 0; k <= 10; k += 5) {
        const double x = zone.left() + zone.width() * k / 10.0;
        const double instant = debut + fenetre_ * k / 10.0;
        peintre.drawText(QRectF(x - 45, zone.bottom() + 3, 90, 16),
                         Qt::AlignCenter,
                         QString("%1 s").arg(std::max(0.0, instant), 0, 'f', 3));
    }

    if (temps_.size() < 2) {
        peintre.setPen(QPen(QColor(120, 135, 148), 1));
        police.setPointSizeF(10.0);
        peintre.setFont(police);
        peintre.drawText(zone, Qt::AlignCenter,
                         "Lancez la simulation, puis choisissez un signal.");
        return;
    }

    // --- tracé, par colonne de pixels
    //
    // Un créneau contient bien plus de points que la fenêtre n'a de pixels.
    // Tracer un point sur deux ferait disparaître des impulsions entières :
    // on relève donc le minimum ET le maximum de chaque colonne, ce qui
    // conserve fidèlement les fronts. C'est la méthode des oscilloscopes
    // numériques.
    const int largeur = std::max(1, static_cast<int>(zone.width()));
    const double echelle_y = zone.height() / (8.0 * volts_par_division_);

    for (int v = 0; v < kVoies; ++v) {
        if (!voie_active(v) || voies_[v].valeurs.size() != temps_.size()) continue;

        std::vector<float> minima(largeur, std::numeric_limits<float>::max());
        std::vector<float> maxima(largeur, std::numeric_limits<float>::lowest());
        bool quelque_chose = false;

        for (size_t k = 0; k < temps_.size(); ++k) {
            const double position = (temps_[k] - debut) / fenetre_;
            if (position < 0.0 || position > 1.0) continue;
            const int colonne = std::min(
                largeur - 1, static_cast<int>(position * (largeur - 1)));
            const float valeur = voies_[v].valeurs[k];
            minima[colonne] = std::min(minima[colonne], valeur);
            maxima[colonne] = std::max(maxima[colonne], valeur);
            quelque_chose = true;
        }
        if (!quelque_chose) continue;

        peintre.setPen(QPen(kCouleurs[v], 1.6));
        QPainterPath chemin;
        bool commence = false;
        double x_precedent = 0, y_precedent = 0;
        for (int colonne = 0; colonne < largeur; ++colonne) {
            if (maxima[colonne] < minima[colonne]) continue;   // colonne vide
            const double x = zone.left() + colonne;
            const double y_haut = y_zero - maxima[colonne] * echelle_y;
            const double y_bas = y_zero - minima[colonne] * echelle_y;
            if (!commence) {
                chemin.moveTo(x, y_bas);
                commence = true;
            } else {
                chemin.lineTo(x, y_precedent);   // raccord horizontal
            }
            chemin.lineTo(x, y_bas);
            chemin.lineTo(x, y_haut);            // trait vertical = le front
            x_precedent = x;
            y_precedent = y_haut;
        }
        (void)x_precedent;
        peintre.setClipRect(zone);
        peintre.drawPath(chemin);
        peintre.setClipping(false);
    }
}

// ---------------------------------------------------------------------------
Oscilloscope::Oscilloscope(QWidget* parent) : QWidget(parent) {
    trace_ = new TraceOscilloscope(this);

    auto* disposition = new QVBoxLayout(this);
    disposition->setContentsMargins(4, 4, 4, 4);
    disposition->addWidget(trace_, 1);

    auto* reglages = new QGridLayout;
    reglages->setHorizontalSpacing(10);

    for (int v = 0; v < TraceOscilloscope::kVoies; ++v) {
        auto* pastille = new QLabel(QString("■ Voie %1").arg(v + 1));
        pastille->setStyleSheet(
            QString("color: %1; font-weight: bold;")
                .arg(TraceOscilloscope::couleur_voie(v).name()));
        auto* selecteur = new QComboBox;
        selecteur->addItem("— aucun —", QString());
        selecteur->setMinimumWidth(140);
        connect(selecteur, &QComboBox::currentTextChanged, this,
                [this, v](const QString& texte) {
                    trace_->definir_signal(v, texte.startsWith("—") ? QString()
                                                                    : texte);
                    rafraichir_mesures();
                });
        auto* mesure = new QLabel("—");
        mesure->setMinimumWidth(150);

        reglages->addWidget(pastille, 0, v * 3);
        reglages->addWidget(selecteur, 0, v * 3 + 1);
        reglages->addWidget(mesure, 0, v * 3 + 2);
        selecteurs_[v] = selecteur;
        mesures_[v] = mesure;
    }

    auto* base_temps = new QComboBox;
    for (double fenetre : kFenetres)
        base_temps->addItem(fenetre < 1.0
                                ? QString("%1 ms").arg(fenetre * 1000, 0, 'g', 3)
                                : QString("%1 s").arg(fenetre, 0, 'g', 3),
                            fenetre);
    base_temps->setCurrentIndex(7);            // 500 ms
    connect(base_temps, &QComboBox::currentIndexChanged, this,
            [this, base_temps](int) {
                const double fenetre = base_temps->currentData().toDouble();
                trace_->definir_fenetre(fenetre);
                // Une fenêtre étroite n'a d'intérêt que si le calcul est assez
                // fin : on vise mille points par écran. Mais élargir la
                // fenêtre ne doit pas dégrader la résolution en dessous de ce
                // qu'il faut pour voir une PWM — d'où le plafond.
                emit resolution_souhaitee(
                    std::clamp(fenetre / 1000.0, 5e-6, 50e-6));
            });

    auto* echelle = new QComboBox;
    for (double volts : {0.1, 0.25, 0.5, 1.0, 2.0, 5.0})
        echelle->addItem(QString("%1 V/div").arg(volts, 0, 'g', 3), volts);
    echelle->setCurrentIndex(3);               // 1 V/div
    connect(echelle, &QComboBox::currentIndexChanged, this, [this, echelle](int) {
        trace_->definir_echelle(echelle->currentData().toDouble());
    });

    auto* gel = new QCheckBox("Geler");
    connect(gel, &QCheckBox::toggled, this,
            [this](bool coche) { trace_->definir_gel(coche); });

    base_temps_ = base_temps;
    reglages->addWidget(new QLabel("Base de temps"), 1, 0);
    reglages->addWidget(base_temps, 1, 1);
    reglages->addWidget(new QLabel("Échelle"), 1, 3);
    reglages->addWidget(echelle, 1, 4);
    reglages->addWidget(gel, 1, 6);
    reglages->setColumnStretch(11, 1);
    disposition->addLayout(reglages);
}

void Oscilloscope::ajouter_trame(const coeur::Formes& formes,
                                 double instant_debut) {
    trace_->ajouter(formes, instant_debut);
    rafraichir_mesures();
}

void Oscilloscope::vider() { trace_->vider(); }

void Oscilloscope::rafraichir_mesures() {
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v) {
        if (!trace_->voie_active(v)) {
            mesures_[v]->setText("—");
            continue;
        }
        double moyenne = 0, maximum = 0;
        trace_->mesurer(v, moyenne, maximum);
        const bool courant = trace_->signal_voie(v).startsWith("I(");
        mesures_[v]->setText(
            courant ? QString("moy %1 / crête %2 mA")
                          .arg(moyenne * 1000, 0, 'f', 2)
                          .arg(maximum * 1000, 0, 'f', 2)
                    : QString("moy %1 / crête %2 V")
                          .arg(moyenne, 0, 'f', 2)
                          .arg(maximum, 0, 'f', 2));
        mesures_[v]->setStyleSheet(
            QString("color: %1;")
                .arg(TraceOscilloscope::couleur_voie(v).name()));
    }
}

void Oscilloscope::proposer_signaux(const QStringList& signaux) {
    if (signaux == signaux_) return;
    signaux_ = signaux;
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v) {
        QComboBox* selecteur = selecteurs_[v];
        const QString choix = selecteur->currentText();
        {
            const QSignalBlocker silence(selecteur);
            selecteur->clear();
            selecteur->addItem("— aucun —", QString());
            selecteur->addItems(signaux_);
            const int rang = selecteur->findText(choix);
            selecteur->setCurrentIndex(rang >= 0 ? rang : 0);
        }
        if (selecteur->currentIndex() == 0) trace_->definir_signal(v, QString());
    }
}

void Oscilloscope::sonder(const QString& designation) {
    if (designation.isEmpty()) return;
    // Si le signal est déjà suivi, ne pas le dupliquer.
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v)
        if (trace_->signal_voie(v) == designation) return;

    // Première voie libre, sinon on tourne.
    int cible = -1;
    for (int v = 0; v < TraceOscilloscope::kVoies && cible < 0; ++v)
        if (!trace_->voie_active(v)) cible = v;
    if (cible < 0) {
        cible = prochaine_voie_;
        prochaine_voie_ = (prochaine_voie_ + 1) % TraceOscilloscope::kVoies;
    }
    const int rang = selecteurs_[cible]->findText(designation);
    if (rang >= 0) selecteurs_[cible]->setCurrentIndex(rang);
}

bool Oscilloscope::aucune_voie_active() const {
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v)
        if (trace_->voie_active(v)) return false;
    return true;
}

void Oscilloscope::sonder_par_defaut() {
    if (!aucune_voie_active()) return;
    // Les rails d'alimentation sont constants : les afficher n'apprend rien.
    static const QStringList sans_interet = {"gnd", "0", "5v", "3v3", "vin"};
    int poses = 0;
    for (const QString& signal : signaux_) {
        if (poses >= 2) break;
        if (signal.startsWith("I(")) continue;
        if (sans_interet.contains(signal.toLower())) continue;
        sonder(signal);
        ++poses;
    }
}

void Oscilloscope::definir_base_temps(double secondes) {
    if (!base_temps_) return;
    // Choisit le calibre disponible le plus proche.
    int meilleur = 0;
    double ecart = 1e9;
    for (int k = 0; k < base_temps_->count(); ++k) {
        const double candidat =
            std::fabs(base_temps_->itemData(k).toDouble() - secondes);
        if (candidat < ecart) {
            ecart = candidat;
            meilleur = k;
        }
    }
    base_temps_->setCurrentIndex(meilleur);
}
