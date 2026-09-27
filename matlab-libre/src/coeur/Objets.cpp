// Objets.cpp — classes définies par l'utilisateur et tables associatives.
//
// Trois mécanismes du langage sont regroupés ici :
//   - la résolution des méthodes et des accesseurs d'une classe ;
//   - la construction de la structure « substruct » que reçoivent subsref
//     et subsasgn, telle que la documente MathWorks ;
//   - les tables « containers.Map », dont l'état vit dans l'interpréteur
//     pour leur donner la sémantique de poignée.
#include <functional>
#include <algorithm>
#include <cmath>
#include <map>
#include <memory>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {

std::shared_ptr<DefinitionClasse> Interpreteur::classeDe(const Valeur& v) {
    if (v.classe != Classe::Objet || v.nomObjet.empty()) return nullptr;
    return classeDefinie(v.nomObjet);
}

bool Interpreteur::classePossede(const Valeur& v, const std::string& methode) {
    auto def = classeDe(v);
    return def && def->aMethode(methode);
}

bool Interpreteur::dansMethodeDe(const std::string& classe) const {
    if (classe.empty()) return false;
    for (auto it = piles_.rbegin(); it != piles_.rend(); ++it) {
        const auto& p = *it;
        if (!p || !p->fonction) continue;
        return p->fonction->classeProprietaire == classe;
    }
    return false;
}

// Dans son propre accesseur, une propriété se lit et s'écrit directement :
// « obj.X = v » dans set.X ne rappelle pas set.X, « obj.X » dans get.X ne
// rappelle pas get.X — sans quoi l'accesseur s'appellerait sans fin.
bool Interpreteur::dansAccesseur(const std::string& accesseur) const {
    for (auto it = piles_.rbegin(); it != piles_.rend(); ++it) {
        const auto& p = *it;
        if (!p || !p->fonction) continue;
        return p->fonction->nom == accesseur;
    }
    return false;
}

std::vector<Valeur> Interpreteur::appelerMethode(const Valeur& objet,
                                                 const std::string& methode,
                                                 std::vector<Valeur> args, int nargout) {
    auto def = classeDe(objet);
    if (!def || !def->aMethode(methode))
        erreur("MATLAB:noSuchMethodOrField",
               "Unrecognized method '" + methode + "' for class '" + objet.nomObjet + "'.");
    std::vector<Valeur> complet;
    if (!def->estStatique(methode)) complet.push_back(objet);
    for (auto& a : args) complet.push_back(a);
    return appelerUtilisateur(def->methodes[methode], complet, nargout);
}

// Vrai si l'expression porte un « end » quelque part : c'est la seule
// raison de refaire le chemin d'accès pour trouver le contexte.
static bool contientFin(const NoeudPtr& n) {
    if (!n) return false;
    if (n->type == TypeN::FinIndice) return true;
    for (const NoeudPtr& enfant : n->enfants)
        if (contientFin(enfant)) return true;
    for (const ElementAcces& e : n->acces)
        for (const NoeudPtr& a : e.args)
            if (contientFin(a)) return true;
    return false;
}

static bool contientFin(const std::vector<NoeudPtr>& args) {
    for (const NoeudPtr& a : args)
        if (contientFin(a)) return true;
    return false;
}

// Ce que vaut la chaîne d'accès jusqu'à un certain rang, en indexation par
// défaut. Rend faux si le chemin ne se refait pas — une méthode au point,
// par exemple : « end » retombe alors sur ce qu'il avait avant.
bool Interpreteur::valeurIntermediaire(const Valeur& base,
                                       const std::vector<ElementAcces>& chaine,
                                       std::size_t debut, std::size_t fin, Valeur& sortie) {
    Valeur courant = base;
    try {
        for (std::size_t k = debut; k < fin; ++k) {
            const ElementAcces& e = chaine[k];
            if (e.genre == '.' || e.genre == '?') {
                std::string nom = e.nom;
                if (e.genre == '?') {
                    auto args = evaluerListe(e.args);
                    if (args.empty()) return false;
                    nom = args[0].versTexte();
                }
                if (courant.classe == Classe::Objet) {
                    // Une classe qui définit subsref décide elle-même de
                    // ce que « .nom » désigne : timetable rend ses
                    // instants sous « .Time » sans porter de propriété de
                    // ce nom. Sans passer par là, « S.Time(end) » ne
                    // trouvait pas la bonne longueur et « end » retombait
                    // sur la taille de l'objet entier.
                    auto def = classeDefinie(courant.nomObjet);
                    if (def && def->aMethode("subsref") && !dansMethodeDe(courant.nomObjet)) {
                        std::vector<ElementAcces> pas(1);
                        pas[0].genre = '.';
                        pas[0].nom = nom;
                        Valeur s = substruct(pas, 0, &courant);
                        auto r = appelerMethode(courant, "subsref", {s}, 1);
                        if (r.empty()) return false;
                        courant = r[0];
                    } else {
                        courant = lireProprieteObjet(courant, nom);
                    }
                } else if (courant.estStructure())
                    courant = courant.champ(nom);
                else
                    return false;
                continue;
            }
            auto idx = evaluerIndices(e.args, &courant, 0, (int)e.args.size());
            courant = indexer(courant, idx, e.genre);
        }
    } catch (...) {
        return false;
    }
    sortie = courant;
    return true;
}

