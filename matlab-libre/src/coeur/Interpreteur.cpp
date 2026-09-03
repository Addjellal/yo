#include <set>

#include "matlibre/Interpreteur.h"
#include "matlibre/Parallele.h"

#include <algorithm>
#include <cmath>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>

#include "matlibre/Affichage.h"
#include "matlibre/Analyseur.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Creux.h"
#include "matlibre/Erreur.h"
#include "matlibre/Operations.h"

namespace fs = std::filesystem;

namespace matlibre {

// Les méthodes d'une classe voient les fonctions locales écrites après le
// bloc classdef ; elles ne se voient pas entre elles par leur nom : comme
// dans MATLAB, un appel de méthode se résout sur la classe du premier
// argument, sans quoi « numel(d.Secondes) » écrit dans la méthode numel
// rappellerait cette méthode au lieu de la fonction du langage.
// Les fonctions locales d'un fichier sont visibles de toutes les autres,
// y compris depuis une fonction imbriquee : « voisines » descend donc
// jusqu'au fond. Sans cela, une fonction imbriquee ne pouvait appeler
// aucune des fonctions locales ecrites apres le « end » de sa parente.
static void propagerVoisines(
    const std::shared_ptr<FonctionUtilisateur>& f,
    const std::map<std::string, std::shared_ptr<FonctionUtilisateur>>& voisines) {
    if (!f) return;
    f->voisines = voisines;
    for (auto& kv : f->imbriquees) propagerVoisines(kv.second, voisines);
}

static void relierClasse(const std::shared_ptr<DefinitionClasse>& def,
                         const std::vector<std::shared_ptr<FonctionUtilisateur>>& locales) {
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
    for (const auto& f : locales) voisines[f->nom] = f;
    for (auto& kv : def->methodes) {
        propagerVoisines(kv.second, voisines);
        kv.second->classeProprietaire = def->nom;
    }
    for (const auto& f : locales) propagerVoisines(f, voisines);
}


// Ce que le message d'erreur nomme : le nom de la fonction, ou celui du
// fichier quand la fonction n'en a pas (un script).
std::string nomCourt(const std::string& nom, const std::string& fichier) {
    std::string base;
    if (!fichier.empty()) {
        std::size_t barre = fichier.find_last_of("/\\");
        base = barre == std::string::npos ? fichier : fichier.substr(barre + 1);
        std::size_t point = base.find_last_of('.');
        if (point != std::string::npos) base = base.substr(0, point);
    }
    // Un script, ou l'enveloppe posee autour : c'est le fichier qui nomme.
    if (nom.empty() || nom[0] == '<') return base;
    // Une sous-fonction se nomme « fichier>fonction », comme sous MATLAB.
    if (!base.empty() && base != nom) return base + ">" + nom;
    return nom;
}

GardePortee::GardePortee(Interpreteur& i, std::shared_ptr<Portee> p) : it(i) {
    it.piles_.push_back(std::move(p));
}
GardePortee::~GardePortee() { it.piles_.pop_back(); }

// Empile un cadre d'exécution pour la durée d'un appel. Le cadre reste
// lisible pendant le déroulement de la pile : c'est là que l'erreur va
// chercher le nom du fichier et la ligne.
GardeCadre::GardeCadre(Interpreteur& i, const std::string& nom, const std::string& fichier)
    : it(i) {
    it.cadres.push_back(CadreErreur{nomCourt(nom, fichier), fichier, 0});
}

GardeCadre::~GardeCadre() {
    if (!it.cadres.empty()) it.cadres.pop_back();
}

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

// Retrouve la poignée partagée d'une portée atteinte par le chaînage.
std::shared_ptr<Portee> Interpreteur::trouverPortee(const Portee* brut) const {
    for (const auto& p : piles_)
        if (p.get() == brut) return p;
    for (const auto& p : piles_)
        for (std::shared_ptr<Portee> q = p->englobante; q; q = q->englobante)
            if (q.get() == brut) return q;
    return nullptr;
}

// Cherche une variable dans une portée, puis dans celles qui l'englobent :
// c'est le partage d'espace de travail des fonctions imbriquées.
static const Valeur* chercherDansChaine(const Portee& depart, const std::string& nom) {
    for (const Portee* p = depart.englobante.get(); p; p = p->englobante.get()) {
        auto it = p->variables.find(nom);
        if (it != p->variables.end()) return &it->second;
    }
    return nullptr;
}

const Valeur* Interpreteur::trouverVariable(const std::string& nom) const {
    const Portee& p = *piles_.back();
    // Le cas courant est une portée sans variable globale ni persistante :
    // on va droit à la table locale.
    if (p.globales.empty() && p.liensPersistants.empty()) {
        auto it = p.variables.find(nom);
        if (it != p.variables.end()) return &it->second;
        return p.englobante ? chercherDansChaine(p, nom) : nullptr;
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
    if (it != p.variables.end()) return &it->second;
    return p.englobante ? chercherDansChaine(p, nom) : nullptr;
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
    // Une variable déjà présente dans une portée englobante s'écrit là-bas :
    // la fonction imbriquée et son parent partagent bien la même case.
    if (p.englobante && p.variables.find(nom) == p.variables.end()) {
        for (Portee* q = p.englobante.get(); q; q = q->englobante.get()) {
            auto it = q->variables.find(nom);
            if (it != q->variables.end()) {
                it->second = std::move(v);
                return;
            }
        }
    }
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

std::string Interpreteur::nomArgument(std::size_t k) const {
    return k < nomsArgumentsAppel_.size() ? nomsArgumentsAppel_[k] : std::string();
}

void Interpreteur::poserNomsArguments(std::vector<std::string> noms) {
    nomsArgumentsAppel_ = std::move(noms);
}

std::vector<std::string> Interpreteur::prendreNomsArguments() {
    std::vector<std::string> noms = std::move(nomsArgumentsAppel_);
    nomsArgumentsAppel_.clear();
    return noms;
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
    indexMethodes_.clear();
    indexMethodesPret_ = false;
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
        for (auto& c : u.classes) {
            relierClasse(c, u.fonctions);
            c->aide = aideDepuisSource(source);
            c->fichier = it->second;
            cacheClasses_[c->nom] = c;
        }
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
        f->script = true;
        cacheFonctions_[nom] = f;
        return f;
    }
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
    for (auto& f : u.fonctions) voisines[f->nom] = f;
    for (auto& f : u.fonctions) {
        f->fichier = it->second;
        propagerVoisines(f, voisines);
    }
    u.fonctions[0]->aide = aideDepuisSource(source);
    // Le nom du fichier prime sur celui écrit dans la première fonction ;
    // les suivantes restent privées au fichier, visibles par « voisines ».
    cacheFonctions_[nom] = u.fonctions[0];
    return u.fonctions[0];
}

// Concaténation d'un crochet : quand une classe définit horzcat ou vertcat,
// MATLAB lui confie l'assemblage plutôt que d'empiler les propriétés.
Valeur Interpreteur::concatenerObjets(const std::vector<std::vector<Valeur>>& rangees) {
    auto methodeUtile = [&](const std::vector<Valeur>& liste,
                            const std::string& methode) -> std::shared_ptr<DefinitionClasse> {
        for (const auto& v : liste) {
            if (v.classe != Classe::Objet || estCarte(v)) continue;
            auto def = classeDe(v);
            if (def && def->aMethode(methode)) return def;
        }
        return nullptr;
    };
    std::vector<Valeur> lignes;
    for (const auto& r : rangees) {
        std::vector<Valeur> elements;
        for (const auto& v : r) {
            // Seul le vide « [] » — toutes dimensions nulles — s'efface
            // d'une concatenation ; un 1x0 garde sa ligne, comme dans
            // MATLAB.
            if (v.nelem() == 0 && !v.estStructure()) {
                bool toutesNulles = true;
                for (int d : v.dims)
                    if (d != 0) toutesNulles = false;
                if (toutesNulles) continue;
            }
            elements.push_back(v);
        }
        if (elements.empty()) continue;
        auto def = methodeUtile(elements, "horzcat");
        if (def && elements.size() > 1) {
            Valeur acc = elements[0];
            for (std::size_t k = 1; k < elements.size(); ++k) {
                std::vector<Valeur> args = {acc, elements[k]};
                auto res = appelerUtilisateur(def->methodes["horzcat"], args, 1);
                acc = res.empty() ? Valeur::vide() : res[0];
            }
            lignes.push_back(acc);
        } else if (def) {
            lignes.push_back(elements[0]);
        } else {
            lignes.push_back(concatener(elements, 1));
        }
    }
    if (lignes.empty()) return Valeur::vide();
    auto def = methodeUtile(lignes, "vertcat");
    if (def && lignes.size() > 1) {
        Valeur acc = lignes[0];
        for (std::size_t k = 1; k < lignes.size(); ++k) {
            std::vector<Valeur> args = {acc, lignes[k]};
            auto res = appelerUtilisateur(def->methodes["vertcat"], args, 1);
            acc = res.empty() ? Valeur::vide() : res[0];
        }
        return acc;
    }
    if (def) return lignes[0];
    return concatener(lignes, 0);
}

// Longueur, en nombre d'accès pointés, du plus long nom composé connu qui
// commence par « nom ». Zéro si aucun n'existe.
std::size_t Interpreteur::nomPointe(const std::string& nom,
                                    const std::vector<ElementAcces>& acces) {
    std::string compose = nom;
    std::size_t meilleur = 0;
    for (std::size_t k = 0; k < acces.size(); ++k) {
        if (acces[k].genre != '.') break;
        compose += "." + acces[k].nom;
        if (natif(compose) || indexFichiers().count(compose)) meilleur = k + 1;
    }
    return meilleur;
}

// Fichier de l'unité en cours : celui de la fonction, sinon le script.
std::string Interpreteur::fichierExecute() const {
    for (auto it = piles_.rbegin(); it != piles_.rend(); ++it) {
        const auto& p = *it;
        if (p && p->fonction && !p->fonction->fichier.empty()) return p->fonction->fichier;
    }
    return fichierCourant;
}

// Les classes auxquelles « X.empty » a un sens : les fondamentales que
// MatLibre sait representer, et toute classe declaree par un classdef.
bool Interpreteur::classeVide(const std::string& nom) {
    bool connue = false;
    classeDepuisNom(nom, &connue);
    if (connue) return true;
    return classeDefinie(nom) != nullptr;
}

Valeur Interpreteur::valeurVideDeClasse(const std::string& nom, const Dims& d) {
    bool connue = false;
    Classe c = classeDepuisNom(nom, &connue);
    if (connue) {
        if (c == Classe::Cellule) return Valeur::celluleDims(d);
        if (c == Classe::Structure) {
            Valeur v = Valeur::structureVide();
            v.dims = d;
            return v;
        }
        Valeur v = Valeur::matriceDims(d);
        v.classe = c;
        return v;
    }
    Valeur v = Valeur::structureVide();
    v.classe = Classe::Objet;
    v.nomObjet = nom;
    // Les proprietes sont posees, mais vides : une methode appelee sur
    // le tableau vide — « isempty(duration.empty) » — les lit, et doit y
    // trouver du vide, non la valeur par defaut d'un objet qui existe.
    if (auto def = classeDefinie(nom)) {
        for (const auto& propriete : def->ordreProprietes)
            v.poserChamp(propriete, Valeur::vide());
        v.poigneeObjet = def->poignee;
    }
    v.dims = d;
    return v;
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
        relierClasse(u.classes[0], u.fonctions);
        // Le bloc de commentaires sous « classdef » est l'aide de la
        // classe, comme celui sous « function » l'est d'une fonction :
        // « help tf » doit le trouver.
        u.classes[0]->aide = aideDepuisSource(source);
        u.classes[0]->fichier = itm->second;
        cacheClasses_[nom] = u.classes[0];
        return u.classes[0];
    }
    std::string source = lireFichier(it->second);
    UniteCompilee u = compiler(source, it->second);
    if (u.classes.empty()) return nullptr;
    relierClasse(u.classes[0], u.fonctions);
    u.classes[0]->aide = aideDepuisSource(source);
    u.classes[0]->fichier = it->second;
    cacheClasses_[nom] = u.classes[0];
    return u.classes[0];
}

// Toutes les methodes de toutes les classes du chemin, baties une fois.
// On ne lit que les fichiers qui portent « classdef » : le mot est
// cherche dans la source, ce qui coute une lecture par fichier, faite une
// seule fois et seulement si l'on demande.
std::shared_ptr<DefinitionClasse> Interpreteur::classeDeMethode(const std::string& nom) {
    if (!indexMethodesPret_) {
        indexMethodesPret_ = true;
        std::vector<std::string> candidats;
        for (const auto& entree : indexClasses_) candidats.push_back(entree.first);
        for (const auto& entree : indexM_) {
            // Un fichier de l'index peut avoir disparu, ou etre nomme
            // relativement a un dossier qu'on a quitte depuis : « exist »
            // n'a pas a echouer pour autant.
            std::string source;
            try {
                source = lireFichier(entree.second);
            } catch (...) {
                continue;
            }
            if (source.find("classdef") == std::string::npos) continue;
            candidats.push_back(entree.first);
        }
        for (const std::string& nomClasse : candidats) {
            std::shared_ptr<DefinitionClasse> c;
            try {
                c = classeDefinie(nomClasse);
            } catch (...) {
                continue;
            }
            if (!c) continue;
            for (const auto& methode : c->methodes)
                if (!indexMethodes_.count(methode.first))
                    indexMethodes_[methode.first] = nomClasse;
        }
    }
    auto trouve = indexMethodes_.find(nom);
    if (trouve == indexMethodes_.end()) return nullptr;
    return classeDefinie(trouve->second);
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
    // Une poignée vers une fonction imbriquée emporte la portée partagée :
    // c'est ce qui fait vivre les rappels d'une application.
    {
        std::shared_ptr<Portee> portante = piles_.back();
        for (Portee* q = portante.get(); q; q = q->englobante.get()) {
            if (!q->fonction) continue;
            auto it = q->fonction->imbriquees.find(nom);
            if (it == q->fonction->imbriquees.end()) continue;
            Portee* hote = q;
            while (hote->anonyme && hote->englobante) hote = hote->englobante.get();
            f->genre = Fonction::Utilisateur;
            f->utilisateur = it->second;
            f->porteeEnglobante = hote == portante.get() ? portante : trouverPortee(hote);
            return f;
        }
    }
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
    // Une fonction imbriquée se résout d'abord : elle est visible depuis son
    // parent et depuis ses sœurs, et nulle part ailleurs.
    {
        std::shared_ptr<Portee> portante = piles_.back();
        for (Portee* q = portante.get(); q; q = q->englobante.get()) {
            if (!q->fonction) {
                if (!q->englobante) break;
                continue;
            }
            auto it = q->fonction->imbriquees.find(nom);
            if (it != q->fonction->imbriquees.end()) {
                // L'activation d'une fonction anonyme ne porte qu'une copie
                // de la capture : la vraie portée partagée est derrière.
                Portee* hote = q;
                while (hote->anonyme && hote->englobante) hote = hote->englobante.get();
                englobanteEnAttente_ =
                    hote == portante.get() ? portante : trouverPortee(hote);
                return appelerUtilisateur(it->second, args, nargout);
            }
        }
    }
    if (p.fonction) {
        auto it = p.fonction->voisines.find(nom);
        if (it != p.fonction->voisines.end())
            return appelerUtilisateur(it->second, args, nargout);
    }
    // Méthode d'un objet : dispatch sur la classe de l'argument dominant.
    // MATLAB retient le premier argument qui est un objet et dont la classe
    // définit la méthode ; « varfun(@sum, T) » atteint ainsi table.varfun.
    for (const auto& a : args) {
        if (a.classe != Classe::Objet) continue;
        // Un nom de classe est toujours un appel de constructeur. Sans ce
        // test, « ss(sys) » où sys est déjà un ss partait vers la méthode
        // « ss » de la classe — c'est-à-dire son constructeur, mais appelé
        // comme une fonction ordinaire : la valeur rendue était une simple
        // structure, et tout ce qui suivait la prenait pour telle.
        if (auto classe = classeDefinie(nom))
            return {construireObjet(*this, classe, args)};
        auto def = classeDefinie(a.nomObjet);
        if (!def) continue;
        auto itm = def->methodes.find(nom);
        if (itm != def->methodes.end()) return appelerUtilisateur(itm->second, args, nargout);
        break;  // le premier objet décide : pas de méthode, pas de dispatch
    }
    if (!args.empty() && args[0].classe == Classe::Fonction) {
        for (std::size_t k = 1; k < args.size(); ++k) {
            if (args[k].classe != Classe::Objet) continue;
            auto def = classeDefinie(args[k].nomObjet);
            if (!def) continue;
            auto itm = def->methodes.find(nom);
            if (itm != def->methodes.end())
                return appelerUtilisateur(itm->second, args, nargout);
            break;
        }
    }
    auto uf = fonctionFichier(nom);
    if (uf) return appelerUtilisateur(uf, args, nargout);
    auto it = natifs_.find(nom);
    if (it != natifs_.end()) {
        // Les fonctions qui ignorent le stockage creux reçoivent une copie
        // dense : aucun résultat ne dépend alors du stockage.
        static const std::set<std::string> saventLireCreux = {
            "sparse", "full", "issparse", "nnz", "nonzeros", "spy", "size", "numel",
            "length", "ndims", "isempty", "class", "isa", "isnumeric", "isreal",
            "spalloc", "spones", "nzmax", "isequal", "disp", "display", "transpose",
            "ctranspose", "spdiags", "speye", "sprand", "sprandn", "mtimes", "mldivide",
            "plus", "minus", "times", "isdiag", "istriu", "istril", "issymmetric"};
        if (!saventLireCreux.count(nom))
            for (auto& a : args)
                if (a.estCreux()) a = denseDepuisCreux(a);
        // Garde-fou : une valeur numerique dont « re » est plus court que
        // « nelem » n'est pas lisible — sa mise en forme sortirait du
        // tableau, et le programme tomberait loin de la fonction fautive.
        // Deux comparaisons d'entiers par sortie, et l'erreur nomme le
        // coupable au lieu de laisser un segment de memoire par terre.
        auto verifierSorties = [&nom](std::vector<Valeur>& sorties) {
            for (const Valeur& v : sorties) {
                if (v.classe == Classe::Cellule || v.classe == Classe::Structure ||
                    v.classe == Classe::Objet || v.classe == Classe::Chaine ||
                    v.classe == Classe::Fonction)
                    continue;
                if (v.estCreux()) continue;
                if (v.re.size() < v.nelem())
                    erreur("MatLibre:sortieIncoherente",
                           formater("La fonction '%s' a rendu un tableau %s annonce a %zu "
                                    "element(s) mais n'en portant que %zu. C'est un defaut "
                                    "de MatLibre : signalez-le.",
                                    nom.c_str(), texteDims(v.dims).c_str(), v.nelem(),
                                    v.re.size()));
            }
        };

        // Le nom de la native qui echoue est ce que MATLAB imprime en
        // tete de son rapport : « Error using double ». Le try/catch ne
        // coute rien tant que rien n'est leve.
        //
        // Sauf pour « error » et sa famille : l'erreur qu'elles levent
        // n'est pas la leur, elle appartient a la fonction qui les
        // appelle. MATLAB ecrit « Error using sim », jamais « Error
        // using error ».
        static const std::set<std::string> porteParole = {
            "error", "rethrow", "throw", "throwAsCaller", "MException", "assert_"};
        if (!profil.actif) {
            try {
                auto r = it->second.fonction(*this, args, nargout);
                verifierSorties(r);
                return r;
            } catch (ErreurMatlab& e) {
                if (e.fonctionNative.empty() && e.pile.empty() && !porteParole.count(nom))
                    e.fonctionNative = nom;
                throw;
            }
        }
        profil.entrerAppel(nom);
        try {
            auto r = it->second.fonction(*this, args, nargout);
            verifierSorties(r);
            profil.sortirAppel(nom);
            return r;
        } catch (ErreurMatlab& e) {
            profil.sortirAppel(nom);
            if (e.fonctionNative.empty() && e.pile.empty() && !porteParole.count(nom))
                e.fonctionNative = nom;
            throw;
        } catch (...) {
            profil.sortirAppel(nom);
            throw;
        }
    }
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
    if (f.genre == Fonction::Utilisateur) {
        if (f.porteeEnglobante) englobanteEnAttente_ = f.porteeEnglobante;
        return appelerUtilisateur(f.utilisateur, args, nargout);
    }
    // Fonction anonyme : la capture forme la portée, les paramètres par-dessus.
    auto portee = std::make_shared<Portee>();
    portee->nomFonction = "@anonyme";
    portee->fonction = f.contexte;
    portee->englobante = f.porteeEnglobante;
    portee->anonyme = true;
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
    portee->nomsEntrees = std::move(nomsArgumentsAppel_);
    nomsArgumentsAppel_.clear();
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
    // Un script s'exécute dans l'espace de travail de l'appelant : les
    // variables qu'il crée y restent après lui. C'est ce qui distingue un
    // script d'une fonction, et ce qui fait qu'on peut écrire un fichier
    // dans l'éditeur, l'exécuter, et retrouver ses variables.
    if (f->script) {
        if (!args.empty())
            erreur("MATLAB:scriptNotAFunction",
                   "Attempt to execute SCRIPT " + f->nom + " as a function:\n" + f->fichier);
        std::string precedent = fichierCourant;
        fichierCourant = f->fichier;
        struct Restaurer {
            std::string& cible;
            std::string valeur;
            ~Restaurer() { cible = valeur; }
        } restaurer{fichierCourant, precedent};
        GardeCadre cadre(*this, f->nom, f->fichier);
        // « return » dans un script rend la main a ce qui l'a lance : il
        // arrete le script, il ne quitte pas la fonction appelante.
        try {
            executerBloc(f->corps);
        } catch (RetourFonction&) {
        } catch (ErreurMatlab& e) {
            e.pile.push_back(cadres.back());
            throw;
        }
        return {};
    }
    std::size_t fixes = f->entrees.size();
    if (f->variadiqueEntree()) fixes -= 1;
    if (!f->variadiqueEntree() && args.size() > f->entrees.size())
        erreur("MATLAB:TooManyInputs",
               "Too many input arguments to function '" + f->nom + "'.");
    auto portee = std::make_shared<Portee>();
    portee->nomFonction = f->nom;
    portee->fonction = f;
    if (f->imbriquee) {
        portee->englobante = englobanteEnAttente_;
        englobanteEnAttente_.reset();
    } else {
        englobanteEnAttente_.reset();
    }
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
    portee->nomsEntrees = std::move(nomsArgumentsAppel_);
    nomsArgumentsAppel_.clear();
    GardePortee garde(*this, portee);
    GardeCadre cadre(*this, f->nom, f->fichier);
    if (profil.actif) profil.entrerAppel(f->nom);
    try {
        executerBloc(f->corps);
    } catch (RetourFonction&) {
    } catch (ErreurMatlab& e) {
        if (profil.actif) profil.sortirAppel(f->nom);
        e.pile.push_back(cadres.back());
        throw;
    } catch (...) {
        if (profil.actif) profil.sortirAppel(f->nom);
        throw;
    }
    if (profil.actif) profil.sortirAppel(f->nom);
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
    // Le drapeau d'interruption est propre au fil : on le suit ici, dans
    // celui qui va executer, pour que « verifierInterruption » lise bien
    // le notre. On ne l'efface pas : c'est a l'hote — la console, le
    // bureau — de le faire au debut de chaque commande.
    suivreInterruption();
    UniteCompilee u = compiler(source, origine);
    for (auto& c : u.classes) {
        relierClasse(c, u.fonctions);
        cacheClasses_[c->nom] = c;
    }
    if (!u.fonctions.empty()) {
        std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
        for (auto& f : u.fonctions) voisines[f->nom] = f;
        for (auto& f : u.fonctions) propagerVoisines(f, voisines);
        if (piles_.back()->fonction) {
            for (auto& kv : voisines) piles_.back()->fonction->voisines[kv.first] = kv.second;
        } else {
            for (auto& kv : voisines) cacheFonctions_[kv.first] = kv.second;
        }
    }
    if (u.script) {
        // Un « return » au plus haut niveau — comme l'abandon du debogueur,
        // qui se sert du meme signal — arrete le script et rien de plus :
        // il n'y a pas de fonction a quitter. Sans cela l'exception
        // traverserait l'appelant, et jusqu'a la boucle d'evenements d'une
        // interface, ou Qt ne pardonne pas.
        try {
            executerBloc(u.script);
        } catch (RetourFonction&) {
            if (profondeur() > 1) throw;
        }
    }
}

void Interpreteur::executerFichier(const std::string& fichier) {
    suivreInterruption();
    std::string source = lireFichier(fichier);
    // mfilename doit pouvoir nommer le fichier en cours d'exécution.
    std::string precedent = fichierCourant;
    fichierCourant = fichier;
    struct Restaurer {
        std::string& cible;
        std::string valeur;
        ~Restaurer() { cible = valeur; }
    } restaurer{fichierCourant, precedent};
    GardeCadre cadre(*this, "<script>", fichier);
    UniteCompilee u = compiler(source, fichier);
    for (auto& c : u.classes) cacheClasses_[c->nom] = c;
    for (auto& c : u.classes) relierClasse(c, u.fonctions);
    std::map<std::string, std::shared_ptr<FonctionUtilisateur>> voisines;
    for (auto& f : u.fonctions) {
        f->fichier = fichier;
        voisines[f->nom] = f;
    }
    for (auto& f : u.fonctions) propagerVoisines(f, voisines);
    if (u.script) {
        auto portee = piles_.back();
        if (!voisines.empty()) {
            auto enveloppe = std::make_shared<FonctionUtilisateur>();
            enveloppe->nom = "<script>";
            enveloppe->fichier = fichier;
            enveloppe->voisines = voisines;
            portee->fonction = enveloppe;
        }
        // Meme raison que dans executerTexte : au plus haut niveau, un
        // « return » arrete le script sans remonter plus loin.
        try {
            executerBloc(u.script);
        } catch (RetourFonction&) {
            if (profondeur() > 1) throw;
        } catch (ErreurMatlab& e) {
            e.pile.push_back(cadres.back());
            throw;
        }
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

// Positions désignées par une cible « c{...} » quand elle en désigne
// plusieurs. Rend une liste vide si la cible ne consomme qu'une sortie —
// c'est le cas ordinaire.
std::vector<std::size_t> Interpreteur::ciblesCellule(const NoeudPtr& cible) {
    std::vector<std::size_t> vide;
    if (!cible || cible->type != TypeN::Acces || cible->acces.size() != 1) return vide;
    const NoeudPtr& base = cible->enfants[0];
    if (base->type != TypeN::Ident) return vide;
    const Valeur* p = trouverVariable(base->texte);
    if (cible->acces[0].genre == '.') {
        if (!p) return vide;
        // « [s.champ] = deal(...) » : autant de sorties que d'éléments du
        // tableau de structures.
        if (p->classe != Classe::Structure || p->nelem() <= 1) return vide;
        std::vector<std::size_t> toutes;
        for (std::size_t k = 1; k <= p->nelem(); ++k) toutes.push_back(k);
        return toutes;
    }
    if (cible->acces[0].genre != '{') return vide;
    // La cellule peut ne pas exister encore : « [varargout{1:nargout}] = f() »
    // la cree. Seul « c{:} » a besoin qu'elle existe, puisque le nombre de
    // cibles vient alors de sa taille.
    if (p && p->classe != Classe::Cellule) return vide;
    const auto& args = cible->acces[0].args;
    if (args.size() != 1) return vide;
    std::vector<std::size_t> positions;
    if (args[0] && args[0]->type == TypeN::DeuxPointsSeul) {
        if (!p) return vide;
        for (std::size_t k = 1; k <= p->nelem(); ++k) positions.push_back(k);
    } else {
        // L'indice est évalué hors du contexte d'indexation : un « end »
        // ne s'y résout pas. Dans ce cas on retombe sur une cible simple,
        // ce qui est le comportement d'avant.
        Valeur idx;
        try {
            idx = evaluer(args[0]);
        } catch (...) {
            return vide;
        }
        if (idx.classe == Classe::Logique) {
            for (std::size_t k = 0; k < idx.nelem(); ++k)
                if (idx.re[k] != 0) positions.push_back(k + 1);
        } else {
            for (std::size_t k = 0; k < idx.nelem(); ++k)
                positions.push_back((std::size_t)idx.re[k]);
        }
    }
    if (positions.size() <= 1) return vide;
    return positions;
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
    if (courante.classe == Classe::Objet && !cible->acces.empty()) {
        if (estCarte(courante) && cible->acces.size() == 1 && cible->acces[0].genre == '(') {
            auto args = evaluerListe(cible->acces[0].args);
            if (args.size() != 1)
                erreur("MATLAB:Map:invalidKeyType",
                       "Specify a single key when writing to a Map.");
            ecrireCarte(courante, args[0], v);
            return;
        }
        auto def = classeDe(courante);
        if (def && def->aMethode("subsasgn") && !dansMethodeDe(courante.nomObjet)) {
            Valeur s = substruct(cible->acces, 0, &courante);
            auto r = appelerMethode(courante, "subsasgn", {s, v}, 1);
            if (!r.empty()) {
                Valeur o = r[0];
                o.classe = Classe::Objet;
                o.nomObjet = courante.nomObjet;
                o.poigneeObjet = courante.poigneeObjet;
                ecrireVariable(nom, std::move(o));
            }
            return;
        }
        if (cible->acces.size() == 1 &&
            (cible->acces[0].genre == '.' || cible->acces[0].genre == '?')) {
            std::string champ = cible->acces[0].nom;
            if (cible->acces[0].genre == '?') {
                auto args = evaluerListe(cible->acces[0].args);
                if (!args.empty()) champ = args[0].versTexte();
            }
            ecrireVariable(nom, ecrireProprieteObjet(std::move(courante), champ, v));
            return;
        }
    }
    Valeur nouvelle = affecterIndex(std::move(courante), cible->acces, 0, v, false);
    ecrireVariable(nom, std::move(nouvelle));
}

void Interpreteur::executerInstruction(const NoeudPtr& n) {
    if (!n) return;
    // Ctrl-C : un test de booléen atomique par instruction. C'est ce qui
    // permet de sortir d'une boucle qui ne finit pas, et de couper
    // l'affichage d'un tableau énorme.
    verifierInterruption();
    // Ou l'on en est : une ecriture d'entier, pour que le message d'erreur
    // puisse nommer la ligne.
    if (n->ligne > 0 && !cadres.empty()) cadres.back().ligne = n->ligne;
    // Profileur et débogueur : deux tests de booléen quand ils sont éteints.
    if (profil.actif) profil.compterLigne(fichierExecute(), n->ligne);
    if ((debogueur.actif || debogueur.action != ActionDebogueur::Continuer) &&
        crochetArret && n->ligne > 0) {
        std::string fichier = fichierExecute();
        if (debogueur.doitArreter(fichier, n->ligne, profondeur())) {
            debogueur.enPause = true;
            debogueur.fichierCourant = fichier;
            debogueur.ligneCourante = n->ligne;
            crochetArret(*this, fichier, n->ligne);
            debogueur.enPause = false;
            if (debogueur.action == ActionDebogueur::Quitter)
                throw RetourFonction{};
        }
    }
    switch (n->type) {
        case TypeN::Rien:
            return;
        case TypeN::Bloc:
            // Un bloc marqué « spmd » part sur tous les travailleurs ; les
            // variables qu'il écrit reviennent en Composite.
            if (n->texte == "spmd" && executerSpmd(*this, n)) return;
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
            // « [c{:}] = deal(...) » n'a qu'une cible écrite, mais elle en
            // désigne plusieurs : ce cas passe par le chemin général.
            bool cibleEclatee = n->cibles.size() == 1 && !suppression &&
                                !ciblesCellule(n->cibles[0]).empty();
            if (n->cibles.size() == 1 && !cibleEclatee) {
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
            // Une cible « c{...} » peut désigner plusieurs éléments : elle
            // consomme alors autant de sorties, ce qui rend possible le
            // « [c{:}] = deal(...) » de MATLAB.
            std::vector<std::vector<std::size_t>> multiples(n->cibles.size());
            std::size_t total = 0;
            bool aMultiple = false;
            for (std::size_t k = 0; k < n->cibles.size(); ++k) {
                multiples[k] = ciblesCellule(n->cibles[k]);
                if (multiples[k].empty()) {
                    total += 1;
                } else {
                    total += multiples[k].size();
                    aMultiple = true;
                }
            }
            std::vector<Valeur> r = evaluerMulti(n->enfants[0], (int)total);
            if (r.size() < total)
                erreur("MATLAB:TooManyOutputs",
                       "Insufficient number of outputs from right hand side of equal "
                       "sign to satisfy assignment.");
            if (!aMultiple) {
                for (std::size_t k = 0; k < n->cibles.size(); ++k) affecter(n->cibles[k], r[k]);
            } else {
                std::size_t pris = 0;
                for (std::size_t k = 0; k < n->cibles.size(); ++k) {
                    if (multiples[k].empty()) {
                        affecter(n->cibles[k], r[pris++]);
                        continue;
                    }
                    const std::string& nom = n->cibles[k]->enfants[0]->texte;
                    // « varargout » n'existe pas encore au moment ou on
                    // l'ecrit : la cellule se cree ici.
                    Valeur courante = existeVariable(nom) ? lireVariable(nom)
                                                          : Valeur::celluleLigne({});
                    if (n->cibles[k]->acces[0].genre == '.') {
                        const std::string& champ = n->cibles[k]->acces[0].nom;
                        courante.detacherStructure();
                        auto trouve = courante.st->champs.find(champ);
                        if (trouve == courante.st->champs.end()) {
                            courante.st->ordre.push_back(champ);
                            courante.st->champs[champ] =
                                std::vector<Valeur>(courante.nelem(), Valeur::vide());
                            trouve = courante.st->champs.find(champ);
                        }
                        for (std::size_t position : multiples[k])
                            trouve->second[position - 1] = r[pris++];
                    } else {
                        for (std::size_t position : multiples[k]) {
                            std::vector<Valeur> un{Valeur::scalaire((double)position)};
                            courante = ecrireIndex(std::move(courante), un, r[pris++], '{');
                        }
                    }
                    ecrireVariable(nom, std::move(courante));
                }
            }
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
            // « for k = 1:1e9 » ne doit rien allouer : MATLAB parcourt un
            // intervalle sans le construire, et c'est ce qui permet
            // d'ecrire une boucle d'un milliard de tours. Construire le
            // vecteur demanderait ici seize gigaoctets — et le programme
            // se faisait tuer par le systeme avant meme d'entrer dans la
            // boucle.
            if (!n->drapeau && n->enfants[0] && n->enfants[0]->type == TypeN::Plage &&
                n->cibles.size() == 1 && n->cibles[0]->type == TypeN::Ident) {
                Valeur d = evaluer(n->enfants[0]->enfants[0]);
                Valeur p = n->enfants[0]->enfants[1] ? evaluer(n->enfants[0]->enfants[1])
                                                     : Valeur::scalaire(1.0);
                Valeur f = evaluer(n->enfants[0]->enfants[2]);
                if (d.estScalaire() && p.estScalaire() && f.estScalaire() &&
                    d.estNumerique() && p.estNumerique() && f.estNumerique() &&
                    !d.estComplexe() && !p.estComplexe() && !f.estComplexe()) {
                    double a = d.re[0], pas = p.re[0], b = f.re[0];
                    // Le nombre de tours, calcule comme le fait MATLAB :
                    // une seule multiplication, pas une accumulation qui
                    // deriverait sur les flottants.
                    long long tours = 0;
                    if (pas != 0 && std::isfinite(a) && std::isfinite(pas) &&
                        std::isfinite(b))
                        tours = (long long)std::floor((b - a) / pas + 1e-10) + 1;
                    if (tours < 0) tours = 0;
                    const std::string& nomBoucle = n->cibles[0]->texte;
                    for (long long j = 0; j < tours; ++j) {
                        verifierInterruption();
                        ecrireVariable(nomBoucle, Valeur::scalaire(a + (double)j * pas));
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
            }
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
            // parfor : on tente le pool de travailleurs. Si le corps n'est
            // pas classable (variables ni en tranches ni réduites), on
            // retombe sur la boucle séquentielle, dont le résultat est le
            // même.
            if (n->drapeau && lignes == 1 && n->cibles[0]->type == TypeN::Ident &&
                plage.classe != Classe::Cellule && !plage.estStructure()) {
                std::vector<Valeur> iterations;
                iterations.reserve(colonnes);
                for (std::size_t j = 0; j < colonnes; ++j)
                    iterations.push_back(extraireElement(plage, j));
                PlanParfor plan = analyserParfor(n, n->cibles[0]->texte, *this);
                if (plan.utilisable &&
                    executerParforParallele(*this, n, iterations, plan)) {
                    // La variable de boucle garde sa dernière valeur, comme
                    // après une boucle ordinaire.
                    if (!iterations.empty())
                        ecrireVariable(n->cibles[0]->texte, iterations.back());
                    return;
                }
            }
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
                // « err.stack » de MATLAB : un cadre par appel traverse, du
                // plus profond au plus haut, avec son fichier et sa ligne.
                Valeur pile = Valeur::structureVide();
                pile.st = std::make_shared<ChampsStructure>();
                pile.st->ordre = {"file", "name", "line"};
                std::size_t cadresErreur = e.pile.size();
                pile.dims = {1, (int)std::max<std::size_t>(cadresErreur, 1)};
                for (const auto& champ : pile.st->ordre)
                    pile.st->champs[champ] =
                        std::vector<Valeur>(std::max<std::size_t>(cadresErreur, 1),
                                            Valeur::vide());
                if (cadresErreur == 0) {
                    pile.st->champs["file"][0] = Valeur::texte("");
                    pile.st->champs["name"][0] = Valeur::texte(portee().nomFonction);
                    pile.st->champs["line"][0] = Valeur::scalaire(n->ligne);
                } else {
                    for (std::size_t k = 0; k < cadresErreur; ++k) {
                        pile.st->champs["file"][k] = Valeur::texte(e.pile[k].fichier);
                        pile.st->champs["name"][k] = Valeur::texte(e.pile[k].nom);
                        pile.st->champs["line"][k] = Valeur::scalaire(e.pile[k].ligne);
                    }
                }
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
        case TypeN::OpPostfixe: {
            Valeur a = evaluer(n->enfants[0]);
            // Une classe peut définir transpose et ctranspose.
            if (a.classe == Classe::Objet && !estCarte(a)) {
                const char* methode = n->texte == "'" ? "ctranspose" : "transpose";
                auto def = classeDe(a);
                if (def && def->aMethode(methode)) {
                    auto r = appelerMethode(a, methode, {}, 1);
                    if (!r.empty()) return r[0];
                }
            }
            return transposer(a, n->texte == "'");
        }
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
        } else if (!n->acces.empty() && n->acces[0].genre == '.' &&
                   nomPointe(nom, n->acces) > 0) {
            // Nom pointé, comme « containers.Map » ou
            // « matlab.lang.makeValidName » : les premiers accès font partie
            // du nom de la fonction. On retient le plus long qui existe.
            std::size_t segments = nomPointe(nom, n->acces);
            std::string compose = nom;
            for (std::size_t k = 0; k < segments; ++k) compose += "." + n->acces[k].nom;
            std::vector<Valeur> args;
            debut = segments;
            if (n->acces.size() > segments && n->acces[segments].genre == '(') {
                args = evaluerListe(n->acces[segments].args);
                debut = segments + 1;
            }
            courant = appeler(compose, args,
                              debut < n->acces.size() ? 1 : std::max(nargout, 1));
        } else if (!n->acces.empty() && n->acces[0].genre == '.' &&
                   n->acces[0].nom == "empty" && classeVide(nom) &&
                   !(classeDefinie(nom) && classeDefinie(nom)->aMethode("empty"))) {
            // « double.empty(0,3) », « MaClasse.empty » : le tableau vide
            // de la classe. C'est la seule methode statique que MATLAB
            // donne a toute classe, y compris aux classes fondamentales.
            Dims d = {0, 0};
            debut = 1;
            if (n->acces.size() > 1 && n->acces[1].genre == '(') {
                auto args = evaluerListe(n->acces[1].args);
                d.clear();
                if (args.size() == 1 && args[0].nelem() > 1) {
                    for (double x : args[0].re) d.push_back(std::max(0, (int)x));
                } else {
                    for (const auto& a : args) d.push_back(std::max(0, (int)a.scal()));
                }
                while (d.size() < 2) d.push_back(d.empty() ? 0 : d[0]);
                debut = 2;
            }
            bool aZero = false;
            for (int x : d) aZero = aZero || x == 0;
            if (!aZero)
                erreur("MATLAB:class:emptyMustBeZero",
                       "At least one dimension must be zero for 'empty'.");
            courant.push_back(valeurVideDeClasse(nom, d));
        } else if (!n->acces.empty() && n->acces[0].genre == '.' && classeDefinie(nom)) {
            // Méthode statique ou propriété constante d'une classe.
            auto def = classeDefinie(nom);
            const std::string& membre = n->acces[0].nom;
            if (def->aMethode(membre)) {
                std::vector<Valeur> args;
                debut = 1;
                if (n->acces.size() > 1 && n->acces[1].genre == '(') {
                    args = evaluerListe(n->acces[1].args);
                    debut = 2;
                }
                courant = appelerUtilisateur(def->methodes[membre], args,
                                             debut < n->acces.size() ? 1
                                                                     : std::max(nargout, 1));
            } else {
                auto itd = def->defauts.find(membre);
                if (itd == def->defauts.end() || !itd->second)
                    erreur("MATLAB:noSuchMethodOrField",
                           "Unrecognized method or property '" + membre + "' for class '" +
                               nom + "'.");
                courant.push_back(evaluer(itd->second));
                debut = 1;
            }
        } else {
            // Fonction : les arguments du premier accès sont ses paramètres.
            int demandees = nargout < 0 ? 1 : nargout;
            if (!n->acces.empty() && n->acces[0].genre == '(') {
                auto args = evaluerListe(n->acces[0].args);
                // Les noms des arguments qui sont de simples variables :
                // « inputname » les rend, « display » s'en sert.
                std::vector<std::string> noms;
                for (const NoeudPtr& a : n->acces[0].args)
                    noms.push_back(a && a->type == TypeN::Ident ? a->texte : std::string());
                poserNomsArguments(std::move(noms));
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
        bool chaineConsommee = false;
        for (const Valeur& base : courant) {
            if (base.classe == Classe::Objet) {
                // « m.isKey('a') », « m.remove('a') » : l'appel de methode
                // au point, que MATLAB accepte sur containers.Map comme
                // sur toute classe.
                if (estCarte(base) && e.genre == '.' && k + 1 < n->acces.size() &&
                    n->acces[k + 1].genre == '(') {
                    static const std::set<std::string> methodes = {
                        "isKey", "remove", "keys", "values", "length", "Count"};
                    if (methodes.count(e.nom)) {
                        std::vector<Valeur> args = {base};
                        for (Valeur& a : evaluerListe(n->acces[k + 1].args))
                            args.push_back(std::move(a));
                        auto r = appeler(e.nom, args, std::max(nargout, 1));
                        for (auto& x : r) suivant.push_back(x);
                        ++k;   // le « ( » vient d'etre consomme
                        dernier = (k + 1 == n->acces.size());
                        continue;
                    }
                }
                if (estCarte(base) && e.genre == '(') {
                    auto args = evaluerListe(e.args);
                    if (args.size() != 1)
                        erreur("MATLAB:Map:invalidKeyType",
                               "Specify a single key when reading from a Map.");
                    suivant.push_back(lireCarte(base, args[0]));
                    continue;
                }
                auto def = classeDe(base);
                if (def && def->aMethode("subsref") && !dansMethodeDe(base.nomObjet)) {
                    // La classe prend en charge toute la chaîne restante,
                    // comme le veut la documentation de subsref.
                    Valeur s = substruct(n->acces, k, &base);
                    auto r = appelerMethode(base, "subsref", {s}, std::max(nargout, 1));
                    for (auto& x : r) suivant.push_back(x);
                    chaineConsommee = true;
                    continue;
                }
            }
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
                if (base.classe == Classe::Objet) {
                    suivant.push_back(lireProprieteObjet(base, nom));
                    continue;
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
        if (chaineConsommee) break;
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
            if (base->classe == Classe::Objet) {
                // Une classe peut définir « end », comme le prévoit la
                // documentation ; sinon on interroge sa taille.
                Valeur copie = *base;
                auto def = classeDe(copie);
                if (def && def->aMethode("end")) {
                    auto r = appelerMethode(copie, "end",
                                            {Valeur::scalaire(position + 1),
                                             Valeur::scalaire(total)}, 1);
                    if (!r.empty()) return {r[0]};
                }
                if (def && def->aMethode("size")) {
                    auto r = appelerMethode(copie, "size", {}, 1);
                    if (!r.empty() && r[0].nelem() > (std::size_t)position) {
                        if (total == 1) {
                            double n2 = 1;
                            for (std::size_t d = 0; d < r[0].nelem(); ++d) n2 *= r[0].re[d];
                            return {Valeur::scalaire(n2)};
                        }
                        return {Valeur::scalaire(r[0].re[(std::size_t)position])};
                    }
                }
                if (estCarte(copie))
                    return {Valeur::scalaire((double)carteDe(copie)->ordre.size())};
            }
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
            // Une classe peut définir transpose et ctranspose : « x.' » et
            // « x' » passent alors par elles.
            if (a.classe == Classe::Objet && !estCarte(a)) {
                const char* methode = n->texte == "'" ? "ctranspose" : "transpose";
                auto def = classeDe(a);
                if (def && def->aMethode(methode)) {
                    auto r = appelerMethode(a, methode, {}, 1);
                    if (!r.empty()) return {r[0]};
                }
            }
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
            return {concatenerObjets(rangees)};
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
            // Si la fonction courante a des imbriquées, ou en est une, la
            // poignée garde sa portée : le rappel appelé plus tard y
            // retrouvera les variables partagées.
            if (portee().fonction &&
                (!portee().fonction->imbriquees.empty() || portee().fonction->imbriquee))
                f->porteeEnglobante = piles_.back();
            f->texte = texteExpression(n);
            return {Valeur::poignee(f)};
        }
        case TypeN::PoigneeNom: {
            auto f = resoudrePoignee(n->texte);
            f->texte = "@" + n->texte;
            if (portee().fonction &&
                (!portee().fonction->imbriquees.empty() || portee().fonction->imbriquee))
                f->porteeEnglobante = piles_.back();
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
