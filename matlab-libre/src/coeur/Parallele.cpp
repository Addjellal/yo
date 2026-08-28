// Parallele.cpp — pool de travailleurs pour parfor, spmd et parfeval.
//
// Chaque travailleur est un interpréteur neuf, doté du même chemin et de la
// même bibliothèque, mais d'un espace de travail à lui. On lui envoie une
// copie des variables diffusées, il exécute ses itérations, puis il rend ce
// qu'il a écrit : les cases des variables en tranches et la valeur des
// réductions. Rien n'est partagé pendant l'exécution, donc rien à verrouiller.
#include "matlibre/Parallele.h"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <future>
#include <exception>
#include <limits>
#include <memory>
#include <mutex>
#include <sstream>
#include <thread>

#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

int tailleDemandee = 0;   // 0 = pas de pool ouvert

// --- inspection de l'arbre ------------------------------------------------

// Description d'une variable du corps, telle que l'exige la classification
// de MATLAB (« Classification of Variables in parfor-Loops »).
struct Usage {
    bool vue = false;            // déjà rencontrée dans le parcours
    bool premierEstEcriture = false;  // premier événement : une écriture
    bool luAvantEcrit = false;   // lue avant toute écriture : entrée
    bool ecritTranche = false;   // X(i) = ...
    bool ecritReduction = false; // X = X op ...
    bool ecritAutre = false;     // toute autre écriture
    bool ecritIndexe = false;    // X(autre chose que i) = ... : non classable
    std::string operateur;
};

struct Analyse {
    std::vector<std::string> ordre;              // ordre de première rencontre
    std::map<std::string, Usage> usages;
    bool inconnu = false;                        // construction non classable
    Usage& acceder(const std::string& nom) {
        if (usages.find(nom) == usages.end()) ordre.push_back(nom);
        return usages[nom];
    }
};

// Nom de la variable visée par une cible d'affectation, et forme de l'accès.
std::string cibleDe(const NoeudPtr& cible, char& genre) {
    genre = 0;
    if (!cible) return {};
    if (cible->type == TypeN::Ident) return cible->texte;
    if (cible->type == TypeN::Acces && !cible->enfants.empty() &&
        cible->enfants[0]->type == TypeN::Ident) {
        if (!cible->acces.empty()) genre = cible->acces[0].genre;
        return cible->enfants[0]->texte;
    }
    return {};
}

// L'affectation « X(i) = ... » où i est la variable de boucle : tranche.
bool estTrancheDe(const NoeudPtr& cible, const std::string& variableBoucle) {
    if (!cible || cible->type != TypeN::Acces) return false;
    if (cible->acces.size() != 1) return false;
    const ElementAcces& a = cible->acces[0];
    if (a.genre != '(' && a.genre != '{') return false;
    if (a.args.empty()) return false;
    // Le premier indice doit être exactement la variable de boucle, les
    // autres des « : ». C'est la forme que MATLAB accepte sans réserve.
    if (!a.args[0] || a.args[0]->type != TypeN::Ident || a.args[0]->texte != variableBoucle)
        return false;
    for (std::size_t k = 1; k < a.args.size(); ++k)
        if (!a.args[k] || a.args[k]->type != TypeN::DeuxPointsSeul) return false;
    return true;
}

