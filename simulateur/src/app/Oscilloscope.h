// Oscilloscope à quatre voies.
//
// Il n'affiche rien d'inventé : les courbes sont exactement les points rendus
// par l'analyse transitoire de ngspice, accumulés au fil des trames. Une voie
// peut suivre la tension d'un nœud ou le courant d'un composant.
#pragma once

#include <QColor>
#include <QStringList>
#include <QWidget>

#include <array>
#include <deque>
#include <map>

#include "core/engines/NgspiceEngine.h"

class QComboBox;
class QCheckBox;
class QSlider;
class QLabel;

// La zone de tracé proprement dite.
class TraceOscilloscope : public QWidget {
    Q_OBJECT

public:
    static constexpr int kVoies = 4;

    explicit TraceOscilloscope(QWidget* parent = nullptr);

    void ajouter(const coeur::Formes& formes, double instant_debut);
    void vider();

    void definir_signal(int voie, const QString& designation);
    QString signal_voie(int voie) const;
    static QColor couleur_voie(int voie);

    void definir_fenetre(double secondes);
    double fenetre() const { return fenetre_; }
    void definir_echelle(double volts_par_division);
    void definir_gel(bool gele) { gele_ = gele; }

    // Mesures affichées à côté de chaque voie. La moyenne sur la fenêtre
    // visible est plus parlante que le dernier échantillon : sur une PWM,
    // celui-ci vaut 0 ou 5 V selon l'instant, ce qui n'apprend rien.
    double derniere_valeur(int voie) const;
    void mesurer(int voie, double& moyenne, double& maximum) const;
    double rapport_cyclique(int voie) const;
    double concordance(int a, int b) const;
    bool voie_active(int voie) const;

protected:
    void paintEvent(QPaintEvent* evenement) override;

private:
    struct Voie {
        QString designation;              // "d13" ou "I(LED1)"
        std::deque<float> valeurs;
    };

    std::array<Voie, kVoies> voies_;
    std::deque<float> temps_;
    double fenetre_ = 0.05;               // durée affichée, en secondes
    double volts_par_division_ = 1.0;
    bool gele_ = false;
    double dernier_instant_ = 0.0;

    // Mémoire circulaire : au-delà, les points les plus anciens sont oubliés.
    static constexpr double kMemoire = 5.0;   // secondes conservées

    void purger();
    // Cherche la courbe correspondant à une désignation dans une trame.
    static const std::vector<double>* courbe_pour(const coeur::Formes& formes,
                                                  const QString& designation);
};

// Le panneau complet : la zone de tracé et ses réglages.
class Oscilloscope : public QWidget {
    Q_OBJECT

public:
    explicit Oscilloscope(QWidget* parent = nullptr);

    void ajouter_trame(const coeur::Formes& formes, double instant_debut);
    void vider();

    // Met à jour la liste des signaux proposés, en conservant les choix faits.
    // `libelles` dit ce que désigne chaque signal — un nom de nœud seul ne
    // veut rien dire pour qui vient de dessiner le montage.
    void proposer_signaux(const QStringList& signaux,
                          const std::map<QString, QString>& libelles = {});

    // Voie affectée automatiquement quand on clique un fil du schéma.
    void sonder(const QString& designation);

    // Si aucune voie n'est réglée, en choisir de plausibles : un oscilloscope
    // qui n'affiche rien au premier lancement ne donne envie à personne de
    // chercher où sont les réglages.
    void sonder_par_defaut();
    void definir_base_temps(double secondes);

    // Compte rendu chiffré des voies : moyenne, crête, rapport cyclique, et
    // concordance entre les deux premières voies. Sert à vérifier sans se
    // fier à l'œil qu'un signal en suit un autre.
    QString rapport() const;
    bool aucune_voie_active() const;

signals:
    // La base de temps a changé : le moteur peut avoir besoin d'affiner son
    // pas de calcul pour que la courbe reste lisible.
    void resolution_souhaitee(double secondes);

private:
    TraceOscilloscope* trace_ = nullptr;
    std::array<QComboBox*, TraceOscilloscope::kVoies> selecteurs_ = {};
    std::array<QLabel*, TraceOscilloscope::kVoies> mesures_ = {};
    QComboBox* base_temps_ = nullptr;
    QStringList signaux_;
    std::map<QString, QString> libelles_;
    int prochaine_voie_ = 0;

    void rafraichir_mesures();
};
