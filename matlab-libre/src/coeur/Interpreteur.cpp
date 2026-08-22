#include "matlibre/Interpreteur.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>

#include "matlibre/Affichage.h"
#include "matlibre/Analyseur.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Operations.h"

namespace fs = std::filesystem;

namespace matlibre {

GardePortee::GardePortee(Interpreteur& i, std::shared_ptr<Portee> p) : it(i) {
    it.piles_.push_back(std::move(p));
}
GardePortee::~GardePortee() { it.piles_.pop_back(); }

Interpreteur::Interpreteur() {
    piles_.push_back(std::make_shared<Portee>());
    piles_.back()->nomFonction = "base";
}

Interpreteur::~Interpreteur() = default;

std::ostream& Interpreteur::sortie() { return sortie_ ? *sortie_ : std::cout; }
std::ostream& Interpreteur::erreurSortie() { return std::cerr; }

void Interpreteur::ouvrirJournal(const std::string& fichier) {
    journal_ = std::make_shared<std::ofstream>(fichier, std::ios::app);
}
void Interpreteur::fermerJournal() { journal_.reset(); }

Portee& Interpreteur::porteeAppelante() {
    if (piles_.size() < 2) return *piles_.front();
    return *piles_[piles_.size() - 2];
}

// ------------------------------------------------------------- variables

const Valeur* Interpreteur::trouverVariable(const std::string& nom) const {
    const Portee& p = *piles_.back();
    // Le cas courant est une portée sans variable globale ni persistante :
    // on va droit à la table locale.
    if (p.globales.empty() && p.liensPersistants.empty()) {
        auto it = p.variables.find(nom);
        return it == p.variables.end() ? nullptr : &it->second;
    }
    if (p.globales.count(nom)) {
        auto it = globales.find(nom);
        return it == globales.end() ? nullptr : &it->second;
    }
    auto itp = p.liensPersistants.find(nom);
    if (itp != p.liensPersistants.end()) {
        auto it = persistantes.find(itp->second);
        return it == persistantes.end() ? nullptr : &it->second;
    }
    auto it = p.variables.find(nom);
    return it == p.variables.end() ? nullptr : &it->second;
}

bool Interpreteur::existeVariable(const std::string& nom) const {
    return trouverVariable(nom) != nullptr;
}

Valeur Interpreteur::lireVariable(const std::string& nom) const {
    const Valeur* v = trouverVariable(nom);
    if (!v)
        erreur("MATLAB:UndefinedFunction",
               "Unrecognized function or variable '" + nom + "'.");
    return *v;
}

void Interpreteur::ecrireVariable(const std::string& nom, Valeur v) {
    Portee& p = *piles_.back();
    if (p.globales.empty() && p.liensPersistants.empty()) {
        p.variables[nom] = std::move(v);
        return;
    }
    if (p.globales.count(nom)) { globales[nom] = std::move(v); return; }
    auto itp = p.liensPersistants.find(nom);
    if (itp != p.liensPersistants.end()) {
        persistantes[itp->second] = std::move(v);
        return;
    }
    p.variables[nom] = std::move(v);
}

void Interpreteur::effacerVariable(const std::string& nom) {
    Portee& p = *piles_.back();
    p.variables.erase(nom);
    p.globales.erase(nom);
    p.liensPersistants.erase(nom);
}

std::vector<std::string> Interpreteur::nomsVariables() const {
    std::vector<std::string> noms;
    for (const auto& kv : piles_.back()->variables) noms.push_back(kv.first);
    for (const auto& g : piles_.back()->globales) noms.push_back(g);
    std::sort(noms.begin(), noms.end());
    noms.erase(std::unique(noms.begin(), noms.end()), noms.end());
    return noms;
}

// ------------------------------------------------------------- fonctions

void Interpreteur::enregistrer(const std::string& nom, Builtin f, const std::string& groupe,
                               const std::string& aide) {
    EntreeNative e;
    e.fonction = f;
    e.groupe = groupe;
    e.aide = aide;
    natifs_[nom] = e;
}

const EntreeNative* Interpreteur::natif(const std::string& nom) const {
    auto it = natifs_.find(nom);
    return it == natifs_.end() ? nullptr : &it->second;
}

std::vector<std::string> Interpreteur::nomsNatifs() const {
    std::vector<std::string> noms;
    noms.reserve(natifs_.size());
    for (const auto& kv : natifs_) noms.push_back(kv.first);
    std::sort(noms.begin(), noms.end());
    return noms;
}

void Interpreteur::ajouterChemin(const std::string& dossier, bool enTete) {
    std::string d = dossier;
    if (!d.empty() && d.back() == '/') d.pop_back();
    auto it = std::find(chemin_.begin(), chemin_.end(), d);
    if (it != chemin_.end()) chemin_.erase(it);
    if (enTete) chemin_.insert(chemin_.begin(), d);
    else chemin_.push_back(d);
    reindexerChemin();
}

void Interpreteur::retirerChemin(const std::string& dossier) {
    auto it = std::find(chemin_.begin(), chemin_.end(), dossier);
    if (it != chemin_.end()) chemin_.erase(it);
    reindexerChemin();
}

void Interpreteur::reindexerChemin() {
    indexM_.clear();
    indexClasses_.clear();
    for (auto it = chemin_.rbegin(); it != chemin_.rend(); ++it) {
        std::error_code ec;
        if (!fs::is_directory(*it, ec)) continue;
        for (const auto& entree : fs::directory_iterator(*it, ec)) {
            if (!entree.is_regular_file()) continue;
            std::string nom = entree.path().filename().string();
            if (nom.size() < 3 || nom.substr(nom.size() - 2) != ".m") continue;
            std::string base = nom.substr(0, nom.size() - 2);
            indexM_[base] = entree.path().string();
        }
        // Les dossiers « @classe » et « +paquet » sont explorés aussi.
        for (const auto& entree : fs::directory_iterator(*it, ec)) {
            if (!entree.is_directory()) continue;
            std::string nom = entree.path().filename().string();
            if (nom.empty() || (nom[0] != '@' && nom[0] != '+')) continue;
            for (const auto& f : fs::directory_iterator(entree.path(), ec)) {
                if (!f.is_regular_file()) continue;
                std::string fn = f.path().filename().string();
                if (fn.size() < 3 || fn.substr(fn.size() - 2) != ".m") continue;
                std::string base = fn.substr(0, fn.size() - 2);
                if (nom[0] == '@' && base == nom.substr(1)) indexClasses_[base] = f.path().string();
                else if (!indexM_.count(base)) indexM_[base] = f.path().string();
            }
        }
    }
    cacheFonctions_.clear();
    cacheClasses_.clear();
}

static std::string lireFichier(const std::string& chemin) {
    std::ifstream f(chemin, std::ios::binary);
    if (!f) erreur("MATLAB:fileNotFound", "Unable to open file '" + chemin + "'.");
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

std::string aideDepuisSource(const std::string& source) {
    // Le bloc de commentaires qui suit la ligne « function » est l'aide.
    std::istringstream in(source);
    std::string ligne;
    std::string aide;
    bool commence = false;
    while (std::getline(in, ligne)) {
        std::string t = ligne;
        std::size_t d = t.find_first_not_of(" \t\r");
        if (d == std::string::npos) {
            if (commence) break;
            continue;
        }
        t = t.substr(d);
        if (!commence && (t.rfind("function", 0) == 0 || t.rfind("classdef", 0) == 0)) continue;
        if (t[0] == '%' || t[0] == '#') {
            commence = true;
            std::string contenu = t.substr(1);
            if (!contenu.empty() && contenu[0] == ' ') contenu = contenu.substr(1);
            aide += contenu + "\n";
        } else if (commence) {
            break;
        } else if (!aide.empty()) {
            break;
        } else {
            if (t.rfind("function", 0) != 0) continue;
        }
    }
    return aide;
}

std::shared_ptr<FonctionUtilisateur> Interpreteur::fonctionFichier(const std::string& nom) {
    auto itc = cacheFonctions_.find(nom);
    if (itc != cacheFonctions_.end()) return itc->second;
    auto it = indexM_.find(nom);
    if (it == indexM_.end()) return nullptr;
    std::string source = lireFichier(it->second);
    UniteCompilee u = compiler(source, it->second);
    if (!u.classes.empty()) {
        // C'est un fichier de classe, pas de fonction : on le retient comme
        // tel et l'on ne rend rien.
        for (auto& c : u.classes) cacheClasses_[c->nom] = c;
        cacheFonctions_[nom] = nullptr;
        return nullptr;
    }
    if (u.fonctions.empty()) {
        // Un script : on l'enveloppe dans une fonction sans argument.
        auto f = std::make_shared<FonctionUtilisateur>();
        f->nom = nom;
        f->corps = u.script ? u.script : Noeud::creer(TypeN::Bloc);
        f->fichier = it->second;
        f->aide = aideDepuisSource(source);
        f->entrees.clear();
        f->sorties.clear();
        cacheFonctions_[nom] = f;
        return f;
    }
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
    for (auto& f : u.fonctions) voisines[f->nom] = f;
    for (auto& f : u.fonctions) {
        f->fichier = it->second;
        f->voisines = voisines;
    }
    u.fonctions[0]->aide = aideDepuisSource(source);
    // Le nom du fichier prime sur celui écrit dans la première fonction ;
    // les suivantes restent privées au fichier, visibles par « voisines ».
    cacheFonctions_[nom] = u.fonctions[0];
    return u.fonctions[0];
}

std::shared_ptr<DefinitionClasse> Interpreteur::classeDefinie(const std::string& nom) {
    auto itc = cacheClasses_.find(nom);
    if (itc != cacheClasses_.end()) return itc->second;
    auto it = indexClasses_.find(nom);
    if (it == indexClasses_.end()) {
        auto itm = indexM_.find(nom);
        if (itm == indexM_.end()) return nullptr;
        std::string source = lireFichier(itm->second);
        if (source.find("classdef") == std::string::npos) return nullptr;
        UniteCompilee u = compiler(source, itm->second);
        if (u.classes.empty()) return nullptr;
        cacheClasses_[nom] = u.classes[0];
        return u.classes[0];
    }
    UniteCompilee u = compiler(lireFichier(it->second), it->second);
    if (u.classes.empty()) return nullptr;
    cacheClasses_[nom] = u.classes[0];
    return u.classes[0];
}

bool Interpreteur::fonctionExiste(const std::string& nom) const {
    if (natifs_.count(nom)) return true;
    if (indexM_.count(nom)) return true;
    if (indexClasses_.count(nom)) return true;
    const Portee& p = *piles_.back();
    if (p.fonction && p.fonction->voisines.count(nom)) return true;
    return false;
}

std::shared_ptr<Fonction> Interpreteur::resoudrePoignee(const std::string& nom) {
    auto f = std::make_shared<Fonction>();
    f->nom = nom;
    const Portee& p = *piles_.back();
    if (p.fonction) {
        auto it = p.fonction->voisines.find(nom);
        if (it != p.fonction->voisines.end()) {
            f->genre = Fonction::Utilisateur;
            f->utilisateur = it->second;
            return f;
        }
    }
    auto uf = fonctionFichier(nom);
    if (uf) {
        f->genre = Fonction::Utilisateur;
        f->utilisateur = uf;
        return f;
    }
    auto it = natifs_.find(nom);
    if (it != natifs_.end()) {
        f->genre = Fonction::Native;
        f->native = it->second.fonction;
        return f;
    }
    erreur("MATLAB:UndefinedFunction", "Unrecognized function or variable '" + nom + "'.");
}

std::vector<Valeur> Interpreteur::appeler(const std::string& nom, std::vector<Valeur> args,
                                          int nargout) {
    ++compteurAppels;
    const Portee& p = *piles_.back();
    if (p.fonction) {
        auto it = p.fonction->voisines.find(nom);
        if (it != p.fonction->voisines.end())
            return appelerUtilisateur(it->second, args, nargout);
    }
    // Méthode d'un objet : dispatch sur la classe du premier argument.
    if (!args.empty() && args[0].classe == Classe::Objet) {
        auto def = classeDefinie(args[0].nomObjet);
        if (def) {
            auto itm = def->methodes.find(nom);
            if (itm != def->methodes.end())
                return appelerUtilisateur(itm->second, args, nargout);
        }
    }
    auto uf = fonctionFichier(nom);
    if (uf) return appelerUtilisateur(uf, args, nargout);
    auto it = natifs_.find(nom);
    if (it != natifs_.end()) return it->second.fonction(*this, args, nargout);
    auto def = classeDefinie(nom);
    if (def) return {construireObjet(*this, def, args)};
    erreur("MATLAB:UndefinedFunction",
           "Unrecognized function or variable '" + nom + "'.");
}

std::vector<Valeur> Interpreteur::appelerValeur(const Valeur& poignee, std::vector<Valeur> args,
                                                int nargout) {
    if (poignee.classe != Classe::Fonction || !poignee.fn) {
        if (poignee.estTexte() || poignee.estChaine())
            return appeler(poignee.versTexte(), args, nargout);
        erreur("MATLAB:UndefinedFunction", "Value is not a function handle.");
    }
    const Fonction& f = *poignee.fn;
    if (f.genre == Fonction::Native) return f.native(*this, args, nargout);
    if (f.genre == Fonction::Utilisateur) return appelerUtilisateur(f.utilisateur, args, nargout);
    // Fonction anonyme : la capture forme la portée, les paramètres par-dessus.
    auto portee = std::make_shared<Portee>();
    portee->nomFonction = "@anonyme";
    portee->fonction = f.contexte;
    if (f.capture)
        for (const auto& kv : *f.capture) portee->variables[kv.first] = kv.second;
    for (std::size_t k = 0; k < f.parametres.size(); ++k) {
        if (f.parametres[k] == "~") continue;
        if (k < args.size()) portee->variables[f.parametres[k]] = args[k];
    }
    if (!f.parametres.empty() && f.parametres.back() == "varargin") {
        Valeur reste = Valeur::celluleDims({1, 0});
        std::vector<Valeur> extra;
        for (std::size_t k = f.parametres.size() - 1; k < args.size(); ++k)
            extra.push_back(args[k]);
        reste = Valeur::celluleLigne(extra);
        portee->variables["varargin"] = reste;
    }
    portee->nargin = (int)args.size();
    portee->nargout = nargout;
    GardePortee garde(*this, portee);
    auto sorties = evaluerMulti(f.corps, nargout);
    std::size_t demandees = (std::size_t)std::max(nargout, 1);
    if (sorties.size() > demandees) sorties.resize(demandees);
    return sorties;
}

std::vector<Valeur> Interpreteur::appelerUtilisateur(
    const std::shared_ptr<FonctionUtilisateur>& f, std::vector<Valeur>& args, int nargout) {
    if (piles_.size() > 400)
        erreur("MATLAB:recursionLimit",
               "Maximum recursion limit of 400 reached. Use set(0,'RecursionLimit',N) to "
               "change the limit.");
    std::size_t fixes = f->entrees.size();
    if (f->variadiqueEntree()) fixes -= 1;
    if (!f->variadiqueEntree() && args.size() > f->entrees.size())
        erreur("MATLAB:TooManyInputs",
               "Too many input arguments to function '" + f->nom + "'.");
    auto portee = std::make_shared<Portee>();
    portee->nomFonction = f->nom;
    portee->fonction = f;
    for (std::size_t k = 0; k < fixes && k < args.size(); ++k) {
        if (f->entrees[k] == "~") continue;
        portee->variables[f->entrees[k]] = args[k];
    }
    if (f->variadiqueEntree()) {
        std::vector<Valeur> extra;
        for (std::size_t k = fixes; k < args.size(); ++k) extra.push_back(args[k]);
        portee->variables["varargin"] = Valeur::celluleLigne(extra);
    }
    portee->nargin = (int)args.size();
    portee->nargout = nargout;
    GardePortee garde(*this, portee);
    try {
        executerBloc(f->corps);
    } catch (RetourFonction&) {
    }
    std::vector<Valeur> sorties;
    std::size_t nFixes = f->sorties.size();
    if (f->variadiqueSortie()) nFixes -= 1;
    for (std::size_t k = 0; k < nFixes; ++k) {
        const Valeur* v = trouverVariable(f->sorties[k]);
        if (!v) {
            if ((int)k < std::max(nargout, k == 0 ? 0 : 1))
                erreur("MATLAB:outputArgUndefined",
                       formater("Output argument \"%s\" (and possibly others) not assigned "
                                "a value in the execution with \"%s\" function.",
                                f->sorties[k].c_str(), f->nom.c_str()));
            break;
        }
        sorties.push_back(*v);
    }
    if (f->variadiqueSortie()) {
        const Valeur* v = trouverVariable("varargout");
        if (v && v->classe == Classe::Cellule)
            for (const auto& x : v->cellules) sorties.push_back(x);
    }
    // On ne rend que ce qui a été demandé : une fonction appelée dans une
    // liste d'arguments ne doit pas y injecter ses sorties surnuméraires.
    std::size_t demandees = (std::size_t)std::max(nargout, 1);
    if (sorties.size() > demandees) sorties.resize(demandees);
    return sorties;
}

// ------------------------------------------------------------- exécution

void Interpreteur::executerTexte(const std::string& source, const std::string& origine) {
    UniteCompilee u = compiler(source, origine);
    for (auto& c : u.classes) cacheClasses_[c->nom] = c;
    if (!u.fonctions.empty()) {
        std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
        for (auto& f : u.fonctions) voisines[f->nom] = f;
        for (auto& f : u.fonctions) f->voisines = voisines;
        if (piles_.back()->fonction) {
            for (auto& kv : voisines) piles_.back()->fonction->voisines[kv.first] = kv.second;
        } else {
            for (auto& kv : voisines) cacheFonctions_[kv.first] = kv.second;
        }
    }
    if (u.script) executerBloc(u.script);
}

void Interpreteur::executerFichier(const std::string& fichier) {
    std::string source = lireFichier(fichier);
    UniteCompilee u = compiler(source, fichier);
    for (auto& c : u.classes) cacheClasses_[c->nom] = c;
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
    for (auto& f : u.fonctions) {
        f->fichier = fichier;
        voisines[f->nom] = f;
    }
    for (auto& f : u.fonctions) f->voisines = voisines;
    if (u.script) {
        auto portee = piles_.back();
        if (!voisines.empty()) {
            auto enveloppe = std::make_shared<FonctionUtilisateur>();
            enveloppe->nom = "<script>";
            enveloppe->voisines = voisines;
            portee->fonction = enveloppe;
        }
        executerBloc(u.script);
    } else if (!u.fonctions.empty()) {
        std::vector<Valeur> args;
        appelerUtilisateur(u.fonctions[0], args, 0);
    }
}

void Interpreteur::executerBloc(const NoeudPtr& b) {
    if (!b) return;
    for (const auto& n : b->enfants) executerInstruction(n);
}

static bool estSuppression(const NoeudPtr& valeur) {
    return valeur && valeur->type == TypeN::Matrice && valeur->rangees.empty();
}

void Interpreteur::affecter(const NoeudPtr& cible, const Valeur& v) {
    if (cible->type == TypeN::Ident) {
        if (cible->texte == "~") return;
        ecrireVariable(cible->texte, v);
        return;
    }
    if (cible->type != TypeN::Acces)
        erreur("MATLAB:invalidAssignment", "Invalid assignment target.");
    const NoeudPtr& base = cible->enfants[0];
    if (base->type != TypeN::Ident)
        erreur("MATLAB:invalidAssignment",
               "Left side of an assignment must be a variable.");
    const std::string& nom = base->texte;
    Valeur courante;
    const Valeur* p = trouverVariable(nom);
    if (p) courante = *p;
    else if (!cible->acces.empty() && (cible->acces[0].genre == '.' ||
                                       cible->acces[0].genre == '?'))
        courante = Valeur::structureVide();
    else if (!cible->acces.empty() && cible->acces[0].genre == '{')
        courante = Valeur::celluleDims({0, 0});
    else
        courante = Valeur::vide();
    // « courante » est notre copie de travail : on la déplace ensuite de
    // proche en proche plutôt que de recopier le tableau à chaque étape.
    Valeur nouvelle = affecterIndex(std::move(courante), cible->acces, 0, v, false);
    ecrireVariable(nom, std::move(nouvelle));
}

void Interpreteur::executerInstruction(const NoeudPtr& n) {
    if (!n) return;
    switch (n->type) {
        case TypeN::Rien:
            return;
        case TypeN::Bloc:
            executerBloc(n);
            return;
        case TypeN::Expression: {
            const NoeudPtr& e = n->enfants[0];
            // Un appel de fonction sans sortie ne pose pas « ans ».
            std::vector<Valeur> r = evaluerMulti(e, 0);
            if (!r.empty()) {
                bool estVariable = (e->type == TypeN::Ident) && existeVariable(e->texte);
                if (!estVariable) ecrireVariable("ans", r[0]);
                if (n->afficher)
                    afficherResultat(*this, estVariable ? e->texte : "ans", r[0]);
            }
            return;
        }
        case TypeN::Affectation: {
            // « x(2) = [] » supprime des éléments ; « s.champ = [] » et
            // « c{2} = [] » posent simplement une valeur vide.
            bool suppression = estSuppression(n->enfants[0]) &&
                               n->cibles.size() == 1 &&
                               n->cibles[0]->type == TypeN::Acces &&
                               !n->cibles[0]->acces.empty() &&
                               n->cibles[0]->acces.back().genre == '(';
            if (n->cibles.size() == 1) {
                Valeur v;
                if (suppression && n->cibles[0]->type == TypeN::Acces) {
                    const NoeudPtr& cible = n->cibles[0];
                    const std::string& nom = cible->enfants[0]->texte;
                    Valeur courante = lireVariable(nom);
                    Valeur nouvelle = affecterIndex(std::move(courante), cible->acces, 0,
                                                    Valeur::vide(), true);
                    ecrireVariable(nom, std::move(nouvelle));
                    if (n->afficher) afficherResultat(*this, nom, lireVariable(nom));
                    return;
                }
                v = evaluer(n->enfants[0]);
                affecter(n->cibles[0], v);
                if (n->afficher) {
                    const NoeudPtr& c = n->cibles[0];
                    std::string nom = c->type == TypeN::Ident ? c->texte : c->enfants[0]->texte;
                    afficherResultat(*this, nom, lireVariable(nom));
                }
                return;
            }
            std::vector<Valeur> r = evaluerMulti(n->enfants[0], (int)n->cibles.size());
            if (r.size() < n->cibles.size()) {
                std::size_t demandees = n->cibles.size();
                if (r.size() + 1 == demandees || r.size() < demandees)
                    erreur("MATLAB:TooManyOutputs",
                           "Insufficient number of outputs from right hand side of equal "
                           "sign to satisfy assignment.");
            }
            for (std::size_t k = 0; k < n->cibles.size(); ++k) affecter(n->cibles[k], r[k]);
            if (n->afficher)
                for (const auto& c : n->cibles) {
                    if (c->type == TypeN::Ident && c->texte == "~") continue;
                    std::string nom = c->type == TypeN::Ident ? c->texte : c->enfants[0]->texte;
                    afficherResultat(*this, nom, lireVariable(nom));
                }
            return;
        }
        case TypeN::Si: {
            // Les enfants alternent condition et bloc ; le dernier est le
            // bloc « else » quand le drapeau est levé.
            std::size_t nPaires = n->enfants.size() - (n->drapeau ? 1 : 0);
            for (std::size_t k = 0; k + 1 < nPaires; k += 2) {
                if (evaluer(n->enfants[k]).vrai()) {
                    executerBloc(n->enfants[k + 1]);
                    return;
                }
            }
            if (n->drapeau) executerBloc(n->enfants.back());
            return;
        }
        case TypeN::TantQue: {
            while (evaluer(n->enfants[0]).vrai()) {
                try {
                    executerBloc(n->enfants[1]);
                } catch (RuptureBoucle&) {
                    break;
                } catch (ContinuerBoucle&) {
                    continue;
                }
            }
            return;
        }
        case TypeN::FaireJusqua: {
            for (;;) {
                try {
                    executerBloc(n->enfants[0]);
                } catch (RuptureBoucle&) {
                    break;
                } catch (ContinuerBoucle&) {
                }
                if (evaluer(n->enfants[1]).vrai()) break;
            }
            return;
        }
        case TypeN::Pour: {
            Valeur plage = evaluer(n->enfants[0]);
            std::size_t colonnes;
            int lignes;
            if (plage.classe == Classe::Cellule) {
                lignes = plage.nlignes();
                colonnes = (std::size_t)plage.ncolonnes();
            } else if (plage.estStructure()) {
                lignes = 1;
                colonnes = plage.nelem();
            } else {
                lignes = plage.nlignes();
                colonnes = (std::size_t)plage.ncolonnes();
            }
            if (plage.nelem() == 0) return;
            for (std::size_t j = 0; j < colonnes; ++j) {
                Valeur iteration;
                if (lignes == 1) {
                    iteration = extraireElement(plage, j);
                    if (plage.classe == Classe::Cellule) {
                        Valeur c = Valeur::celluleDims({1, 1});
                        c.cellules[0] = plage.cellules[j];
                        iteration = c;
                    }
                } else {
                    std::vector<Valeur> idx = {Valeur::texte(":"),
                                               Valeur::scalaire((double)j + 1)};
                    iteration = indexer(plage, idx, '(');
                }
                affecter(n->cibles[0], iteration);
                try {
                    executerBloc(n->enfants[1]);
                } catch (RuptureBoucle&) {
                    break;
                } catch (ContinuerBoucle&) {
                    continue;
                }
            }
            return;
        }
        case TypeN::Choix: {
            Valeur sujet = evaluer(n->enfants[0]);
            // enfants[0] est le sujet, puis alternent cas et bloc.
            std::size_t nPaires = n->enfants.size() - (n->drapeau ? 1 : 0);
            for (std::size_t k = 1; k + 1 < nPaires; k += 2) {
                Valeur cas = evaluer(n->enfants[k]);
                bool correspond = false;
                if (cas.classe == Classe::Cellule) {
                    for (const auto& c : cas.cellules)
                        if (comparerCas(sujet, c)) { correspond = true; break; }
                } else {
                    correspond = comparerCas(sujet, cas);
                }
                if (correspond) {
                    executerBloc(n->enfants[k + 1]);
                    return;
                }
            }
            if (n->drapeau) executerBloc(n->enfants.back());
            return;
        }
        case TypeN::Essayer: {
            if (n->drapeau) {  // unwind_protect
                try {
                    executerBloc(n->enfants[0]);
                } catch (...) {
                    executerBloc(n->enfants[1]);
                    throw;
                }
                executerBloc(n->enfants[1]);
                return;
            }
            try {
                executerBloc(n->enfants[0]);
            } catch (ErreurMatlab& e) {
                dernierIdentifiant = e.identifiant;
                dernierMessage = e.message;
                Valeur err = Valeur::structureVide();
                err.poserChamp("identifier", Valeur::texte(e.identifiant));
                err.poserChamp("message", Valeur::texte(e.message));
                Valeur pile = Valeur::structureVide();
                pile.poserChamp("file", Valeur::texte(""));
                pile.poserChamp("name", Valeur::texte(portee().nomFonction));
                pile.poserChamp("line", Valeur::scalaire(n->ligne));
                err.poserChamp("stack", pile);
                err.classe = Classe::Objet;
                err.nomObjet = "MException";
                derniereErreur = err;
                if (!n->texte.empty()) ecrireVariable(n->texte, err);
                executerBloc(n->enfants[1]);
            }
            return;
        }
        case TypeN::Rupture: throw RuptureBoucle{};
        case TypeN::Continuer: throw ContinuerBoucle{};
        case TypeN::Retour: throw RetourFonction{};
        case TypeN::Global: {
            for (std::size_t k = 0; k < n->noms.size(); ++k) {
                const std::string& nom = n->noms[k];
                portee().globales.insert(nom);
                if (!globales.count(nom)) {
                    globales[nom] = n->enfants[k] ? evaluer(n->enfants[k]) : Valeur::vide();
                }
            }
            return;
        }
        case TypeN::Persistant: {
            for (std::size_t k = 0; k < n->noms.size(); ++k) {
                std::string cle = portee().nomFonction + "::" + n->noms[k];
                portee().liensPersistants[n->noms[k]] = cle;
                if (!persistantes.count(cle))
                    persistantes[cle] = n->enfants[k] ? evaluer(n->enfants[k]) : Valeur::vide();
            }
            return;
        }
        case TypeN::Commande: {
            std::vector<Valeur> args;
            for (const auto& a : n->noms) args.push_back(Valeur::texte(a));
            std::vector<Valeur> r = appeler(n->texte, args, 0);
            if (!r.empty()) {
                ecrireVariable("ans", r[0]);
                if (n->afficher) afficherResultat(*this, "ans", r[0]);
            }
            return;
        }
        default: {
            Valeur v = evaluer(n);
            (void)v;
            return;
        }
    }
}

// ------------------------------------------------------------- évaluation

Valeur Interpreteur::evaluer(const NoeudPtr& n) {
    // Chemin court pour les nœuds les plus fréquents : on évite d'allouer
    // le vecteur de sorties que réclame « evaluerMulti ». Dans une boucle
    // serrée, c'est l'essentiel du coût.
    switch (n->type) {
        case TypeN::Nombre:
            if (n->imaginaire) return Valeur::complexe(0.0, n->nombre);
            return Valeur::scalaire(n->nombre);
        case TypeN::Litteral: return Valeur::texte(n->texte);
        case TypeN::LitteralChaine: return Valeur::chaine(n->texte);
        case TypeN::Ident: {
            const Valeur* v = trouverVariable(n->texte);
            if (v) return *v;
            break;
        }
        case TypeN::OpBinaire: {
            const std::string& op = n->texte;
            if (op != "&&" && op != "||") {
                Valeur a = evaluer(n->enfants[0]);
                Valeur b = evaluer(n->enfants[1]);
                if (a.classe != Classe::Objet && b.classe != Classe::Objet)
                    return operationBinaire(op, a, b);
                break;
            }
            break;
        }
        case TypeN::OpUnaire: {
            Valeur a = evaluer(n->enfants[0]);
            if (a.classe != Classe::Objet) return operationUnaire(n->texte, a);
            break;
        }
        case TypeN::OpPostfixe:
            return transposer(evaluer(n->enfants[0]), n->texte == "'");
        default: break;
    }
    auto r = evaluerMulti(n, 1);
    if (r.empty()) {
        erreur("MATLAB:emptyOutput",
               "Too many output arguments: the expression produced no value.");
    }
    return r[0];
}

std::vector<Valeur> Interpreteur::evaluerIndices(const std::vector<NoeudPtr>& args,
                                                 const Valeur* base, int, int) {
    std::vector<Valeur> idx;
    int total = (int)args.size();
    for (int k = 0; k < total; ++k) {
        const NoeudPtr& a = args[(std::size_t)k];
        if (a->type == TypeN::DeuxPointsSeul) {
            idx.push_back(Valeur::texte(":"));
            continue;
        }
        pileFin_.emplace_back(base, k, total);
        try {
            if (a->type == TypeN::Acces || a->type == TypeN::Ident) {
                auto liste = evaluerMulti(a, 1);
                for (auto& v : liste) idx.push_back(v);
                if (liste.empty()) idx.push_back(Valeur::vide());
            } else {
                idx.push_back(evaluer(a));
            }
        } catch (...) {
            pileFin_.pop_back();
            throw;
        }
        pileFin_.pop_back();
    }
    return idx;
}

std::vector<Valeur> Interpreteur::evaluerListe(const std::vector<NoeudPtr>& args) {
    std::vector<Valeur> sortie;
    for (const auto& a : args) {
        if (!a) continue;
        if (a->type == TypeN::DeuxPointsSeul) {
            sortie.push_back(Valeur::texte(":"));
            continue;
        }
        // Une expression « c{...} » ou « s.champ » peut rendre plusieurs valeurs.
        if (a->type == TypeN::Acces) {
            auto liste = evaluerMulti(a, -1);
            for (auto& v : liste) sortie.push_back(v);
            continue;
        }
        sortie.push_back(evaluer(a));
    }
    return sortie;
}

// Développe les listes séparées par des virgules d'un accès.
Valeur Interpreteur::evaluerAcces(const NoeudPtr& n, int nargout, std::vector<Valeur>* multi) {
    const NoeudPtr& baseNoeud = n->enfants[0];
    std::vector<Valeur> courant;
    std::size_t debut = 0;

    if (baseNoeud->type == TypeN::Ident) {
        const std::string& nom = baseNoeud->texte;
        const Valeur* v = trouverVariable(nom);
        if (v) {
            courant.push_back(*v);
            // Appel d'une poignée de fonction stockée dans une variable.
            if (v->classe == Classe::Fonction && !n->acces.empty() &&
                n->acces[0].genre == '(') {
                auto args = evaluerListe(n->acces[0].args);
                courant = appelerValeur(*v, args, std::max(nargout, 1));
                debut = 1;
            }
        } else {
            // Fonction : les arguments du premier accès sont ses paramètres.
            int demandees = nargout < 0 ? 1 : nargout;
            if (!n->acces.empty() && n->acces[0].genre == '(') {
                auto args = evaluerListe(n->acces[0].args);
                courant = appeler(nom, args, n->acces.size() > 1 ? 1 : demandees);
                debut = 1;
            } else {
                std::vector<Valeur> aucun;
                courant = appeler(nom, aucun, n->acces.empty() ? demandees : 1);
            }
            if (courant.empty()) {
                if (multi) { multi->clear(); return Valeur::vide(); }
                erreur("MATLAB:maxlhs",
                       "Too many output arguments: function '" + nom + "' returned nothing.");
            }
        }
    } else {
        courant.push_back(evaluer(baseNoeud));
    }

    for (std::size_t k = debut; k < n->acces.size(); ++k) {
        const ElementAcces& e = n->acces[k];
        bool dernier = (k + 1 == n->acces.size());
        std::vector<Valeur> suivant;
        for (const Valeur& base : courant) {
            if (e.genre == '(') {
                if (base.classe == Classe::Fonction) {
                    auto args = evaluerListe(e.args);
                    auto r = appelerValeur(base, args, dernier ? std::max(nargout, 1) : 1);
                    for (auto& x : r) suivant.push_back(x);
                    continue;
                }
                auto idx = evaluerIndices(e.args, &base, 0, (int)e.args.size());
                suivant.push_back(indexer(base, idx, '('));
            } else if (e.genre == '{') {
                auto idx = evaluerIndices(e.args, &base, 0, (int)e.args.size());
                auto liste = indexerListe(base, idx, '{');
                for (auto& x : liste) suivant.push_back(x);
            } else {
                std::string nom = e.nom;
                if (e.genre == '?') {
                    auto args = evaluerListe(e.args);
                    if (args.empty())
                        erreur("MATLAB:badsubscript", "Invalid dynamic field name.");
                    nom = args[0].versTexte();
                }
                if (base.classe == Classe::Objet) {
                    auto def = classeDefinie(base.nomObjet);
                    if (def && !base.aChamp(nom) && def->methodes.count(nom)) {
                        std::vector<Valeur> args = {base};
                        if (dernier || n->acces[k + 1].genre != '(') {
                            auto r = appelerUtilisateur(def->methodes[nom], args,
                                                        dernier ? std::max(nargout, 1) : 1);
                            for (auto& x : r) suivant.push_back(x);
                            continue;
                        }
                        auto extra = evaluerListe(n->acces[k + 1].args);
                        for (auto& x : extra) args.push_back(x);
                        auto r = appelerUtilisateur(
                            def->methodes[nom], args,
                            (k + 2 == n->acces.size()) ? std::max(nargout, 1) : 1);
                        for (auto& x : r) suivant.push_back(x);
                        ++k;
                        continue;
                    }
                }
                if (!base.estStructure())
                    erreur("MATLAB:structRefFromNonStruct",
                           formater("Dot indexing is not supported for variables of this "
                                    "type (%s).", base.classeNom().c_str()));
                if (!base.aChamp(nom))
                    erreur("MATLAB:nonExistentField",
                           "Unrecognized field name \"" + nom + "\".");
                std::size_t n2 = base.nelem();
                for (std::size_t i = 0; i < n2; ++i) suivant.push_back(base.champ(nom, i));
            }
        }
        courant = suivant;
    }

    if (multi) *multi = courant;
    if (courant.empty()) {
        if (multi) return Valeur::vide();
        erreur("MATLAB:index:expected_one_output",
               "Expected one output from a curly brace or dot indexing expression, but "
               "there were 0 results.");
    }
    return courant[0];
}

std::vector<Valeur> Interpreteur::evaluerMulti(const NoeudPtr& n, int nargout) {
    switch (n->type) {
        case TypeN::Nombre: {
            if (n->imaginaire) return {Valeur::complexe(0.0, n->nombre)};
            return {Valeur::scalaire(n->nombre)};
        }
        case TypeN::Litteral: return {Valeur::texte(n->texte)};
        case TypeN::LitteralChaine: return {Valeur::chaine(n->texte)};
        case TypeN::Ident: {
            const Valeur* v = trouverVariable(n->texte);
            if (v) return {*v};
            std::vector<Valeur> args;
            auto r = appeler(n->texte, args, nargout < 0 ? 1 : nargout);
            return r;
        }
        case TypeN::FinIndice: {
            if (pileFin_.empty())
                erreur("MATLAB:endWithoutIndex",
                       "The 'end' operator must be used within an array index expression.");
            auto [base, position, total] = pileFin_.back();
            if (!base) return {Valeur::scalaire(0)};
            std::size_t taille;
            if (total == 1) {
                taille = base->nelem();
            } else if (position + 1 < total) {
                taille = (std::size_t)((std::size_t)position < base->dims.size()
                                           ? base->dims[(std::size_t)position]
                                           : 1);
            } else {
                taille = 1;
                for (std::size_t d = (std::size_t)position; d < base->dims.size(); ++d)
                    taille *= (std::size_t)base->dims[d];
            }
            return {Valeur::scalaire((double)taille)};
        }
        case TypeN::DeuxPointsSeul: return {Valeur::texte(":")};
        case TypeN::OpBinaire: {
            const std::string& op = n->texte;
            if (op == "&&") {
                Valeur a = evaluer(n->enfants[0]);
                if (!a.vrai()) return {Valeur::booleen(false)};
                return {Valeur::booleen(evaluer(n->enfants[1]).vrai())};
            }
            if (op == "||") {
                Valeur a = evaluer(n->enfants[0]);
                if (a.vrai()) return {Valeur::booleen(true)};
                return {Valeur::booleen(evaluer(n->enfants[1]).vrai())};
            }
            Valeur a = evaluer(n->enfants[0]);
            Valeur b = evaluer(n->enfants[1]);
            if (a.classe == Classe::Objet || b.classe == Classe::Objet) {
                std::string methode = nomMethodeOperateur(op);
                const Valeur& obj = a.classe == Classe::Objet ? a : b;
                auto def = classeDefinie(obj.nomObjet);
                if (def && def->methodes.count(methode)) {
                    std::vector<Valeur> args = {a, b};
                    return appelerUtilisateur(def->methodes[methode], args, 1);
                }
            }
            return {operationBinaire(op, a, b)};
        }
        case TypeN::OpUnaire: {
            Valeur a = evaluer(n->enfants[0]);
            if (a.classe == Classe::Objet) {
                std::string methode = n->texte == "-" ? "uminus"
                                                      : (n->texte == "+" ? "uplus" : "not");
                auto def = classeDefinie(a.nomObjet);
                if (def && def->methodes.count(methode)) {
                    std::vector<Valeur> args = {a};
                    return appelerUtilisateur(def->methodes[methode], args, 1);
                }
            }
            return {operationUnaire(n->texte, a)};
        }
        case TypeN::OpPostfixe: {
            Valeur a = evaluer(n->enfants[0]);
            return {transposer(a, n->texte == "'")};
        }
        case TypeN::Plage: {
            Valeur debut = evaluer(n->enfants[0]);
            Valeur pas = n->enfants[1] ? evaluer(n->enfants[1]) : Valeur::scalaire(1.0);
            Valeur fin = evaluer(n->enfants[2]);
            return {construirePlage(debut, pas, fin)};
        }
        case TypeN::Matrice: {
            std::vector<std::vector<Valeur>> rangees;
            for (const auto& r : n->rangees) rangees.push_back(evaluerListe(r));
            return {concatenerRangees(rangees)};
        }
        case TypeN::Cellule: {
            std::vector<std::vector<Valeur>> rangees;
            for (const auto& r : n->rangees) rangees.push_back(evaluerListe(r));
            return {celluleDepuisRangees(rangees)};
        }
        case TypeN::Anonyme: {
            auto f = std::make_shared<Fonction>();
            f->genre = Fonction::Anonyme;
            f->parametres = n->noms;
            f->corps = n->enfants[0];
            f->capture = std::make_shared<std::unordered_map<std::string, Valeur>>(
                portee().variables);
            f->contexte = portee().fonction;
            f->texte = texteExpression(n);
            return {Valeur::poignee(f)};
        }
        case TypeN::PoigneeNom: {
            auto f = resoudrePoignee(n->texte);
            f->texte = "@" + n->texte;
            return {Valeur::poignee(f)};
        }
        case TypeN::Acces: {
            std::vector<Valeur> multi;
            evaluerAcces(n, nargout, &multi);
            return multi;
        }
        default:
            erreur("MATLAB:parseError", "Unsupported expression.");
    }
}

}  // namespace matlibre