// L'affectation « X = X op expr » ou « X = expr op X » : réduction.
std::string operateurReductionDe(const Noeud& n, const std::string& nom) {
    if (n.cibles.size() != 1 || n.cibles[0]->type != TypeN::Ident) return {};
    if (n.cibles[0]->texte != nom) return {};
    if (n.enfants.empty()) return {};
    const NoeudPtr& e = n.enfants[0];
    auto estNom = [&](const NoeudPtr& x) {
        return x && x->type == TypeN::Ident && x->texte == nom;
    };
    if (e->type == TypeN::OpBinaire && e->enfants.size() == 2) {
        static const std::vector<std::string> associatifs = {"+", "*", ".*", "&", "|"};
        if (std::find(associatifs.begin(), associatifs.end(), e->texte) != associatifs.end() &&
            (estNom(e->enfants[0]) || estNom(e->enfants[1])))
            return e->texte;
        return {};
    }
    if (e->type == TypeN::Matrice) {
        // « v = [v, x] » ou « v = [v; x] » : concaténation, associative.
        for (const auto& r : e->rangees)
            for (const auto& x : r)
                if (estNom(x)) return e->rangees.size() > 1 ? ";" : ",";
        return {};
    }
    if (e->type == TypeN::Acces && !e->enfants.empty() &&
        e->enfants[0]->type == TypeN::Ident && !e->acces.empty()) {
        static const std::vector<std::string> fonctions = {"min", "max", "plus", "times"};
        const std::string& f = e->enfants[0]->texte;
        if (std::find(fonctions.begin(), fonctions.end(), f) != fonctions.end())
            for (const auto& a : e->acces[0].args)
                if (estNom(a)) return f;
    }
    return {};
}

void parcourir(const NoeudPtr& n, Analyse& a, const std::string& variableBoucle);

void lire(const NoeudPtr& n, Analyse& a, const std::string& variableBoucle) {
    if (!n) return;
    if (n->type == TypeN::Ident) {
        Usage& u = a.acceder(n->texte);
        if (!u.vue) { u.vue = true; u.premierEstEcriture = false; }
        if (!u.ecritTranche && !u.ecritReduction && !u.ecritAutre) u.luAvantEcrit = true;
        return;
    }
    if (n->type == TypeN::Acces && !n->enfants.empty() &&
        n->enfants[0]->type == TypeN::Ident) {
        Usage& u = a.acceder(n->enfants[0]->texte);
        if (!u.vue) { u.vue = true; u.premierEstEcriture = false; }
        if (!u.ecritTranche && !u.ecritReduction && !u.ecritAutre) u.luAvantEcrit = true;
        for (const auto& acc : n->acces)
            for (const auto& e : acc.args) lire(e, a, variableBoucle);
        return;
    }
    parcourir(n, a, variableBoucle);
}

// Parcours dans l'ordre du programme : c'est cet ordre qui distingue une
// variable temporaire (écrite d'abord) d'une réduction (lue d'abord).
void parcourir(const NoeudPtr& n, Analyse& a, const std::string& variableBoucle) {
    if (!n) return;
    switch (n->type) {
        case TypeN::Affectation: {
            for (const auto& e : n->enfants) lire(e, a, variableBoucle);
            for (const auto& c : n->cibles) {
                char genre;
                std::string nom = cibleDe(c, genre);
                if (nom.empty()) {
                    if (c && c->type != TypeN::Ident) a.inconnu = true;
                    continue;
                }
                if (c->type == TypeN::Acces)
                    for (const auto& acc : c->acces)
                        for (const auto& e : acc.args) lire(e, a, variableBoucle);
                Usage& u = a.acceder(nom);
                if (!u.vue) { u.vue = true; u.premierEstEcriture = true; }
                if (genre != 0) {
                    if (estTrancheDe(c, variableBoucle)) {
                        u.ecritTranche = true;
                    } else {
                        // Indexation par autre chose : la variable est lue
                        // puis réécrite, donc partagée entre itérations.
                        u.luAvantEcrit = true;
                        u.ecritAutre = true;
                        u.ecritIndexe = true;
                    }
                } else {
                    std::string op = operateurReductionDe(*n, nom);
                    if (!op.empty()) {
                        u.ecritReduction = true;
                        u.operateur = op;
                        u.luAvantEcrit = true;
                    } else {
                        u.ecritAutre = true;
                    }
                }
            }
            return;
        }
        case TypeN::Pour: {
            if (!n->enfants.empty()) lire(n->enfants[0], a, variableBoucle);
            for (const auto& c : n->cibles) {
                char genre;
                std::string nom = cibleDe(c, genre);
                if (nom.empty()) continue;
                Usage& u = a.acceder(nom);
                if (!u.vue) { u.vue = true; u.premierEstEcriture = true; }
                u.ecritAutre = true;
            }
            if (n->enfants.size() > 1) parcourir(n->enfants[1], a, variableBoucle);
            return;
        }
        case TypeN::Global:
        case TypeN::Persistant:
            a.inconnu = true;
            return;
        case TypeN::Ident:
        case TypeN::Acces:
            lire(n, a, variableBoucle);
            return;
        default:
            for (const auto& c : n->cibles) lire(c, a, variableBoucle);
            for (const auto& e : n->enfants) parcourir(e, a, variableBoucle);
            for (const auto& r : n->rangees)
                for (const auto& e : r) parcourir(e, a, variableBoucle);
            for (const auto& acc : n->acces)
                for (const auto& e : acc.args) parcourir(e, a, variableBoucle);
            return;
    }
}

}  // namespace