// La structure attendue par subsref : un tableau 1xN de champs « type » et
// « subs ». type vaut '()', '{}' ou '.', subs une cellule d'indices ou le
// nom du champ.
Valeur Interpreteur::substruct(const std::vector<ElementAcces>& chaine, std::size_t debut,
                               const Valeur* base) {
    std::size_t n = chaine.size() - debut;
    Valeur s;
    s.classe = Classe::Structure;
    s.dims = {1, (int)n};
    s.st = std::make_shared<ChampsStructure>();
    s.st->ordre = {"type", "subs"};
    s.st->champs["type"] = std::vector<Valeur>(n, Valeur::vide());
    s.st->champs["subs"] = std::vector<Valeur>(n, Valeur::vide());
    for (std::size_t k = 0; k < n; ++k) {
        const ElementAcces& e = chaine[debut + k];
        if (e.genre == '.' || e.genre == '?') {
            std::string nom = e.nom;
            if (e.genre == '?') {
                auto args = evaluerListe(e.args);
                if (!args.empty()) nom = args[0].versTexte();
            }
            s.st->champs["type"][k] = Valeur::texte(".");
            s.st->champs["subs"][k] = Valeur::texte(nom);
        } else {
            // « end » se résout sur ce que vaut la chaîne à cet endroit :
            // dans « P.D(1:end) », c'est la taille de D, non celle de P.
            // Le premier élément a la base ; pour les suivants, on refait
            // le chemin en indexation par défaut, ce qui ne coûte que
            // lorsqu'un « end » l'exige.
            const Valeur* contexte = k == 0 ? base : nullptr;
            Valeur intermediaire;
            if (k > 0 && base && contientFin(e.args) &&
                valeurIntermediaire(*base, chaine, debut, debut + k, intermediaire))
                contexte = &intermediaire;
            auto idx = evaluerIndices(e.args, contexte, 0, (int)e.args.size());
            Valeur cellule = Valeur::celluleLigne(idx);
            s.st->champs["type"][k] = Valeur::texte(e.genre == '(' ? "()" : "{}");
            s.st->champs["subs"][k] = cellule;
        }
    }
    return s;
}

Valeur Interpreteur::lireProprieteObjet(const Valeur& objet, const std::string& nom) {
    if (crochetLirePropriete) {
        Valeur resultat;
        if (crochetLirePropriete(*this, objet, nom, resultat)) return resultat;
    }
    if (estCarte(objet)) {
        auto table = carteDe(objet);
        if (nom == "Count") return Valeur::scalaire((double)table->ordre.size());
        if (nom == "KeyType") return Valeur::texte(table->typeCle);
        if (nom == "ValueType") return Valeur::texte(table->typeValeur);
        if (nom == "keys" || nom == "values" || nom == "length") {
            std::vector<Valeur> args = {objet};
            auto r = appeler(nom, args, 1);
            return r.empty() ? Valeur::vide() : r[0];
        }
        erreur("MATLAB:noSuchMethodOrField",
               "Unrecognized property '" + nom + "' for class 'containers.Map'.");
    }
    auto def = classeDe(objet);
    if (def) {
        // Une propriété dépendante passe par son accesseur get.
        std::string accesseur = "get." + nom;
        if (def->aMethode(accesseur) && !dansAccesseur(accesseur)) {
            auto r = appelerMethode(objet, accesseur, {}, 1);
            return r.empty() ? Valeur::vide() : r[0];
        }
    }
    if (!objet.aChamp(nom))
        erreur("MATLAB:noSuchMethodOrField",
               "Unrecognized property '" + nom + "' for class '" + objet.nomObjet + "'.");
    return objet.champ(nom, 0);
}

