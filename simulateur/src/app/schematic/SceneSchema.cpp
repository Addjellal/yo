#include "app/schematic/SceneSchema.h"

#include <QApplication>
#include <QGraphicsLineItem>
#include <QGraphicsPathItem>
#include <QJsonArray>
#include <QGraphicsSceneContextMenuEvent>
#include <QGraphicsSceneMouseEvent>
#include <QGraphicsView>
#include <QKeyEvent>
#include <QPainter>

#include <algorithm>
#include <cctype>
#include <cmath>
#include <set>

#include "app/schematic/ItemComposant.h"
#include "app/schematic/ItemFil.h"
#include "app/schematic/ItemJonction.h"
#include "core/Device.h"

namespace {

constexpr double kPas = 10.0;    // pas de la grille

QPointF aligner(const QPointF& point) {
    return QPointF(std::round(point.x() / kPas) * kPas,
                   std::round(point.y() / kPas) * kPas);
}

// Numérotation Arduino d'un nom de broche : "D13" -> 13, "A0" -> 14.
//
// Les noms de port de l'ATmega328P y entrent aussi — "PB5" -> 13 — parce que
// c'est la même broche désignée deux fois : une carte Arduino l'appelle D13,
// la puce nue l'appelle PB5. Une seule numérotation interne suffit donc pour
// les deux, et tout ce qui suit (le cœur, le couplage électrique, l'ADC) ne
// connaît que celle-là.
//
// A6 et A7 n'existent que sur le Nano et la Pro Mini : ce sont deux entrées
// de convertisseur sans étage numérique. Elles reçoivent donc les numéros 20
// et 21, que le couplage traite en analogique pur.
int numero_broche(const std::string& nom) {
    if (nom.size() < 2) return -1;

    // "PB5", "PC0", "PD7" : la désignation du fabricant.
    if (nom.size() == 3 && nom[0] == 'P' && nom[2] >= '0' && nom[2] <= '7') {
        const int bit = nom[2] - '0';
        if (nom[1] == 'D') return bit;                       // PD0..PD7 -> 0..7
        if (nom[1] == 'B' && bit <= 5) return 8 + bit;        // PB0..PB5 -> 8..13
        if (nom[1] == 'C' && bit <= 5) return 14 + bit;       // PC0..PC5 -> A0..A5
        return -1;
    }

    const std::string chiffres = nom.substr(1);
    if (chiffres.find_first_not_of("0123456789") != std::string::npos) return -1;
    const int valeur = std::stoi(chiffres);
    // Jusqu'à D53 : c'est ce que porte un Mega. Une carte qui n'a pas ces
    // broches ne les déclare simplement pas.
    if (nom[0] == 'D' && valeur >= 0 && valeur <= 53) return valeur;
    if (nom[0] == 'A' && valeur >= 0 && valeur <= 7) return 14 + valeur;
    return -1;
}

// Le numéro interne d'une borne de carte. Le modèle a le dernier mot : la
// même étiquette « PB1 » désigne la broche 9 d'un ATmega328P et la broche 1
// d'un ATtiny85, et aucune règle de nommage ne peut deviner laquelle.
int numero_de_borne(const coeur::Modele& modele, const std::string& nom) {
    auto propre = modele.broches_mcu.find(nom);
    if (propre != modele.broches_mcu.end()) return propre->second;
    return numero_broche(nom);
}

// Nom de nœud utilisable partout : SPICE accepte « AM1_+ » comme nom de nœud,
// mais pas dans une expression « V(AM1_+) » — le « + » y est un opérateur. On
// traduit donc les signes des bornes, une fois pour toutes.
std::string assainir_noeud(const std::string& brut) {
    std::string propre;
    for (char c : brut) {
        if (std::isalnum(static_cast<unsigned char>(c))) propre += c;
        else if (c == '+') propre += 'P';
        else if (c == '-') propre += 'N';
        else propre += '_';
    }
    return propre;
}

// Union-find : deux bornes reliées par un fil appartiennent au même nœud.
struct Classes {
    std::vector<int> parent;
    int ajouter() {
        parent.push_back(static_cast<int>(parent.size()));
        return static_cast<int>(parent.size()) - 1;
    }
    int racine(int k) {
        while (parent[k] != k) {
            parent[k] = parent[parent[k]];
            k = parent[k];
        }
        return k;
    }
    void unir(int a, int b) {
        a = racine(a);
        b = racine(b);
        if (a != b) parent[b] = a;
    }
};

// Le tissu électrique du schéma : quelles bornes et quels points de fil sont
// le même nœud.
//
// Extrait de `calculer_noeuds` pour être partagé avec le survol. Les deux
// questions — « comment s'appelle chaque nœud ? » et « qu'y a-t-il sur le
// nœud sous le curseur ? » — se répondent sur le même tissu ; les calculer
// séparément serait le meilleur moyen qu'elles finissent par se contredire,
// et le survol montrerait alors un nœud que la netlist ne connaît pas.
struct Reseau {
    Classes classes;
    std::map<const ItemComposant*, std::vector<int>> bornes;
    std::map<const ItemJonction*, int> jonctions;

    // L'indice d'une extrémité de fil, quelle que soit sa nature. -1 quand
    // l'ancre ne désigne rien de connu — un composant effacé, par exemple.
    int indice(const Ancre& ancre) const {
        if (ancre.jonction) {
            auto it = jonctions.find(ancre.jonction);
            return it == jonctions.end() ? -1 : it->second;
        }
        auto it = bornes.find(ancre.composant);
        if (it == bornes.end()) return -1;
        if (ancre.borne < 0 || ancre.borne >= static_cast<int>(it->second.size()))
            return -1;
        return it->second[ancre.borne];
    }
};

// Le nom qu'un composant IMPOSE à son nœud, s'il en impose un.
//
// Une masse impose « GND », une étiquette impose ce que l'utilisateur a
// tapé. C'est ce mécanisme qui relie deux points du schéma SANS fil entre
// eux — et c'est même toute la raison d'être du symbole de masse : personne
// ne tire un fil d'un bout à l'autre de la feuille pour refermer un circuit.
std::string nom_impose(const ItemComposant* composant) {
    const coeur::Modele* modele = composant->modele();
    if (!modele) return {};
    if (!modele->noeud_impose.empty()) return modele->noeud_impose;
    if (modele->noeud_depuis_texte.empty()) return {};
    auto texte = composant->textes.find(modele->noeud_depuis_texte);
    if (texte != composant->textes.end() && !texte->second.empty())
        return texte->second;
    for (const coeur::Propriete& propriete : modele->proprietes)
        if (propriete.cle == modele->noeud_depuis_texte)
            return propriete.defaut_texte;
    return {};
}

Reseau tisser(const std::vector<ItemComposant*>& composants,
              const std::vector<ItemJonction*>& jonctions,
              const std::vector<ItemFil*>& fils) {
    Reseau reseau;
    for (ItemComposant* composant : composants) {
        std::vector<int> pour_ce_composant;
        for (int k = 0; k < composant->nb_bornes(); ++k)
            pour_ce_composant.push_back(reseau.classes.ajouter());
        reseau.bornes[composant] = pour_ce_composant;
    }

    // Les points de fil sont des nœuds comme les autres : ils entrent dans la
    // même relation d'équivalence. C'est ce qui fait qu'une dérivation en T
    // relie électriquement les trois fils sans code particulier — trois unions
    // sur la même classe.
    for (ItemJonction* jonction : jonctions)
        reseau.jonctions[jonction] = reseau.classes.ajouter();

    for (ItemFil* fil : fils) {
        const int a = reseau.indice(fil->ancre_depart());
        const int b = reseau.indice(fil->ancre_arrivee());
        if (a < 0 || b < 0) continue;
        reseau.classes.unir(a, b);
    }

    // Un fil n'est PAS le seul moyen de relier deux points.
    //
    // Deux masses posées aux deux bouts de la feuille sont le même nœud, sans
    // le moindre trait entre elles ; deux étiquettes de même nom aussi.
    // `calculer_noeuds()` le savait déjà — il donnait le même NOM aux deux —
    // mais leurs classes restaient distinctes, si bien que le survol
    // n'allumait que la moitié du nœud. Un élève y aurait lu que ses deux
    // masses ne communiquent pas : l'exact contraire de ce que le cours
    // enseigne, et de ce que la simulation calcule.
    std::map<std::string, int> par_nom_impose;
    for (ItemComposant* composant : composants) {
        const std::string impose = nom_impose(composant);
        if (impose.empty()) continue;
        auto indices = reseau.bornes.find(composant);
        if (indices == reseau.bornes.end() || indices->second.empty()) continue;
        // Un symbole d'alimentation impose son nom à TOUTES ses bornes ; il
        // n'en a qu'une en pratique, mais rien ne l'y oblige.
        for (int index : indices->second) {
            auto place = par_nom_impose.find(impose);
            if (place == par_nom_impose.end())
                par_nom_impose[impose] = index;
            else
                reseau.classes.unir(place->second, index);
        }
    }
    return reseau;
}

}  // namespace

SceneSchema::SceneSchema(QObject* parent) : QGraphicsScene(parent) {
    setSceneRect(-1500, -1000, 3000, 2000);
    setBackgroundBrush(QColor(252, 252, 250));
}

void SceneSchema::definir_outil(Outil outil) {
    outil_ = outil;
    abandonner_fil();
    // Le curseur restait figé sur la forme du dernier survol : on survolait un
    // composant, on prenait la gomme, et le curseur disait encore « déplacer »
    // pendant tout le travail à la gomme. Rien ne le remettait à zéro.
    for (QGraphicsView* vue : views())
        vue->setCursor(outil == Outil::Suppression ? Qt::ForbiddenCursor
                                                   : Qt::ArrowCursor);
}

QString SceneSchema::prochaine_reference(const std::string& prefixe) {
    int& compteur = compteurs_[prefixe];
    for (;;) {
        ++compteur;
        const QString candidate =
            QString::fromStdString(prefixe) + QString::number(compteur);
        bool prise = false;
        for (ItemComposant* composant : composants())
            if (composant->reference() == candidate) prise = true;
        if (!prise) return candidate;
    }
}

ItemComposant* SceneSchema::ajouter_composant(const QString& type,
                                              const QPointF& position) {
    const coeur::Modele* modele =
        coeur::Catalogue::instance().modele(type.toStdString());
    if (!modele) {
        emit journal(QString("Composant inconnu : %1").arg(type));
        return nullptr;
    }
    auto* item = new ItemComposant(modele, prochaine_reference(modele->prefixe));
    item->setPos(aligner(position));
    addItem(item);
    emit journal(QString("Ajouté : %1 (%2)")
                     .arg(item->reference(),
                          QString::fromStdString(modele->libelle)));
    return item;
}

std::vector<ItemComposant*> SceneSchema::composants() const {
    std::vector<ItemComposant*> resultat;
    for (QGraphicsItem* item : items())
        if (item->type() == ItemComposant::Type)
            resultat.push_back(static_cast<ItemComposant*>(item));
    std::sort(resultat.begin(), resultat.end(),
              [](ItemComposant* a, ItemComposant* b) {
                  return a->reference() < b->reference();
              });
    return resultat;
}

QStringList SceneSchema::cartes_presentes() const {
    QStringList resultat;
    for (ItemComposant* composant : composants())
        if (composant->modele() && composant->modele()->carte)
            resultat << composant->reference();
    resultat.sort();
    return resultat;
}

std::vector<CartePosee> SceneSchema::cartes_posees() const {
    std::vector<CartePosee> resultat;
    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->carte) continue;
        CartePosee posee;
        posee.reference = composant->reference();
        posee.mcu = modele->mcu.empty() ? "atmega328p" : modele->mcu;
        posee.horloge = modele->horloge ? modele->horloge : 16000000;
        posee.tension_logique = modele->tension_logique;
        posee.resistance_sortie = modele->resistance_sortie;
        posee.resistance_tirage = modele->resistance_tirage;
        resultat.push_back(posee);
    }
    std::sort(resultat.begin(), resultat.end(),
              [](const CartePosee& a, const CartePosee& b) {
                  return a.reference < b.reference;
              });
    return resultat;
}

std::vector<ItemJonction*> SceneSchema::jonctions() const {
    std::vector<ItemJonction*> resultat;
    for (QGraphicsItem* item : items())
        if (item->type() == ItemJonction::Type)
            resultat.push_back(static_cast<ItemJonction*>(item));
    return resultat;
}

// Coupe un fil en deux autour d'un point.
//
// Repris de LibrePCB (`schematiceditorstate_drawwire.cpp`, branche
// « split netline ») : poser une ancre, créer les deux moitiés, supprimer
// l'original. L'ordre importe — on ajoute avant de retirer, pour qu'aucune
// extrémité ne pende dans le vide entre-temps.
ItemJonction* SceneSchema::decouper(ItemFil* fil, const QPointF& point) {
    // Le schéma vient de changer sous la surbrillance : ce qu'elle désignait
    // n'existe peut-être plus, et aucun mouvement de souris ne viendra la
    // rafraîchir tant que le curseur reste immobile. On l'éteint donc ici —
    // le prochain déplacement la rallumera sur l'état neuf.
    eteindre_noeud();
    if (!fil) return nullptr;
    const Ancre a = fil->ancre_depart();
    const Ancre b = fil->ancre_arrivee();
    if (!a.valide() || !b.valide()) return nullptr;

    ItemJonction* jonction = new ItemJonction(point);
    addItem(jonction);
    addItem(new ItemFil(a, Ancre(jonction)));
    addItem(new ItemFil(Ancre(jonction), b));
    removeItem(fil);
    delete fil;
    return jonction;
}