int taillePool() { return tailleDemandee; }
void definirTaillePool(int n) { tailleDemandee = n; }

int coeursDisponibles() {
    unsigned n = std::thread::hardware_concurrency();
    return n == 0 ? 1 : (int)n;
}

PlanParfor analyserParfor(const NoeudPtr& boucle, const std::string& variableBoucle,
                          const Interpreteur& it) {
    PlanParfor plan;
    plan.variableBoucle = variableBoucle;
    const NoeudPtr& corps = boucle->enfants.size() > 1 ? boucle->enfants[1] : nullptr;
    if (!corps) {
        plan.raison = "corps vide";
        return plan;
    }
    Analyse a;
    Usage& boucleVar = a.acceder(variableBoucle);
    boucleVar.vue = true;
    boucleVar.premierEstEcriture = true;
    boucleVar.ecritAutre = true;   // la variable de boucle est donnée
    parcourir(corps, a, variableBoucle);
    if (a.inconnu) {
        plan.raison = "variable globale, persistante ou cible d'affectation non classable";
        return plan;
    }
    for (const auto& nom : a.ordre) {
        if (nom == variableBoucle) continue;
        const Usage& u = a.usages.at(nom);
        bool ecrite = u.ecritTranche || u.ecritReduction || u.ecritAutre;
        if (!ecrite) {
            // Lue seulement : diffusée si c'est une variable, sinon c'est un
            // nom de fonction, que le travailleur résoudra tout seul.
            if (it.existeVariable(nom)) plan.diffusees.push_back(nom);
            continue;
        }
        if (u.ecritIndexe) {
            plan.raison = "la variable « " + nom + "  » est écrite à un indice qui n'est "
                          "pas la variable de boucle";
            return plan;
        }
        if (u.ecritTranche && !u.ecritReduction && !u.ecritAutre) {
            plan.tranches.push_back(nom);
            continue;
        }
        if (u.premierEstEcriture) {
            // Écrite avant toute lecture : la variable naît et meurt dans
            // l'itération, c'est une temporaire, quoi qu'il advienne ensuite.
            plan.temporaires.push_back(nom);
            continue;
        }
        if (u.ecritReduction && !u.ecritTranche && !u.ecritAutre) {
            plan.reductions.push_back(nom);
            plan.operateurReduction[nom] = u.operateur;
            continue;
        }
        plan.raison = "la variable « " + nom + " » n'est ni en tranches ni réduite";
        return plan;
    }
    plan.utilisable = true;
    return plan;
}

