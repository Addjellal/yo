// Parallele.cpp (bibliothèque) — les fonctions du calcul parallèle.
//
// parpool, gcp, parfeval, fetchOutputs, numlabs, labindex : la surface que
// documente MathWorks pour la Parallel Computing Toolbox, posée sur le pool
// de travailleurs de src/coeur/Parallele.cpp.
#include <algorithm>
#include <thread>

#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Parallele.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

Valeur objetPool(int n) {
    Valeur v = Valeur::structureVide();
    v.poserChamp("NumWorkers", Valeur::scalaire((double)n));
    v.poserChamp("Connected", Valeur::booleen(n > 0));
    v.poserChamp("Cluster", Valeur::texte("local"));
    v.poserChamp("SpmdEnabled", Valeur::booleen(true));
    v.poserChamp("IdleTimeout", Valeur::scalaire(30.0));
    return v;
}

FONCTION(fnParpool) {
    INUTILISE
    int n = coeursDisponibles();
    for (const auto& a : args) {
        if (a.estNumerique() && a.estScalaire()) n = (int)a.scal();
    }
    if (n < 1) n = 1;
    definirTaillePool(n);
    if (nargout > 0) return {objetPool(n)};
    it.sortie() << formater(
        "Starting parallel pool (parpool) using the 'local' profile ...\n"
        "Connected to the parallel pool (number of workers: %d).\n", n);
    return {};
}

FONCTION(fnGcp) {
    INUTILISE
    bool creer = true;
    for (const auto& a : args)
        if ((a.estTexte() || a.estChaine()) && a.versTexte() == "nocreate") creer = false;
    if (taillePool() == 0) {
        if (!creer) return {Valeur::vide()};
        definirTaillePool(coeursDisponibles());
    }
    return {objetPool(taillePool())};
}

FONCTION(fnDeletePool) {
    INUTILISE
    definirTaillePool(0);
    return {};
}

FONCTION(fnNumlabs) {
    INUTILISE
    // Hors d'un bloc spmd, il n'y a qu'un laboratoire.
    return {Valeur::scalaire(1.0)};
}

FONCTION(fnLabindex) {
    INUTILISE
    return {Valeur::scalaire(1.0)};
}

Valeur objetFuture(long long id, const std::string& nom) {
    Valeur v = Valeur::structureVide();
    v.poserChamp("ID", Valeur::scalaire((double)id));
    v.poserChamp("Function", Valeur::texte(nom));
    v.poserChamp("State", Valeur::texte("running"));
    return v;
}

long long identifiantFuture(const Valeur& v) {
    if (!v.estStructure() || !v.aChamp("ID"))
        erreur("MATLAB:parallel:InvalidFuture", "Expected a parallel.Future object.");
    return (long long)v.champ("ID", 0).scal();
}

FONCTION(fnParfeval) {
    INUTILISE
    if (args.size() < 2)
        erreur("MATLAB:minrhs", "parfeval requires a function handle and an output count.");
    std::size_t debut = 0;
    // parfeval(pool, @f, nout, ...) est accepté comme parfeval(@f, nout, ...).
    if (args[0].estStructure() && args[0].aChamp("NumWorkers")) debut = 1;
    const Valeur& fonction = args[debut];
    if (fonction.classe != Classe::Fonction)
        erreur("MATLAB:parfeval:InvalidFunction", "The first argument must be a function "
                                                  "handle.");
    int nout = (int)args[debut + 1].scal();
    std::vector<Valeur> reste(args.begin() + (long)debut + 2, args.end());
    long long id = lancerTravail(it, fonction, nout, reste);
    return {objetFuture(id, fonction.fn ? fonction.fn->texte : "@f")};
}