// Un point d'où ne part plus qu'un fil — ou aucun — ne relie plus rien.
// Le laisser afficherait une pastille de connexion là où il n'y a pas de
// connexion, ce qui est exactement le contraire de ce qu'elle veut dire.
void SceneSchema::balayer_jonctions() {
    // La liste des fils se relit à CHAQUE tour.
    //
    // Elle était prise une fois avant la boucle : supprimer un fil au premier
    // tour laissait un pointeur mort que le tour suivant relisait —
    // use-after-free confirmé à l'ASan sur deux points voisins d'une même
    // dorsale, et comptage de degré faux dans tous les autres cas.
    //
    // La boucle tourne jusqu'à point fixe : retirer un fil peut faire tomber
    // un autre point sous le seuil, et il faut alors recommencer.
    bool encore = true;
    while (encore) {
        encore = false;
        const std::vector<ItemFil*> tous = fils();
        for (ItemJonction* jonction : jonctions()) {
            int degre = 0;
            for (ItemFil* fil : tous)
                if (fil->touche(jonction)) ++degre;
            jonction->degre = degre;
            if (degre >= 2) continue;
            // Le seul fil restant meurt avec elle : il ne mène plus nulle part.
            for (ItemFil* fil : tous) {
                if (!fil->touche(jonction)) continue;
                removeItem(fil);
                delete fil;
            }
            removeItem(jonction);
            delete jonction;
            encore = true;
            break;   // la liste vient de changer : on la reprend
        }
    }
}

std::vector<ItemFil*> SceneSchema::fils() const {
    std::vector<ItemFil*> resultat;
    for (QGraphicsItem* item : items())
        if (item->type() == ItemFil::Type)
            resultat.push_back(static_cast<ItemFil*>(item));
    return resultat;
}

void SceneSchema::supprimer_selection() {
    // Le schéma vient de changer sous la surbrillance : ce qu'elle désignait
    // n'existe peut-être plus, et aucun mouvement de souris ne viendra la
    // rafraîchir tant que le curseur reste immobile. On l'éteint donc ici —
    // le prochain déplacement la rallumera sur l'état neuf.
    eteindre_noeud();
    // On retire d'abord les fils : supprimer un composant sans ses fils
    // laisserait des pointeurs pendants.
    //
    // L'ensemble n'est pas un luxe : un fil tendu entre deux composants tous
    // deux sélectionnés serait sinon désigné deux fois, et détruit deux fois.
    std::set<QGraphicsItem*> a_supprimer;
    for (QGraphicsItem* item : selectedItems()) {
        if (item->type() == ItemComposant::Type) {
            auto* composant = static_cast<ItemComposant*>(item);
            for (ItemFil* fil : fils())
                if (fil->touche(composant)) a_supprimer.insert(fil);
        }
        // Un point de dérivation est sélectionnable — un lasso qui passe
        // dessus l'attrape, la gomme aussi. Il obéit à la même règle que le
        // composant, et elle n'était appliquée qu'au composant : le point
        // partait seul, ses fils restaient à lire sa position dans de la
        // mémoire libérée dès le premier redessin.
        if (item->type() == ItemJonction::Type) {
            auto* jonction = static_cast<ItemJonction*>(item);
            for (ItemFil* fil : fils())
                if (fil->touche(jonction)) a_supprimer.insert(fil);
        }
        a_supprimer.insert(item);
    }
    // Un fil en cours de tracé peut partir d'un composant qu'on efface : le
    // laisser en attente, c'est garder un pointeur vers un objet détruit.
    // Une ancre peut désigner un composant OU un point de fil : les deux
    // peuvent être dans la fournée.
    if ((cible_depart_.ancre.composant
         && a_supprimer.count(cible_depart_.ancre.composant))
        || (cible_depart_.fil
            && a_supprimer.count(static_cast<QGraphicsItem*>(cible_depart_.fil))))
        abandonner_fil();
    // Le glissé d'un segment et l'attente d'un verdict, eux, tiennent des
    // pointeurs qu'aucun tri ne met à l'abri : une poignée peut aussi être
    // emportée INDIRECTEMENT par le balayage, quand la suppression d'un
    // voisin fait tomber son degré à un. On clôt donc le geste sans chercher
    // à savoir s'il est concerné — un geste interrompu par une suppression
    // n'a de toute façon plus rien à finir.
    oublier_geste_en_cours();

    // L'ordre compte, et il coûte cher à ignorer : retirer un composant fait
    // recalculer par Qt le cadre des objets voisins, donc celui des fils qui
    // s'y accrochent — lesquels demandent alors la position d'une borne d'un
    // composant qui n'est plus dans la scène. Les fils partent donc les
    // premiers, tous, avant qu'aucun composant ne bouge.
    //
    // Le tri se fait AVANT la moindre destruction : une fois un objet détruit,
    // même lui demander son type est déjà trop tard.
    std::vector<QGraphicsItem*> fils_a_couper, objets_a_retirer;
    for (QGraphicsItem* item : a_supprimer) {
        if (item->type() == ItemFil::Type)
            fils_a_couper.push_back(item);
        else
            objets_a_retirer.push_back(item);
    }
    for (QGraphicsItem* item : fils_a_couper) {
        removeItem(item);
        delete item;
    }
    for (QGraphicsItem* item : objets_a_retirer) {
        removeItem(item);
        delete item;
    }
    // Un point qui ne relie plus rien doit disparaître avec le reste. Sans
    // cet appel, il restait à l'écran une pastille de connexion là où plus
    // rien ne se connecte, et son degré gardait la valeur d'avant.
    balayer_jonctions();
    emit selection_composant(nullptr);
}

void SceneSchema::tout_effacer() {
    // Tout ce que la scène contient va disparaître : un geste en cours ne
    // peut plus désigner quoi que ce soit.
    oublier_geste_en_cours();
    // Le schéma vient de changer sous la surbrillance : ce qu'elle désignait
    // n'existe peut-être plus, et aucun mouvement de souris ne viendra la
    // rafraîchir tant que le curseur reste immobile. On l'éteint donc ici —
    // le prochain déplacement la rallumera sur l'état neuf.
    eteindre_noeud();
    clear();                     // détruit déjà le trait provisoire
    compteurs_.clear();
    // Les pointeurs sont remis à zéro sans passer par abandonner_fil() : les
    // objets viennent d'être détruits par clear(). Un fil resté « en attente »
    // désignerait sinon un composant qui n'existe plus.
    cible_depart_ = Cible();
    fil_provisoire_ = nullptr;
    fil_en_attente_ = false;
    emit selection_composant(nullptr);
}

std::pair<ItemComposant*, int> SceneSchema::borne_sous(
    const QPointF& point) const {
    for (ItemComposant* composant : composants()) {
        const int borne = composant->borne_proche(point);
        if (borne >= 0) return {composant, borne};
    }
    return {nullptr, -1};
}

// Ce que vise le curseur, par ordre de priorité.
//
// Le principe est celui de `findItemsAtPos` de LibrePCB : un classement
// explicite, tout ce à quoi on peut se connecter passant avant le corps du
// composant. On y ajoute leur idée de palier — un objet proche du curseur sans
// être dessous reste candidat, mais après ceux qui sont dessous —, ce qui fait
// de l'aimantation une conséquence du classement plutôt qu'un traitement à
// part.
static ItemComposant* composant_sous(const QGraphicsScene* scene,
                                     const QPointF& point);

SceneSchema::Cible SceneSchema::viser(const QPointF& point) const {
    Cible meilleure;
    int meilleure_priorite = 1 << 20;
    auto retenir = [&](int priorite, const Cible& candidate) {
        if (priorite >= meilleure_priorite) return;
        meilleure_priorite = priorite;
        meilleure = candidate;
    };

    // Le rayon de capture est constant À L'ÉCRAN, pas dans la scène.
    //
    // Il était exprimé en unités de scène, donc il rétrécissait avec le zoom :
    // à 0,3× les quatorze unités ne faisaient plus que quatre pixels, et
    // viser une broche devenait impossible. On appuyait alors dans le vide,
    // le rectangle de sélection démarrait, et le geste de câblage tournait en
    // sélection — sans que rien n'explique pourquoi ça marchait tout à
    // l'heure et plus maintenant.
    //
    // C'est aussi le « palier de distance » de LibrePCB : un objet proche du
    // curseur sans être dessous reste candidat. La tolérance appartient au
    // geste de la main, pas à l'échelle du dessin.
    double echelle = 1.0;
    for (QGraphicsView* vue : views())
        if (vue->transform().m11() > 1e-6) echelle = vue->transform().m11();
    // Quatorze pixels à l'écran, quel que soit le zoom — borné pour qu'un
    // dézoom extrême n'avale pas la moitié du schéma.
    const double rayon = std::min(14.0 / echelle, 60.0);

    // 0 — une broche. La cible la plus précise et la plus demandée.
    for (ItemComposant* composant : composants()) {
        const int borne = composant->borne_proche(point, rayon);
        if (borne < 0) continue;
        Cible c;
        c.genre = Cible::Genre::Broche;
        c.ancre = Ancre(composant, borne);
        c.point = c.ancre.position();   // aimantée sur la broche
        retenir(0, c);
    }

    // 10 — un point de fil existant.
    for (ItemJonction* jonction : jonctions()) {
        const QPointF delta = jonction->pos() - point;
        if (std::hypot(delta.x(), delta.y()) > rayon) continue;
        Cible c;
        c.genre = Cible::Genre::Jonction;
        c.ancre = Ancre(jonction);
        c.point = jonction->pos();
        retenir(10, c);
    }

    // 20 — un fil. Le viser, c'est demander à le couper.
    for (ItemFil* fil : fils()) {
        if (!fil->shape().contains(fil->mapFromScene(point))) continue;
        Cible c;
        c.genre = Cible::Genre::Fil;
        c.fil = fil;
        c.point = point;
        retenir(20, c);
    }

    // 70 — le corps d'un composant : on le sélectionne, on le déplace.
    if (ItemComposant* composant = composant_sous(this, point)) {
        Cible c;
        c.genre = Cible::Genre::Composant;
        c.composant = composant;
        c.point = point;
        retenir(70, c);
    }
    return meilleure;
}

// Une cible devient une ancre. Un fil visé se coupe en deux pour la fournir :
// c'est là, et seulement là, que naît un point de dérivation.
Ancre SceneSchema::ancrer(const Cible& cible) {
    switch (cible.genre) {
        case Cible::Genre::Broche:
        case Cible::Genre::Jonction:
            return cible.ancre;
        case Cible::Genre::Fil: {
            ItemJonction* point = decouper(cible.fil, cible.point);
            return point ? Ancre(point) : Ancre();
        }
        default:
            return Ancre();
    }
}

// ---------------------------------------------------------------------------
// Le nœud sous le curseur
// ---------------------------------------------------------------------------
SceneSchema::Noeud SceneSchema::noeud_sous(const QPointF& point) const {
    Noeud noeud;
    const Cible cible = viser(point);
    if (!cible.connectable()) return noeud;

    const std::vector<ItemComposant*> liste = composants();
    const std::vector<ItemJonction*> points = jonctions();
    const std::vector<ItemFil*> traits = fils();
    Reseau reseau = tisser(liste, points, traits);

    // De quelle classe part-on ? Un fil visé n'est PAS coupé pour la
    // circonstance : la découpe appartient au clic, pas au survol. C'est son
    // ancre de départ qui donne le nœud — les deux bouts d'un fil sont dans
    // la même classe, puisque c'est lui qui les a unis.
    int depart = -1;
    switch (cible.genre) {
        case Cible::Genre::Broche:
        case Cible::Genre::Jonction:
            depart = reseau.indice(cible.ancre);
            break;
        case Cible::Genre::Fil:
            depart = cible.fil ? reseau.indice(cible.fil->ancre_depart()) : -1;
            break;
        default:
            break;
    }
    if (depart < 0) return noeud;
    const int racine = reseau.classes.racine(depart);

    for (ItemComposant* composant : liste) {
        auto it = reseau.bornes.find(composant);
        if (it == reseau.bornes.end()) continue;
        for (int k = 0; k < static_cast<int>(it->second.size()); ++k)
            if (reseau.classes.racine(it->second[k]) == racine)
                noeud.bornes.emplace_back(composant, k);
    }
    for (ItemJonction* jonction : points) {
        auto it = reseau.jonctions.find(jonction);
        if (it != reseau.jonctions.end()
            && reseau.classes.racine(it->second) == racine)
            noeud.jonctions.push_back(jonction);
    }
    for (ItemFil* fil : traits) {
        const int a = reseau.indice(fil->ancre_depart());
        if (a >= 0 && reseau.classes.racine(a) == racine)
            noeud.fils.push_back(fil);
    }

    // Le nom est celui que porte n'importe laquelle de ses bornes — c'est le
    // même calcul que celui de la netlist, donc le même nom que SPICE verra.
    // Une borne en l'air n'en a pas, et c'est exact : elle n'est pas un nœud.
    const auto noms = calculer_noeuds();
    for (const auto& [composant, borne] : noeud.bornes) {
        auto it = noms.find(composant);
        if (it == noms.end() || borne >= static_cast<int>(it->second.size()))
            continue;
        if (it->second[borne].empty()) continue;
        noeud.nom = QString::fromStdString(it->second[borne]);
        break;
    }
    return noeud;
}

