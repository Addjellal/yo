#include "app/schematic/SceneSchema.h"

#include <QGraphicsLineItem>
#include <QGraphicsSceneMouseEvent>
#include <QKeyEvent>
#include <QPainter>

#include <algorithm>
#include <cmath>

#include "app/schematic/ItemComposant.h"
#include "app/schematic/ItemFil.h"
#include "core/Device.h"

namespace {

constexpr double kPas = 10.0;    // pas de la grille

QPointF aligner(const QPointF& point) {
    return QPointF(std::round(point.x() / kPas) * kPas,
                   std::round(point.y() / kPas) * kPas);
}

// Numérotation Arduino d'un nom de broche : "D13" -> 13, "A0" -> 14.
int numero_broche(const std::string& nom) {
    if (nom.size() < 2) return -1;
    const std::string chiffres = nom.substr(1);
    if (chiffres.find_first_not_of("0123456789") != std::string::npos) return -1;
    const int valeur = std::stoi(chiffres);
    if (nom[0] == 'D' && valeur >= 0 && valeur <= 13) return valeur;
    if (nom[0] == 'A' && valeur >= 0 && valeur <= 5) return 14 + valeur;
    return -1;
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
    if (fil_provisoire_) {
        removeItem(fil_provisoire_);
        delete fil_provisoire_;
        fil_provisoire_ = nullptr;
    }
    fil_depart_ = nullptr;
    fil_borne_ = -1;
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
    std::vector<QGraphicsItem*> a_supprimer;
    for (QGraphicsItem* item : selectedItems()) {
        if (item->type() == ItemComposant::Type) {
            auto* composant = static_cast<ItemComposant*>(item);
            for (ItemFil* fil : fils())
                if (fil->touche(composant)) a_supprimer.push_back(fil);
        }
        a_supprimer.push_back(item);
    }
    for (QGraphicsItem* item : a_supprimer) {
        if (item->scene() == this) {
            removeItem(item);
            delete item;
        }
    }
    emit selection_composant(nullptr);
}

void SceneSchema::tout_effacer() {
    clear();
    compteurs_.clear();
    fil_depart_ = nullptr;
    fil_provisoire_ = nullptr;
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

    for (ItemFil* fil : fils()) {
        auto a = indices.find(fil->depart());
        auto b = indices.find(fil->arrivee());
        if (a == indices.end() || b == indices.end()) continue;
        if (fil->borne_depart() >= static_cast<int>(a->second.size())) continue;
        if (fil->borne_arrivee() >= static_cast<int>(b->second.size())) continue;
        classes.unir(a->second[fil->borne_depart()],
                     b->second[fil->borne_arrivee()]);
    }

    // Nommage : un symbole d'alimentation impose son nom ; à défaut une broche
    // de carte donne le sien ; sinon un nom interne N1, N2…
    std::map<int, std::string> noms;
    for (ItemComposant* composant : liste) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || modele->noeud_impose.empty()) continue;
        for (int k = 0; k < composant->nb_bornes(); ++k)
            noms[classes.racine(indices[composant][k])] = modele->noeud_impose;
    }
    for (ItemComposant* composant : liste) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->carte) continue;
        for (int k = 0; k < composant->nb_bornes(); ++k) {
            const int racine = classes.racine(indices[composant][k]);
            if (noms.count(racine)) continue;
            noms[racine] = modele->bornes[k].nom;
        }
    }
    int suivant = 1;
    for (ItemFil* fil : fils()) {
        auto a = indices.find(fil->depart());
        if (a == indices.end()) continue;
        const int racine = classes.racine(a->second[fil->borne_depart()]);
        if (!noms.count(racine)) noms[racine] = "N" + std::to_string(suivant++);
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

    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele) continue;
        const auto& noms = noeuds.at(composant);

        if (modele->carte) {
            if (!broches) continue;
            for (int k = 0; k < composant->nb_bornes(); ++k) {
                const std::string nom = modele->bornes[k].nom;
                const int numero = numero_broche(nom);
                if (numero < 0 || noms[k].empty()) continue;
                broches->push_back({numero, nom, noms[k]});
            }
            continue;
        }
        if (!modele->noeud_impose.empty()) continue;   // symbole d'alimentation
        if (!modele->vers_spice) continue;             // décoratif

        auto& instance = netlist.ajouter(composant->reference().toStdString(),
                                         modele->type);
        instance.valeurs = composant->valeurs;
        instance.textes = composant->textes;
        for (int k = 0; k < composant->nb_bornes(); ++k)
            netlist.relier(instance.reference, modele->bornes[k].nom, noms[k]);
    }
    return netlist;
}