FONCTION(fnFetchOutputs) {
    INUTILISE
    exigerArguments(args, 1, 1, "fetchOutputs");
    if (args[0].classe == Classe::Cellule) {
        std::vector<Valeur> sorties;
        for (const auto& f : args[0].cellules) {
            auto r = recupererTravail(identifiantFuture(f));
            if (!r.empty()) sorties.push_back(r[0]);
        }
        return {Valeur::celluleLigne(sorties)};
    }
    auto r = recupererTravail(identifiantFuture(args[0]));
    if (r.empty()) return {Valeur::vide()};
    if (nargout <= 1) return {r[0]};
    return r;
}

FONCTION(fnWaitFuture) {
    INUTILISE
    exigerArguments(args, 1, 2, "wait");
    if (!args[0].estStructure() || !args[0].aChamp("ID")) return {};
    long long id = identifiantFuture(args[0]);
    while (!travailFini(id)) std::this_thread::yield();
    return {};
}

FONCTION(fnCancelFuture) {
    INUTILISE
    exigerArguments(args, 1, 1, "cancel");
    annulerTravail(identifiantFuture(args[0]));
    return {};
}

FONCTION(fnIsFutureDone) {
    INUTILISE
    exigerArguments(args, 1, 1, "matlibre_futurepret");
    return {Valeur::booleen(travailFini(identifiantFuture(args[0])))};
}

FONCTION(fnParfevalOnAll) {
    INUTILISE
    if (args.size() < 2)
        erreur("MATLAB:minrhs", "parfevalOnAll requires a function handle and an output "
                                "count.");
    std::size_t debut = args[0].estStructure() && args[0].aChamp("NumWorkers") ? 1 : 0;
    const Valeur& fonction = args[debut];
    int nout = (int)args[debut + 1].scal();
    std::vector<Valeur> reste(args.begin() + (long)debut + 2, args.end());
    int n = taillePool() > 0 ? taillePool() : coeursDisponibles();
    std::vector<Valeur> futures;
    for (int k = 0; k < n; ++k)
        futures.push_back(objetFuture(lancerTravail(it, fonction, nout, reste),
                                      fonction.fn ? fonction.fn->texte : "@f"));
    return {Valeur::celluleLigne(futures)};
}

FONCTION(fnTicBytes) {
    INUTILISE
    return {Valeur::scalaire(0.0)};
}

}  // namespace

void enregistrerParallele(Interpreteur& it) {
    it.enregistrer("parpool", fnParpool, "parallele",
                   "parpool  Ouvre un pool de travailleurs.");
    it.enregistrer("gcp", fnGcp, "parallele", "gcp  Pool courant, cree si besoin.");
    it.enregistrer("matlibre_fermerpool", fnDeletePool, "parallele",
                   "matlibre_fermerpool  Ferme le pool courant.");
    it.enregistrer("numlabs", fnNumlabs, "parallele",
                   "numlabs  Nombre de laboratoires du bloc spmd.");
    it.enregistrer("labindex", fnLabindex, "parallele",
                   "labindex  Numero du laboratoire courant.");
    it.enregistrer("parfeval", fnParfeval, "parallele",
                   "parfeval  Lance une fonction sur un travailleur.");
    it.enregistrer("parfevalOnAll", fnParfevalOnAll, "parallele",
                   "parfevalOnAll  Lance une fonction sur tous les travailleurs.");
    it.enregistrer("fetchOutputs", fnFetchOutputs, "parallele",
                   "fetchOutputs  Recupere le resultat d'un travail.");
    it.enregistrer("wait", fnWaitFuture, "parallele", "wait  Attend la fin d'un travail.");
    it.enregistrer("cancel", fnCancelFuture, "parallele", "cancel  Annule un travail.");
    it.enregistrer("matlibre_futurepret", fnIsFutureDone, "parallele",
                   "matlibre_futurepret  Vrai si le travail est termine.");
    it.enregistrer("ticBytes", fnTicBytes, "parallele",
                   "ticBytes  Compteur d'octets echanges (nul ici).");
    it.enregistrer("tocBytes", fnTicBytes, "parallele",
                   "tocBytes  Compteur d'octets echanges (nul ici).");
}

}  // namespace matlibre
