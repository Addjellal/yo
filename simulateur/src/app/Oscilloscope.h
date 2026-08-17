// Oscilloscope à quatre voies.
//
// Il n'affiche rien d'inventé : les courbes sont exactement les points rendus
// par l'analyse transitoire de ngspice, accumulés au fil des trames. Une voie
// peut suivre la tension d'un nœud ou le courant d'un composant.
#pragma once

#include <QColor>
#include <QSize>
#include <QStringList>
#include <QWidget>

#include <array>
#include <deque>

class QMouseEvent;
#include <map>

#include "core/engines/NgspiceEngine.h"

class QComboBox;
class QDoubleSpinBox;
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

    // --- déclenchement ------------------------------------------------------
    // Sans lui, l'écran affiche « l'instant présent » et un signal dont la
    // période ne tombe pas juste défile sans arrêt. Avec lui, l'image se cale
    // sur un front : c'est ce qui rend une forme d'onde lisible.
    enum class Declenchement { Aucun, Auto, Normal };
    void definir_declenchement(Declenchement mode);
    void definir_voie_declenchement(int voie);
    void definir_niveau_declenchement(double volts);
    void definir_front_montant(bool montant);
    // Vrai si un front a été trouvé au dernier tracé : l'interface le dit,
    // comme la diode « TRIG » d'un appareil.
    bool declenche() const { return declenche_; }
    double niveau_declenchement() const { return niveau_declenchement_; }
    bool niveau_automatique() const { return niveau_automatique_; }

    // --- réglages par voie ---------------------------------------------------
    // Décalage vertical : deux signaux superposés se distinguent mal ; on les
    // écarte comme on tourne le bouton « position » d'un appareil.
    void definir_decalage(int voie, double volts);
    double decalage(int voie) const;
    // Couplage alternatif : la composante continue est retirée à l'affichage,
    // ce qui permet de voir une ondulation de 50 mV posée sur 5 V.
    void definir_couplage_alternatif(int voie, bool alternatif);
    bool couplage_alternatif(int voie) const;

    // Mode XY : la voie 1 en abscisse, la voie 2 en ordonnée, le temps
    // disparaît. C'est la figure de Lissajous — déphasage et non-linéarité s'y
    // lisent d'un coup d'œil.
    void definir_mode_xy(bool xy);
    bool mode_xy() const { return mode_xy_; }

    // --- curseurs -----------------------------------------------------------
    // Curseur A suit la souris, curseur B se pose au clic. L'écart des deux
    // donne un temps, une tension et une fréquence.
    QString lecture_curseurs() const;

    // Début de la fenêtre réellement tracée : elle se déplace avec le
    // déclenchement. Sert au tracé, à la lecture des curseurs, et à vérifier
    // sans écran que l'image se cale bien sur le front.
    double debut_fenetre() const { return debut_affiche_; }
    // Valeur d'une voie à un instant, par interpolation.
    double valeur_a(int voie, double instant) const;

    // Mesures affichées à côté de chaque voie. La moyenne sur la fenêtre
    // visible est plus parlante que le dernier échantillon : sur une PWM,
    // celui-ci vaut 0 ou 5 V selon l'instant, ce qui n'apprend rien.
    double derniere_valeur(int voie) const;
    void mesurer(int voie, double& moyenne, double& maximum) const;
    double rapport_cyclique(int voie) const;
    double concordance(int a, int b) const;
    bool voie_active(int voie) const;
    // Vrai si la dernière trame contenait vraiment ce signal. Faux quand il a
    // été choisi mais que rien ne le fournit — ce qui doit se DIRE, et non se
    // dessiner comme un zéro.
    bool voie_mesuree(int voie) const;

signals:
    // Les curseurs ont bougé : le panneau met sa lecture à jour.
    void curseurs_changes();

protected:
    void paintEvent(QPaintEvent* evenement) override;
    void mouseMoveEvent(QMouseEvent* evenement) override;
    void mousePressEvent(QMouseEvent* evenement) override;
    void mouseReleaseEvent(QMouseEvent* evenement) override;
    void leaveEvent(QEvent* evenement) override;