// Poignées graphiques : « ax.XTick = [...] », « f.Name = '...' ». Elles ne
// sont pas des objets de classe MATLAB mais des références vers une figure
// et un axe, et leurs propriétés vivent dans la figure. Les deux crochets
// ci-dessous sont posés par la bibliothèque graphique.
std::function<bool(Interpreteur&, const Valeur&, const std::string&, const Valeur&)>
    crochetEcrirePropriete;
std::function<bool(Interpreteur&, const Valeur&, const std::string&, Valeur&)>
    crochetLirePropriete;
std::function<bool(Interpreteur&, const Valeur&)> crochetSupprimerGraphique;

static bool contientNom(const std::vector<std::string>& liste, const std::string& nom) {
    for (const auto& n : liste)
        if (n == nom) return true;
    return false;
}

Valeur Interpreteur::ecrireProprieteObjet(Valeur objet, const std::string& nom,
                                          const Valeur& valeur) {
    if (crochetEcrirePropriete && crochetEcrirePropriete(*this, objet, nom, valeur))
        return objet;
    auto def = classeDe(objet);
    if (def) {
        // Une classe dit quelles propriétés elle porte. En écrire une
        // autre ne la crée pas : elle serait posée sur l'objet et lue par
        // personne — le réglage aurait l'air pris et ne vaudrait rien.
        // C'est ainsi qu'« InputDelay » se posait sur un modèle LTI qui
        // l'ignorait. On refuse, en nommant la propriété et la classe.
        if (!estCarte(objet) && !def->ordreProprietes.empty() &&
            !contientNom(def->ordreProprietes, nom) &&
            !contientNom(def->dependantes, nom) && !def->aMethode("set." + nom)) {
            std::string liste;
            for (const auto& p : def->ordreProprietes) {
                if (!liste.empty()) liste += ", ";
                liste += p;
            }
            erreur("MATLAB:noPublicFieldForClass",
                   "Unrecognized property '" + nom + "' for class '" + objet.nomObjet +
                       "'. Declared properties: " + liste + ".");
        }
        std::string accesseur = "set." + nom;
        if (def->aMethode(accesseur) && !dansAccesseur(accesseur)) {
            auto r = appelerMethode(objet, accesseur, {valeur}, 1);
            if (!r.empty()) {
                Valeur o = r[0];
                o.classe = Classe::Objet;
                o.nomObjet = objet.nomObjet;
                o.poigneeObjet = objet.poigneeObjet;
                return o;
            }
            return objet;
        }
    }
    objet.poserChamp(nom, valeur, 0);
    return objet;
}

// ------------------------------------------------------- containers.Map

bool Interpreteur::estCarte(const Valeur& v) const {
    return v.classe == Classe::Objet && v.nomObjet == "containers.Map";
}

std::shared_ptr<CarteAssociative> Interpreteur::carteDe(const Valeur& v) {
    if (!estCarte(v)) erreur("MATLAB:Map:invalidHandle", "Not a containers.Map object.");
    long long id = (long long)v.champ("__id", 0).scal();
    auto it = cartes.find(id);
    if (it == cartes.end())
        erreur("MATLAB:Map:invalidHandle", "This containers.Map handle is no longer valid.");
    return it->second;
}

// Une clé de containers.Map est un texte ou un nombre ; on la ramène à une
// chaîne pour l'ordre, en gardant la valeur d'origine pour « keys ».
std::string Interpreteur::cleCanonique(const Valeur& cle) {
    if (cle.estTexte() || cle.estChaine()) return "s:" + cle.versTexte();
    if (cle.estNumerique() || cle.classe == Classe::Logique)
        return "n:" + formater("%.17g", cle.scal());
    erreur("MATLAB:Map:invalidKeyType",
           "Keys must be a character vector, a string, or a numeric scalar.");
}

Valeur Interpreteur::lireCarte(const Valeur& carte, const Valeur& cle) {
    auto table = carteDe(carte);
    std::string k = cleCanonique(cle);
    auto it = table->valeurs.find(k);
    if (it == table->valeurs.end())
        erreur("MATLAB:Containers:Map:NoKey",
               "The given key is not present in the container.");
    return it->second;
}