void SceneSchema::eteindre_noeud() {
    if (noeud_allume_.isEmpty()) return;
    noeud_allume_.clear();
    description_allumee_.clear();
    for (ItemComposant* composant : composants())
        composant->definir_bornes_allumees({});
    for (ItemFil* fil : fils()) fil->definir_surbrillance(false);
    for (ItemJonction* jonction : jonctions())
        jonction->definir_surbrillance(false);
    emit survol_noeud(QString(), QString());
}

void SceneSchema::allumer_noeud(const QPointF& point) {
    const Noeud noeud = noeud_sous(point);
    if (noeud.nom.isEmpty()) {
        eteindre_noeud();
        return;
    }

    // La surbrillance est REPOSÉE à chaque appel, au lieu d'être court-
    // circuitée quand le nom n'a pas changé. Entre deux survols le schéma a
    // pu changer — un fil supprimé, une annulation — et le nom seul ne le
    // dirait pas : on garderait un halo sur un fil qui n'appartient plus au
    // nœud. Les `definir_…` ne repeignent que ce qui change réellement ; le
    // coût est donc celui d'une comparaison par objet, pas d'un rendu.
    std::map<ItemComposant*, std::vector<int>> par_composant;
    for (const auto& [composant, borne] : noeud.bornes)
        par_composant[composant].push_back(borne);
    for (ItemComposant* composant : composants()) {
        auto it = par_composant.find(composant);
        composant->definir_bornes_allumees(
            it == par_composant.end() ? std::vector<int>() : it->second);
    }
    const std::set<const ItemFil*> fils_allumes(noeud.fils.begin(),
                                                noeud.fils.end());
    for (ItemFil* fil : fils())
        fil->definir_surbrillance(fils_allumes.count(fil) > 0);
    const std::set<const ItemJonction*> points_allumes(noeud.jonctions.begin(),
                                                       noeud.jonctions.end());
    for (ItemJonction* jonction : jonctions())
        jonction->definir_surbrillance(points_allumes.count(jonction) > 0);

    // Le nom NE SUFFIT PAS à décider qu'il n'y a rien à réémettre.
    //
    // C'est le raccourci écarté quinze lignes plus haut pour la surbrillance,
    // et que j'avais laissé ici : entre deux survols du même nœud, un fil a
    // pu s'ajouter ou disparaître. Le nom reste « R1_1 », le contenu non — et
    // la barre d'état annonçait alors la composition du tout premier survol,
    // indéfiniment.
    QStringList relie;
    for (const auto& [composant, borne] : noeud.bornes)
        relie << composant->reference() + "." + composant->nom_borne(borne);
    const QString description = relie.join(" · ");
    if (noeud.nom == noeud_allume_ && description == description_allumee_)
        return;
    noeud_allume_ = noeud.nom;
    description_allumee_ = description;
    emit survol_noeud(noeud.nom, description);
}

// ---------------------------------------------------------------------------
// Attribution des noms de nœuds
// ---------------------------------------------------------------------------
std::map<const ItemComposant*, std::vector<std::string>>
SceneSchema::calculer_noeuds() const {
    const std::vector<ItemComposant*> liste = composants();
    Reseau reseau = tisser(liste, jonctions(), fils());
    Classes& classes = reseau.classes;
    const std::map<const ItemComposant*, std::vector<int>>& indices =
        reseau.bornes;

    // Nommage : un symbole d'alimentation impose son nom ; à défaut une broche
    // de carte donne le sien ; sinon un nom interne N1, N2…
    std::map<int, std::string> noms;
    for (ItemComposant* composant : liste) {
        const coeur::Modele* modele = composant->modele();
        if (!modele) continue;
        std::string impose = modele->noeud_impose;
        // Étiquette : le nom est celui que l'utilisateur a choisi. Deux
        // étiquettes de même nom donnent le même nœud, sans fil entre elles —
        // c'est tout l'intérêt.
        if (impose.empty() && !modele->noeud_depuis_texte.empty()) {
            auto texte = composant->textes.find(modele->noeud_depuis_texte);
            if (texte != composant->textes.end() && !texte->second.empty())
                impose = texte->second;
            else
                for (const coeur::Propriete& propriete : modele->proprietes)
                    if (propriete.cle == modele->noeud_depuis_texte)
                        impose = propriete.defaut_texte;
        }
        if (impose.empty()) continue;
        // ASSAINI COMME LES AUTRES, et pas seulement les noms engendrés.
        //
        // Un nom imposé — étiquette de nœud, symbole d'alimentation — passait
        // tel quel. Une virgule y suffit à tromper le panneau « Contrôle »,
        // qui s'en sert pour distinguer un nom de nœud d'une LISTE de
        // composants : l'anomalie s'afficherait alors comme si elle visait
        // deux composants. L'interface n'est pas atteignable ainsi (le nom
        // vient d'une liste fermée), mais `depuis_json` recopie les textes
        // d'un fichier de projet sans les valider — et SPICE, lui, refuse
        // déjà bien d'autres caractères.
        impose = assainir_noeud(impose);
        for (int k = 0; k < composant->nb_bornes(); ++k)
            noms[classes.racine(indices.at(composant)[k])] = impose;
    }
    // Combien de cartes ? La réponse change le nommage : avec une seule, la
    // broche D13 donne le nœud « D13 », lisible. Avec deux, ce nom
    // désignerait le même nœud pour les deux cartes — elles se retrouveraient
    // court-circuitées, et SPICE recevrait deux fois la même source. On
    // préfixe donc par la référence de la carte.
    int nombre_cartes = 0;
    for (ItemComposant* composant : liste)
        if (composant->modele() && composant->modele()->carte) ++nombre_cartes;

    for (ItemComposant* composant : liste) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->carte) continue;
        const std::string prefixe =
            nombre_cartes > 1 ? composant->reference().toStdString() + "_"
                              : std::string();
        for (int k = 0; k < composant->nb_bornes(); ++k) {
            const int racine = classes.racine(indices.at(composant)[k]);
            if (noms.count(racine)) continue;
            // Les broches d'alimentation restent communes : deux cartes
            // posées sur le même schéma partagent forcément leur masse.
            const std::string& borne = modele->bornes[k].nom;
            const bool alimentation = borne == coeur::Netlist::kMasse ||
                                      borne == coeur::Netlist::kAlim ||
                                      borne == "3V3" || borne == "VIN";
            noms[racine] = alimentation ? borne : prefixe + borne;
        }
    }
    // Les nœuds restants portent le nom de la première borne qui les touche,
    // dans l'ordre des références : « R1_2 » plutôt que « N3 ». C'est ce que
    // fait KiCad, et pour la même raison — « N3 » n'apprend rien à personne,
    // alors qu'un nom tiré du montage se retrouve sur le schéma.
    // Bornes réellement câblées, relevées en une seule passe sur les fils :
    // les chercher borne par borne coûterait le produit des deux nombres, et
    // cette fonction est appelée à chaque image.
    std::set<std::pair<const ItemComposant*, int>> cablees;
    for (ItemFil* fil : fils()) {
        cablees.emplace(fil->depart(), fil->borne_depart());
        cablees.emplace(fil->arrivee(), fil->borne_arrivee());
    }
    for (ItemComposant* composant : liste) {
        for (int k = 0; k < composant->nb_bornes(); ++k) {
            const int racine = classes.racine(indices.at(composant)[k]);
            if (noms.count(racine)) continue;
            // Une borne en l'air n'est pas un nœud : elle n'est reliée à rien.
            if (!cablees.count({composant, k})) continue;
            noms[racine] =
                assainir_noeud(composant->reference().toStdString() + "_"
                               + composant->nom_borne(k).toStdString());
        }
    }

    std::map<const ItemComposant*, std::vector<std::string>> resultat;
    for (ItemComposant* composant : liste) {
        std::vector<std::string> pour_ce_composant;
        for (int k = 0; k < composant->nb_bornes(); ++k) {
            const int racine = classes.racine(indices.at(composant)[k]);
            auto it = noms.find(racine);
            pour_ce_composant.push_back(it == noms.end() ? std::string()
                                                         : it->second);
        }
        resultat[composant] = pour_ce_composant;
    }
    return resultat;
}

coeur::Netlist SceneSchema::construire_netlist(
    std::vector<LiaisonBroche>* broches) const {
    coeur::Netlist netlist;
    const auto noeuds = calculer_noeuds();
    if (broches) broches->clear();

    // Premier temps : les composants. Ils déterminent quels nœuds existent
    // réellement.
    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || modele->carte) continue;
        if (!modele->noeud_impose.empty()) continue;   // symbole d'alimentation
        if (!modele->vers_spice) continue;             // décoratif

        const auto& noms = noeuds.at(composant);
        auto& instance = netlist.ajouter(composant->reference().toStdString(),
                                         modele->type);
        instance.valeurs = composant->valeurs;
        instance.textes = composant->textes;
        for (int k = 0; k < composant->nb_bornes(); ++k)
            netlist.relier(instance.reference, modele->bornes[k].nom, noms[k]);
    }

    // Second temps : les broches de carte, et seulement celles qui aboutissent
    // quelque part. Une broche en l'air ajouterait une source, une résistance
    // et une condition initiale à chaque résolution, pour rien — sur une carte
    // à vingt broches dont une seule est câblée, c'est l'essentiel du coût.
    if (!broches) return netlist;

    // Recensement préalable : combien de broches de carte aboutissent sur
    // chaque nœud ? Deux cartes reliées directement l'une à l'autre n'ont
    // aucun composant entre elles, et seraient écartées à tort par le test
    // « broche en l'air » s'il ne regardait que les composants.
    std::map<std::string, int> broches_par_noeud;
    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->carte) continue;
        const auto& noms = noeuds.at(composant);
        for (int k = 0; k < composant->nb_bornes(); ++k)
            if (numero_de_borne(*modele, modele->bornes[k].nom) >= 0
                && !noms[k].empty())
                ++broches_par_noeud[noms[k]];
    }

    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->carte) continue;
        const auto& noms = noeuds.at(composant);
        for (int k = 0; k < composant->nb_bornes(); ++k) {
            const std::string nom = modele->bornes[k].nom;
            const int numero = numero_de_borne(*modele, nom);
            if (numero < 0 || noms[k].empty()) continue;
            // Une broche compte si elle rejoint un composant, ou si elle
            // rejoint la broche d'une autre carte.
            const bool vers_composant = netlist.occurrences(noms[k]) > 0;
            const bool vers_autre_carte = broches_par_noeud[noms[k]] > 1;
            if (!vers_composant && !vers_autre_carte) continue;
            broches->push_back({numero, nom, noms[k],
                                composant->reference().toStdString()});
        }
    }
    return netlist;
}

coeur::Netlist SceneSchema::netlist_pcb() const {
    coeur::Netlist netlist = construire_netlist(nullptr);
    const auto noeuds = calculer_noeuds();

    // Une carte programmable ne va pas dans SPICE — elle est émulée — mais
    // elle occupe une place et des connecteurs sur le circuit imprimé. Sans
    // elle, la carte routée n'aurait plus rien pour recevoir les fils.
    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->carte) continue;
        const std::string reference = composant->reference().toStdString();
        netlist.ajouter(reference, modele->type);
        const auto& noms = noeuds.at(composant);
        for (int k = 0; k < composant->nb_bornes()
                        && k < static_cast<int>(modele->bornes.size());
             ++k) {
            if (noms[k].empty()) continue;
            netlist.relier(reference, modele->bornes[k].nom, noms[k]);
        }
    }
    return netlist;
}

