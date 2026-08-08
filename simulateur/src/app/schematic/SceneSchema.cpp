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
        a_supprimer.insert(item);
    }
    // Un fil en cours de tracé peut partir d'un composant qu'on efface : le
    // laisser en attente, c'est garder un pointeur vers un objet détruit.
    if (fil_depart_ && a_supprimer.count(fil_depart_)) abandonner_fil();

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
    emit selection_composant(nullptr);
}

void SceneSchema::tout_effacer() {
    clear();                     // détruit déjà le trait provisoire
    compteurs_.clear();
    // Les pointeurs sont remis à zéro sans passer par abandonner_fil() : les
    // objets viennent d'être détruits par clear(). Un fil resté « en attente »
    // désignerait sinon un composant qui n'existe plus.
    fil_depart_ = nullptr;
    fil_provisoire_ = nullptr;
    fil_borne_ = -1;
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
            if (numero_broche(modele->bornes[k].nom) >= 0 && !noms[k].empty())
                ++broches_par_noeud[noms[k]];
    }

    for (ItemComposant* composant : composants()) {
        const coeur::Modele* modele = composant->modele();
        if (!modele || !modele->carte) continue;
        const auto& noms = noeuds.at(composant);
        for (int k = 0; k < composant->nb_bornes(); ++k) {
            const std::string nom = modele->bornes[k].nom;
            const int numero = numero_broche(nom);
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

void SceneSchema::effacer_resultats() {
    for (ItemComposant* composant : composants()) {
        composant->definir_eclat(0.0);
        composant->definir_mesure({});
    }
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

// Démarre un fil depuis une borne, et pose le trait provisoire qui suit le
// curseur.
void SceneSchema::commencer_fil(ItemComposant* composant, int borne,
                                const QPointF& point) {
    fil_depart_ = composant;
    fil_borne_ = borne;
    fil_en_attente_ = false;
    point_appui_ = point;
    fil_provisoire_ = addLine(QLineF(composant->position_borne(borne), point),
                              QPen(QColor(0, 120, 215), 1.5, Qt::DashLine));
}

// Referme le fil sur une borne d'arrivée, si elle est valable.
bool SceneSchema::terminer_fil(const QPointF& point) {
    auto [composant, borne] = borne_sous(point);
    const bool valable =
        composant && !(composant == fil_depart_ && borne == fil_borne_);
    if (valable) {
        addItem(new ItemFil(fil_depart_, fil_borne_, composant, borne));
        emit journal(QString("Fil : %1.%2 — %3.%4")
                         .arg(fil_depart_->reference(),
                              fil_depart_->nom_borne(fil_borne_),
                              composant->reference(),
                              composant->nom_borne(borne)));
    }
    abandonner_fil();
    return valable;
}

void SceneSchema::abandonner_fil() {
    if (fil_provisoire_) {
        removeItem(fil_provisoire_);
        delete fil_provisoire_;
        fil_provisoire_ = nullptr;
    }
    fil_depart_ = nullptr;
    fil_borne_ = -1;
    fil_en_attente_ = false;
}

// Composant sous un point, quelle que soit la partie touchée.
static ItemComposant* composant_sous(QGraphicsScene* scene, const QPointF& point) {
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
        if (fil_en_attente_ && fil_depart_) {
            if (!terminer_fil(point)) abandonner_fil();
            return;
        }

        // Cliquer une borne suffit à tirer un fil : c'est ce que font les
        // ateliers de saisie de schéma, et cela évite d'aller chercher un
        // outil pour l'opération la plus fréquente du dessin.
        auto [composant, borne] = borne_sous(point);
        if (composant) {
            commencer_fil(composant, borne, point);
            return;
        }
        if (outil_ == Outil::Fil) return;   // l'outil fil ne fait que ça
        // Un déplacement commence peut-être : on garde l'état d'avant pour
        // pouvoir l'annuler, et on ne l'empilera qu'en cas de vrai changement.
        // Seulement si le clic porte sur un composant : sérialiser la scène à
        // chaque clic dans le vide serait du travail pour rien.
        if (composant_sous(this, point)) etat_avant_geste_ = vers_json();
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
    if (fil_provisoire_ && fil_depart_) {
        fil_provisoire_->setLine(
            QLineF(fil_depart_->position_borne(fil_borne_),
                   evenement->scenePos()));
        return;
    }

    // Le curseur change au-dessus d'une borne : sans ce signe, rien ne dirait
    // qu'un clic va tirer un fil plutôt que déplacer le composant.
    if (outil_ != Outil::Suppression) {
        const bool sur_borne = borne_sous(evenement->scenePos()).first != nullptr;
        for (QGraphicsView* vue : views())
            vue->setCursor(sur_borne ? Qt::CrossCursor : Qt::ArrowCursor);
    }

    QGraphicsScene::mouseMoveEvent(evenement);
    // Un composant déplacé entraîne le retracé de ses fils.
    for (ItemFil* fil : fils()) fil->rafraichir();
}

void SceneSchema::mouseReleaseEvent(QGraphicsSceneMouseEvent* evenement) {
    if (fil_provisoire_ && fil_depart_ && !fil_en_attente_) {
        const QPointF point = evenement->scenePos();
        if (terminer_fil(point)) return;

        // Relâché sans avoir bougé : c'était un clic, pas un glissement. Le
        // fil reste alors accroché au curseur jusqu'au clic suivant — les
        // deux façons de câbler cohabitent ainsi sans se gêner.
        if (QLineF(point_appui_, point).length() < 6.0) {
            auto [composant, borne] = borne_sous(point_appui_);
            if (composant) {
                commencer_fil(composant, borne, point);
                fil_en_attente_ = true;
            }
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
    // Le clic droit ouvre les options et ne touche à rien d'autre : il
    // n'entame pas de fil, il ne déplace rien.
    abandonner_fil();
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

    QJsonArray tableau_fils;
    for (ItemFil* fil : fils()) {
        // Un fil dont une extrémité sort de la sélection n'a nulle part où
        // aller : on ne le copie pas.
        if (!index.count(fil->depart()) || !index.count(fil->arrivee())) continue;
        QJsonObject objet;
        objet["a"] = index[fil->depart()];
        objet["borne_a"] = fil->borne_depart();
        objet["b"] = index[fil->arrivee()];
        objet["borne_b"] = fil->borne_arrivee();
        tableau_fils.append(objet);
    }

    QJsonObject racine;
    racine["format"] = "simulateur-embarque/schema";
    racine["version"] = 1;
    racine["composants"] = tableau_composants;
    racine["fils"] = tableau_fils;
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
    for (const QJsonValue& valeur : racine["fils"].toArray()) {
        const QJsonObject objet = valeur.toObject();
        const int a = objet["a"].toInt(), b = objet["b"].toInt();
        if (a < 0 || b < 0 || a >= static_cast<int>(ajoutes.size())
            || b >= static_cast<int>(ajoutes.size()))
            continue;
        if (!ajoutes[a] || !ajoutes[b]) continue;
        addItem(new ItemFil(ajoutes[a], objet["borne_a"].toInt(), ajoutes[b],
                            objet["borne_b"].toInt()));
    }
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