namespace {

// Combine deux valeurs selon l'opérateur de réduction retenu.
Valeur combiner(Interpreteur& it, const std::string& op, const Valeur& a, const Valeur& b) {
    if (op == ",") return concatener({a, b}, 1);
    if (op == ";") return concatener({a, b}, 0);
    if (op == "min" || op == "max") {
        auto r = it.appeler(op, {a, b}, 1);
        return r.empty() ? a : r[0];
    }
    if (op == "plus") return operationBinaire("+", a, b);
    if (op == "times") return operationBinaire(".*", a, b);
    return operationBinaire(op, a, b);
}

// Élément neutre de chaque opérateur de réduction : le travailleur part de
// là, et les résultats partiels se combinent ensuite avec la valeur d'avant
// la boucle. Les opérateurs admis sont associatifs, l'ordre est donc sans
// effet sur le résultat.
Valeur elementNeutre(const std::string& op) {
    if (op == "+" || op == "plus") return Valeur::scalaire(0.0);
    if (op == "*" || op == ".*" || op == "times") return Valeur::scalaire(1.0);
    if (op == "&") return Valeur::booleen(true);
    if (op == "|") return Valeur::booleen(false);
    if (op == "," || op == ";") return Valeur::vide();
    if (op == "min") return Valeur::scalaire(std::numeric_limits<double>::infinity());
    if (op == "max") return Valeur::scalaire(-std::numeric_limits<double>::infinity());
    return Valeur::vide();
}

struct ResultatTravailleur {
    std::map<std::string, std::vector<std::pair<std::size_t, Valeur>>> tranches;
    std::map<std::string, Valeur> reductions;
    std::string erreur;
    std::string identifiant;
};

}  // namespace