// ---------------------------------------------------------------------------
void SceneSchema::appliquer_resultats(
    const std::map<std::string, double>& courants,
    const std::map<std::string, double>& tensions) {
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
    for (ItemFil* fil : fils()) {
        auto it = noeuds.find(fil->depart());
        if (it == noeuds.end()) continue;
        if (fil->borne_depart() >= static_cast<int>(it->second.size())) continue;
        std::string noeud = it->second[fil->borne_depart()];
        std::transform(noeud.begin(), noeud.end(), noeud.begin(),
                       [](unsigned char c) { return std::tolower(c); });
        auto mesure = tensions.find(noeud);
        if (mesure != tensions.end()) fil->definir_tension(mesure->second);
    }
}

void SceneSchema::effacer_resultats() {
    for (ItemComposant* composant : composants()) composant->definir_eclat(0.0);
    for (ItemFil* fil : fils()) fil->rafraichir();
    update();
}

// ---------------------------------------------------------------------------
void SceneSchema::drawBackground(QPainter* peintre, const QRectF& zone) {
    peintre->fillRect(zone, backgroundBrush());
    peintre->setPen(QPen(QColor(226, 230, 226), 0.6));
    const double gauche = std::floor(zone.left() / kPas) * kPas;
    const double haut = std::floor(zone.top() / kPas) * kPas;
    for (double x = gauche; x < zone.right(); x += kPas)
        peintre->drawLine(QPointF(x, zone.top()), QPointF(x, zone.bottom()));
    for (double y = haut; y < zone.bottom(); y += kPas)
        peintre->drawLine(QPointF(zone.left(), y), QPointF(zone.right(), y));
    // repères tous les 100 unités
    peintre->setPen(QPen(QColor(206, 214, 206), 0.9));
    for (double x = std::floor(zone.left() / 100) * 100; x < zone.right(); x += 100)
        peintre->drawLine(QPointF(x, zone.top()), QPointF(x, zone.bottom()));
    for (double y = std::floor(zone.top() / 100) * 100; y < zone.bottom(); y += 100)
        peintre->drawLine(QPointF(zone.left(), y), QPointF(zone.right(), y));
}

void SceneSchema::mousePressEvent(QGraphicsSceneMouseEvent* evenement) {
    const QPointF point = evenement->scenePos();

    if (outil_ == Outil::Fil && evenement->button() == Qt::LeftButton) {
        auto [composant, borne] = borne_sous(point);
        if (composant) {
            fil_depart_ = composant;
            fil_borne_ = borne;
            fil_provisoire_ = addLine(QLineF(composant->position_borne(borne),
                                             point),
                                      QPen(QColor(0, 120, 215), 1.5,
                                           Qt::DashLine));
        }
        return;
    }
    if (outil_ == Outil::Suppression && evenement->button() == Qt::LeftButton) {
        clearSelection();
        if (QGraphicsItem* item = itemAt(point, QTransform())) {
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
    if (fil_provisoire_ && fil_depart_) {
        fil_provisoire_->setLine(
            QLineF(fil_depart_->position_borne(fil_borne_),
                   evenement->scenePos()));
        return;
    }
    QGraphicsScene::mouseMoveEvent(evenement);
    // Un composant déplacé entraîne le retracé de ses fils.
    for (ItemFil* fil : fils()) fil->rafraichir();
}

void SceneSchema::mouseReleaseEvent(QGraphicsSceneMouseEvent* evenement) {
    if (fil_provisoire_ && fil_depart_) {
        removeItem(fil_provisoire_);
        delete fil_provisoire_;
        fil_provisoire_ = nullptr;

        auto [composant, borne] = borne_sous(evenement->scenePos());
        if (composant && !(composant == fil_depart_ && borne == fil_borne_)) {
            addItem(new ItemFil(fil_depart_, fil_borne_, composant, borne));
            emit journal(QString("Fil : %1.%2 — %3.%4")
                             .arg(fil_depart_->reference(),
                                  fil_depart_->nom_borne(fil_borne_),
                                  composant->reference(),
                                  composant->nom_borne(borne)));
        }
        fil_depart_ = nullptr;
        fil_borne_ = -1;
        return;
    }
    QGraphicsScene::mouseReleaseEvent(evenement);
    // Réalignement sur la grille après un déplacement.
    for (QGraphicsItem* item : selectedItems())
        if (item->type() == ItemComposant::Type) item->setPos(aligner(item->pos()));
    for (ItemFil* fil : fils()) fil->rafraichir();
}

void SceneSchema::keyPressEvent(QKeyEvent* evenement) {
    if (evenement->key() == Qt::Key_Delete) {
        supprimer_selection();
        return;
    }
    if (evenement->key() == Qt::Key_R) {
        for (QGraphicsItem* item : selectedItems())
            if (item->type() == ItemComposant::Type)
                static_cast<ItemComposant*>(item)->tourner();
        for (ItemFil* fil : fils()) fil->rafraichir();
        return;
    }
    QGraphicsScene::keyPressEvent(evenement);
}
