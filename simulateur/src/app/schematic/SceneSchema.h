// Scène de saisie du schéma.
//
// Son rôle décisif : transformer un dessin en `coeur::Netlist`. C'est la
// couture du projet — le schéma produit la netlist, les moteurs la consomment,
// et le futur module PCB la consommera aussi, sans rien changer ici.
#pragma once

#include <QGraphicsScene>

#include <cstdint>
#include <QJsonObject>
#include <QPoint>
#include <QPointF>
#include <QString>
#include <QStringList>

#include <map>
#include <string>
#include <vector>

#include "core/Netlist.h"
#include "core/engines/NgspiceEngine.h"

#include "app/schematic/Ancre.h"

class ItemComposant;
class ItemFil;
class ItemJonction;

// Une broche de carte programmable reliée à un nœud du circuit.
struct LiaisonBroche {
    int numero = 0;            // numérotation Arduino : 0..13, A0=14…A5=19
    std::string nom;           // "D13", "A0"
    std::string noeud;         // nœud auquel elle est reliée
    std::string carte;         // référence de la carte : "U1", "U2"…
};

// Une carte programmable posée sur le schéma, avec ce qu'il faut pour la
// faire tourner : quelle puce, à quelle vitesse. Deux cartes du même schéma
// peuvent porter deux puces différentes — un Arduino et un ATtiny — et
// chacune doit être compilée et exécutée pour la sienne.
struct CartePosee {
    QString reference;
    std::string mcu = "atmega328p";
    uint32_t horloge = 16000000;
    double tension_logique = 5.0;
    double resistance_sortie = 25.0;
    double resistance_tirage = 35000.0;
};

class SceneSchema : public QGraphicsScene {
    Q_OBJECT

public:
    enum class Outil { Selection, Fil, Suppression };

    // Ce que vise le curseur. Défini tôt : le tracé en cours le garde en
    // membre, et la découpe n'a lieu qu'au bout du geste.
    struct Cible {
        enum class Genre { Rien, Broche, Jonction, Fil, Composant };
        Genre genre = Genre::Rien;
        Ancre ancre;                          // Broche et Jonction
        ItemFil* fil = nullptr;               // Fil : celui qu'il faudra couper
        ItemComposant* composant = nullptr;   // Composant : son corps
        QPointF point;                        // position retenue

        // Ce sur quoi un fil peut naître ou mourir.
        bool connectable() const {
            return genre == Genre::Broche || genre == Genre::Jonction
                   || genre == Genre::Fil;
        }
    };


    explicit SceneSchema(QObject* parent = nullptr);

    void definir_outil(Outil outil);
    Outil outil() const { return outil_; }

    ItemComposant* ajouter_composant(const QString& type, const QPointF& position);
    void supprimer_selection();
    void tout_effacer();

    // --- sérialisation ------------------------------------------------------
    // Le schéma sait s'écrire et se relire. C'est ce qui sert à
    // l'enregistrement, mais aussi à l'annulation (une pile d'états) et au
    // presse-papiers (un extrait d'état) : trois usages, une seule mécanique.
    QJsonObject vers_json(bool selection_seule = false) const;
    // `decalage` déplace ce qui est relu — utile pour un collage qui ne doit
    // pas se superposer à l'original. Renvoie les composants créés.
    std::vector<ItemComposant*> depuis_json(const QJsonObject& racine,
                                            bool remplacer = true,
                                            const QPointF& decalage = {});

    // --- annulation ---------------------------------------------------------
    // À appeler AVANT une modification : l'état courant est empilé.
    void memoriser();
    // Empile un état précis (celui d'avant un geste déjà commencé).
    void empiler(QJsonObject etat);
    bool annuler();
    bool retablir();
    bool peut_annuler() const { return !pile_annulation_.empty(); }
    // Ouvrir un projet ou en commencer un neuf efface l'histoire : annuler
    // ramènerait sinon le schéma précédent, ce que personne n'attend.
    void oublier_historique();
    bool peut_retablir() const { return !pile_retablissement_.empty(); }

    // --- presse-papiers -----------------------------------------------------
    void copier_selection();
    bool coller();
    void dupliquer_selection();
    bool presse_papiers_rempli() const { return !presse_papiers_.isEmpty(); }

    // Construit la netlist du schéma et la liste des broches de carte.
    coeur::Netlist construire_netlist(std::vector<LiaisonBroche>* broches) const;

    // Netlist destinée au circuit imprimé. Elle diffère sur un point : les
    // cartes programmables en font partie. La simulation les confie à
    // l'émulateur et les tient hors de SPICE, mais sur une carte elles
    // existent bel et bien — ce sont leurs connecteurs qu'on y soude.
    coeur::Netlist netlist_pcb() const;