bool executerParforParallele(Interpreteur& it, const NoeudPtr& boucle,
                             const std::vector<Valeur>& iterations, const PlanParfor& plan) {
    if (!plan.utilisable) return false;
    const NoeudPtr& corps = boucle->enfants[1];
    std::size_t n = iterations.size();
    int demandes = taillePool() > 0 ? taillePool() : coeursDisponibles();
    int travailleurs = (int)std::min<std::size_t>((std::size_t)std::max(1, demandes), n);
    if (travailleurs < 2 || n < 2) return false;

    // Les valeurs diffusées sont copiées une fois ; les travailleurs les
    // partagent en lecture seule, la copie sur écriture les protège.
    std::vector<std::pair<std::string, Valeur>> diffusees;
    for (const auto& nom : plan.diffusees) diffusees.emplace_back(nom, it.lireVariable(nom));

    std::string racine = it.racineToolbox();
    std::vector<std::string> chemins = it.chemin();

    std::vector<ResultatTravailleur> resultats((std::size_t)travailleurs);
    std::vector<std::thread> fils;
    std::atomic<std::size_t> prochaine{0};

    auto tache = [&](int rang) {
        ResultatTravailleur& sortie = resultats[(std::size_t)rang];
        try {
            Interpreteur ouvrier;
            ouvrier.installerBibliotheque();
            ouvrier.definirRacineToolbox(racine);
            for (auto p = chemins.rbegin(); p != chemins.rend(); ++p)
                ouvrier.ajouterChemin(*p, true);
            std::ostringstream muet;
            ouvrier.definirSortie(&muet);
            for (const auto& kv : diffusees) ouvrier.ecrireVariable(kv.first, kv.second);
            // Chaque réduction démarre à son élément neutre : la valeur qui
            // précédait la boucle est réintégrée une seule fois, à la fin.
            for (const auto& nom : plan.reductions)
                ouvrier.ecrireVariable(nom, elementNeutre(plan.operateurReduction.at(nom)));
            bool aTravaille = false;
            for (;;) {
                std::size_t k = prochaine.fetch_add(1);
                if (k >= n) break;
                aTravaille = true;
                for (const auto& nom : plan.temporaires) ouvrier.effacerVariable(nom);
                for (const auto& nom : plan.tranches) ouvrier.effacerVariable(nom);
                ouvrier.ecrireVariable(plan.variableBoucle, iterations[k]);
                ouvrier.executerBloc(corps);
                for (const auto& nom : plan.tranches) {
                    if (!ouvrier.existeVariable(nom)) continue;
                    Valeur v = ouvrier.lireVariable(nom);
                    // La tranche écrite est à l'indice de l'itération.
                    std::vector<Valeur> idx = {iterations[k]};
                    Valeur element = ouvrier.indexer(v, idx, '(');
                    sortie.tranches[nom].emplace_back(k, element);
                }
            }
            if (aTravaille)
                for (const auto& nom : plan.reductions)
                    if (ouvrier.existeVariable(nom))
                        sortie.reductions[nom] = ouvrier.lireVariable(nom);
        } catch (const ErreurMatlab& e) {
            sortie.erreur = e.message;
            sortie.identifiant = e.identifiant;
        } catch (const std::exception& e) {
            sortie.erreur = e.what();
        } catch (...) {
            sortie.erreur = "Unhandled error on a parallel worker.";
        }
    };

    for (int r = 0; r < travailleurs; ++r) fils.emplace_back(tache, r);
    for (auto& f : fils) f.join();

    for (const auto& r : resultats)
        if (!r.erreur.empty())
            erreur(r.identifiant.empty() ? "MATLAB:parfor:workerError" : r.identifiant,
                   r.erreur);

    // Les écritures reviennent dans l'ordre des itérations : le résultat est
    // celui de la boucle séquentielle, quel que soit l'ordre d'exécution.
    for (const auto& nom : plan.tranches) {
        std::vector<std::pair<std::size_t, Valeur>> cases;
        for (const auto& r : resultats) {
            auto p = r.tranches.find(nom);
            if (p != r.tranches.end())
                cases.insert(cases.end(), p->second.begin(), p->second.end());
        }
        std::sort(cases.begin(), cases.end(),
                  [](const auto& a, const auto& b) { return a.first < b.first; });
        Valeur cible = it.existeVariable(nom) ? it.lireVariable(nom) : Valeur::vide();
        for (const auto& c : cases) {
            std::vector<Valeur> idx = {iterations[c.first]};
            cible = it.ecrireIndex(std::move(cible), idx, c.second, '(');
        }
        it.ecrireVariable(nom, std::move(cible));
    }
    for (const auto& nom : plan.reductions) {
        Valeur accumulateur;
        bool premier = true;
        if (it.existeVariable(nom)) {
            accumulateur = it.lireVariable(nom);
            premier = false;
        }
        for (const auto& r : resultats) {
            auto p = r.reductions.find(nom);
            if (p == r.reductions.end()) continue;
            if (premier) {
                accumulateur = p->second;
                premier = false;
            } else {
                accumulateur = combiner(it, plan.operateurReduction.at(nom), accumulateur,
                                        p->second);
            }
        }
        if (!premier) it.ecrireVariable(nom, std::move(accumulateur));
    }
    return true;
}

std::vector<std::vector<Valeur>> appliquerEnParallele(
    Interpreteur& it, const std::string& fonction,
    const std::vector<std::vector<Valeur>>& lots, int nargout) {
    std::size_t n = lots.size();
    std::vector<std::vector<Valeur>> sorties(n);
    int demandes = taillePool() > 0 ? taillePool() : coeursDisponibles();
    int travailleurs = (int)std::min<std::size_t>((std::size_t)std::max(1, demandes), n);
    if (travailleurs < 2) {
        for (std::size_t k = 0; k < n; ++k) sorties[k] = it.appeler(fonction, lots[k], nargout);
        return sorties;
    }
    std::string racine = it.racineToolbox();
    std::vector<std::string> chemins = it.chemin();
    std::atomic<std::size_t> prochaine{0};
    std::vector<std::string> erreurs((std::size_t)travailleurs);
    std::vector<std::thread> fils;
    auto tache = [&](int rang) {
        try {
            Interpreteur ouvrier;
            ouvrier.installerBibliotheque();
            ouvrier.definirRacineToolbox(racine);
            for (auto p = chemins.rbegin(); p != chemins.rend(); ++p)
                ouvrier.ajouterChemin(*p, true);
            std::ostringstream muet;
            ouvrier.definirSortie(&muet);
            for (;;) {
                std::size_t k = prochaine.fetch_add(1);
                if (k >= n) break;
                sorties[k] = ouvrier.appeler(fonction, lots[k], nargout);
            }
        } catch (const ErreurMatlab& e) {
            erreurs[(std::size_t)rang] = e.message;
        } catch (const std::exception& e) {
            erreurs[(std::size_t)rang] = e.what();
        }
    };
    for (int r = 0; r < travailleurs; ++r) fils.emplace_back(tache, r);
    for (auto& f : fils) f.join();
    for (const auto& e : erreurs)
        if (!e.empty()) erreur("MATLAB:parallel:workerError", e);
    return sorties;
}