void Interpreteur::ecrireCarte(const Valeur& carte, const Valeur& cle, const Valeur& valeur) {
    auto table = carteDe(carte);
    std::string k = cleCanonique(cle);
    if (!table->valeurs.count(k)) {
        table->ordre.push_back(k);
        std::sort(table->ordre.begin(), table->ordre.end());
        table->clesOriginales[k] = cle;
    }
    table->valeurs[k] = valeur;
}

Valeur Interpreteur::creerCarte(std::shared_ptr<CarteAssociative> carte) {
    long long id = prochaineCarte++;
    cartes[id] = std::move(carte);
    Valeur v = Valeur::structureVide();
    v.classe = Classe::Objet;
    v.nomObjet = "containers.Map";
    v.poigneeObjet = true;
    v.poserChamp("__id", Valeur::scalaire((double)id));
    return v;
}


// --- les énumérations ---------------------------------------------------------

const std::string Interpreteur::champMembre = "\x01membre";
const std::string Interpreteur::champValeurEnum = "\x01valeur";

bool Interpreteur::estEnumeration(const Valeur& v) const {
    return v.classe == Classe::Objet && v.st && v.st->champs.count(champMembre) > 0;
}

// La classe numérique dont dérive une énumération : un parent fondamental
// — int32, uint8, double... —, ou celui d'un parent défini, comme
// Simulink.IntEnumType l'est d'int32.
bool Interpreteur::baseEnumeration(const std::shared_ptr<DefinitionClasse>& def, Classe& base) {
    for (const auto& nomParent : def->parents) {
        bool fondamentale = false;
        Classe c = classeDepuisNom(nomParent, &fondamentale);
        if (fondamentale && (classeNumerique(c) || c == Classe::Logique)) {
            base = c;
            return true;
        }
        auto parent = classeDefinie(nomParent);
        if (parent && parent.get() != def.get() && baseEnumeration(parent, base)) return true;
    }
    return false;
}

Valeur Interpreteur::membreEnumeration(const std::shared_ptr<DefinitionClasse>& def,
                                       const std::string& nom) {
    const std::string cle = def->nom + "." + nom;
    auto itc = cacheEnumerations_.find(cle);
    if (itc != cacheEnumerations_.end()) return itc->second;
    std::size_t i = 0;
    while (i < def->enumerations.size() && def->enumerations[i] != nom) ++i;
    if (i == def->enumerations.size())
        erreur("MATLAB:noSuchMethodOrField",
               "Unrecognized method or property '" + nom + "' for class '" + def->nom + "'.");
    std::vector<Valeur> args;
    if (i < def->argumentsEnumeration.size())
        for (const auto& a : def->argumentsEnumeration[i]) args.push_back(evaluer(a));
    Classe base = Classe::Double;
    Valeur membre;
    if (baseEnumeration(def, base)) {
        // une énumération entière : sa valeur est son seul argument
        if (args.size() != 1 || args[0].nelem() != 1 || !(args[0].estNumerique() ||
                                                           args[0].classe == Classe::Logique))
            erreur("MATLAB:class:InvalidEnumerationValue",
                   "Le membre '" + nom + "' de l'enumeration '" + def->nom +
                       "' doit porter une valeur numerique, entre parentheses : la classe "
                       "derive de " + nomClasse(base) + ".");
        membre = Valeur::structureVide();
        membre.classe = Classe::Objet;
        membre.nomObjet = def->nom;
        membre.poserChamp(champMembre, Valeur::texte(nom));
        membre.poserChamp(champValeurEnum, convertirValeurVers(args[0], base));
        for (const auto& p : def->ordreProprietes) {
            Valeur defaut = Valeur::vide();
            auto itd = def->defauts.find(p);
            if (itd != def->defauts.end() && itd->second) defaut = evaluer(itd->second);
            membre.poserChamp(p, defaut);
        }
    } else {
        // les arguments vont au constructeur, qui pose les propriétés
        bool avant = enConstructionEnumeration;
        enConstructionEnumeration = true;
        try {
            membre = construireObjet(*this, def, args);
        } catch (...) {
            enConstructionEnumeration = avant;
            throw;
        }
        enConstructionEnumeration = avant;
        membre.classe = Classe::Objet;
        membre.nomObjet = def->nom;
        membre.poserChamp(champMembre, Valeur::texte(nom));
    }
    cacheEnumerations_[cle] = membre;
    return membre;
}