// ---------------------------------------------------------------------------
void SceneSchema::appliquer_resultats(
    const std::map<std::string, double>& courants,
    const std::map<std::string, double>& tensions,
    const coeur::Formes* formes) {
    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele) continue;
        std::string reference = composant->reference().toStdString();
        std::transform(reference.begin(), reference.end(), reference.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        // CHAQUE MORCEAU DE SYMBOLE QUI S'ALLUME A SON PROPRE COURANT.
        //
        // L'afficheur sept segments déclarait `lumineux = true` et restait
        // NOIR quoi que fasse le circuit : le halo cherche un courant sous la
        // référence du composant, or ses sept diodes s'appellent D<RÉF>0 à
        // D<RÉF>6. Rien ne le signalait — ni message, ni test.
        for (const coeur::TraitSymbole& trait : modele->symbole) {
            if (trait.lumiere.empty()) continue;
            auto mesure = courants.find(reference + trait.lumiere);
            const double courant =
                mesure == courants.end() ? 0.0 : std::fabs(mesure->second);
            const double nominal = modele->courant_nominal > 0
                                       ? modele->courant_nominal
                                       : 0.02;
            double eclat = nominal > 0 ? courant / nominal : 0.0;
            eclat = eclat <= 0 ? 0 : std::pow(std::min(eclat, 1.5), 0.45);
            composant->definir_eclat_segment(trait.lumiere,
                                             std::min(1.0, eclat));
        }
        if (!modele->lumineux) continue;
        std::string cle = composant->reference().toStdString();
        std::transform(cle.begin(), cle.end(), cle.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        auto it = courants.find(cle);
        const double courant = it == courants.end() ? 0.0 : std::fabs(it->second);
        const double nominal =
            modele->courant_nominal > 0 ? modele->courant_nominal : 0.02;
        // L'œil répond au logarithme du flux : une LED à 10 % du courant
        // nominal ne paraît pas 10 fois moins lumineuse.
        double eclat = courant / nominal;
        eclat = eclat <= 0 ? 0 : std::pow(std::min(eclat, 1.5), 0.45);
        composant->definir_eclat(std::min(1.0, eclat));
    }

    const auto noeuds = calculer_noeuds();

    // Instruments : ils lisent le circuit résolu et affichent leur mesure sous
    // leur symbole, comme le ferait un appareil posé sur la paillasse.
    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->mesure_instrument) continue;
        auto it = noeuds.find(composant);
        if (it == noeuds.end()) continue;

        auto tension_de = [&](const std::string& nom_borne) {
            for (int k = 0; k < composant->nb_bornes(); ++k) {
                if (composant->nom_borne(k).toStdString() != nom_borne) continue;
                if (k >= static_cast<int>(it->second.size())) return 0.0;
                std::string noeud = it->second[k];
                std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                               [](unsigned char c) { return std::tolower(c); });
                auto mesure = tensions.find(noeud);
                return mesure == tensions.end() ? 0.0 : mesure->second;
            }
            return 0.0;
        };
        std::string reference = composant->reference().toStdString();
        std::transform(reference.begin(), reference.end(), reference.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        auto courant = courants.find(reference);

        coeur::Instance provisoire;
        provisoire.reference = composant->reference().toStdString();
        provisoire.type = modele->type;
        for (const auto& paire : composant->valeurs)
            provisoire.valeurs[paire.first] = paire.second;
        // Les textes portent la position de l'appareil (continu, alternatif) :
        // les oublier reviendrait à ignorer le réglage de l'utilisateur.
        for (const auto& paire : composant->textes)
            provisoire.textes[paire.first] = paire.second;

        coeur::Modele::Lecture lecture;
        lecture.tension = tension_de;
        lecture.courant = courant == courants.end() ? 0.0 : courant->second;
        if (formes && !formes->vide()) {
            lecture.temps = &formes->temps;
            auto onde = formes->courants.find(reference);
            if (onde != formes->courants.end())
                lecture.forme_courant = &onde->second;
            lecture.forme_tension =
                [&](const std::string& nom_borne) -> const std::vector<double>* {
                for (int k = 0; k < composant->nb_bornes(); ++k) {
                    if (composant->nom_borne(k).toStdString() != nom_borne)
                        continue;
                    if (k >= static_cast<int>(it->second.size())) return nullptr;
                    std::string noeud = it->second[k];
                    std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                                   [](unsigned char c) { return std::tolower(c); });
                    auto trouve = formes->tensions.find(noeud);
                    return trouve == formes->tensions.end() ? nullptr
                                                            : &trouve->second;
                }
                return nullptr;
            };
        }
        composant->definir_mesure(
            QString::fromStdString(modele->mesure_instrument(provisoire, lecture)));
    }

    // La tension d'un fil se lit à l'une ou l'autre de ses extrémités : elles
    // sont sur le même nœud. Interroger la seule extrémité de départ laissait
    // sans mesure tout fil partant d'un point de dérivation, puisqu'un point
    // n'est pas un composant — on essaie donc les deux.
    auto noeud_de_ancre = [&noeuds](const Ancre& ancre) -> std::string {
        if (!ancre.composant) return {};
        auto it = noeuds.find(ancre.composant);
        if (it == noeuds.end()) return {};
        if (ancre.borne < 0 || ancre.borne >= static_cast<int>(it->second.size()))
            return {};
        return it->second[ancre.borne];
    };
    // Un fil tendu entre DEUX points n'a aucune borne à interroger : essayer
    // les deux bouts ne suffisait pas, et il restait sans tension ni couleur
    // alors qu'il est sur un nœud parfaitement résolu. On donne donc d'abord
    // son nom de nœud à chaque point, en le propageant de proche en proche
    // depuis les bornes — un point et le fil qui l'atteint sont sur le même
    // nœud, par définition.
    const std::vector<ItemFil*> tous_les_fils = fils();
    std::map<const ItemJonction*, std::string> noeud_du_point;
    for (bool encore = true; encore;) {
        encore = false;
        for (ItemFil* fil : tous_les_fils) {
            const Ancre& a = fil->ancre_depart();
            const Ancre& b = fil->ancre_arrivee();
            auto nom = [&](const Ancre& ancre) -> std::string {
                if (ancre.composant) return noeud_de_ancre(ancre);
                auto it = noeud_du_point.find(ancre.jonction);
                return it == noeud_du_point.end() ? std::string() : it->second;
            };
            const std::string na = nom(a), nb = nom(b);
            if (!na.empty() && b.jonction && nb.empty()) {
                noeud_du_point[b.jonction] = na;
                encore = true;
            } else if (!nb.empty() && a.jonction && na.empty()) {
                noeud_du_point[a.jonction] = nb;
                encore = true;
            }
        }
    }

    for (ItemFil* fil : tous_les_fils) {
        std::string noeud = noeud_de_ancre(fil->ancre_depart());
        if (noeud.empty()) noeud = noeud_de_ancre(fil->ancre_arrivee());
        if (noeud.empty()) {
            for (const Ancre& ancre : {fil->ancre_depart(), fil->ancre_arrivee()}) {
                if (!ancre.jonction) continue;
                auto it = noeud_du_point.find(ancre.jonction);
                if (it != noeud_du_point.end()) noeud = it->second;
            }
        }
        if (noeud.empty()) continue;
        std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        auto mesure = tensions.find(noeud);
        if (mesure != tensions.end()) fil->definir_tension(mesure->second);
    }
}

QString SceneSchema::noeud_de(const ItemComposant* composant, int borne) const {
    const auto noeuds = calculer_noeuds();
    auto it = noeuds.find(composant);
    if (it == noeuds.end() || borne < 0
        || borne >= static_cast<int>(it->second.size()))
        return {};
    return QString::fromStdString(it->second[borne]);
}

std::map<QString, QString> SceneSchema::description_noeuds() const {
    const auto noeuds = calculer_noeuds();
    std::map<QString, QStringList> bornes_par_noeud;
    for (ItemComposant* composant : composants()) {
        auto it = noeuds.find(composant);
        if (it == noeuds.end()) continue;
        for (int k = 0; k < composant->nb_bornes()
                        && k < static_cast<int>(it->second.size()); ++k) {
            if (it->second[k].empty()) continue;
            bornes_par_noeud[QString::fromStdString(it->second[k])]
                << composant->reference() + "." + composant->nom_borne(k);
        }
    }
    std::map<QString, QString> resultat;
    for (auto& paire : bornes_par_noeud) {
        paire.second.sort();
        resultat[paire.first] = paire.second.join(" · ");
    }
    return resultat;
}

void SceneSchema::appliquer_etats(
    const std::map<std::string, std::map<std::string, double>>& etats) {
    for (ItemComposant* composant : composants()) {
        auto it = etats.find(composant->reference().toStdString());
        if (it == etats.end()) continue;
        // Les valeurs reviennent dans le composant : c'est ce qui fait que
        // l'angle d'un servomoteur survit à la reconstruction de la netlist,
        // laquelle a lieu à chaque modification du schéma.
        for (const auto& paire : it->second)
            composant->valeurs[paire.first] = paire.second;

        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->lecture) continue;
        coeur::Instance instance;
        instance.reference = composant->reference().toStdString();
        instance.type = modele->type;
        instance.valeurs = composant->valeurs;
        instance.textes = composant->textes;
        composant->definir_mesure(
            QString::fromStdString(modele->lecture(instance)));
    }
}

void SceneSchema::marquer_grille(const QString& reference) {
    for (ItemComposant* composant : composants())
        if (composant->reference() == reference) composant->definir_grille(true);
    update();
}

void SceneSchema::effacer_anomalies() {
    for (ItemComposant* composant : composants())
        composant->definir_anomalies({});
}

void SceneSchema::poser_anomalies(
    const std::vector<coeur::Anomalie>& anomalies) {
    // Table des marqueurs à poser, par composant. On la remplit d'abord, on
    // la pose ensuite : un composant peut porter plusieurs anomalies — deux
    // bornes en l'air sur la même résistance, c'est le cas ordinaire d'un
    // composant qu'on vient de déposer.
    std::map<ItemComposant*, std::vector<ItemComposant::MarqueurErc>> a_poser;
    std::map<QString, ItemComposant*> par_reference;
    for (ItemComposant* composant : composants())
        par_reference[composant->reference()] = composant;

    for (const coeur::Anomalie& anomalie : anomalies) {
        if (anomalie.gravite == coeur::Anomalie::Gravite::Information) continue;
        const bool erreur =
            anomalie.gravite == coeur::Anomalie::Gravite::Erreur;

        // Les trois formes de `reference`. La liste jointe par virgules est
        // celle des courts-circuits ; un nom de nœud ne désigne aucun
        // composant et ne trouvera simplement rien, ce qui est le traitement
        // correct — un nœud n'a pas de symbole où poser un triangle.
        const QStringList cibles =
            QString::fromStdString(anomalie.reference).split(',');
        for (const QString& brute : cibles) {
            const QString cible = brute.trimmed();
            if (cible.isEmpty()) continue;
            auto it = par_reference.find(cible);
            if (it == par_reference.end()) continue;

            ItemComposant::MarqueurErc marqueur;
            marqueur.erreur = erreur;
            marqueur.borne = -1;
            if (!anomalie.borne.empty()) {
                const QString nom = QString::fromStdString(anomalie.borne);
                for (int k = 0; k < it->second->nb_bornes(); ++k)
                    if (it->second->nom_borne(k) == nom) {
                        marqueur.borne = k;
                        break;
                    }
            }
            std::vector<ItemComposant::MarqueurErc>& liste = a_poser[it->second];
            // Deux règles peuvent viser la même borne : un seul triangle.
            if (std::find(liste.begin(), liste.end(), marqueur) == liste.end())
                liste.push_back(marqueur);
        }
    }

    for (ItemComposant* composant : composants()) {
        auto it = a_poser.find(composant);
        composant->definir_anomalies(
            it == a_poser.end() ? std::vector<ItemComposant::MarqueurErc>()
                                : it->second);
    }
}

QRectF SceneSchema::designer_anomalie(const QString& reference) {
    clearSelection();
    QRectF cadre;
    auto retenir = [&cadre](QGraphicsItem* item) {
        item->setSelected(true);
        cadre = cadre.isNull() ? item->sceneBoundingRect()
                               : cadre.united(item->sceneBoundingRect());
    };

    // Forme 1 et 2 : une référence, ou plusieurs jointes par virgules.
    bool trouve_un_composant = false;
    for (const QString& brute : reference.split(',')) {
        const QString cible = brute.trimmed();
        if (cible.isEmpty()) continue;
        for (ItemComposant* composant : composants())
            if (composant->reference() == cible) {
                retenir(composant);
                trouve_un_composant = true;
            }
    }
    if (trouve_un_composant) return cadre;

    // Forme 3 : un nom de nœud. Il n'a pas de symbole — ce sont ses fils qui
    // le matérialisent, et les sélectionner montre son étendue exacte.
    const QString noeud = reference.trimmed();
    if (noeud.isEmpty()) return cadre;
    const auto noms = calculer_noeuds();
    std::set<const ItemComposant*> touches;
    for (const auto& [composant, par_borne] : noms)
        for (const std::string& nom : par_borne)
            if (QString::fromStdString(nom) == noeud) touches.insert(composant);
    if (touches.empty()) return cadre;

    for (ItemFil* fil : fils()) {
        const ItemComposant* a = fil->depart();
        const ItemComposant* b = fil->arrivee();
        if ((a && touches.count(a)) || (b && touches.count(b))) retenir(fil);
    }
    // Un nœud peut n'avoir aucun fil — deux étiquettes de même nom le
    // relient sans trait. On se rabat alors sur les composants qu'il touche,
    // faute de quoi le clic ne montrerait rien.
    if (cadre.isNull())
        for (const ItemComposant* composant : touches)
            for (ItemComposant* pose : composants())
                if (pose == composant) retenir(pose);
    return cadre;
}

void SceneSchema::effacer_resultats() {
    for (ItemComposant* composant : composants()) {
        composant->definir_eclat(0.0);
        composant->definir_mesure({});
        // L'arrêt de la simulation remet le montage à neuf, en accord avec
        // MoteurSimulation qui vide sa liste au même moment.
        composant->definir_grille(false);
    }
    for (ItemFil* fil : fils()) fil->rafraichir();
    update();
}