private:
    struct Voie {
        QString designation;              // "d13" ou "I(LED1)"
        std::deque<float> valeurs;
        double decalage = 0.0;            // volts, à l'affichage seulement
        bool alternatif = false;          // couplage : continu retiré
        // Ce signal a-t-il RÉELLEMENT été mesuré à la dernière trame ?
        //
        // Un signal choisi mais que le moteur ne fournit pas — le courant
        // d'un composant dont aucun élément SPICE ne porte la référence —
        // donnait une suite de zéros, tracée en LIGNE PLATE. Indiscernable
        // de « aucun courant ne circule ». L'élève en concluait que son
        // montage ne marchait pas, alors que c'est la mesure qui manquait.
        bool mesuree = false;
    };

    std::array<Voie, kVoies> voies_;
    std::deque<float> temps_;
    double fenetre_ = 0.05;               // durée affichée, en secondes
    double volts_par_division_ = 1.0;
    bool gele_ = false;
    double dernier_instant_ = 0.0;

    Declenchement declenchement_ = Declenchement::Auto;
    int voie_declenchement_ = 0;
    mutable double niveau_declenchement_ = 2.5;
    bool front_montant_ = true;
    // Tant que l'utilisateur n'a pas fixé de niveau, on prend le milieu du
    // signal : 2,5 V conviendrait à une sortie logique et jamais à une
    // sinusoïde centrée sur zéro.
    bool niveau_automatique_ = true;
    bool declenche_ = false;
    double debut_affiche_ = 0.0;      // début de la fenêtre réellement tracée

    bool mode_xy_ = false;
    // LE CURSEUR DE MESURE SUIT LA SOURIS, DONC L'ÉCRAN — PAS LE TEMPS.
    //
    // Il était gardé en secondes. Or la fenêtre AVANCE avec la simulation :
    // un curseur posé à t = 100 s glissait tout seul vers la gauche pendant
    // que la souris ne bougeait pas, jusqu'à se coller au bord. On voyait un
    // trait vertical dériver sans y toucher, puis rester planté là.
    //
    // Il est donc gardé en FRACTION de la fenêtre (0 à 1) : il reste sous le
    // pointeur, quoi que fasse le temps. Le curseur de référence B, lui, est
    // bien un instant — c'est tout son intérêt, mesurer une durée — et sort
    // de l'écran quand la fenêtre l'a dépassé.
    double curseur_a_part_ = -1.0;    // 0..1 dans la fenêtre, -1 = aucun
    double curseur_b_ = -1.0;         // en secondes, -1 = aucun
    // Le niveau de déclenchement s'attrape à la souris : on tire le trait.
    bool tire_le_niveau_ = false;
    // L'instant du curseur A, déduit de sa position à l'écran.
    double curseur_a() const;

public:
    void poser_part_curseur(double part) { curseur_a_part_ = part; }
    double part_curseur() const { return curseur_a_part_; }

private:

    // Instant du dernier front trouvé dans le tampon, ou -1.
    double chercher_front() const;
    // Valeur telle qu'elle doit être TRACÉE : couplage et décalage appliqués.
    double valeur_affichee(int voie, size_t rang, double continu) const;
    // Composante continue d'une voie sur la fenêtre visible.
    double continu_voie(int voie, double debut) const;
    // Tracé en mode XY, séparé : il ne partage rien avec le tracé temporel.
    void tracer_xy(QPainter& peintre, const QRectF& zone, double debut,
                   double echelle_y, double y_zero) const;

    // Mémoire circulaire : au-delà, les points les plus anciens sont oubliés.
    static constexpr double kMemoire = 5.0;   // secondes conservées

    void purger();
    // Cherche la courbe correspondant à une désignation dans une trame.
    //
    // Elle rend une COPIE, et non un pointeur dans la trame, parce qu'une
    // désignation ne renvoie pas toujours à une courbe existante : la tension
    // AUX BORNES d'un composant se calcule, point par point, comme la
    // différence de deux potentiels. Le coût est une recopie par voie et par
    // trame — quelques milliers de doubles, sans commune mesure avec le
    // calcul du circuit qui les produit.
    std::vector<double> courbe_pour(const coeur::Formes& formes,
                                    const QString& designation) const;

    // Les deux nœuds de chaque composant à deux bornes, par référence. C'est
    // ce qui permet de tracer « U(R1) » sans que l'oscilloscope connaisse le
    // schéma : on lui donne la table, il fait la soustraction.
    std::map<QString, std::pair<QString, QString>> bornes_;

public:
    void definir_bornes(
        const std::map<QString, std::pair<QString, QString>>& bornes) {
        bornes_ = bornes;
    }
};