Valeur Interpreteur::membresEnumeration(const std::shared_ptr<DefinitionClasse>& def) {
    std::vector<Valeur> membres;
    for (const auto& nom : def->enumerations) membres.push_back(membreEnumeration(def, nom));
    if (membres.empty()) return valeurVideDeClasse(def->nom, {0, 1});
    return concatener(membres, 0);
}

std::vector<std::string> Interpreteur::nomsMembres(const Valeur& v) const {
    std::vector<std::string> noms;
    for (std::size_t k = 0; k < v.nelem(); ++k) noms.push_back(v.champ(champMembre, k).versTexte());
    return noms;
}

// Les valeurs d'une énumération entière, dans sa classe de base.
Valeur Interpreteur::valeursEnumeration(const Valeur& v, const char* operation) {
    auto def = classeDefinie(v.nomObjet);
    Classe base = Classe::Double;
    if (!def || !baseEnumeration(def, base))
        erreur("MATLAB:UndefinedFunction",
               std::string("Undefined function '") + operation +
                   "' for input arguments of type '" + v.nomObjet + "'.");
    Valeur r = Valeur::matriceDims(v.dims);
    r.classe = base;
    for (std::size_t k = 0; k < v.nelem(); ++k) r.re[k] = v.champ(champValeurEnum, k).scal();
    return r;
}

Valeur Interpreteur::convertirEnEnumeration(const std::shared_ptr<DefinitionClasse>& def,
                                            const Valeur& v) {
    if (estEnumeration(v) && v.nomObjet == def->nom) return v;
    Classe base = Classe::Double;
    bool entiere = baseEnumeration(def, base);
    std::vector<Valeur> membres;
    Dims d = v.dims;
    if (v.classe == Classe::Caractere || v.classe == Classe::Chaine ||
        v.classe == Classe::Cellule) {
        std::vector<std::string> noms;
        if (v.classe == Classe::Caractere) {
            noms.push_back(v.versTexte());
            d = {1, 1};
        } else if (v.classe == Classe::Chaine) {
            noms = v.chaines;
        } else {
            for (const auto& c : v.cellules) noms.push_back(c.versTexte());
        }
        for (const auto& nom : noms) {
            bool connu = false;
            for (const auto& m : def->enumerations) connu = connu || m == nom;
            if (!connu)
                erreur("MATLAB:class:CannotConvert",
                       "'" + nom + "' n'est pas un membre de l'enumeration '" + def->nom + "'.");
            membres.push_back(membreEnumeration(def, nom));
        }
    } else if (entiere && (v.estNumerique() || v.classe == Classe::Logique)) {
        for (std::size_t k = 0; k < v.nelem(); ++k) {
            double x = v.re[k];
            bool trouve = false;
            for (const auto& nom : def->enumerations) {
                Valeur m = membreEnumeration(def, nom);
                if (m.champ(champValeurEnum).scal() == x) {
                    membres.push_back(m);
                    trouve = true;
                    break;
                }
            }
            if (!trouve)
                erreur("MATLAB:class:CannotConvert",
                       formater("Aucun membre de l'enumeration '%s' ne vaut %g.",
                                def->nom.c_str(), x));
        }
    } else {
        erreur("MATLAB:class:CannotConvert",
               "Une valeur de classe '" + v.classeNom() +
                   "' ne se convertit pas en membre de l'enumeration '" + def->nom + "'.");
    }
    if (membres.empty()) return valeurVideDeClasse(def->nom, d);
    Valeur r = concatener(membres, 1);
    r.dims = d;
    return r;
}