// ---------------------------------------------------------------------------
void SceneSchema::drawBackground(QPainter* peintre, const QRectF& zone) {
    peintre->fillRect(zone, backgroundBrush());

    // Une grille ne se trace que si on peut la voir.
    //
    // Elle se traçait sans condition. Au zoom minimal (0,15), deux lignes du
    // pas fin sont séparées d'un pixel et demi : la feuille devient un aplat
    // gris uniforme sur lequel on ne distingue plus un fil. Et comme la vue
    // est en rafraîchissement intégral, ces milliers de lignes invisibles
    // étaient retracées à chaque image pendant la simulation.
    //
    // KiCad règle la même question par un « Min grid spacing » en pixels :
    // les lignes plus serrées que ce seuil ne sont pas tracées, quel que soit
    // le pas courant. On reprend le principe, sans l'exposer — un seuil de
    // cinq pixels ne se règle pas, il se constate.
    constexpr double kEcartMinimal = 5.0;
    const double echelle = peintre->transform().m11();

    if (kPas * echelle >= kEcartMinimal) {
        peintre->setPen(QPen(QColor(226, 230, 226), 0.6));
        const double gauche = std::floor(zone.left() / kPas) * kPas;
        const double haut = std::floor(zone.top() / kPas) * kPas;
        for (double x = gauche; x < zone.right(); x += kPas)
            peintre->drawLine(QPointF(x, zone.top()), QPointF(x, zone.bottom()));
        for (double y = haut; y < zone.bottom(); y += kPas)
            peintre->drawLine(QPointF(zone.left(), y), QPointF(zone.right(), y));
    }

    // Les repères de cent tiennent plus longtemps : quand le pas fin
    // disparaît, ils restent seuls et gardent une échelle lisible.
    if (100.0 * echelle >= kEcartMinimal) {
        peintre->setPen(QPen(QColor(206, 214, 206), 0.9));
        for (double x = std::floor(zone.left() / 100) * 100; x < zone.right();
             x += 100)
            peintre->drawLine(QPointF(x, zone.top()), QPointF(x, zone.bottom()));
        for (double y = std::floor(zone.top() / 100) * 100; y < zone.bottom();
             y += 100)
            peintre->drawLine(QPointF(zone.left(), y), QPointF(zone.right(), y));
    }
}

// Démarre un fil depuis une borne, et pose le trait provisoire qui suit le
// curseur.
// Fige le segment déjà tracé et repart du point posé.
//
// Le point créé n'a qu'un fil tant que la suite n'est pas tracée : c'est
// pourquoi le balayage ne doit pas passer avant que le chemin soit terminé.
// Un abandon en cours de route le laisse à un seul fil, et le balayage le
// retire alors avec sa branche — un chemin qui ne mène nulle part ne se
// garde pas.
void SceneSchema::poser_point_de_passage(const QPointF& point) {
    // Un coude posé est une modification définitive : il s'annule aussi.
    // L'état est relevé avant la découpe qu'`ancrer` peut déclencher.
    const QJsonObject avant_le_coude = vers_json();
    // Même précaution qu'à la fermeture : un tracé qui attendait depuis un fil
    // ne doit pas découper un fil qui n'existe plus.
    if (cible_depart_.genre == Cible::Genre::Fil
        && !fil_vivant(cible_depart_.fil)) {
        abandonner_fil();
        return;
    }
    const Ancre depart = ancrer(cible_depart_);
    if (!depart.valide()) {
        abandonner_fil();
        return;
    }
    auto* etape = new ItemJonction(aligner(point));
    addItem(etape);
    addItem(new ItemFil(depart, Ancre(etape)));
    empiler(avant_le_coude);

    Cible suite;
    suite.genre = Cible::Genre::Jonction;
    suite.ancre = Ancre(etape);
    suite.point = etape->pos();
    // On efface le trait provisoire SANS balayer : le point qu'on vient de
    // poser n'a encore qu'un fil, et le balayage l'emporterait aussitôt avec
    // sa branche. Il ne reprendra son droit qu'à la fin du chemin.
    effacer_provisoire();
    commencer_fil(suite, suite.point);
    fil_en_attente_ = true;
}

bool SceneSchema::amorcer_fil_au(const QPointF& point) {
    const Cible cible = viser(point);
    if (!cible.connectable()) return false;
    abandonner_fil();
    commencer_fil(cible, cible.point);
    // Le fil reste accroché au curseur jusqu'au clic suivant : c'est la même
    // mécanique que le clic simple sur une broche, et elle n'introduit aucun
    // mode — rien à quitter, il suffit de cliquer ou d'appuyer sur Échap.
    fil_en_attente_ = true;
    return true;
}

void SceneSchema::commencer_fil(const Cible& depart, const QPointF& point) {
    // Tant qu'un fil se tire, la vue ne sélectionne plus.
    //
    // Accepter l'événement suffit en théorie ; le couper à la source ne
    // dépend d'aucune subtilité de propagation. Un geste de câblage et un
    // rectangle de sélection ne peuvent pas coexister — c'est l'un OU
    // l'autre, jamais les deux en même temps.
    for (QGraphicsView* vue : views())
        vue->setDragMode(QGraphicsView::NoDrag);
    cible_depart_ = depart;
    fil_en_attente_ = false;
    point_appui_ = point;
    fil_provisoire_ =
        addPath(ItemFil::chemin(depart.point, point),
                QPen(QColor(0, 120, 215), 1.5, Qt::DashLine));
}

// Le nom lisible d'une ancre, pour le journal.
static QString nom_ancre(const Ancre& ancre) {
    if (ancre.composant)
        return ancre.composant->reference() + "."
               + ancre.composant->nom_borne(ancre.borne);
    return QStringLiteral("dérivation");
}

// Referme le fil sur une borne d'arrivée, si elle est valable.
// Cet objet est-il TOUJOURS dans la scène ?
//
// Un fil coupé est détruit, un point de fil devenu inutile est balayé. Toute
// ancre relevée avant l'un de ces deux gestes doit être revérifiée avant
// d'être réutilisée, sans quoi on déréférence un objet mort.
bool SceneSchema::fil_vivant(const ItemFil* fil) const {
    if (!fil) return false;
    for (const ItemFil* trait : fils())
        if (trait == fil) return true;
    return false;
}

// Ces deux cibles désignent-elles le MÊME point de raccordement ?
//
// C'est la question qui décide si un geste de câblage mène quelque part. Sur
// un fil, l'écart se juge à la demi-maille : deux points plus proches que ça
// s'aimanteraient sur le même nœud de grille, et le « fil » qui les relierait
// ne serait pas un fil mais un clic qui a glissé.
static bool meme_raccord(const SceneSchema::Cible& a,
                         const SceneSchema::Cible& b) {
    if (a.genre != b.genre) return false;
    switch (a.genre) {
        case SceneSchema::Cible::Genre::Broche:
        case SceneSchema::Cible::Genre::Jonction:
            return a.ancre == b.ancre;
        case SceneSchema::Cible::Genre::Fil:
            if (a.fil != b.fil) return false;
            return (a.point - b.point).manhattanLength() < kPas / 2.0;
        default:
            return false;
    }
}

bool SceneSchema::ancre_vivante(const Ancre& ancre) const {
    if (ancre.jonction) {
        for (ItemJonction* jonction : jonctions())
            if (jonction == ancre.jonction) return true;
        return false;
    }
    if (!ancre.composant) return false;
    for (ItemComposant* composant : composants())
        if (composant == ancre.composant) return true;
    return false;
}

bool SceneSchema::terminer_fil(const QPointF& point, Ancre* depart_materialise) {
    if (depart_materialise) *depart_materialise = Ancre();
    if (!cible_depart_.connectable()) return false;

    // UN GESTE QUI N'ABOUTIT PAS NE TOUCHE À RIEN.
    //
    // C'était faux, et ça coûtait cher : appuyer sur un fil puis relâcher sans
    // bouger — le geste qu'on fait pour DÉSIGNER un fil — découpait ce fil en
    // deux et y laissait une jonction de degré 2. Le balayage ne l'enlève pas
    // (elle relie bien deux fils), la pastille ne se dessine pas (il en
    // faudrait trois) : la topologie changeait en silence, au moindre clic
    // raté, et la pile d'annulation gagnait une entrée pour un geste que
    // personne n'avait demandé.
    //
    // Tout ce qui peut être vérifié l'est donc AVANT la moindre découpe, et
    // l'échec laisse le tracé exactement dans l'état où il l'a trouvé : c'est
    // à l'appelant, pas à cette fonction, de décider si le geste continue.
    if (cible_depart_.genre == Cible::Genre::Fil
        && !fil_vivant(cible_depart_.fil)) {
        // Le fil de départ a disparu pendant que le tracé attendait le clic
        // de fermeture. Il n'y a plus rien à couper — ni à déréférencer.
        abandonner_fil();
        return false;
    }
    const Cible arrivee_visee = viser(point);
    if (!arrivee_visee.connectable()) return false;
    if (meme_raccord(arrivee_visee, cible_depart_)) return false;

    // TIRER UN FIL S'ANNULE, comme le reste.
    //
    // Ce n'était pas le cas : `terminer_fil` n'appelait pas `memoriser()`.
    // L'action la plus fréquente du logiciel n'entrait donc PAS dans la pile,
    // qui ne gardait que les suppressions, les rotations et les collages —
    // d'où l'impression qu'un seul geste tenait en mémoire, alors que Ctrl+Z
    // sautait par-dessus tous les fils pour retomber bien plus loin en
    // arrière.
    //
    // L'état est relevé AVANT toute découpe, et n'est empilé QUE s'il diffère
    // vraiment de ce qui suit : un geste qui échoue sans rien changer ne doit
    // pas laisser derrière lui une entrée d'annulation qui ne fait rien, ce
    // qui serait aussi déroutant que l'absence.
    const QJsonObject avant_le_fil = vers_json();
    auto consigner = [this, &avant_le_fil] {
        if (avant_le_fil != vers_json()) empiler(avant_le_fil);
    };
    // C'est ici, et seulement ici, que l'on découpe : le geste va aboutir.
    const Ancre depart = ancrer(cible_depart_);
    // Le départ est désormais MATÉRIALISÉ, et la cible d'origine est périmée :
    // si elle visait un fil, ce fil vient d'être coupé et détruit. L'appelant
    // qui veut reprendre le tracé doit repartir de cette ancre-ci, jamais de
    // la cible.
    if (depart_materialise) *depart_materialise = depart;
    if (!depart.valide()) {
        abandonner_fil();
        consigner();
        return false;
    }
    // Le départ vient peut-être de couper un fil — éventuellement celui que
    // visait l'arrivée. On revise donc sur une scène à jour, sans quoi on
    // ancrerait sur un objet détruit.
    const Cible fraiche = viser(point);
    if (!fraiche.connectable()) {
        abandonner_fil();
        balayer_jonctions();
        consigner();
        return false;
    }
    const Ancre arrivee = ancrer(fraiche);
    if (!arrivee.valide() || arrivee == depart) {
        abandonner_fil();
        balayer_jonctions();
        consigner();
        return false;
    }
    addItem(new ItemFil(depart, arrivee));
    emit journal(QString("Fil : %1 — %2").arg(nom_ancre(depart),
                                              nom_ancre(arrivee)));
    balayer_jonctions();
    abandonner_fil();
    consigner();
    return true;
}

// ---------------------------------------------------------------------------
// Déplacer un segment de fil
//
// La plainte : « le mouvement des fils quand on appuie dessus une fois branché
// est loin d'être comme dans Simulink ». Chez MathWorks, un glissé simple sur
// un segment le déplace, et le curseur annonce l'axe permis.
//
// Ce qu'on garde de Simulink : le glissé nu déplace, l'aperçu est le tracé
// final, le voisinage est dérangé le moins possible. Ce qu'on n'en prend pas :
// leur `Ctrl`+glissé pour dériver, qui inverserait la polarité déjà écrite ici
// — chez nous un CLIC dérive, et cette convention n'a pas à se réapprendre
// pour ressembler à un logiciel que l'élève n'ouvrira jamais.
//
// Le partage se fait au seuil de glissé de Qt, celui qui sépare partout
// ailleurs un clic d'un déplacement : en deçà on dérive, au-delà on déplace.
// Aucun mode, aucune touche à retenir.
// ---------------------------------------------------------------------------
bool SceneSchema::axe_perpendiculaire(const ItemFil* fil, QPointF* axe) {
    if (!fil) return false;
    const QPointF a = fil->ancre_depart().position();
    const QPointF b = fil->ancre_arrivee().position();
    const double dx = std::fabs(a.x() - b.x());
    const double dy = std::fabs(a.y() - b.y());
    // Un fil en équerre n'a pas d'axe : le déplacer voudrait dire deux choses
    // à la fois. On refuse — et le clic y garde son sens de dérivation, ce qui
    // permet justement d'y poser les coudes qui le rendront d'aplomb.
    if (dx > 0.01 && dy > 0.01) return false;
    if (dx <= 0.01 && dy <= 0.01) return false;
    if (axe) *axe = (dy <= 0.01) ? QPointF(0, 1) : QPointF(1, 0);
    return true;
}