// --- spmd -----------------------------------------------------------------

bool executerSpmd(Interpreteur& it, const NoeudPtr& bloc) {
    if (!bloc) return false;
    int demandes = taillePool() > 0 ? taillePool() : coeursDisponibles();
    int travailleurs = std::max(1, demandes);
    Analyse a;
    parcourir(bloc, a, std::string());
    if (a.inconnu) return false;
    std::vector<std::string> diffusees, ecrites;
    for (const auto& nom : a.ordre) {
        const Usage& u = a.usages.at(nom);
        bool ecrite = u.ecritTranche || u.ecritReduction || u.ecritAutre;
        if (ecrite) ecrites.push_back(nom);
        if (!u.premierEstEcriture && it.existeVariable(nom)) diffusees.push_back(nom);
    }
    if (travailleurs < 2) {
        // Un seul travailleur : le bloc s'exécute sur place, et les
        // variables écrites deviennent des Composite à une case.
        it.ecrireVariable("labindex", Valeur::scalaire(1.0));
        it.ecrireVariable("numlabs", Valeur::scalaire(1.0));
        it.executerBloc(bloc);
        for (const auto& nom : ecrites) {
            if (!it.existeVariable(nom)) continue;
            Valeur c = Valeur::celluleDims({1, 1});
            c.cellules[0] = it.lireVariable(nom);
            it.ecrireVariable(nom, std::move(c));
        }
        return true;
    }
    std::vector<std::pair<std::string, Valeur>> valeursDiffusees;
    for (const auto& nom : diffusees) valeursDiffusees.emplace_back(nom, it.lireVariable(nom));
    std::string racine = it.racineToolbox();
    std::vector<std::string> chemins = it.chemin();
    std::vector<std::map<std::string, Valeur>> sorties((std::size_t)travailleurs);
    std::vector<std::string> erreurs((std::size_t)travailleurs);
    std::vector<std::thread> fils;
    auto tache = [&](int rang) {
        try {
            Interpreteur ouvrier;
            ouvrier.installerBibliotheque();
            ouvrier.definirRacineToolbox(racine);
            for (auto p = chemins.rbegin(); p != chemins.rend(); ++p)
                ouvrier.ajouterChemin(*p, true);
            std::ostringstream muet;
            ouvrier.definirSortie(&muet);
            for (const auto& kv : valeursDiffusees) ouvrier.ecrireVariable(kv.first, kv.second);
            ouvrier.ecrireVariable("labindex", Valeur::scalaire((double)rang + 1));
            ouvrier.ecrireVariable("numlabs", Valeur::scalaire((double)travailleurs));
            ouvrier.executerBloc(bloc);
            for (const auto& nom : ecrites)
                if (ouvrier.existeVariable(nom))
                    sorties[(std::size_t)rang][nom] = ouvrier.lireVariable(nom);
        } catch (const ErreurMatlab& e) {
            erreurs[(std::size_t)rang] = e.message;
        } catch (const std::exception& e) {
            erreurs[(std::size_t)rang] = e.what();
        }
    };
    for (int r = 0; r < travailleurs; ++r) fils.emplace_back(tache, r);
    for (auto& f : fils) f.join();
    for (const auto& e : erreurs)
        if (!e.empty()) erreur("MATLAB:spmd:workerError", e);
    for (const auto& nom : ecrites) {
        Valeur c = Valeur::celluleDims({1, travailleurs});
        for (int r = 0; r < travailleurs; ++r) {
            auto p = sorties[(std::size_t)r].find(nom);
            c.cellules[(std::size_t)r] = p == sorties[(std::size_t)r].end() ? Valeur::vide()
                                                                            : p->second;
        }
        it.ecrireVariable(nom, std::move(c));
    }
    return true;
}