// Le panneau complet : la zone de tracé et ses réglages.
class Oscilloscope : public QWidget {
    Q_OBJECT

public:
    explicit Oscilloscope(QWidget* parent = nullptr);

    // LA TAILLE D'OUVERTURE, ÉNONCÉE UNE SEULE FOIS.
    //
    // Choisie pour la COURBE : un oscilloscope se lit en largeur, et 940 px
    // laissent quatre cent cinquante pixels de haut au tracé une fois les
    // réglages posés. Les réglages, eux, n'en réclament que 746 depuis qu'ils
    // ne partagent plus les colonnes des voies — ils tiendraient dans une
    // fenêtre nettement plus étroite, et le banc le vérifie aussi, pour que le
    // remède reste une VRAIE réorganisation et non une fenêtre agrandie.
    //
    // Écrite ici, elle sert aux deux fenêtres de l'application et au banc.
    static QSize taille_conseillee() { return QSize(940, 620); }

    void ajouter_trame(const coeur::Formes& formes, double instant_debut);
    void vider();

    // Met à jour la liste des signaux proposés, en conservant les choix faits.
    // `libelles` dit ce que désigne chaque signal — un nom de nœud seul ne
    // veut rien dire pour qui vient de dessiner le montage.
    void proposer_signaux(const QStringList& signaux,
                          const std::map<QString, QString>& libelles = {});

    // La table des bornes, transmise à la trace : « U(R1) » a besoin de
    // savoir entre QUELS nœuds mesurer.
    void definir_bornes(
        const std::map<QString, std::pair<QString, QString>>& bornes);
    // L'unité de chaque signal qui n'est pas en volts : tours par minute,
    // degrés, pas. Sans elle, l'appareil annoncerait des volts pour un angle.
    void definir_unites(const std::map<QString, QString>& unites);

    // Voie affectée automatiquement quand on clique un fil du schéma.
    void sonder(const QString& designation);

    // Si aucune voie n'est réglée, en choisir de plausibles : un oscilloscope
    // qui n'affiche rien au premier lancement ne donne envie à personne de
    // chercher où sont les réglages.
    void sonder_par_defaut();
    void definir_base_temps(double secondes);
    // La durée réellement AFFICHÉE, en secondes. Exposée pour le banc : le
    // sélecteur et la trace peuvent diverger, et c'est arrivé.
    double fenetre_affichee() const;

    // Compte rendu chiffré des voies : moyenne, crête, rapport cyclique, et
    // concordance entre les deux premières voies. Sert à vérifier sans se
    // fier à l'œil qu'un signal en suit un autre.
    QString rapport() const;
    // Cette voie a-t-elle vraiment été mesurée ? Exposé pour le banc : une
    // courbe absente doit se DIRE, et cette promesse se vérifie.
    bool voie_est_mesuree(int voie) const;
    bool aucune_voie_active() const;
    // Le signal affecté à une voie. Sert à vérifier qu'un scope posé sur le
    // schéma suit bien ce qui lui est câblé.
    QString signal_de_voie(int voie) const;
    // Pose le curseur de mesure à une fraction de la fenêtre, et la relit.
    // Pour le banc : simuler un déplacement de souris dans un widget non
    // affiché ne dit rien de fiable sur les coordonnées, alors qu'on veut
    // vérifier une règle simple — le curseur ne dérive pas.
    void poser_curseur_pour_essai(double part);
    double part_curseur_pour_essai() const;
    // Ce que le bandeau des curseurs affiche.
    QString lecture_curseurs_pour_essai() const;

signals:
    // La base de temps a changé : le moteur peut avoir besoin d'affiner son
    // pas de calcul pour que la courbe reste lisible.
    void resolution_souhaitee(double secondes);

private:
    TraceOscilloscope* trace_ = nullptr;
    std::array<QComboBox*, TraceOscilloscope::kVoies> selecteurs_ = {};
    std::map<QString, QString> unites_;
    std::array<QLabel*, TraceOscilloscope::kVoies> mesures_ = {};
    QComboBox* base_temps_ = nullptr;
    QDoubleSpinBox* niveau_ = nullptr;
    QLabel* curseurs_ = nullptr;
    QLabel* etat_declenchement_ = nullptr;
    QStringList signaux_;
    std::map<QString, QString> libelles_;
    int prochaine_voie_ = 0;

    void rafraichir_mesures();
};
