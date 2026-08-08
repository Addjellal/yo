// Panneau d'analyses — l'équivalent du « grapheur » des ateliers de
// simulation : on choisit une analyse, on la lance, et le résultat se lit sur
// une courbe avec ses axes, sa légende et un curseur de lecture.
//
// Trois analyses, celles que proposent LTspice et Multisim :
//   * balayage continu  (.dc)  — caractéristique de transfert ;
//   * réponse en fréquence (.ac) — diagramme de Bode, gain et phase ;
//   * spectre (FFT) du dernier relevé transitoire — raies et distorsion.
//
// Le panneau ne sait pas simuler : il demande, il affiche. C'est la fenêtre
// principale qui exécute, ce qui laisse le panneau vérifiable seul.
#pragma once

#include <QStringList>
#include <QVector>
#include <QWidget>

#include "core/analysis/Analyses.h"

class QComboBox;
class QDoubleSpinBox;
class QSpinBox;
class QLabel;
class QStackedWidget;

// Zone de tracé générique : des séries de points, deux axes, une légende.
class TraceCourbes : public QWidget {
    Q_OBJECT

public:
    struct Serie {
        QString nom;
        QVector<QPointF> points;
        bool axe_droit = false;      // tracée sur l'axe de droite (la phase)
    };

    explicit TraceCourbes(QWidget* parent = nullptr);

    void definir(QVector<Serie> series, bool log_x, bool barres);
    void definir_axes(const QString& x, const QString& gauche,
                      const QString& droite);
    void vider();

    const QVector<Serie>& series() const { return series_; }

protected:
    void paintEvent(QPaintEvent* evenement) override;
    void mouseMoveEvent(QMouseEvent* evenement) override;
    void leaveEvent(QEvent* evenement) override;

private:
    QVector<Serie> series_;
    bool log_x_ = false;
    bool barres_ = false;
    QString titre_x_, titre_gauche_, titre_droite_;
    double curseur_ = -1.0;          // abscisse écran du curseur, -1 = aucun

    // Bornes calculées à chaque changement de séries.
    double x_min_ = 0, x_max_ = 1, g_min_ = 0, g_max_ = 1, d_min_ = 0, d_max_ = 1;
    bool axe_droit_utilise_ = false;

    void recalculer_bornes();
    double abscisse_ecran(double x, const QRectF& cadre) const;
    double ordonnee_ecran(double y, const QRectF& cadre, bool droite) const;
    double abscisse_donnee(double ecran, const QRectF& cadre) const;
};

class PanneauAnalyses : public QWidget {
    Q_OBJECT

public:
    explicit PanneauAnalyses(QWidget* parent = nullptr);

    // Listes tenues à jour par la fenêtre quand le schéma change.
    void proposer_signaux(const QStringList& signaux);
    void proposer_sources(const QStringList& sources);

    // `reference` : nœud pris pour entrée du diagramme de Bode (le gain est
    // alors un vrai rapport sortie/entrée). Vide = module brut.
    void afficher_balayage(const coeur::Balayage& balayage, bool bode,
                           const QString& reference = {});
    void afficher_spectre(const coeur::Spectre& spectre, const QString& signal);
    void afficher_mesures(const coeur::Mesures& mesures, const QString& signal);
    void signaler(const QString& message);

    // Choisit l'analyse depuis l'extérieur (menu, vérification automatique).
    void choisir_analyse(int rang);
    void lancer();

    // Compte rendu textuel du dernier résultat : sert au mode de vérification
    // « --analyse », et prouve que la courbe affichée porte bien les valeurs
    // attendues.
    QString resume() const { return resume_; }
    QString csv() const;

signals:
    void balayage_demande(const QString& directive, bool bode);
    void spectre_demande(const QString& signal, int harmoniques);

private:
    TraceCourbes* trace_ = nullptr;
    QComboBox* type_ = nullptr;
    QStackedWidget* reglages_ = nullptr;
    QLabel* resume_widget_ = nullptr;

    // Balayage continu
    QComboBox* source_ = nullptr;
    QDoubleSpinBox* debut_ = nullptr;
    QDoubleSpinBox* fin_ = nullptr;
    QDoubleSpinBox* pas_ = nullptr;
    // Réponse en fréquence
    QDoubleSpinBox* f_debut_ = nullptr;
    QDoubleSpinBox* f_fin_ = nullptr;
    QSpinBox* points_ = nullptr;
    // Spectre
    QComboBox* signal_ = nullptr;
    QSpinBox* harmoniques_ = nullptr;

    QString resume_;
    QString derniere_directive_;
    // Vrai dès que l'utilisateur a lui-même choisi dans la liste : tant qu'il
    // ne l'a pas fait, la sélection suit le schéma.
    bool source_choisie_ = false;
    bool signal_choisi_ = false;
    coeur::Balayage dernier_balayage_;
    coeur::Spectre dernier_spectre_;

    void construire();
    // Bornes et unités du balayage continu, ajustées à la grandeur choisie.
    void adapter_bornes(const QString& grandeur);
};
