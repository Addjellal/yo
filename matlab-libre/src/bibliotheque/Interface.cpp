// Interface.cpp — le registre des composants d'interface.
//
// Une application MatLibre décrit son interface en appelant uifigure,
// uibutton, uilabel… Chaque appel range un composant ici ; une interface
// registre pour dessiner la fenêtre dans le navigateur, et renvoie les
// événements, qui déclenchent les rappels dans l'interpréteur.
//
// Sans fenêtre, le registre reste consultable : une application peut être
// pilotée en ligne de commande, ce qui la rend testable.
#include <algorithm>
#include <map>
#include <memory>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, std::vector<Valeur>& args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

std::string texteDe(const Valeur& v) { return v.versTexte(); }

ComposantInterface* trouver(Interpreteur& it, long long id) {
    auto p = it.composantsInterface.find(id);
    if (p == it.composantsInterface.end())
        erreur("MATLAB:ui:InvalidHandle", "Invalid UI component handle.");
    return &p->second;
}

FONCTION(fnCreer) {
    INUTILISE
    if (args.size() < 1)
        erreur("MATLAB:minrhs", "matlibre_ui_creer requires a component type.");
    ComposantInterface c;
    c.id = it.prochainComposant++;
    c.type = texteDe(args[0]);
    if (args.size() > 1 && args[1].estNumerique()) c.parent = (long long)args[1].scal();
    it.composantsInterface[c.id] = c;
    if (c.type == "figure") it.figureInterfaceCourante = c.id;
    return {Valeur::scalaire((double)c.id)};
}

FONCTION(fnPoser) {
    INUTILISE
    exigerArguments(args, 3, 3, "matlibre_ui_poser");
    ComposantInterface* c = trouver(it, (long long)args[0].scal());
    std::string nom = texteDe(args[1]);
    const Valeur& v = args[2];
    if (nom == "Text" || nom == "Title" || nom == "Label") c->texte = texteDe(v);
    else if (nom == "Position") {
        c->position.clear();
        for (std::size_t k = 0; k < v.nelem(); ++k) c->position.push_back(v.re[k]);
    } else if (nom == "Limits") {
        c->minimum = v.nelem() > 0 ? v.re[0] : 0.0;
        c->maximum = v.nelem() > 1 ? v.re[1] : 1.0;
    } else if (nom == "Items") {
        c->items.clear();
        if (v.classe == Classe::Cellule)
            for (const auto& e : v.cellules) c->items.push_back(e.versTexte());
        else
            c->items.push_back(texteDe(v));
    } else if (nom == "Callback" || nom == "ButtonPushedFcn" ||
               nom == "ValueChangedFcn") {
        c->rappel = v;
    } else if (nom == "Enable") {
        c->actif = v.estTexte() ? (texteDe(v) == "on") : v.vrai();
    } else if (nom == "Visible") {
        c->visible = v.estTexte() ? (texteDe(v) == "on") : v.vrai();
    } else if (nom == "Value") {
        c->valeur = v;
    } else {
        c->autres[nom] = v;
    }
    return {};
}

FONCTION(fnLire) {
    INUTILISE
    exigerArguments(args, 2, 2, "matlibre_ui_lire");
    ComposantInterface* c = trouver(it, (long long)args[0].scal());
    std::string nom = texteDe(args[1]);
    if (nom == "Type") return {Valeur::texte(c->type)};
    if (nom == "Text" || nom == "Title" || nom == "Label") return {Valeur::texte(c->texte)};
    if (nom == "Parent") return {Valeur::scalaire((double)c->parent)};
    if (nom == "Position") return {Valeur::ligne(c->position)};
    if (nom == "Limits") return {Valeur::ligne({c->minimum, c->maximum})};
    if (nom == "Items") {
        std::vector<Valeur> cases;
        for (const auto& s : c->items) cases.push_back(Valeur::texte(s));
        return {Valeur::celluleLigne(cases)};
    }
    if (nom == "Callback") return {c->rappel};
    if (nom == "Enable") return {Valeur::booleen(c->actif)};
    if (nom == "Visible") return {Valeur::booleen(c->visible)};
    if (nom == "Value") return {c->valeur};
    auto p = c->autres.find(nom);
    if (p != c->autres.end()) return {p->second};
    return {Valeur::vide()};
}

FONCTION(fnSupprimer) {
    INUTILISE
    exigerArguments(args, 1, 1, "matlibre_ui_supprimer");
    long long id = (long long)args[0].scal();
    // Supprimer une fenêtre emporte ses enfants.
    std::vector<long long> aRetirer = {id};
    bool change = true;
    while (change) {
        change = false;
        for (const auto& kv : it.composantsInterface) {
            if (std::find(aRetirer.begin(), aRetirer.end(), kv.second.parent) != aRetirer.end() &&
                std::find(aRetirer.begin(), aRetirer.end(), kv.first) == aRetirer.end()) {
                aRetirer.push_back(kv.first);
                change = true;
            }
        }
    }
    for (long long k : aRetirer) it.composantsInterface.erase(k);
    if (it.figureInterfaceCourante == id) it.figureInterfaceCourante = 0;
    return {};
}