// --- parfeval ---------------------------------------------------------------

namespace {

struct Travail {
    std::future<std::vector<Valeur>> resultat;
    std::string erreur;
    bool recupere = false;
};

std::map<long long, std::shared_ptr<Travail>>& tableTravaux() {
    static std::map<long long, std::shared_ptr<Travail>> t;
    return t;
}
std::mutex& verrouTravaux() {
    static std::mutex m;
    return m;
}
long long prochainTravail = 1;

}  // namespace

long long lancerTravail(Interpreteur& it, const Valeur& fonction, int nargout,
                        std::vector<Valeur> args) {
    std::string racine = it.racineToolbox();
    std::vector<std::string> chemins = it.chemin();
    auto travail = std::make_shared<Travail>();
    travail->resultat = std::async(std::launch::async, [racine, chemins, fonction, nargout,
                                                        args]() -> std::vector<Valeur> {
        Interpreteur ouvrier;
        ouvrier.installerBibliotheque();
        ouvrier.definirRacineToolbox(racine);
        for (auto p = chemins.rbegin(); p != chemins.rend(); ++p)
            ouvrier.ajouterChemin(*p, true);
        std::ostringstream muet;
        ouvrier.definirSortie(&muet);
        return ouvrier.appelerValeur(fonction, args, std::max(1, nargout));
    });
    std::lock_guard<std::mutex> garde(verrouTravaux());
    long long id = prochainTravail++;
    tableTravaux()[id] = travail;
    return id;
}

bool travailFini(long long id) {
    std::lock_guard<std::mutex> garde(verrouTravaux());
    auto p = tableTravaux().find(id);
    if (p == tableTravaux().end()) return true;
    if (p->second->recupere) return true;
    return p->second->resultat.wait_for(std::chrono::seconds(0)) == std::future_status::ready;
}

std::vector<Valeur> recupererTravail(long long id) {
    std::shared_ptr<Travail> travail;
    {
        std::lock_guard<std::mutex> garde(verrouTravaux());
        auto p = tableTravaux().find(id);
        if (p == tableTravaux().end())
            erreur("MATLAB:parallel:UnknownFuture", "Unrecognized parallel future.");
        travail = p->second;
    }
    if (travail->recupere)
        erreur("MATLAB:parallel:AlreadyFetched", "Outputs have already been fetched.");
    std::vector<Valeur> r;
    try {
        r = travail->resultat.get();
    } catch (const ErreurMatlab& e) {
        travail->recupere = true;
        erreur(e.identifiant.empty() ? "MATLAB:parallel:workerError" : e.identifiant,
               e.message);
    } catch (const std::exception& e) {
        travail->recupere = true;
        erreur("MATLAB:parallel:workerError", e.what());
    }
    travail->recupere = true;
    return r;
}

void annulerTravail(long long id) {
    std::lock_guard<std::mutex> garde(verrouTravaux());
    tableTravaux().erase(id);
}

int travauxEnCours() {
    std::lock_guard<std::mutex> garde(verrouTravaux());
    int n = 0;
    for (const auto& kv : tableTravaux())
        if (!kv.second->recupere) ++n;
    return n;
}

}  // namespace matlibre