// Deux opérandes dont l'un au moins est un membre d'énumération. Deux
// membres d'une même classe se comparent par leur nom, un membre et un
// texte aussi ; une énumération entière calcule sur ses valeurs.
Valeur Interpreteur::operationEnumeration(const std::string& op, const Valeur& a,
                                          const Valeur& b) {
    const Valeur& e = estEnumeration(a) ? a : b;
    const Valeur& autre = estEnumeration(a) ? b : a;
    auto def = classeDefinie(e.nomObjet);
    const bool egalite = op == "==" || op == "~=" || op == "!=";
    auto estTexte = [](const Valeur& v) {
        return v.classe == Classe::Caractere || v.classe == Classe::Chaine ||
               v.classe == Classe::Cellule;
    };
    if (def && egalite && (estEnumeration(autre) || estTexte(autre))) {
        if (estEnumeration(autre) && autre.nomObjet != e.nomObjet)
            erreur("MATLAB:UndefinedFunction",
                   "Undefined function 'eq' for input arguments of type '" + a.nomObjet +
                       "' and '" + b.nomObjet + "'.");
        Valeur ea = estEnumeration(a) ? a : convertirEnEnumeration(def, a);
        Valeur eb = estEnumeration(b) ? b : convertirEnEnumeration(def, b);
        auto na = nomsMembres(ea), nb = nomsMembres(eb);
        std::size_t n = std::max(na.size(), nb.size());
        if (na.size() != nb.size() && na.size() != 1 && nb.size() != 1)
            erreur("MATLAB:dimagree", "Matrix dimensions must agree.");
        Valeur r = Valeur::matriceDims(na.size() >= nb.size() ? ea.dims : eb.dims);
        r.classe = Classe::Logique;
        for (std::size_t k = 0; k < n; ++k) {
            bool pareil = na[na.size() == 1 ? 0 : k] == nb[nb.size() == 1 ? 0 : k];
            r.re[k] = (pareil == (op == "==")) ? 1.0 : 0.0;
        }
        return r;
    }
    Valeur va = estEnumeration(a) ? valeursEnumeration(a, nomMethodeOperateur(op).c_str()) : a;
    Valeur vb = estEnumeration(b) ? valeursEnumeration(b, nomMethodeOperateur(op).c_str()) : b;
    if (va.classe == Classe::Objet || vb.classe == Classe::Objet)
        erreur("MATLAB:UndefinedFunction",
               "Undefined function '" + nomMethodeOperateur(op) +
                   "' for input arguments of type '" + e.nomObjet + "'.");
    return operationBinaire(op, va, vb);
}