// Liste complète, telle qu'une interface la lit.
FONCTION(fnListe) {
    INUTILISE
    std::size_t n = it.composantsInterface.size();
    Valeur s = Valeur::structureVide();
    s.dims = {1, (int)n};
    s.st = std::make_shared<ChampsStructure>();
    s.st->ordre = {"Id", "Type", "Parent", "Text", "Position", "Value", "Items",
                   "Limits", "Enable", "Visible", "HasCallback"};
    std::size_t taille = std::max<std::size_t>(n, 1);
    for (const auto& nom : s.st->ordre)
        s.st->champs[nom] = std::vector<Valeur>(taille, Valeur::vide());
    std::size_t k = 0;
    for (const auto& kv : it.composantsInterface) {
        const ComposantInterface& c = kv.second;
        s.st->champs["Id"][k] = Valeur::scalaire((double)c.id);
        s.st->champs["Type"][k] = Valeur::texte(c.type);
        s.st->champs["Parent"][k] = Valeur::scalaire((double)c.parent);
        s.st->champs["Text"][k] = Valeur::texte(c.texte);
        s.st->champs["Position"][k] = Valeur::ligne(c.position);
        s.st->champs["Value"][k] = c.valeur;
        std::vector<Valeur> items;
        for (const auto& x : c.items) items.push_back(Valeur::texte(x));
        s.st->champs["Items"][k] = Valeur::celluleLigne(items);
        s.st->champs["Limits"][k] = Valeur::ligne({c.minimum, c.maximum});
        s.st->champs["Enable"][k] = Valeur::booleen(c.actif);
        s.st->champs["Visible"][k] = Valeur::booleen(c.visible);
        s.st->champs["HasCallback"][k] =
            Valeur::booleen(c.rappel.classe == Classe::Fonction);
        ++k;
    }
    if (n == 0) s.dims = {0, 0};
    return {s};
}

// Déclenche le rappel d'un composant, éventuellement après avoir posé une
// nouvelle valeur : c'est ce que fait un clic dans une interface.
FONCTION(fnDeclencher) {
    INUTILISE
    if (args.empty()) erreur("MATLAB:minrhs", "matlibre_ui_declencher requires a handle.");
    long long id = (long long)args[0].scal();
    ComposantInterface* c = trouver(it, id);
    if (args.size() > 1) c->valeur = args[1];
    if (c->rappel.classe != Classe::Fonction) return {};
    Valeur source = Valeur::structureVide();
    source.poserChamp("Id", Valeur::scalaire((double)id));
    source.poserChamp("Type", Valeur::texte(c->type));
    source.poserChamp("Value", c->valeur);
    Valeur evenement = Valeur::structureVide();
    evenement.poserChamp("Source", source);
    evenement.poserChamp("Value", c->valeur);
    evenement.poserChamp("EventName", Valeur::texte("Action"));
    std::vector<Valeur> arguments = {source, evenement};
    it.appelerValeur(c->rappel, arguments, 0);
    return {};
}

FONCTION(fnFigureCourante) {
    INUTILISE
    return {Valeur::scalaire((double)it.figureInterfaceCourante)};
}

}  // namespace

void enregistrerInterface(Interpreteur& it) {
    it.enregistrer("matlibre_ui_creer", fnCreer, "interface",
                   "matlibre_ui_creer  Cree un composant d'interface.");
    it.enregistrer("matlibre_ui_poser", fnPoser, "interface",
                   "matlibre_ui_poser  Pose une propriete d'un composant.");
    it.enregistrer("matlibre_ui_lire", fnLire, "interface",
                   "matlibre_ui_lire  Lit une propriete d'un composant.");
    it.enregistrer("matlibre_ui_supprimer", fnSupprimer, "interface",
                   "matlibre_ui_supprimer  Supprime un composant et ses enfants.");
    it.enregistrer("matlibre_ui_liste", fnListe, "interface",
                   "matlibre_ui_liste  Liste les composants d'interface.");
    it.enregistrer("matlibre_ui_declencher", fnDeclencher, "interface",
                   "matlibre_ui_declencher  Declenche le rappel d'un composant.");
    it.enregistrer("matlibre_ui_figure", fnFigureCourante, "interface",
                   "matlibre_ui_figure  Identifiant de la fenetre courante.");
}

}  // namespace matlibre