bool SceneSchema::commencer_deplacement_segment(ItemFil* fil,
                                                const QPointF& appui) {
    QPointF axe;
    if (!fil_vivant(fil) || !axe_perpendiculaire(fil, &axe)) return false;

    // L'état d'avant, relevé avant la moindre insertion : le geste s'annule
    // d'un bloc, poignées comprises.
    avant_deplacement_ = vers_json();

    // LE DÉRANGEMENT MINIMAL, appliqué.
    //
    // Une extrémité tenue par une BROCHE ne bouge pas : elle appartient au
    // composant. On y insère donc un point, relié à la broche par un bout de
    // fil neuf, et c'est ce point qui suivra la souris — le composant ne
    // bouge pas d'un pixel, et le segment se décale en emmenant ses deux
    // raccords. Une extrémité qui est DÉJÀ un point de fil se déplace telle
    // quelle : ses autres fils s'allongent, personne n'est débranché.
    //
    // C'est le corollaire écrit dans DECISION-FILS : « un fil tendu entre
    // deux broches n'a rien à déplacer ». Il n'a rien à déplacer tant qu'on
    // ne lui a pas donné de quoi.
    // UN FIL SORT TOUT DROIT D'UNE BROCHE AVANT DE TOURNER.
    //
    // La poignée était posée EXACTEMENT sur la broche. Le segment déplacé
    // partait donc du point d'accroche à angle droit, et l'on ne voyait plus
    // d'où le fil partait : le coude, la borne et l'étiquette de tension se
    // superposaient en un seul amas de traits. C'est la remarque de
    // l'utilisateur, et c'est une règle de dessin d'électronique bien avant
    // d'être une question de goût — sur un schéma tracé à la main, un fil
    // quitte toujours sa broche en ligne droite sur une petite longueur.
    //
    // La poignée est donc reculée le long du fil, vers l'autre bout. Deux
    // mailles suffisent à rendre l'accroche lisible ; sur un fil court on se
    // contente du tiers, et en deçà d'une maille on renonce — un dégagement
    // plus long que le fil lui-même le ferait revenir sur ses pas.
    const QPointF le_long(axe.y(), axe.x());   // l'axe DU fil, pas le sien
    auto poignee = [this, &le_long](const Ancre& bout,
                                    const QPointF& vers) -> ItemJonction* {
        if (bout.jonction) return bout.jonction;
        const QPointF depart = bout.position();
        const QPointF ecart = vers - depart;
        const double course =
            le_long.x() != 0.0 ? ecart.x() : ecart.y();
        double degagement = std::min(2.0 * kPas, std::fabs(course) / 3.0);
        degagement = std::floor(degagement / kPas) * kPas;
        if (degagement < kPas) degagement = 0.0;
        const QPointF pose =
            depart + le_long * (course < 0 ? -degagement : degagement);
        auto* point = new ItemJonction(pose);
        addItem(point);
        addItem(new ItemFil(bout, Ancre(point)));
        return point;
    };
    const Ancre a = fil->ancre_depart();
    const Ancre b = fil->ancre_arrivee();
    ItemJonction* pa = poignee(a, b.position());
    ItemJonction* pb = poignee(b, a.position());
    if (pa != a.jonction || pb != b.jonction) {
        // Le segment change d'ancres : on le refait, plutôt que d'ouvrir
        // `ItemFil` à la mutation de son départ.
        removeItem(fil);
        delete fil;
        addItem(new ItemFil(Ancre(pa), Ancre(pb)));
    }

    poignees_ = {pa, pb};
    origines_poignees_ = {pa->pos(), pb->pos()};
    axe_deplacement_ = axe;
    appui_point_ = appui;
    for (QGraphicsView* vue : views()) vue->setDragMode(QGraphicsView::NoDrag);
    eteindre_noeud();
    balayer_jonctions();
    return true;
}

void SceneSchema::poursuivre_deplacement_segment(const QPointF& point) {
    if (poignees_.size() != 2) return;
    // Seule la composante perpendiculaire compte : le long du fil, un
    // déplacement ne déplacerait rien de visible.
    const QPointF ecart = point - appui_point_;
    const double libre =
        axe_deplacement_.x() != 0.0 ? ecart.x() : ecart.y();
    // Aimanté sur la grille, comme tout le reste — sans quoi le segment
    // atterrirait entre deux mailles et les fils voisins avec lui.
    const double pas = std::round(libre / kPas) * kPas;
    for (std::size_t i = 0; i < poignees_.size(); ++i)
        poignees_[i]->setPos(origines_poignees_[i] + axe_deplacement_ * pas);
    for (ItemFil* fil : fils()) fil->rafraichir();
}

void SceneSchema::terminer_deplacement_segment() {
    if (poignees_.empty()) return;
    const bool immobile = poignees_[0]->pos() == origines_poignees_[0];
    // UNE COPIE, PAS LE MEMBRE.
    //
    // `depuis_json` prend une référence, et il passe par `tout_effacer`, qui
    // remet désormais l'état du geste à zéro — dont ce membre. On lui aurait
    // donc donné un objet vidé au moment même où il le lit, et l'annulation
    // aurait effacé le schéma entier.
    const QJsonObject avant = avant_deplacement_;
    poignees_.clear();
    origines_poignees_.clear();
    avant_deplacement_ = QJsonObject();
    rendre_le_rectangle_a_la_vue();

    if (immobile) {
        // Reposé là où il était : les points insérés pour le tenir n'ont plus
        // de raison d'être, et laisser une topologie modifiée derrière un
        // geste sans effet est exactement le défaut qu'on vient de corriger
        // ailleurs. On remet le schéma tel qu'il était.
        depuis_json(avant);
    } else if (avant != vers_json()) {
        empiler(avant);
        emit journal("Segment déplacé.");
    }
    balayer_jonctions();
}

// CE QUI DÉTRUIT CLÔT D'ABORD LE GESTE EN COURS.
//
// Un geste de souris désigne des objets d'un événement à l'autre : le fil sur
// lequel on vient d'appuyer, les deux poignées qu'on est en train de glisser.
// Rien n'oblige l'utilisateur à finir ce geste avant d'appuyer sur Suppr ou
// Ctrl+Z — le raccourci appartient à la fenêtre, il part même bouton enfoncé.
// La scène était alors reconstruite ou vidée sous les pieds du geste, qui
// continuait à écrire dans des objets détruits.
//
// Trois use-after-free confirmés à l'ASan tenaient à cet oubli, et tous à la
// même cause : `abandonner_fil()` était bien appelé par ce qui détruit, mais
// il ne connaît que le TRACÉ. L'attente d'un verdict et le glissé d'un segment
// sont deux états de plus, arrivés depuis, et que personne n'avait pensé à
// clore.
void SceneSchema::oublier_geste_en_cours() {
    trace_au_bouton_droit_ = false;
    poignees_.clear();
    origines_poignees_.clear();
    avant_deplacement_ = QJsonObject();
    appui_en_attente_ = Cible();
    rendre_le_rectangle_a_la_vue();
}

void SceneSchema::rendre_le_rectangle_a_la_vue() {
    for (QGraphicsView* vue : views())
        vue->setDragMode(QGraphicsView::RubberBandDrag);
}

void SceneSchema::effacer_provisoire() {
    if (!fil_provisoire_) return;
    removeItem(fil_provisoire_);
    delete fil_provisoire_;
    fil_provisoire_ = nullptr;
}

void SceneSchema::abandonner_fil() {
    effacer_provisoire();
    // La sélection au rectangle reprend son droit dès que le fil est fini.
    rendre_le_rectangle_a_la_vue();
    // Un appui resté sans verdict n'a plus rien à trancher.
    appui_en_attente_ = Cible();
    cible_depart_ = Cible();
    fil_en_attente_ = false;
    // Les points de passage d'un chemin abandonné n'ont plus qu'un fil : le
    // balayage les retire, de proche en proche jusqu'au premier point qui
    // relie vraiment quelque chose.
    balayer_jonctions();
}

// Composant sous un point, quelle que soit la partie touchée.
static ItemComposant* composant_sous(const QGraphicsScene* scene,
                                    const QPointF& point) {
    for (QGraphicsItem* item : scene->items(point))
        if (item->type() == ItemComposant::Type)
            return static_cast<ItemComposant*>(item);
    return nullptr;
}

void SceneSchema::mousePressEvent(QGraphicsSceneMouseEvent* evenement) {
    const QPointF point = evenement->scenePos();

    // LE BOUTON DROIT TIRE UNE DÉRIVATION — depuis un fil, et depuis lui seul.
    //
    // C'est le geste de Simulink, à la lettre : « position the pointer on the
    // line where you want the branch to start, then right-click and drag ».
    // Sur un fil, le bouton gauche MANIPULE ce qui existe — il déplace le
    // segment, il le désigne — et c'est le bouton droit qui fait NAÎTRE un
    // fil neuf. Les deux rôles ne se disputent plus le même geste, et c'est
    // ce qui permet enfin au glissé gauche de vouloir dire « déplacer », sans
    // seuil ni devinette.
    //
    // Depuis une broche, rien ne change : le bouton gauche câble, comme dans
    // Simulink où l'on tire un signal d'un port à la souris.
    if (evenement->button() == Qt::RightButton && outil_ != Outil::Suppression
        && !fil_provisoire_ && !fil_en_attente_) {
        const Cible cible = viser(point);
        if (cible.genre == Cible::Genre::Fil) {
            evenement->accept();
            commencer_fil(cible, cible.point);
            trace_au_bouton_droit_ = true;
            appui_point_ = point;
            return;
        }
    }

    if (evenement->button() == Qt::LeftButton && outil_ != Outil::Suppression) {
        // Fil laissé en attente par un premier clic : ce clic-ci le referme,
        // ou l'abandonne s'il tombe à côté d'une borne.
        if (fil_en_attente_ && cible_depart_.connectable()) {
            // ACCEPTER est indispensable, et ce n'est pas un détail.
            //
            // Le rectangle de sélection ne vient pas de la scène mais de la
            // VUE : QGraphicsView le démarre quand la scène n'a pas accepté
            // l'événement. Nos branches de câblage faisaient « return » sans
            // accepter, si bien qu'un fil se tirait ET qu'un rectangle de
            // sélection s'ouvrait par-dessus, en même temps.
            evenement->accept();
            if (terminer_fil(point)) return;
            // Le clic tombe sur une cible, mais le fil n'a pas pu s'y
            // refermer : c'est le point de départ lui-même. Y poser un coude
            // fabriquerait un segment de longueur nulle — on renonce.
            //
            // Ce cas ne se distinguait pas du clic dans le vide parce que
            // `terminer_fil` abandonnait le tracé dans les deux cas ; le clic
            // dans le vide n'avait donc plus de cible de départ et ne posait
            // AUCUN coude, contrairement à ce que la suite annonce.
            if (viser(point).connectable()) {
                abandonner_fil();
                return;
            }
            // Clic dans le vide pendant un tracé : on POSE UN POINT DE
            // PASSAGE et l'on continue, au lieu de tout abandonner.
            //
            // C'est le geste de Simulink et celui de Proteus — « if you want
            // a wire in a particular place, you can simply click at the
            // intermediate corners ». Il donne la main sur le chemin sans
            // changer d'outil, et c'était le point 3 de DECISION-FILS.md,
            // écrit mais jamais fait.
            poser_point_de_passage(point);
            return;
        }

        // Sans mode : ce qui est sous le curseur décide. Broche, point de
        // fil ou fil — on câble ; corps de composant — on sélectionne. Plus
        // d'outil à choisir avant d'agir, et notamment plus de bascule en
        // sélection quand on part d'un fil, qui était le défaut le plus
        // visible à l'usage.
        const Cible cible = viser(point);

        // Ctrl+clic DÉSIGNE, sans rien câbler.
        //
        // C'est le seul moyen de sélectionner UN fil précis : le rectangle de
        // sélection emporte ses voisins dans un schéma dense. Une fois
        // désigné, le fil se déplace aux flèches — le mécanisme existe déjà et
        // n'attendait que ça. Ctrl est ici la convention de l'explorateur de
        // fichiers, pas un mode : il ajoute à une sélection, il n'arme rien.
        if (evenement->modifiers() & Qt::ControlModifier) {
            if (cible.genre == Cible::Genre::Fil && cible.fil) {
                evenement->accept();
                cible.fil->setSelected(!cible.fil->isSelected());
                return;
            }
            if (cible.genre == Cible::Genre::Jonction && cible.ancre.jonction) {
                evenement->accept();
                ItemJonction* point_de_fil = cible.ancre.jonction;
                point_de_fil->setSelected(!point_de_fil->isSelected());
                return;
            }
        }

        // APPUYER SUR UN FIL NE DÉCIDE PAS ENCORE.
        //
        // Clic = dériver, glissé perpendiculaire = déplacer le segment. Les
        // deux commencent par le même appui ; c'est la souris qui tranche, au
        // seuil de glissé de Qt. Décider dès l'appui, comme on le faisait,
        // rendait le déplacement impossible à offrir sans une touche à
        // retenir.
        if (cible.genre == Cible::Genre::Fil) {
            evenement->accept();
            appui_en_attente_ = cible;
            appui_point_ = point;
            for (QGraphicsView* vue : views())
                vue->setDragMode(QGraphicsView::NoDrag);
            return;
        }

        if (cible.connectable()) {
            // On NE DÉCOUPE PAS ici.
            //
            // On le faisait, et la découpe restait commise même quand le
            // geste était abandonné : un clic au milieu d'un fil suivi d'un
            // Échap laissait le fil coupé en deux autour d'un point mort, que
            // l'enregistrement suivant jetait — la pile s'en trouvait
            // débranchée, définitivement, sans trace. La cible est donc
            // gardée telle quelle, et n'est ancrée qu'au moment où le fil
            // naît vraiment.
            evenement->accept();
            commencer_fil(cible, cible.point);
            return;
        }
        if (outil_ == Outil::Fil) return;   // l'outil fil ne fait que ça
        // Un déplacement commence peut-être : on garde l'état d'avant pour
        // pouvoir l'annuler, et on ne l'empilera qu'en cas de vrai changement.
        // Seulement si le clic porte sur un composant : sérialiser la scène à
        // chaque clic dans le vide serait du travail pour rien.
        if (cible.genre == Cible::Genre::Composant)
            etat_avant_geste_ = vers_json();
    }
    if (outil_ == Outil::Suppression && evenement->button() == Qt::LeftButton) {
        clearSelection();
        if (QGraphicsItem* item = itemAt(point, QTransform())) {
            // La gomme s'annule comme le reste : on garde l'état d'avant.
            memoriser();
            item->setSelected(true);
            supprimer_selection();
        }
        return;
    }

    QGraphicsScene::mousePressEvent(evenement);
    if (QGraphicsItem* item = itemAt(point, QTransform())) {
        if (item->type() == ItemComposant::Type) {
            emit selection_composant(static_cast<ItemComposant*>(item));
            return;
        }
    }
    emit selection_composant(nullptr);
}

