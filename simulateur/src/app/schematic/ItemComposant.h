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

namespace coeur {
struct Modele;
}

class ItemComposant : public QGraphicsItem {
public:
    enum { Type = UserType + 1 };

    ItemComposant(const coeur::Modele* modele, QString reference);

    int type() const override { return Type; }
    QRectF boundingRect() const override;
    void paint(QPainter* peintre, const QStyleOptionGraphicsItem* option,
               QWidget* widget) override;

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

    // Valeurs et textes réglables, recopiés dans la netlist.
    std::map<std::string, double> valeurs;
    std::map<std::string, std::string> textes;

    // Texte affiché sous la référence (« 220 Ω », « rouge »…).
    QString etiquette() const;

private:
    const coeur::Modele* modele_ = nullptr;
    QString reference_;
    double eclat_ = 0.0;
    QRectF cadre_;

    void recalculer_cadre();
};