bool Interpreteur::fonctionEnumeration(const std::string& nom, const std::vector<Valeur>& args,
                                       std::vector<Valeur>& resultat) {
    if (args.empty()) return false;
    const Valeur& e = args[0];
    if (nom == "isenum") {
        resultat = {Valeur::booleen(estEnumeration(e))};
        return true;
    }
    if (!estEnumeration(e)) {
        if (nom == "ismember" && args.size() >= 2 && estEnumeration(args[1])) {
            // un texte cherché parmi des membres : il devient membre
            auto def = classeDefinie(args[1].nomObjet);
            if (!def) return false;
            std::vector<Valeur> converti = args;
            converti[0] = convertirEnEnumeration(def, e);
            return fonctionEnumeration(nom, converti, resultat);
        }
        return false;
    }
    auto def = classeDefinie(e.nomObjet);
    if (!def) return false;
    const std::vector<std::string> noms = nomsMembres(e);
    if (nom == "char") {
        if (noms.size() == 1) {
            resultat = {Valeur::texte(noms[0])};
            return true;
        }
        std::size_t largeur = 0;
        for (const auto& n : noms) largeur = std::max(largeur, n.size());
        Valeur r = Valeur::matriceDims({(int)noms.size(), (int)largeur});
        r.classe = Classe::Caractere;
        for (std::size_t i = 0; i < noms.size(); ++i)
            for (std::size_t j = 0; j < largeur; ++j)
                r.re[i + j * noms.size()] =
                    j < noms[i].size() ? (double)(unsigned char)noms[i][j] : 32.0;
        resultat = {r};
        return true;
    }
    if (nom == "string") {
        Valeur r;
        r.classe = Classe::Chaine;
        r.dims = e.dims;
        r.chaines = noms;
        resultat = {r};
        return true;
    }
    if (nom == "cellstr") {
        Valeur r = Valeur::celluleDims(e.dims);
        for (std::size_t k = 0; k < noms.size(); ++k) r.cellules[k] = Valeur::texte(noms[k]);
        resultat = {r};
        return true;
    }
    bool fondamentale = false;
    Classe cible = classeDepuisNom(nom, &fondamentale);
    if (fondamentale && (classeNumerique(cible) || cible == Classe::Logique)) {
        Classe base = Classe::Double;
        if (!baseEnumeration(def, base))
            erreur("MATLAB:invalidConversion",
                   "Conversion to " + nom + " from " + e.nomObjet + " is not possible.");
        resultat = {convertirValeurVers(valeursEnumeration(e, nom.c_str()), cible)};
        return true;
    }
    if (nom == "isa" && args.size() >= 2) {
        const std::string demandee = args[1].versTexte();
        bool oui = demandee == e.nomObjet;
        for (const auto& a : def->ancetres) oui = oui || a == demandee;
        Classe base = Classe::Double;
        if (baseEnumeration(def, base)) {
            oui = oui || demandee == nomClasse(base) || demandee == "numeric" ||
                  (classeEntiere(base) && demandee == "integer") ||
                  ((base == Classe::Double || base == Classe::Simple) && demandee == "float");
            for (const auto& p : def->parents) oui = oui || p == demandee;
        }
        resultat = {Valeur::booleen(oui)};
        return true;
    }
    // sort, unique, max, min, flip... calculent sur les valeurs d'une
    // énumération entière — ou sur le rang des membres, pour UNIQUE et les
    // retournements d'une énumération sans valeurs —, puis les rendent membres
    static const std::map<std::string, int> parValeurs = {
        {"sort", 2}, {"unique", 3}, {"max", 2}, {"min", 2},
        {"flip", 1}, {"fliplr", 1}, {"flipud", 1}};
    auto itv = parValeurs.find(nom);
    if (itv != parValeurs.end()) {
        Classe base = Classe::Double;
        const bool entiere = baseEnumeration(def, base);
        const bool parRang = !entiere && (nom == "unique" || nom.rfind("flip", 0) == 0);
        if (!entiere && !parRang)
            erreur("MATLAB:UndefinedFunction",
                   "Undefined function '" + nom + "' for input arguments of type '" +
                       e.nomObjet + "'.");
        auto codes = [&](const Valeur& v) {
            if (entiere) return valeursEnumeration(v, nom.c_str());
            Valeur r = Valeur::matriceDims(v.dims);
            const auto n = nomsMembres(v);
            for (std::size_t k = 0; k < n.size(); ++k)
                r.re[k] = (double)(std::find(def->enumerations.begin(), def->enumerations.end(),
                                             n[k]) - def->enumerations.begin() + 1);
            return r;
        };
        std::vector<Valeur> calcul = args;
        for (auto& a : calcul)
            if (estEnumeration(a)) {
                if (a.nomObjet != e.nomObjet)
                    erreur("MATLAB:UndefinedFunction",
                           "Undefined function '" + nom + "' for input arguments of type '" +
                               e.nomObjet + "' and '" + a.nomObjet + "'.");
                a = codes(a);
            }
        resultat = appeler(nom, calcul, itv->second);
        if (!resultat.empty()) {
            if (entiere) {
                resultat[0] = convertirEnEnumeration(def, resultat[0]);
            } else {
                Valeur noms = Valeur::celluleDims(resultat[0].dims);
                for (std::size_t k = 0; k < resultat[0].nelem(); ++k)
                    noms.cellules[k] =
                        Valeur::texte(def->enumerations[(std::size_t)resultat[0].re[k] - 1]);
                resultat[0] = convertirEnEnumeration(def, noms);
            }
        }
        return true;
    }
    if (nom == "ismember" && args.size() >= 2) {
        Valeur ensemble = estEnumeration(args[1]) ? args[1] : convertirEnEnumeration(def, args[1]);
        if (ensemble.nomObjet != e.nomObjet) {
            Valeur faux = Valeur::matriceDims(e.dims);
            faux.classe = Classe::Logique;
            resultat = {faux, Valeur::matriceDims(e.dims)};
            return true;
        }
        const std::vector<std::string> parmi = nomsMembres(ensemble);
        Valeur tf = Valeur::matriceDims(e.dims);
        tf.classe = Classe::Logique;
        Valeur ou = Valeur::matriceDims(e.dims);
        for (std::size_t k = 0; k < noms.size(); ++k)
            for (std::size_t j = 0; j < parmi.size(); ++j)
                if (parmi[j] == noms[k]) {
                    tf.re[k] = 1.0;
                    ou.re[k] = (double)(j + 1);
                    break;
                }
        resultat = {tf, ou};
        return true;
    }
    return false;
}

}  // namespace matlibre