void SceneSchema::mouseMoveEvent(QGraphicsSceneMouseEvent* evenement) {
    if (deplace_un_segment()) {
        evenement->accept();
        poursuivre_deplacement_segment(evenement->scenePos());
        return;
    }

    // Le geste amorcé sur un fil attend le verdict de la souris.
    if (appui_en_attente_.genre == Cible::Genre::Fil) {
        const QPointF ecart = evenement->scenePos() - appui_point_;
        // Le seuil de Qt, pas une constante maison : c'est celui qui sépare
        // déjà le clic du glissé dans toute la boîte à outils, donc celui que
        // la main de l'utilisateur connaît sans le savoir.
        if (ecart.manhattanLength() < QApplication::startDragDistance()) {
            evenement->accept();
            return;
        }
        const Cible appui = appui_en_attente_;
        appui_en_attente_ = Cible();
        evenement->accept();
        // Le fil a pu être supprimé entre l'appui et ce mouvement. Le
        // relâchement le vérifiait, pas le mouvement : deux usages du même
        // état, un seul gardé.
        if (!fil_vivant(appui.fil)) {
            rendre_le_rectangle_a_la_vue();
            return;
        }
        QPointF axe;
        const bool perpendiculaire =
            axe_perpendiculaire(appui.fil, &axe)
            && (axe.x() != 0.0 ? std::fabs(ecart.x()) > std::fabs(ecart.y())
                               : std::fabs(ecart.y()) > std::fabs(ecart.x()));
        if (perpendiculaire
            && commencer_deplacement_segment(appui.fil, appui_point_)) {
            poursuivre_deplacement_segment(evenement->scenePos());
            return;
        }
        // Sinon, c'est une dérivation : le tracé commence au point d'appui,
        // exactement comme si l'on avait cliqué.
        commencer_fil(appui, appui.point);
    }

    if (fil_provisoire_ && cible_depart_.connectable()) {
        // L'APERÇU DOIT ÊTRE LE TRACÉ FINAL, sinon il ment.
        //
        // Il suivait le curseur au pixel près. Or le clic, lui, ne pose
        // jamais son point là : dans le vide il l'ALIGNE SUR LA GRILLE
        // (`poser_point_de_passage`), et sur une cible il le pose sur
        // l'ancre. On voyait donc un fil en biais et l'on en obtenait un
        // droit — et à quelques pixels d'écart vertical, la tolérance
        // d'alignement décidait l'inverse de ce que l'aperçu montrait.
        //
        // C'est le troisième piège que DECISION-FILS §« Ce qu'il faudra
        // vérifier » annonçait : « l'aperçu doit être celui du tracé final,
        // sinon il ment ». Il mentait.
        const Cible sous_curseur = viser(evenement->scenePos());
        const QPointF arrivee = sous_curseur.connectable()
                                    ? sous_curseur.point
                                    : aligner(evenement->scenePos());
        fil_provisoire_->setPath(ItemFil::chemin(cible_depart_.point, arrivee));
        // Même raison qu'à l'appui : sans cela, la vue croit le geste libre
        // et étire un rectangle de sélection pendant qu'on tire le fil.
        evenement->accept();
        return;
    }

    // Le curseur annonce ce que le clic va faire. C'est ce qui rend l'absence
    // de mode lisible plutôt que surprenante : sans ce signe, rien ne dirait
    // qu'un clic va câbler plutôt que déplacer. Proteus fait de même — crayon
    // au-dessus d'une broche, marque verte au-dessus d'un fil.
    if (outil_ != Outil::Suppression) {
        const Cible cible = viser(evenement->scenePos());
        Qt::CursorShape forme = Qt::ArrowCursor;
        if (cible.genre == Cible::Genre::Broche
            || cible.genre == Cible::Genre::Jonction)
            forme = Qt::CrossCursor;
        else if (cible.genre == Cible::Genre::Fil) {
            // LE CURSEUR ANNONCE L'AXE, comme chez MathWorks.
            //
            // Sur un fil, deux gestes cohabitent : le clic dérive, le glissé
            // déplace. Le second est le seul des deux qui soit CONTRAINT — on
            // ne déplace un segment que perpendiculairement à lui-même — et
            // c'est donc lui que le curseur doit dire, sans quoi l'utilisateur
            // découvrirait la contrainte en la heurtant. La main reste pour
            // les fils en équerre, qu'on ne peut que dériver.
            QPointF axe;
            if (axe_perpendiculaire(cible.fil, &axe))
                forme = axe.x() != 0.0 ? Qt::SizeHorCursor : Qt::SizeVerCursor;
            else
                forme = Qt::PointingHandCursor;
        }
        else if (cible.genre == Cible::Genre::Composant)
            forme = Qt::SizeAllCursor;        // ici, on déplace
        for (QGraphicsView* vue : views()) vue->setCursor(forme);

        // … et tout le nœud s'allume. Le curseur dit ce que le clic FERA ;
        // la surbrillance dit ce qui EST relié. Deux questions différentes,
        // posées par le même geste, répondues au même endroit.
        allumer_noeud(evenement->scenePos());
    }

    QGraphicsScene::mouseMoveEvent(evenement);
    // Un composant déplacé entraîne le retracé de ses fils.
    for (ItemFil* fil : fils()) fil->rafraichir();
}

void SceneSchema::mouseReleaseEvent(QGraphicsSceneMouseEvent* evenement) {
    // Fin d'un glissé au bouton droit : la dérivation se referme si elle
    // tombe sur une cible, sinon elle reste accrochée au curseur et c'est un
    // clic GAUCHE qui la terminera — la suite du tracé ne dépend plus du
    // bouton par lequel il a commencé.
    if (trace_au_bouton_droit_ && evenement->button() == Qt::RightButton) {
        trace_au_bouton_droit_ = false;
        evenement->accept();
        const QPointF point = evenement->scenePos();
        if ((point - appui_point_).manhattanLength()
            < QApplication::startDragDistance()) {
            // Un simple clic droit, sans glissé : ce n'était pas une
            // dérivation. On rend la main au menu contextuel.
            abandonner_fil();
            return;
        }
        // Le menu contextuel part au RELÂCHEMENT sous Windows, donc APRÈS ce
        // geste : sans cela, chaque dérivation finirait par un menu à
        // chasser.
        ignorer_prochain_menu_ = true;
        if (terminer_fil(point)) return;
        if (cible_depart_.connectable()) fil_en_attente_ = true;
        return;
    }

    if (deplace_un_segment()) {
        evenement->accept();
        terminer_deplacement_segment();
        return;
    }

    // Appuyé sur un fil au bouton GAUCHE, relâché sans avoir franchi le
    // seuil : c'était un clic, et un clic gauche sur un fil le DÉSIGNE.
    //
    // Il dérivait, et c'est ce qui rendait le fil intouchable : on ne pouvait
    // pas le montrer sans en faire pousser un autre. La dérivation est passée
    // au bouton droit, comme dans Simulink ; le bouton gauche ne s'occupe plus
    // que de ce qui existe déjà — désigner d'un clic, déplacer d'un glissé.
    if (appui_en_attente_.genre == Cible::Genre::Fil) {
        const Cible appui = appui_en_attente_;
        appui_en_attente_ = Cible();
        evenement->accept();
        rendre_le_rectangle_a_la_vue();
        if (!fil_vivant(appui.fil)) return;
        if (!(evenement->modifiers() & Qt::ControlModifier)) clearSelection();
        appui.fil->setSelected(true);
        emit selection_composant(nullptr);
        return;
    }

    if (fil_provisoire_ && cible_depart_.connectable() && !fil_en_attente_) {
        evenement->accept();
        const QPointF point = evenement->scenePos();
        Ancre materialisee;
        if (terminer_fil(point, &materialisee)) return;

        // RELÂCHER NE TERMINE JAMAIS UN FIL.
        //
        // Le fil reste accroché au curseur jusqu'à ce qu'un clic le referme
        // sur une cible, ou qu'Échap l'abandonne. C'est la seule règle qui
        // n'oblige à rien : on peut câbler d'un glissement continu comme on
        // peut lâcher le bouton, réfléchir, se déplacer, puis cliquer.
        //
        // Auparavant le fil n'était gardé que si la souris n'avait pas bougé
        // de plus de six pixels — au-delà, relâcher dans le vide le JETAIT.
        // Le geste le plus naturel du débutant (partir d'une broche, traverser
        // le schéma, souffler, reprendre) effaçait donc son travail sans un
        // mot, et rien à l'écran ne disait pourquoi. Un clic dans le vide,
        // lui, pose un point de passage : c'est le presseEvent qui s'en
        // charge, et c'est ce qui permet d'imposer un tracé.
        //
        // ON NE REPART JAMAIS DE LA CIBLE D'ORIGINE.
        //
        // C'était un use-after-free, et il plantait pour de bon. Quand le
        // tracé part d'un FIL, `terminer_fil` appelle `ancrer`, qui découpe ce
        // fil et le DÉTRUIT pour y poser une jonction. Si l'arrivée n'aboutit
        // pas, la cible gardée par l'appelant désigne alors un objet mort.
        //
        // Avant que « relâcher ne termine plus un fil », ce chemin n'était
        // atteint que si la souris n'avait pas bougé de six pixels — le
        // défaut existait déjà, il était seulement très difficile à
        // déclencher.
        //
        // On repart donc de l'ancre RÉELLEMENT matérialisée, et seulement
        // après avoir vérifié qu'elle est encore dans la scène : `ancrer` peut
        // avoir échoué, et `balayer_jonctions` peut avoir emporté un point
        // devenu inutile entre-temps.
        if (materialisee.valide() && ancre_vivante(materialisee)) {
            Cible reprise;
            reprise.genre = materialisee.jonction ? Cible::Genre::Jonction
                                                  : Cible::Genre::Broche;
            reprise.ancre = materialisee;
            reprise.point = materialisee.position();
            commencer_fil(reprise, point);
            fil_en_attente_ = true;
            return;
        }
        // Rien n'a été matérialisé : `terminer_fil` n'a alors touché à rien
        // du tout, tracé compris. Le fil provisoire est encore accroché au
        // curseur et son départ tient toujours — il n'y a qu'à le laisser
        // en attente du clic qui le refermera. Plus besoin de reconstruire
        // une cible à partir d'une copie que la découpe pouvait périmer :
        // c'est cette reconstruction qui était l'use-after-free.
        if (cible_depart_.connectable()) fil_en_attente_ = true;
        return;
    }
    QGraphicsScene::mouseReleaseEvent(evenement);
    // Réalignement sur la grille après un déplacement.
    for (QGraphicsItem* item : selectedItems())
        if (item->type() == ItemComposant::Type) item->setPos(aligner(item->pos()));
    for (ItemFil* fil : fils()) fil->rafraichir();

    // Quelque chose a-t-il bougé ? Si oui, le geste devient annulable.
    if (!etat_avant_geste_.isEmpty()) {
        if (etat_avant_geste_ != vers_json()) empiler(etat_avant_geste_);
        etat_avant_geste_ = QJsonObject();
    }
}

void SceneSchema::mouseDoubleClickEvent(QGraphicsSceneMouseEvent* evenement) {
    if (evenement->button() == Qt::LeftButton) {
        // Un double-clic ne doit pas laisser un fil à moitié tiré derrière lui.
        abandonner_fil();
        if (ItemComposant* composant = composant_sous(this,
                                                      evenement->scenePos())) {
            emit selection_composant(composant);
            emit double_clic_composant(composant);
            return;
        }
    }
    QGraphicsScene::mouseDoubleClickEvent(evenement);
}

void SceneSchema::contextMenuEvent(QGraphicsSceneContextMenuEvent* evenement) {
    // Une dérivation vient d'être tirée au bouton droit : le menu qui suit
    // n'a pas été demandé. Sous Windows il part au relâchement, donc APRÈS le
    // geste — le test doit venir avant tout le reste.
    if (ignorer_prochain_menu_) {
        ignorer_prochain_menu_ = false;
        evenement->accept();
        return;
    }
    // Un geste en cours : le clic droit l'abandonne, et RIEN d'autre.
    //
    // Il abandonnait le fil puis ouvrait quand même le menu : on voulait
    // renoncer, on se retrouvait avec un menu non demandé à chasser d'un
    // second clic. Les deux rôles du bouton droit doivent s'exclure, et c'est
    // ce que fait Proteus — « click left to effect the move, or else abort it
    // by clicking right ».
    if (fil_provisoire_ || fil_en_attente_) {
        abandonner_fil();
        evenement->accept();
        return;
    }
    ItemComposant* composant = composant_sous(this, evenement->scenePos());
    if (composant) {
        clearSelection();
        composant->setSelected(true);
        emit selection_composant(composant);
    }
    emit menu_demande(composant, evenement->screenPos());
    evenement->accept();
}

