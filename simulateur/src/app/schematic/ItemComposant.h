// Un composant posé sur le schéma.
//
// L'élément ne sait rien dessiner de particulier : il interprète la liste de
// figures portée par le Modele. Ajouter un composant au catalogue suffit donc
// à le rendre dessinable, sans toucher à ce fichier.
#pragma once

#include <QGraphicsItem>
#include <QString>

#include <map>
#include <string>
#include <vector>

namespace coeur {
struct Modele;
}

class ItemComposant : public QGraphicsItem {
public:
    enum { Type = UserType + 1 };

    ItemComposant(const coeur::Modele* modele, QString reference);

    int type() const override { return Type; }
    QRectF boundingRect() const override;
    // La zone qui répond au clic n'est pas celle qu'on repeint : le cadre
    // de dessin doit couvrir jusqu'aux textes, la forme cliquable doit
    // rester serrée sur le symbole.
    QPainterPath shape() const override;
    void paint(QPainter* peintre, const QStyleOptionGraphicsItem* option,
               QWidget* widget) override;

protected:
    // Prévient les fils accrochés à ce composant qu'il va bouger, puis qu'il
    // a bougé. Sans le premier avertissement, Qt n'efface pas leur ancien
    // tracé et l'écran garde des traînées.
    QVariant itemChange(GraphicsItemChange changement,
                        const QVariant& valeur) override;

public:

    const coeur::Modele* modele() const { return modele_; }
    const QString& reference() const { return reference_; }
    void definir_reference(QString reference);

    int nb_bornes() const;
    QString nom_borne(int index) const;
    QPointF position_borne(int index) const;          // en coordonnées scène
    // Indice de la borne la plus proche d'un point de la scène, -1 si aucune.
    int borne_proche(const QPointF& point, double rayon = 14.0) const;

    void tourner();                                    // rotation de 90°

    // Éclat 0..1 : pour les composants lumineux, calculé à partir du courant.
    void definir_eclat(double eclat);
    double eclat() const { return eclat_; }

    // Composant qui a dépassé une de ses limites absolues pendant la
    // simulation. Il se dessine noirci et barré : on doit le voir sans avoir
    // à lire le journal.
    void definir_grille(bool grille);
    bool grille() const { return grille_; }

    // Bornes appartenant au nœud survolé — leur INDICE, pas le composant.
    //
    // Un composant n'est jamais « dans » un nœud : il en relie plusieurs, et
    // c'est justement ce qu'un élève doit comprendre. Allumer le corps dirait
    // le contraire, et confondrait en plus avec le noirci du composant grillé.
    void definir_bornes_allumees(std::vector<int> bornes);
    const std::vector<int>& bornes_allumees() const { return bornes_allumees_; }

    // Un manquement aux règles électriques, posé À CÔTÉ de ce qu'il vise.
    //
    // Jamais en noircissant le composant : le noirci-barré dit « grillé », un
    // fait PHYSIQUE constaté pendant la simulation. Dessiner pareil une broche
    // en l'air enseignerait qu'un fil oublié détruit un composant — c'est
    // faux, et c'est précisément le genre de fausse idée qu'un simulateur de
    // formation doit se garder d'installer.
    struct MarqueurErc {
        int borne = -1;        // -1 : le composant entier
        bool erreur = true;    // erreur (rouge) ou avertissement (orangé)
        bool operator==(const MarqueurErc& autre) const {
            return borne == autre.borne && erreur == autre.erreur;
        }
    };
    void definir_anomalies(std::vector<MarqueurErc> marqueurs);
    const std::vector<MarqueurErc>& anomalies() const { return anomalies_; }

    // Valeurs et textes réglables, recopiés dans la netlist.
    std::map<std::string, double> valeurs;
    std::map<std::string, std::string> textes;

    // Texte affiché sous la référence (« 220 Ω », « rouge »…).
    QString etiquette() const;

    // Grandeur mesurée pendant la simulation (« 90° », « 1450 tr/min ») :
    // un composant à mécanique n'a d'intérêt que si on voit où il en est.
    void definir_mesure(const QString& mesure);
    const QString& mesure() const { return mesure_; }

private:
    const coeur::Modele* modele_ = nullptr;
    QString reference_;
    double eclat_ = 0.0;
    bool grille_ = false;
    std::vector<int> bornes_allumees_;
    std::vector<MarqueurErc> anomalies_;
    QString mesure_;
    QRectF cadre_;          // zone cliquable
    QRectF cadre_peint_;    // tout ce que paint() peut toucher

    void recalculer_cadre();
    void dessiner_anomalies(QPainter* peintre) const;
};