    // Nom du nœud rattaché à une borne (après construction de la netlist).
    // Références des cartes programmables posées, câblées ou non. La liste
    // des broches ne suffit pas : une carte seule sur un schéma vide n'a
    // aucune broche reliée, et resterait pourtant à programmer.
    QStringList cartes_presentes() const;
    // Les mêmes, avec leur puce et leur horloge.
    std::vector<CartePosee> cartes_posees() const;

    // Ce que relie chaque nœud : « R1_2 » -> « C1.1 · R1.2 ». Sert à ne
    // jamais proposer un nom de nœud sans dire ce qu'il désigne.
    std::map<QString, QString> description_noeuds() const;

    // Nom du nœud auquel est rattachée une borne. Vide si elle est en l'air.
    QString noeud_de(const ItemComposant* composant, int borne) const;

    std::vector<ItemComposant*> composants() const;
    std::vector<ItemFil*> fils() const;
    std::vector<ItemJonction*> jonctions() const;

    // Coupe un fil en deux autour d'un point, et rend le point créé.
    //
    // C'est le mécanisme de la dérivation en T, pris tel quel dans LibrePCB :
    // on pose une ancre au lieu du clic, on crée les deux moitiés de l'ancien
    // fil, on supprime l'ancien. Aucune notion de « jonction » n'est
    // nécessaire ailleurs — le T est trois fils partageant une ancre.
    ItemJonction* decouper(ItemFil* fil, const QPointF& point);

    // Balaie les points devenus inutiles : un point d'où ne part plus qu'un
    // fil, ou aucun, n'a plus de raison d'être. Appelé après toute suppression.
    void balayer_jonctions();

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

    // Marque un composant comme grillé : il se dessine noirci et barré.
    void marquer_grille(const QString& reference);

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
    // La CIBLE d'où part le fil en cours — pas une ancre.
    //
    // Garder la cible plutôt que l'ancre est ce qui permet de ne découper
    // qu'au dernier moment : tant que le geste n'a pas abouti, aucun fil
    // existant n'a été touché.
    Cible cible_depart_;
    QGraphicsLineItem* fil_provisoire_ = nullptr;
    // Fil accroché au curseur entre deux clics (câblage en deux temps).
    bool fil_en_attente_ = false;
    QPointF point_appui_;
    std::map<std::string, int> compteurs_;   // par préfixe : R1, R2…

    // Annulation : des états complets du schéma. Un schéma pèse quelques
    // kilo-octets, en garder cinquante ne coûte rien et évite d'inventer un
    // journal d'opérations que chaque nouvelle commande faudrait enrichir.
    std::vector<QJsonObject> pile_annulation_;
    std::vector<QJsonObject> pile_retablissement_;
    QJsonObject presse_papiers_;
    // État d'avant le geste en cours : un déplacement à la souris doit
    // pouvoir s'annuler, et on ne connaît son résultat qu'au relâchement.
    QJsonObject etat_avant_geste_;
    static constexpr int kProfondeurAnnulation = 50;

    // Recherche la borne sous le curseur, tous composants confondus.
    std::pair<ItemComposant*, int> borne_sous(const QPointF& point) const;

    // Ce que vise le curseur.
    //
    // Sans mode, c'est cette question qui remplace le choix d'un outil : on
    // ne demande plus à l'utilisateur de déclarer son intention, on la lit
    // sous le curseur. LibrePCB résout la même question par une table de
    // priorités explicite ; on reprend le principe.
    //
    // Écart assumé sur leur ordre : chez eux le fil (20) passe avant la
    // broche (40). Ça marche parce qu'un point de fil, prioritaire, occupe
    // les extrémités. Ici un fil se termine DIRECTEMENT sur une broche : le
    // fil gagnerait toujours, et cliquer une broche découperait le fil au
    // lieu de s'y connecter. La broche passe donc en tête.
    Cible viser(const QPointF& point) const;

    // Transforme une cible en ancre utilisable, en découpant le fil si c'est
    // un fil qui est visé. Rend une ancre invalide si la cible ne se connecte
    // pas.
    Ancre ancrer(const Cible& cible);

    // Cycle de vie d'un fil en cours de tracé.
    void commencer_fil(const Cible& depart, const QPointF& point);
    bool terminer_fil(const QPointF& point);   // vrai si un fil a été créé
    void abandonner_fil();

    // Association (composant, borne) -> nom de nœud, calculée par les fils.
    std::map<const ItemComposant*, std::vector<std::string>> calculer_noeuds() const;

    QString prochaine_reference(const std::string& prefixe);
};