void SceneSchema::keyPressEvent(QKeyEvent* evenement) {
    if (evenement->key() == Qt::Key_Escape) {
        // Échap n'est consommé QUE s'il avait un tracé à abandonner. Sans
        // fil en cours il poursuit sa route vers la fenêtre, qui s'en sert
        // pour sortir du mode présentation. Un événement avalé sans rien
        // faire rendait ce second usage impossible à brancher — et rien à
        // l'écran n'aurait expliqué pourquoi la touche ne répondait pas.
        const bool tracait = fil_provisoire_ != nullptr || fil_en_attente_;
        abandonner_fil();
        if (tracait) return;
    }
    if (evenement->key() == Qt::Key_Delete) {
        if (!selectedItems().isEmpty()) memoriser();
        supprimer_selection();
        return;
    }
    // Les flèches déplacent la sélection d'un pas de grille.
    //
    // C'est la seule façon d'ALIGNER pour de bon : à la souris, on approche,
    // on dépasse, on recommence. Au clavier, deux composants posés sur la
    // même ligne y restent. La proposition était retenue au chantier 2 et
    // n'avait jamais été écrite.
    //
    // `Maj` donne le pas fin — une unité — pour les cas où la grille est trop
    // grosse. C'est la convention de KiCad et d'Inkscape.
    {
        const int touche = evenement->key();
        QPointF pas;
        if (touche == Qt::Key_Left) pas = QPointF(-1, 0);
        else if (touche == Qt::Key_Right) pas = QPointF(1, 0);
        else if (touche == Qt::Key_Up) pas = QPointF(0, -1);
        else if (touche == Qt::Key_Down) pas = QPointF(0, 1);
        if (!pas.isNull()) {
            // Rien de sélectionné : la flèche appartient à la vue, qui s'en
            // sert pour défiler. La consommer sans rien déplacer priverait
            // l'utilisateur du seul déplacement au clavier qu'il avait.
            if (selectedItems().isEmpty()) {
                QGraphicsScene::keyPressEvent(evenement);
                return;
            }
            const double amplitude =
                (evenement->modifiers() & Qt::ShiftModifier) ? 1.0 : kPas;
            const QPointF ecart = pas * amplitude;

            // Un point de fil déplacé deux fois avancerait du double : on
            // rassemble d'abord, on déplace ensuite. Le cas arrive dès qu'un
            // fil ET son point sont tous deux dans la sélection.
            std::set<QGraphicsItem*> a_deplacer;
            for (QGraphicsItem* item : selectedItems()) {
                if (item->type() == ItemComposant::Type
                    || item->type() == ItemJonction::Type) {
                    a_deplacer.insert(item);
                    continue;
                }
                // Un FIL sélectionné se déplace par ses ancres mobiles.
                //
                // Une extrémité tenue par une broche ne bouge pas — elle
                // appartient au composant. Une extrémité qui est un point de
                // fil, si. C'est exactement le partage que fait LibrePCB, où
                // un `dynamic_cast` vers le point de fil sert de filtre :
                // voir DECISION-FILS.md.
                if (item->type() != ItemFil::Type) continue;
                auto* fil = static_cast<ItemFil*>(item);
                for (const Ancre& ancre :
                     {fil->ancre_depart(), fil->ancre_arrivee()})
                    if (ancre.jonction) a_deplacer.insert(ancre.jonction);
            }
            if (a_deplacer.empty()) {
                evenement->accept();
                return;
            }
            memoriser();
            for (QGraphicsItem* item : a_deplacer)
                item->setPos(item->pos() + ecart);
            for (ItemFil* fil : fils()) fil->rafraichir();
            // Ce qui vient de bouger n'est plus sous le curseur.
            eteindre_noeud();
            evenement->accept();
            return;
        }
    }

    if (evenement->key() == Qt::Key_R) {
        if (selectedItems().isEmpty()) return;
        memoriser();
        for (QGraphicsItem* item : selectedItems())
            if (item->type() == ItemComposant::Type)
                static_cast<ItemComposant*>(item)->tourner();
        for (ItemFil* fil : fils()) fil->rafraichir();
        return;
    }
    QGraphicsScene::keyPressEvent(evenement);
}

// ---------------------------------------------------------------------------
// Sérialisation, annulation, presse-papiers
//
// Les trois reposent sur la même idée : un schéma sait s'écrire en JSON et se
// relire. Annuler, c'est relire l'état précédent ; coller, c'est relire un
// extrait. Rien à réécrire quand une commande nouvelle apparaît.
// ---------------------------------------------------------------------------
QJsonObject SceneSchema::vers_json(bool selection_seule) const {
    QJsonArray tableau_composants;
    std::map<const ItemComposant*, int> index;
    int rang = 0;
    for (ItemComposant* item : composants()) {
        if (selection_seule && !item->isSelected()) continue;
        index[item] = rang++;
        QJsonObject objet;
        objet["type"] = QString::fromStdString(item->modele()->type);
        objet["reference"] = item->reference();
        objet["x"] = item->pos().x();
        objet["y"] = item->pos().y();
        objet["rotation"] = item->rotation();
        QJsonObject valeurs;
        for (const auto& paire : item->valeurs)
            valeurs[QString::fromStdString(paire.first)] = paire.second;
        objet["valeurs"] = valeurs;
        QJsonObject textes;
        for (const auto& paire : item->textes)
            textes[QString::fromStdString(paire.first)] =
                QString::fromStdString(paire.second);
        objet["textes"] = textes;
        tableau_composants.append(objet);
    }

    // Les points de dérivation s'enregistrent aussi.
    //
    // Ils ne s'enregistraient pas, et le filtre ci-dessous jetait alors TOUT
    // fil qui en touchait un — `depart()` rend nullptr sur une jonction, et
    // `index.count(nullptr)` vaut zéro. Un T de six fils repartait à trois, la
    // dérivation débranchée, sans un mot. Et comme `memoriser()`, `annuler()`
    // et `coller()` passent tous par ici, un simple Ctrl+Z sur un geste sans
    // rapport suffisait à effacer le T.
    QJsonArray tableau_jonctions;
    std::map<const ItemJonction*, int> index_jonction;
    for (ItemJonction* jonction : jonctions()) {
        index_jonction[jonction] = tableau_jonctions.size();
        QJsonObject objet;
        objet["x"] = jonction->pos().x();
        objet["y"] = jonction->pos().y();
        tableau_jonctions.append(objet);
    }

    // Une extrémité de fil s'écrit selon sa nature : broche d'un composant,
    // ou point de dérivation.
    auto ecrire_ancre = [&](const Ancre& ancre, QJsonObject& objet,
                            const char* cle_genre, const char* cle_index,
                            const char* cle_borne) -> bool {
        if (ancre.jonction) {
            auto it = index_jonction.find(ancre.jonction);
            if (it == index_jonction.end()) return false;
            objet[cle_genre] = "point";
            objet[cle_index] = it->second;
            return true;
        }
        if (!ancre.composant || !index.count(ancre.composant)) return false;
        objet[cle_genre] = "broche";
        objet[cle_index] = index[ancre.composant];
        objet[cle_borne] = ancre.borne;
        return true;
    };

    QJsonArray tableau_fils;
    for (ItemFil* fil : fils()) {
        QJsonObject objet;
        // Un fil dont une extrémité sort de la sélection n'a nulle part où
        // aller : on ne le copie pas.
        if (!ecrire_ancre(fil->ancre_depart(), objet, "genre_a", "a", "borne_a"))
            continue;
        if (!ecrire_ancre(fil->ancre_arrivee(), objet, "genre_b", "b", "borne_b"))
            continue;
        tableau_fils.append(objet);
    }

    QJsonObject racine;
    racine["format"] = "simulateur-embarque/schema";
    racine["version"] = 1;
    racine["composants"] = tableau_composants;
    racine["fils"] = tableau_fils;
    racine["jonctions"] = tableau_jonctions;
    return racine;
}

std::vector<ItemComposant*> SceneSchema::depuis_json(const QJsonObject& racine,
                                                     bool remplacer,
                                                     const QPointF& decalage) {
    // Relire un schéma — ouverture, annulation, collage — remplace ce que la
    // surbrillance désignait. `tout_effacer()` l'éteint déjà, mais pas dans
    // le cas d'un collage qui ajoute sans remplacer.
    eteindre_noeud();
    if (remplacer) tout_effacer();

    std::vector<ItemComposant*> ajoutes;
    for (const QJsonValue& valeur : racine["composants"].toArray()) {
        const QJsonObject objet = valeur.toObject();
        ItemComposant* item = ajouter_composant(
            objet["type"].toString(),
            QPointF(objet["x"].toDouble(), objet["y"].toDouble()) + decalage);
        if (!item) {
            ajoutes.push_back(nullptr);
            continue;
        }
        // En remplacement, la référence enregistrée fait foi. En collage, il
        // faut au contraire une référence neuve : deux R3 se battraient.
        if (remplacer) item->definir_reference(objet["reference"].toString());
        item->setRotation(objet["rotation"].toDouble());
        const QJsonObject valeurs = objet["valeurs"].toObject();
        for (auto it = valeurs.begin(); it != valeurs.end(); ++it)
            item->valeurs[it.key().toStdString()] = it.value().toDouble();
        const QJsonObject textes = objet["textes"].toObject();
        for (auto it = textes.begin(); it != textes.end(); ++it)
            item->textes[it.key().toStdString()] =
                it.value().toString().toStdString();
        ajoutes.push_back(item);
    }
    std::vector<ItemJonction*> points;
    for (const QJsonValue& valeur : racine["jonctions"].toArray()) {
        const QJsonObject objet = valeur.toObject();
        auto* point = new ItemJonction(
            QPointF(objet["x"].toDouble(), objet["y"].toDouble()));
        addItem(point);
        points.push_back(point);
    }

    // Relit une extrémité. L'absence de « genre » désigne un fichier écrit
    // avant que les points existent : tout y était une broche.
    auto lire_ancre = [&](const QJsonObject& objet, const char* cle_genre,
                          const char* cle_index,
                          const char* cle_borne) -> Ancre {
        const int rang = objet[cle_index].toInt(-1);
        if (rang < 0) return {};
        if (objet[cle_genre].toString("broche") == "point") {
            if (rang >= static_cast<int>(points.size())) return {};
            return Ancre(points[rang]);
        }
        if (rang >= static_cast<int>(ajoutes.size()) || !ajoutes[rang])
            return {};
        return Ancre(ajoutes[rang], objet[cle_borne].toInt());
    };

    for (const QJsonValue& valeur : racine["fils"].toArray()) {
        const QJsonObject objet = valeur.toObject();
        const Ancre a = lire_ancre(objet, "genre_a", "a", "borne_a");
        const Ancre b = lire_ancre(objet, "genre_b", "b", "borne_b");
        if (!a.valide() || !b.valide()) continue;
        addItem(new ItemFil(a, b));
    }
    // Les points relus n'ont pas encore de degré : sans cela, aucun ne
    // dessinerait sa pastille et un T rechargé passerait pour un croisement.
    balayer_jonctions();
    return ajoutes;
}

void SceneSchema::empiler(QJsonObject etat) {
    pile_annulation_.push_back(std::move(etat));
    if (static_cast<int>(pile_annulation_.size()) > kProfondeurAnnulation)
        pile_annulation_.erase(pile_annulation_.begin());
    pile_retablissement_.clear();
}

void SceneSchema::memoriser() {
    pile_annulation_.push_back(vers_json());
    if (static_cast<int>(pile_annulation_.size()) > kProfondeurAnnulation)
        pile_annulation_.erase(pile_annulation_.begin());
    // Une nouvelle action rend caduc tout ce qui avait été annulé : c'est le
    // comportement attendu partout ailleurs.
    pile_retablissement_.clear();
}

void SceneSchema::oublier_historique() {
    pile_annulation_.clear();
    pile_retablissement_.clear();
    etat_avant_geste_ = QJsonObject();
}

bool SceneSchema::annuler() {
    if (pile_annulation_.empty()) return false;
    pile_retablissement_.push_back(vers_json());
    const QJsonObject precedent = pile_annulation_.back();
    pile_annulation_.pop_back();
    depuis_json(precedent);
    emit journal("Annulé.");
    return true;
}

bool SceneSchema::retablir() {
    if (pile_retablissement_.empty()) return false;
    pile_annulation_.push_back(vers_json());
    const QJsonObject suivant = pile_retablissement_.back();
    pile_retablissement_.pop_back();
    depuis_json(suivant);
    emit journal("Rétabli.");
    return true;
}

void SceneSchema::copier_selection() {
    const QJsonObject extrait = vers_json(true);
    if (extrait["composants"].toArray().isEmpty()) return;
    presse_papiers_ = extrait;
    emit journal(QString("Copié : %1 composant(s).")
                     .arg(extrait["composants"].toArray().size()));
}

bool SceneSchema::coller() {
    if (presse_papiers_.isEmpty()) return false;
    memoriser();
    clearSelection();
    // Décalage d'une maille : le collage doit se voir, pas se superposer.
    const std::vector<ItemComposant*> ajoutes =
        depuis_json(presse_papiers_, false, QPointF(kPas * 4, kPas * 4));
    for (ItemComposant* item : ajoutes)
        if (item) item->setSelected(true);
    emit journal(QString("Collé : %1 composant(s).").arg(ajoutes.size()));
    return !ajoutes.empty();
}

void SceneSchema::dupliquer_selection() {
    const QJsonObject garde = presse_papiers_;
    copier_selection();
    coller();
    presse_papiers_ = garde.isEmpty() ? presse_papiers_ : garde;
}
