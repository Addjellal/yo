#include "app/Oscilloscope.h"

#include "app/BarreDefilante.h"

#include <QCheckBox>
#include <QComboBox>
#include <QDoubleSpinBox>
#include <QGridLayout>
#include <QLabel>
#include <QMouseEvent>
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
    // Sans suivi de la souris, le curseur ne bougerait qu'en gardant le
    // bouton enfoncé — ce n'est pas ainsi qu'on lit une courbe.
    setMouseTracking(true);
    // Assez pour lire une courbe, pas assez pour interdire de rétrécir le
    // panneau : au-delà, c'est l'utilisateur qui décide de la hauteur.
    setMinimumHeight(110);
    setAutoFillBackground(false);
}

QColor TraceOscilloscope::couleur_voie(int voie) {
    return kCouleurs[std::clamp(voie, 0, kVoies - 1)];
}

void TraceOscilloscope::definir_signal(int voie, const QString& designation) {
    if (voie < 0 || voie >= kVoies) return;
    if (voies_[voie].designation == designation) return;
    voies_[voie].designation = designation;
    // Un deque neuf, plutôt qu'un `assign` sur l'ancien.
    //
    // `deque::assign(n, …)` choisit entre effacer et insérer selon `n` et la
    // taille courante ; sur la branche d'insertion GCC calcule `n - size()`
    // sans pouvoir prouver que `n >= size()`, la soustraction non signée
    // déborde, et il annonce un memset de dix-huit trillions d'octets.
    // Borner `n` ne sert donc à rien — j'avais essayé — puisque c'est la
    // SOUSTRACTION qui déborde, pas `n`.
    //
    // Construire puis échanger supprime la branche : il n'y a plus de taille
    // précédente à comparer. C'est aussi plus clair — on veut un tampon neuf,
    // pas une modification de l'ancien.
    std::deque<float>(temps_.size(), 0.0f).swap(voies_[voie].valeurs);
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

// Fraction du temps passé au-dessus de la moitié de la crête : le rapport
// cyclique, mesuré et non déduit.
double TraceOscilloscope::rapport_cyclique(int voie) const {
    double moyenne = 0, maximum = 0;
    mesurer(voie, moyenne, maximum);
    if (maximum <= 1e-9) return 0.0;
    const float seuil = static_cast<float>(maximum / 2);
    const float debut = static_cast<float>(dernier_instant_ - fenetre_);
    size_t hauts = 0, total = 0;
    for (size_t k = temps_.size(); k-- > 0;) {
        if (temps_[k] < debut) break;
        if (voies_[voie].valeurs[k] > seuil) ++hauts;
        ++total;
    }
    return total ? static_cast<double>(hauts) / total : 0.0;
}

// Proportion d'instants où les deux voies sont dans le même état logique.
// Deux signaux identiques donnent 100 %, deux signaux indépendants environ
// 50 %, deux signaux en opposition 0 %.
double TraceOscilloscope::concordance(int a, int b) const {
    if (!voie_active(a) || !voie_active(b)) return 0.0;
    if (voies_[a].valeurs.size() != temps_.size()) return 0.0;
    if (voies_[b].valeurs.size() != temps_.size()) return 0.0;
    double moyenne = 0, crete_a = 0, crete_b = 0;
    mesurer(a, moyenne, crete_a);
    mesurer(b, moyenne, crete_b);
    if (crete_a <= 1e-9 || crete_b <= 1e-9) return 0.0;

    const float seuil_a = static_cast<float>(crete_a / 2);
    const float seuil_b = static_cast<float>(crete_b / 2);
    const float debut = static_cast<float>(dernier_instant_ - fenetre_);
    size_t accord = 0, total = 0;
    for (size_t k = temps_.size(); k-- > 0;) {
        if (temps_[k] < debut) break;
        if ((voies_[a].valeurs[k] > seuil_a) == (voies_[b].valeurs[k] > seuil_b))
            ++accord;
        ++total;
    }
    return total ? static_cast<double>(accord) / total : 0.0;
}

std::vector<double> TraceOscilloscope::courbe_pour(
    const coeur::Formes& formes, const QString& designation) const {
    if (designation.isEmpty()) return {};

    auto potentiel = [&formes](const QString& noeud) -> const std::vector<double>* {
        if (noeud.isEmpty()) return nullptr;
        auto it = formes.tensions.find(noeud.toLower().toStdString());
        return it == formes.tensions.end() ? nullptr : &it->second;
    };

    if (designation.startsWith("I(") && designation.endsWith(")")) {
        const std::string reference =
            designation.mid(2, designation.size() - 3).toLower().toStdString();
        auto it = formes.courants.find(reference);
        return it == formes.courants.end() ? std::vector<double>{} : it->second;
    }

    // LA TENSION AUX BORNES, et non le potentiel d'un point.
    //
    // C'est la grandeur qu'on cherche dès qu'on quitte les montages où tout
    // se mesure par rapport à la masse : la tension aux bornes d'un
    // condensateur dans un filtre, d'une bobine, de la résistance haute d'un
    // pont diviseur. Un oscilloscope d'atelier la donne avec deux sondes et
    // une soustraction mentale ; ici on la calcule.
    if (designation.startsWith("U(") && designation.endsWith(")")) {
        const QString reference = designation.mid(2, designation.size() - 3);
        auto it = bornes_.find(reference);
        if (it == bornes_.end()) return {};
        const std::vector<double>* a = potentiel(it->second.first);
        const std::vector<double>* b = potentiel(it->second.second);
        // Une borne EN L'AIR n'a pas de potentiel calculé : le nœud n'existe
        // pas dans la trame. On la prend pour zéro plutôt que de ne rien
        // tracer — c'est le comportement d'une sonde dont la pince est en
        // l'air, et le tracé plat dit alors la vérité.
        const std::size_t points =
            std::max(a ? a->size() : 0u, b ? b->size() : 0u);
        std::vector<double> difference(points, 0.0);
        for (std::size_t k = 0; k < points; ++k) {
            const double va = (a && k < a->size()) ? (*a)[k] : 0.0;
            const double vb = (b && k < b->size()) ? (*b)[k] : 0.0;
            difference[k] = va - vb;
        }
        return difference;
    }

    // LES GRANDEURS INTERNES : ni une tension, ni un courant.
    //
    // L'angle d'un servomoteur, la vitesse d'un moteur, le pas d'un pas à
    // pas. Elles ne sortent pas du solveur électrique mais du modèle du
    // composant, et c'est tout l'intérêt : on superpose alors la cause
    // électrique et l'effet mécanique sur le même écran.
    if (designation.startsWith("G(") && designation.endsWith(")")) {
        const std::string cle =
            designation.mid(2, designation.size() - 3).toStdString();
        auto it = formes.grandeurs.find(cle);
        return it == formes.grandeurs.end() ? std::vector<double>{}
                                            : it->second;
    }

    const std::vector<double>* courbe = potentiel(designation);
    return courbe ? *courbe : std::vector<double>{};
}

void Oscilloscope::definir_unites(
    const std::map<QString, QString>& unites) {
    unites_ = unites;
}

void Oscilloscope::definir_bornes(
    const std::map<QString, std::pair<QString, QString>>& bornes) {
    if (trace_) trace_->definir_bornes(bornes);
}

void TraceOscilloscope::ajouter(const coeur::Formes& formes,
                                double instant_debut) {
    if (gele_ || formes.vide()) return;

    // Les courbes sont recherchées une seule fois par trame, pas par point.
    std::vector<double> courbes[kVoies];
    for (int v = 0; v < kVoies; ++v)
        courbes[v] = courbe_pour(formes, voies_[v].designation);

    // UNE MESURE ABSENTE N'EST PAS UNE MESURE NULLE.
    //
    // On note, voie par voie, si la trame contenait vraiment le signal
    // demandé. Sans cela, un signal que le moteur ne fournit pas se traçait
    // en ligne plate à zéro : l'élève lisait « aucun courant » là où il aurait
    // fallu lire « je ne sais pas mesurer ça ».
    for (int v = 0; v < kVoies; ++v)
        voies_[v].mesuree =
            voies_[v].designation.isEmpty() || !courbes[v].empty();

    for (size_t k = 0; k < formes.temps.size(); ++k) {
        temps_.push_back(static_cast<float>(instant_debut + formes.temps[k]));
        for (int v = 0; v < kVoies; ++v) {
            const std::vector<double>& courbe = courbes[v];
            const double valeur = k < courbe.size() ? courbe[k] : 0.0;
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

    // Où placer le zéro ? En bas tant que tout reste positif — c'est le cas
    // d'une sortie logique ou d'une PWM, et on gagne toute la hauteur. Dès
    // qu'un signal descend sous zéro, on le remonte au milieu : sinon la
    // moitié d'une sinusoïde serait purement et simplement invisible.
    bool bipolaire = false;
    for (int v = 0; v < kVoies; ++v)
        for (float valeur : voies_[v].valeurs)
            if (valeur < -0.05f) { bipolaire = true; break; }
    const double y_zero =
        bipolaire ? zone.top() + zone.height() / 2.0 : zone.bottom();

    // --- axes chiffrés
    QFont police = peintre.font();
    police.setPointSizeF(8.0);
    peintre.setFont(police);
    peintre.setPen(QPen(QColor(150, 165, 178), 1));
    for (int k = 0; k <= 8; k += 2) {
        const double y = zone.bottom() - zone.height() * k / 8.0;
        // La graduation se lit à partir du zéro, où qu'il soit placé.
        const double valeur =
            (y_zero - y) / (zone.height() / 8.0) * volts_par_division_;
        peintre.drawText(QRectF(0, y - 8, 42, 16),
                         Qt::AlignRight | Qt::AlignVCenter,
                         QString("%1 V").arg(valeur, 0, 'g', 3));
    }
    // Trait du zéro, plus marqué : sans lui on ne sait plus où est la
    // référence quand elle n'est plus en bas de l'écran.
    if (bipolaire) {
        peintre.setPen(QPen(kGrilleAxe, 1.2));
        peintre.drawLine(QPointF(zone.left(), y_zero),
                         QPointF(zone.right(), y_zero));
        peintre.setPen(QPen(QColor(150, 165, 178), 1));
    }
    // Fenêtre réellement tracée. En déclenchement, elle se cale sur le front
    // trouvé, avec un cinquième d'écran avant lui : on voit ainsi ce qui a
    // précédé l'événement, comme le pré-déclenchement d'un appareil réel.
    double debut = dernier_instant_ - fenetre_;
    declenche_ = false;
    if (declenchement_ != Declenchement::Aucun) {
        const double front = chercher_front();
        if (front >= 0) {
            debut = front - 0.2 * fenetre_;
            declenche_ = true;
        } else if (declenchement_ == Declenchement::Normal
                   && debut_affiche_ > 0) {
            debut = debut_affiche_;      // rien de neuf : on garde l'image
        }
    }
    debut_affiche_ = debut;

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

    if (mode_xy_) {
        tracer_xy(peintre, zone, debut, echelle_y, y_zero);
        return;
    }

    for (int v = 0; v < kVoies; ++v) {
        // Une voie SANS MESURE ne se dessine pas du tout : tracer ses zéros
        // reviendrait à affirmer une valeur qu'on n'a jamais obtenue.
        if (!voie_active(v) || !voies_[v].mesuree
            || voies_[v].valeurs.size() != temps_.size())
            continue;
        const double continu = continu_voie(v, debut);

        std::vector<float> minima(largeur, std::numeric_limits<float>::max());
        std::vector<float> maxima(largeur, std::numeric_limits<float>::lowest());
        bool quelque_chose = false;

        for (size_t k = 0; k < temps_.size(); ++k) {
            const double position = (temps_[k] - debut) / fenetre_;
            if (position < 0.0 || position > 1.0) continue;
            const int colonne = std::min(
                largeur - 1, static_cast<int>(position * (largeur - 1)));
            const float valeur =
                static_cast<float>(valeur_affichee(v, k, continu));
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

    // --- repère du niveau de déclenchement
    if (declenchement_ != Declenchement::Aucun && voie_active(voie_declenchement_)) {
        const double y = y_zero - niveau_declenchement_ * echelle_y;
        if (y > zone.top() && y < zone.bottom()) {
            peintre.setPen(QPen(kCouleurs[voie_declenchement_], 1.0,
                                Qt::DashDotLine));
            peintre.drawLine(QPointF(zone.left(), y), QPointF(zone.right(), y));
            peintre.drawText(QRectF(zone.right() - 40, y - 14, 38, 14),
                             Qt::AlignRight, declenche_ ? "TRIG" : "?");
        }
        if (declenche_) {   // marque du front, à un cinquième de l'écran
            const double x = zone.left() + zone.width() * 0.2;
            peintre.setPen(QPen(QColor(200, 210, 220), 1.0, Qt::DotLine));
            peintre.drawLine(QPointF(x, zone.top()), QPointF(x, zone.bottom()));
        }
    }

    // --- curseurs
    auto tracer_curseur = [&](double instant, const QColor& couleur,
                              const QString& etiquette) {
        if (instant < debut || instant > debut + fenetre_) return;
        const double x = zone.left() + (instant - debut) / fenetre_ * zone.width();
        peintre.setPen(QPen(couleur, 1.0, Qt::DashLine));
        peintre.drawLine(QPointF(x, zone.top()), QPointF(x, zone.bottom()));
        peintre.drawText(QRectF(x + 3, zone.top() + 2, 20, 14), Qt::AlignLeft,
                         etiquette);
    };
    tracer_curseur(curseur_b_, QColor(120, 200, 255), "B");
    tracer_curseur(curseur_a_, QColor(255, 255, 255), "A");
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
        // Le texte affiché explique le signal, la donnée porte son nom :
        // « R1_2 — C1.1 · R1.2 » à l'écran, « R1_2 » pour la courbe.
        connect(selecteur, &QComboBox::currentIndexChanged, this,
                [this, v, selecteur](int) {
                    trace_->definir_signal(v, selecteur->currentData().toString());
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
    // LA VALEUR DE DÉPART SE POSE APRÈS LA CONNEXION.
    //
    // Elle se posait avant : `setCurrentIndex` ne déclenchait alors personne,
    // et la trace gardait sa fenêtre par défaut — cinquante millisecondes —
    // pendant que le sélecteur affichait « 500 ms ». Dix fois trop étroite,
    // sans que rien plante ni ne paraisse vide.
    //
    // C'est le pire genre de défaut d'interface : le réglage affiché est un
    // mensonge. Sur un clignotant d'une demi-seconde, l'élève ne voyait qu'un
    // trait plat et en concluait que son programme ne marchait pas.
    base_temps->setCurrentIndex(7);            // 500 ms

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

    // --- déclenchement : la rangée qui manquait pour que l'image tienne en
    // place. Mêmes réglages que sur un appareil : mode, voie, niveau, front.
    auto* mode = new QComboBox;
    mode->addItem("Auto", static_cast<int>(TraceOscilloscope::Declenchement::Auto));
    mode->addItem("Normal",
                  static_cast<int>(TraceOscilloscope::Declenchement::Normal));
    mode->addItem("Sans", static_cast<int>(TraceOscilloscope::Declenchement::Aucun));
    connect(mode, &QComboBox::currentIndexChanged, this, [this, mode](int) {
        trace_->definir_declenchement(
            static_cast<TraceOscilloscope::Declenchement>(
                mode->currentData().toInt()));
    });

    auto* source = new QComboBox;
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v)
        source->addItem(QString("Voie %1").arg(v + 1));
    connect(source, &QComboBox::currentIndexChanged, this,
            [this](int rang) { trace_->definir_voie_declenchement(rang); });

    auto* niveau = new QDoubleSpinBox;
    niveau->setRange(-100, 100);
    niveau->setDecimals(2);
    niveau->setSingleStep(0.1);
    niveau->setValue(2.5);
    niveau->setSuffix(" V");
    connect(niveau, &QDoubleSpinBox::valueChanged, this,
            [this](double volts) { trace_->definir_niveau_declenchement(volts); });

    auto* front = new QComboBox;
    front->addItem("Front ↑");
    front->addItem("Front ↓");
    connect(front, &QComboBox::currentIndexChanged, this,
            [this](int rang) { trace_->definir_front_montant(rang == 0); });

    // --- réglages d'une voie à la fois : couplage, décalage, et le mode XY.
    // Quatre jeux de boutons prendraient toute la place ; on désigne la voie.
    auto* voie_reglee = new QComboBox;
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v)
        voie_reglee->addItem(QString("Voie %1").arg(v + 1));
    auto* couplage = new QComboBox;
    couplage->addItem("Couplage continu");
    couplage->addItem("Couplage alternatif");
    auto* decalage = new QDoubleSpinBox;
    decalage->setRange(-100, 100);
    decalage->setDecimals(2);
    decalage->setSingleStep(0.5);
    decalage->setSuffix(" V de décalage");
    auto* xy = new QCheckBox("Mode XY");
    xy->setToolTip("Voie 1 en abscisse, voie 2 en ordonnée : la figure de "
                   "Lissajous montre le déphasage d'un coup d'œil.");

    connect(voie_reglee, &QComboBox::currentIndexChanged, this,
            [this, couplage, decalage](int voie) {
                const QSignalBlocker s1(couplage);
                const QSignalBlocker s2(decalage);
                couplage->setCurrentIndex(
                    trace_->couplage_alternatif(voie) ? 1 : 0);
                decalage->setValue(trace_->decalage(voie));
            });
    connect(couplage, &QComboBox::currentIndexChanged, this,
            [this, voie_reglee](int rang) {
                trace_->definir_couplage_alternatif(voie_reglee->currentIndex(),
                                                    rang == 1);
            });
    connect(decalage, &QDoubleSpinBox::valueChanged, this,
            [this, voie_reglee](double volts) {
                trace_->definir_decalage(voie_reglee->currentIndex(), volts);
            });
    connect(xy, &QCheckBox::toggled, this,
            [this](bool coche) { trace_->definir_mode_xy(coche); });

    reglages->addWidget(voie_reglee, 3, 1);
    reglages->addWidget(couplage, 3, 3);
    reglages->addWidget(decalage, 3, 4);
    reglages->addWidget(xy, 3, 6);
    reglages->addWidget(new QLabel("Réglage d'une voie"), 3, 0);

    niveau_ = niveau;
    reglages->addWidget(new QLabel("Déclenchement"), 2, 0);
    reglages->addWidget(mode, 2, 1);
    reglages->addWidget(source, 2, 3);
    reglages->addWidget(niveau, 2, 4);
    reglages->addWidget(front, 2, 6);
    // Quatre rangées de sept colonnes : mises telles quelles, elles exigeaient
    // 1738 pixels de large pour toute la fenêtre, et plus aucun panneau ne
    // pouvait être redimensionné. Défilantes, elles n'exigent plus rien.
    disposition->addWidget(ihm::barre_defilante(reglages));

    // Lecture des curseurs, sous la courbe : la souris suit, un clic pose le
    // repère, et l'écart des deux donne temps, tension et fréquence.
    curseurs_ = new QLabel("Curseurs : passez la souris sur la courbe, "
                           "cliquez pour poser le repère.");
    QFont fonte("monospace");
    fonte.setStyleHint(QFont::TypeWriter);
    curseurs_->setFont(fonte);
    curseurs_->setStyleSheet("color: #444;");
    // Le texte d'une étiquette fixe sa largeur minimale : cette phrase-là, en
    // chasse fixe, réclamait à elle seule 528 pixels pour toute la fenêtre.
    // Elle accepte donc d'être tronquée plutôt que d'imposer sa mesure.
    curseurs_->setSizePolicy(QSizePolicy::Ignored, QSizePolicy::Preferred);
    disposition->addWidget(curseurs_);
    connect(trace_, &TraceOscilloscope::curseurs_changes, this, [this] {
        const QString lecture = trace_->lecture_curseurs();
        curseurs_->setText(lecture.isEmpty()
                               ? QString("Curseurs : passez la souris sur la "
                                         "courbe, cliquez pour poser le repère.")
                               : lecture);
    });
}

void TraceOscilloscope::definir_decalage(int voie, double volts) {
    if (voie < 0 || voie >= kVoies) return;
    voies_[voie].decalage = volts;
    update();
}

double TraceOscilloscope::decalage(int voie) const {
    return (voie < 0 || voie >= kVoies) ? 0.0 : voies_[voie].decalage;
}

void TraceOscilloscope::definir_couplage_alternatif(int voie, bool alternatif) {
    if (voie < 0 || voie >= kVoies) return;
    voies_[voie].alternatif = alternatif;
    update();
}

bool TraceOscilloscope::couplage_alternatif(int voie) const {
    return (voie >= 0 && voie < kVoies) && voies_[voie].alternatif;
}

void TraceOscilloscope::definir_mode_xy(bool xy) {
    mode_xy_ = xy;
    update();
}

// Composante continue d'une voie sur la fenêtre affichée. C'est elle que le
// couplage alternatif retire — exactement ce que fait le condensateur de
// liaison à l'entrée d'un appareil.
double TraceOscilloscope::continu_voie(int voie, double debut) const {
    const Voie& cible = voies_[voie];
    if (cible.valeurs.size() != temps_.size() || temps_.empty()) return 0.0;
    double somme = 0;
    int compte = 0;
    for (size_t k = 0; k < temps_.size(); ++k) {
        if (temps_[k] < debut || temps_[k] > debut + fenetre_) continue;
        somme += cible.valeurs[k];
        ++compte;
    }
    return compte ? somme / compte : 0.0;
}

double TraceOscilloscope::valeur_affichee(int voie, size_t rang,
                                          double continu) const {
    const Voie& cible = voies_[voie];
    if (rang >= cible.valeurs.size()) return 0.0;
    return cible.valeurs[rang] - (cible.alternatif ? continu : 0.0)
           + cible.decalage;
}

// Mode XY : chaque point est (voie 1, voie 2). Aucune décimation par colonne
// ici — la courbe n'est pas une fonction du temps, elle peut revenir sur
// elle-même.
void TraceOscilloscope::tracer_xy(QPainter& peintre, const QRectF& zone,
                                  double debut, double echelle_y,
                                  double y_zero) const {
    if (!voie_active(0) || !voie_active(1)) {
        peintre.setPen(QPen(QColor(120, 135, 148), 1));
        peintre.drawText(zone, Qt::AlignCenter,
                         "Mode XY : choisissez un signal sur les voies 1 et 2.");
        return;
    }
    const double continu_x = continu_voie(0, debut);
    const double continu_y = continu_voie(1, debut);
    const double x_zero = zone.left() + zone.width() / 2.0;

    QPainterPath chemin;
    bool commence = false;
    for (size_t k = 0; k < temps_.size(); ++k) {
        if (temps_[k] < debut || temps_[k] > debut + fenetre_) continue;
        const double x = x_zero + valeur_affichee(0, k, continu_x) * echelle_y;
        const double y = y_zero - valeur_affichee(1, k, continu_y) * echelle_y;
        if (!commence) {
            chemin.moveTo(x, y);
            commence = true;
        } else {
            chemin.lineTo(x, y);
        }
    }
    peintre.setClipRect(zone);
    peintre.setPen(QPen(kCouleurs[1], 1.4));
    peintre.drawPath(chemin);
    peintre.setClipping(false);
    peintre.setPen(QColor(150, 165, 178));
    peintre.drawText(QRectF(zone.left() + 4, zone.bottom() - 16, 200, 14),
                     Qt::AlignLeft, "X : voie 1     Y : voie 2");
}

void TraceOscilloscope::definir_declenchement(Declenchement mode) {
    declenchement_ = mode;
    update();
}

void TraceOscilloscope::definir_voie_declenchement(int voie) {
    voie_declenchement_ = std::clamp(voie, 0, kVoies - 1);
    update();
}

void TraceOscilloscope::definir_niveau_declenchement(double volts) {
    niveau_declenchement_ = volts;
    niveau_automatique_ = false;
    update();
}

void TraceOscilloscope::definir_front_montant(bool montant) {
    front_montant_ = montant;
    update();
}

// Dernier front qui satisfait la condition, cherché en remontant le temps.
// On s'arrête avant la fin du tampon pour qu'il reste de quoi remplir la
// partie droite de l'écran : sinon l'image sauterait à chaque trame.
double TraceOscilloscope::chercher_front() const {
    const Voie& source = voies_[voie_declenchement_];
    if (source.valeurs.size() != temps_.size() || temps_.size() < 3) return -1;

    // Niveau automatique : le milieu de ce que fait le signal. C'est ce que
    // propose la touche « auto set » d'un appareil, et cela évite de chercher
    // un front à 2,5 V dans une sinusoïde qui n'y monte jamais.
    if (niveau_automatique_) {
        float mini = source.valeurs.front(), maxi = source.valeurs.front();
        for (float valeur : source.valeurs) {
            mini = std::min(mini, valeur);
            maxi = std::max(maxi, valeur);
        }
        if (maxi - mini < 1e-6f) return -1;         // signal plat
        niveau_declenchement_ = 0.5 * (mini + maxi);
    }

    const double marge = 0.8 * fenetre_;    // après le front, à afficher
    const double limite = dernier_instant_ - marge;
    for (size_t k = temps_.size() - 1; k > 0; --k) {
        if (temps_[k] > limite) continue;
        const double avant = source.valeurs[k - 1];
        const double apres = source.valeurs[k];
        const bool passe = front_montant_
                               ? (avant < niveau_declenchement_
                                  && apres >= niveau_declenchement_)
                               : (avant > niveau_declenchement_
                                  && apres <= niveau_declenchement_);
        if (!passe) continue;
        // Instant exact du franchissement, entre deux échantillons.
        const double ecart = apres - avant;
        const double part =
            std::fabs(ecart) < 1e-12 ? 0.0
                                     : (niveau_declenchement_ - avant) / ecart;
        return temps_[k - 1] + part * (temps_[k] - temps_[k - 1]);
    }
    return -1;
}

double TraceOscilloscope::valeur_a(int voie, double instant) const {
    if (voie < 0 || voie >= kVoies) return 0.0;
    const Voie& cible = voies_[voie];
    if (cible.valeurs.size() != temps_.size() || temps_.empty()) return 0.0;
    if (instant <= temps_.front()) return cible.valeurs.front();
    if (instant >= temps_.back()) return cible.valeurs.back();
    for (size_t k = 1; k < temps_.size(); ++k) {
        if (temps_[k] < instant) continue;
        const double t0 = temps_[k - 1], t1 = temps_[k];
        if (t1 <= t0) return cible.valeurs[k];
        const double part = (instant - t0) / (t1 - t0);
        return cible.valeurs[k - 1]
               + part * (cible.valeurs[k] - cible.valeurs[k - 1]);
    }
    return cible.valeurs.back();
}

QString TraceOscilloscope::lecture_curseurs() const {
    if (curseur_a_ < 0) return {};
    QString texte = QString("A : t = %1 s").arg(curseur_a_, 0, 'f', 5);
    for (int v = 0; v < kVoies; ++v) {
        if (!voie_active(v)) continue;
        texte += QString("   V%1 = %2 V")
                     .arg(v + 1)
                     .arg(valeur_a(v, curseur_a_), 0, 'f', 3);
    }
    if (curseur_b_ >= 0) {
        const double dt = curseur_a_ - curseur_b_;
        texte += QString("      Δt = %1 ms").arg(dt * 1000.0, 0, 'f', 3);
        if (std::fabs(dt) > 1e-9)
            texte += QString("  (%1 Hz)").arg(1.0 / std::fabs(dt), 0, 'f', 1);
        for (int v = 0; v < kVoies; ++v) {
            if (!voie_active(v)) continue;
            texte += QString("   ΔV%1 = %2 V")
                         .arg(v + 1)
                         .arg(valeur_a(v, curseur_a_) - valeur_a(v, curseur_b_),
                              0, 'f', 3);
        }
    }
    return texte;
}

void TraceOscilloscope::mouseMoveEvent(QMouseEvent* evenement) {
    const QRectF zone = rect().adjusted(46, 8, -8, -22);
    if (zone.width() <= 0) return;
    const double part = (evenement->position().x() - zone.left()) / zone.width();
    curseur_a_ = (part < 0 || part > 1) ? -1.0 : debut_affiche_ + part * fenetre_;
    emit curseurs_changes();
    update();
}

void TraceOscilloscope::mousePressEvent(QMouseEvent* evenement) {
    // Poser le curseur de référence, ou l'enlever si on reclique au même
    // endroit : deux gestes, aucun bouton supplémentaire.
    mouseMoveEvent(evenement);
    curseur_b_ = (curseur_b_ >= 0 && std::fabs(curseur_b_ - curseur_a_)
                                         < fenetre_ / 100.0)
                     ? -1.0
                     : curseur_a_;
    emit curseurs_changes();
    update();
}

void TraceOscilloscope::leaveEvent(QEvent*) {
    curseur_a_ = -1.0;
    emit curseurs_changes();
    update();
}

void Oscilloscope::ajouter_trame(const coeur::Formes& formes,
                                 double instant_debut) {
    trace_->ajouter(formes, instant_debut);
    rafraichir_mesures();
}

void Oscilloscope::vider() { trace_->vider(); }

bool TraceOscilloscope::voie_mesuree(int voie) const {
    return voie >= 0 && voie < kVoies && voies_[voie].mesuree;
}

bool Oscilloscope::voie_est_mesuree(int voie) const {
    return trace_ && trace_->voie_mesuree(voie);
}

void Oscilloscope::rafraichir_mesures() {
    // Niveau automatique : la case le montre, sans passer pour un réglage
    // manuel — sinon le premier rafraîchissement figerait le niveau.
    if (niveau_ && trace_->niveau_automatique()) {
        const QSignalBlocker silence(niveau_);
        niveau_->setValue(trace_->niveau_declenchement());
    }

    for (int v = 0; v < TraceOscilloscope::kVoies; ++v) {
        if (!trace_->voie_active(v)) {
            mesures_[v]->setText("—");
            continue;
        }
        if (!trace_->voie_mesuree(v)) {
            // On le DIT, plutôt que de tracer un zéro qui ment.
            mesures_[v]->setText("aucune mesure pour ce signal");
            mesures_[v]->setStyleSheet("color: #b26a00;");
            continue;
        }
        double moyenne = 0, maximum = 0;
        trace_->mesurer(v, moyenne, maximum);
        const QString signal = trace_->signal_voie(v);
        // L'UNITÉ SUIT LE SIGNAL, et ce n'est pas cosmétique : afficher
        // « 90,00 V » pour l'angle d'un servomoteur enseignerait un
        // contresens. Une unité déclarée par le composant l'emporte ; sinon
        // c'est le volt, sauf pour un courant.
        auto unite = unites_.find(signal);
        if (unite != unites_.end()) {
            mesures_[v]->setText(QString("moy %1 / crête %2 %3")
                                     .arg(moyenne, 0, 'f', 2)
                                     .arg(maximum, 0, 'f', 2)
                                     .arg(unite->second));
        } else if (signal.startsWith("I(")) {
            mesures_[v]->setText(QString("moy %1 / crête %2 mA")
                                     .arg(moyenne * 1000, 0, 'f', 2)
                                     .arg(maximum * 1000, 0, 'f', 2));
        } else {
            mesures_[v]->setText(QString("moy %1 / crête %2 V")
                                     .arg(moyenne, 0, 'f', 2)
                                     .arg(maximum, 0, 'f', 2));
        }
        mesures_[v]->setStyleSheet(
            QString("color: %1;")
                .arg(TraceOscilloscope::couleur_voie(v).name()));
    }
}

void Oscilloscope::proposer_signaux(const QStringList& signaux,
                                    const std::map<QString, QString>& libelles) {
    if (signaux == signaux_ && libelles == libelles_) return;
    signaux_ = signaux;
    libelles_ = libelles;
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v) {
        QComboBox* selecteur = selecteurs_[v];
        const QString choix = selecteur->currentData().toString();
        {
            const QSignalBlocker silence(selecteur);
            selecteur->clear();
            selecteur->addItem("— aucun —", QString());
            for (const QString& signal : signaux_) {
                auto it = libelles_.find(signal);
                selecteur->addItem(it == libelles_.end()
                                       ? signal
                                       : signal + "  —  " + it->second,
                                   signal);
            }
            const int rang = selecteur->findData(choix);
            selecteur->setCurrentIndex(rang >= 0 ? rang : 0);
        }
        trace_->definir_signal(v, selecteur->currentData().toString());
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
    const int rang = selecteurs_[cible]->findData(designation);
    if (rang >= 0) selecteurs_[cible]->setCurrentIndex(rang);
}

QString Oscilloscope::signal_de_voie(int voie) const {
    return trace_ ? trace_->signal_voie(voie) : QString();
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

double Oscilloscope::fenetre_affichee() const {
    return trace_ ? trace_->fenetre() : 0.0;
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

QString Oscilloscope::rapport() const {
    QString texte;
    for (int v = 0; v < TraceOscilloscope::kVoies; ++v) {
        if (!trace_->voie_active(v)) continue;
        // UN RAPPORT NE CHIFFRE QUE CE QU'IL A MESURÉ. Une voie sans donnée
        // y écrivait « moyenne 0,000, crête 0,000 » — trois chiffres faux
        // présentés comme un relevé, et c'est ce rapport que lit la
        // vérification automatique.
        if (!trace_->voie_mesuree(v)) {
            texte += QString("voie %1 (%2) : aucune mesure disponible\n")
                         .arg(v + 1)
                         .arg(trace_->signal_voie(v));
            continue;
        }
        double moyenne = 0, maximum = 0;
        trace_->mesurer(v, moyenne, maximum);
        texte += QString("voie %1 (%2) : moyenne %3, crete %4, "
                         "rapport cyclique %5 %\n")
                     .arg(v + 1)
                     .arg(trace_->signal_voie(v))
                     .arg(moyenne, 0, 'f', 3)
                     .arg(maximum, 0, 'f', 3)
                     .arg(trace_->rapport_cyclique(v) * 100, 0, 'f', 1);
    }
    if (trace_->voie_active(0) && trace_->voie_active(1))
        texte += QString("concordance voie 1 / voie 2 : %1 %\n")
                     .arg(trace_->concordance(0, 1) * 100, 0, 'f', 1);
    return texte;
}
