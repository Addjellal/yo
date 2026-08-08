// Scène de saisie du schéma.
//
// Son rôle décisif : transformer un dessin en `coeur::Netlist`. C'est la
// couture du projet — le schéma produit la netlist, les moteurs la consomment,
// et le futur module PCB la consommera aussi, sans rien changer ici.
#pragma once

#include <QGraphicsScene>
#include <QPoint>
#include <QPointF>
#include <QString>
#include <QStringList>

#include <map>
#include <string>
#include <vector>

#include "core/Netlist.h"
#include "core/engines/NgspiceEngine.h"

class ItemComposant;
class ItemFil;

// Une broche de carte programmable reliée à un nœud du circuit.
struct LiaisonBroche {
    int numero = 0;            // numérotation Arduino : 0..13, A0=14…A5=19
    std::string nom;           // "D13", "A0"
    std::string noeud;         // nœud auquel elle est reliée
    std::string carte;         // référence de la carte : "U1", "U2"…
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
    // Références des cartes programmables posées, câblées ou non. La liste
    // des broches ne suffit pas : une carte seule sur un schéma vide n'a
    // aucune broche reliée, et resterait pourtant à programmer.
    QStringList cartes_presentes() const;

    // Ce que relie chaque nœud : « R1_2 » -> « C1.1 · R1.2 ». Sert à ne
    // jamais proposer un nom de nœud sans dire ce qu'il désigne.
    std::map<QString, QString> description_noeuds() const;

    // Nom du nœud auquel est rattachée une borne. Vide si elle est en l'air.
    QString noeud_de(const ItemComposant* composant, int borne) const;

    std::vector<ItemComposant*> composants() const;
    std::vector<ItemFil*> fils() const;

    // Applique les résultats d'une résolution : éclat des LED, tension des fils.
    // `formes` est facultatif : sans lui, les instruments affichent la valeur
    // instantanée ; avec lui, ils font ce que fait un multimètre — moyenne en
    // continu, valeur efficace en alternatif.
    void appliquer_resultats(const std::map<std::string, double>& courants,
                             const std::map<std::string, double>& tensions,
                             const coeur::Formes* formes = nullptr);
    // Reporte sur le schéma l'état interne des composants à mécanique, tel
    // que le moteur de simulation l'a fait évoluer.
    void appliquer_etats(
        const std::map<std::string, std::map<std::string, double>>& etats);
    void effacer_resultats();

signals:
    void selection_composant(ItemComposant* composant);
    void journal(const QString& message);
    // Double-clic sur un composant : ouvrir ce qu'il a de plus utile à
    // montrer — la fenêtre de mesure d'un instrument, par exemple.
    void double_clic_composant(ItemComposant* composant);
    // Clic droit : la fenêtre principale construit le menu, la scène ne
    // connaît pas les actions de l'application.
    void menu_demande(ItemComposant* composant, const QPoint& ecran);

protected:
    void drawBackground(QPainter* peintre, const QRectF& zone) override;
    void mousePressEvent(QGraphicsSceneMouseEvent* evenement) override;
    void mouseMoveEvent(QGraphicsSceneMouseEvent* evenement) override;
    void mouseReleaseEvent(QGraphicsSceneMouseEvent* evenement) override;
    void mouseDoubleClickEvent(QGraphicsSceneMouseEvent* evenement) override;
    void contextMenuEvent(QGraphicsSceneContextMenuEvent* evenement) override;
    void keyPressEvent(QKeyEvent* evenement) override;

private:
    Outil outil_ = Outil::Selection;
    ItemComposant* fil_depart_ = nullptr;
    int fil_borne_ = -1;
    QGraphicsLineItem* fil_provisoire_ = nullptr;
    // Fil accroché au curseur entre deux clics (câblage en deux temps).
    bool fil_en_attente_ = false;
    QPointF point_appui_;
    std::map<std::string, int> compteurs_;   // par préfixe : R1, R2…

    // Recherche la borne sous le curseur, tous composants confondus.
    std::pair<ItemComposant*, int> borne_sous(const QPointF& point) const;

    // Cycle de vie d'un fil en cours de tracé.
    void commencer_fil(ItemComposant* composant, int borne, const QPointF& point);
    bool terminer_fil(const QPointF& point);   // vrai si un fil a été créé
    void abandonner_fil();

    // Association (composant, borne) -> nom de nœud, calculée par les fils.
    std::map<const ItemComposant*, std::vector<std::string>> calculer_noeuds() const;

    QString prochaine_reference(const std::string& prefixe);
};
