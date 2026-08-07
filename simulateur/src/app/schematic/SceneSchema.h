// Scène de saisie du schéma.
//
// Son rôle décisif : transformer un dessin en `coeur::Netlist`. C'est la
// couture du projet — le schéma produit la netlist, les moteurs la consomment,
// et le futur module PCB la consommera aussi, sans rien changer ici.
#pragma once

#include <QGraphicsScene>
#include <QString>

#include <map>
#include <string>
#include <vector>

#include "core/Netlist.h"

class ItemComposant;
class ItemFil;

// Une broche de carte programmable reliée à un nœud du circuit.
struct LiaisonBroche {
    int numero = 0;            // numérotation Arduino : 0..13, A0=14…A5=19
    std::string nom;           // "D13", "A0"
    std::string noeud;         // nœud auquel elle est reliée
};

class SceneSchema : public QGraphicsScene {
    Q_OBJECT

public:
    enum class Outil { Selection, Fil, Suppression };

    explicit SceneSchema(QObject* parent = nullptr);

    void definir_outil(Outil outil);
    Outil outil() const { return outil_; }

    ItemComposant* ajouter_composant(const QString& type, const QPointF& position);
    void supprimer_selection();
    void tout_effacer();

    // Construit la netlist du schéma et la liste des broches de carte.
    coeur::Netlist construire_netlist(std::vector<LiaisonBroche>* broches) const;

    // Nom du nœud rattaché à une borne (après construction de la netlist).
    std::vector<ItemComposant*> composants() const;
    std::vector<ItemFil*> fils() const;

    // Applique les résultats d'une résolution : éclat des LED, tension des fils.
    void appliquer_resultats(const std::map<std::string, double>& courants,
                             const std::map<std::string, double>& tensions);
    void effacer_resultats();

signals:
    void selection_composant(ItemComposant* composant);
    void journal(const QString& message);

protected:
    void drawBackground(QPainter* peintre, const QRectF& zone) override;
    void mousePressEvent(QGraphicsSceneMouseEvent* evenement) override;
    void mouseMoveEvent(QGraphicsSceneMouseEvent* evenement) override;
    void mouseReleaseEvent(QGraphicsSceneMouseEvent* evenement) override;
    void keyPressEvent(QKeyEvent* evenement) override;

private:
    Outil outil_ = Outil::Selection;
    ItemComposant* fil_depart_ = nullptr;
    int fil_borne_ = -1;
    QGraphicsLineItem* fil_provisoire_ = nullptr;
    std::map<std::string, int> compteurs_;   // par préfixe : R1, R2…

    // Recherche la borne sous le curseur, tous composants confondus.
    std::pair<ItemComposant*, int> borne_sous(const QPointF& point) const;

    // Association (composant, borne) -> nom de nœud, calculée par les fils.
    std::map<const ItemComposant*, std::vector<std::string>> calculer_noeuds() const;

    QString prochaine_reference(const std::string& prefixe);
};
