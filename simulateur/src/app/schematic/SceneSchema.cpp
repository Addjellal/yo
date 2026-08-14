#include "app/schematic/SceneSchema.h"

#include <QGraphicsLineItem>
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
// Attribution des noms de nœuds
// ---------------------------------------------------------------------------
std::map<const ItemComposant*, std::vector<std::string>>
SceneSchema::calculer_noeuds() const {
    const std::vector<ItemComposant*> liste = composants();

    Classes classes;
    std::map<const ItemComposant*, std::vector<int>> indices;
    for (ItemComposant* composant : liste) {
        std::vector<int> pour_ce_composant;
        for (int k = 0; k < composant->nb_bornes(); ++k)
            pour_ce_composant.push_back(classes.ajouter());
        indices[composant] = pour_ce_composant;
    }

    // Les points de fil sont des nœuds comme les autres : ils entrent dans la
    // même relation d'équivalence. C'est ce qui fait qu'une dérivation en T
    // relie électriquement les trois fils sans code particulier — trois unions
    // sur la même classe.
    std::map<const ItemJonction*, int> indices_jonction;
    for (ItemJonction* jonction : jonctions())
        indices_jonction[jonction] = classes.ajouter();

    // L'indice d'une extrémité de fil, quelle que soit sa nature. -1 quand
    // l'ancre ne désigne rien de connu — un composant effacé, par exemple.
    auto indice_de = [&](const Ancre& ancre) -> int {
        if (ancre.jonction) {
            auto it = indices_jonction.find(ancre.jonction);
            return it == indices_jonction.end() ? -1 : it->second;
        }
        auto it = indices.find(ancre.composant);
        if (it == indices.end()) return -1;
        if (ancre.borne < 0 || ancre.borne >= static_cast<int>(it->second.size()))
            return -1;
        return it->second[ancre.borne];
    };

    for (ItemFil* fil : fils()) {
        const int a = indice_de(fil->ancre_depart());
        const int b = indice_de(fil->ancre_arrivee());
        if (a < 0 || b < 0) continue;
        classes.unir(a, b);
    }

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
        for (int k = 0; k < composant->nb_bornes(); ++k)
            noms[classes.racine(indices[composant][k])] = impose;
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
            const int racine = classes.racine(indices[composant][k]);
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
            const int racine = classes.racine(indices[composant][k]);
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
            const int racine = classes.racine(indices[composant][k]);
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
        if (!modele || !modele->lumineux) continue;
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
    cible_depart_ = depart;
    fil_en_attente_ = false;
    point_appui_ = point;
    fil_provisoire_ = addLine(QLineF(depart.point, point),
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
bool SceneSchema::terminer_fil(const QPointF& point) {
    if (!viser(point).connectable()) {
        abandonner_fil();
        return false;
    }
    // C'est ici, et seulement ici, que l'on découpe : le geste va aboutir.
    const Ancre depart = ancrer(cible_depart_);
    if (!depart.valide()) {
        abandonner_fil();
        return false;
    }
    // Le départ vient peut-être de couper un fil — éventuellement celui que
    // visait l'arrivée. On revise donc sur une scène à jour, sans quoi on
    // ancrerait sur un objet détruit.
    const Cible fraiche = viser(point);
    if (!fraiche.connectable()) {
        abandonner_fil();
        balayer_jonctions();
        return false;
    }
    const Ancre arrivee = ancrer(fraiche);
    if (!arrivee.valide() || arrivee == depart) {
        abandonner_fil();
        balayer_jonctions();
        return false;
    }
    addItem(new ItemFil(depart, arrivee));
    emit journal(QString("Fil : %1 — %2").arg(nom_ancre(depart),
                                              nom_ancre(arrivee)));
    balayer_jonctions();
    abandonner_fil();
    return true;
}

void SceneSchema::abandonner_fil() {
    if (fil_provisoire_) {
        removeItem(fil_provisoire_);
        delete fil_provisoire_;
        fil_provisoire_ = nullptr;
    }
    cible_depart_ = Cible();
    fil_en_attente_ = false;
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

    if (evenement->button() == Qt::LeftButton && outil_ != Outil::Suppression) {
        // Fil laissé en attente par un premier clic : ce clic-ci le referme,
        // ou l'abandonne s'il tombe à côté d'une borne.
        if (fil_en_attente_ && cible_depart_.connectable()) {
            if (!terminer_fil(point)) abandonner_fil();
            return;
        }

        // Sans mode : ce qui est sous le curseur décide. Broche, point de
        // fil ou fil — on câble ; corps de composant — on sélectionne. Plus
        // d'outil à choisir avant d'agir, et notamment plus de bascule en
        // sélection quand on part d'un fil, qui était le défaut le plus
        // visible à l'usage.
        const Cible cible = viser(point);
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
    if (fil_provisoire_ && cible_depart_.connectable()) {
        fil_provisoire_->setLine(
            QLineF(cible_depart_.point, evenement->scenePos()));
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
        else if (cible.genre == Cible::Genre::Fil)
            forme = Qt::PointingHandCursor;   // ici, on dérive
        else if (cible.genre == Cible::Genre::Composant)
            forme = Qt::SizeAllCursor;        // ici, on déplace
        for (QGraphicsView* vue : views()) vue->setCursor(forme);
    }

    QGraphicsScene::mouseMoveEvent(evenement);
    // Un composant déplacé entraîne le retracé de ses fils.
    for (ItemFil* fil : fils()) fil->rafraichir();
}

void SceneSchema::mouseReleaseEvent(QGraphicsSceneMouseEvent* evenement) {
    if (fil_provisoire_ && cible_depart_.connectable() && !fil_en_attente_) {
        const QPointF point = evenement->scenePos();
        // À relever AVANT : terminer_fil() appelle abandonner_fil() quand il
        // échoue, ce qui remet l'ancre à zéro.
        const Cible depart = cible_depart_;
        if (terminer_fil(point)) return;

        // Relâché sans avoir bougé : c'était un clic, pas un glissement. Le
        // fil reste alors accroché au curseur jusqu'au clic suivant — les
        // deux façons de câbler cohabitent ainsi sans se gêner.
        if (QLineF(point_appui_, point).length() < 6.0) {
            // Le départ est déjà ancré — éventuellement sur un point de
            // dérivation créé au clic. Le reprendre tel quel, sans re-viser :
            // re-viser découperait une seconde fois.
            commencer_fil(depart, point);
            fil_en_attente_ = true;
        }
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
        abandonner_fil();
        return;
    }
    if (evenement->key() == Qt::Key_Delete) {
        if (!selectedItems().isEmpty()) memoriser();
        supprimer_selection();
        return;
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
