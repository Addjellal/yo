// Fonctionnel.cpp — fonctions qui prennent des fonctions.
#include <algorithm>
#include <cctype>
#include <cmath>
#include <filesystem>
#include <fstream>
#include <memory>
#include <sstream>

#include "matlibre/Affichage.h"
#include "matlibre/Analyseur.h"
#include "matlibre/Lexeur.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"
#include "matlibre/Operations.h"

namespace matlibre {
namespace {

#define FONCTION(nom) \
    std::vector<Valeur> nom(Interpreteur& it, Arguments args, int nargout)
#define INUTILISE (void)it; (void)args; (void)nargout;

FONCTION(fnFeval) {
    INUTILISE
    exigerArguments(args, 1, 0, "feval");
    std::vector<Valeur> reste(args.begin() + 1, args.end());
    if (args[0].classe == Classe::Fonction)
        return it.appelerValeur(args[0], reste, std::max(nargout, 1));
    return it.appeler(args[0].versTexte(), reste, std::max(nargout, 1));
}

FONCTION(fnFunc2str) {
    INUTILISE
    exigerArguments(args, 1, 1, "func2str");
    if (args[0].classe != Classe::Fonction || !args[0].fn)
        erreur("MATLAB:func2str:BadInput", "Input must be a function handle.");
    return {Valeur::texte(args[0].fn->texte.empty() ? "@" + args[0].fn->nom
                                                    : args[0].fn->texte)};
}

FONCTION(fnStr2func) {
    INUTILISE
    exigerArguments(args, 1, 1, "str2func");
    std::string s = args[0].versTexte();
    while (!s.empty() && s.front() == ' ') s.erase(s.begin());
    if (!s.empty() && s[0] == '@') {
        NoeudPtr bloc = compilerBloc(s, "<str2func>");
        if (!bloc->enfants.empty() && bloc->enfants[0]->type == TypeN::Expression)
            return {it.evaluer(bloc->enfants[0]->enfants[0])};
    }
    auto f = it.resoudrePoignee(s);
    f->texte = "@" + s;
    return {Valeur::poignee(f)};
}

// Les options « UniformOutput » et « ErrorHandler » sont lues en fin
// d'arguments, comme dans MATLAB.
struct Options {
    bool uniforme = true;
    Valeur gestionnaire;
    std::size_t finDonnees = 0;
};

Options lireOptions(std::vector<Valeur>& args, std::size_t debut) {
    Options o;
    o.finDonnees = args.size();
    for (std::size_t k = debut; k + 1 < args.size(); ++k) {
        if (!(args[k].estTexte() || args[k].estChaine())) continue;
        std::string nom = args[k].versTexte();
        for (auto& c : nom) c = (char)std::tolower((unsigned char)c);
        if (nom == "uniformoutput") {
            o.uniforme = args[k + 1].vrai();
            o.finDonnees = std::min(o.finDonnees, k);
        } else if (nom == "errorhandler") {
            o.gestionnaire = args[k + 1];
            o.finDonnees = std::min(o.finDonnees, k);
        }
    }
    return o;
}

std::vector<Valeur> appliquerSur(Interpreteur& it, const Valeur& fonction,
                                 const std::vector<Valeur>& entrees, bool cellule,
                                 const Options& options, int nargout, const Dims& forme,
                                 std::size_t n) {
    int sorties = std::max(1, nargout);
    std::vector<std::vector<Valeur>> resultats((std::size_t)sorties);
    for (std::size_t i = 0; i < n; ++i) {
        std::vector<Valeur> appel;
        for (const auto& e : entrees) {
            if (cellule && e.classe == Classe::Cellule)
                appel.push_back(e.cellules[i]);
            else
                appel.push_back(extraireElement(e, i));
        }
        std::vector<Valeur> r;
        try {
            r = it.appelerValeur(fonction, appel, sorties);
        } catch (const ErreurMatlab& e) {
            if (options.gestionnaire.classe != Classe::Fonction) throw;
            Valeur info = Valeur::structureVide();
            info.poserChamp("identifier", Valeur::texte(e.identifiant));
            info.poserChamp("message", Valeur::texte(e.message));
            info.poserChamp("index", Valeur::scalaire((double)(i + 1)));
            std::vector<Valeur> appelGestion = {info};
            for (auto& a : appel) appelGestion.push_back(a);
            r = it.appelerValeur(options.gestionnaire, appelGestion, sorties);
        }
        for (int s = 0; s < sorties; ++s)
            resultats[(std::size_t)s].push_back((std::size_t)s < r.size() ? r[(std::size_t)s]
                                                                          : Valeur::vide());
    }
    std::vector<Valeur> sortiesFinales;
    for (int s = 0; s < sorties; ++s) {
        if (options.uniforme) {
            Valeur v = Valeur::matriceDims(forme);
            bool logique = true;
            for (std::size_t i = 0; i < n; ++i) {
                const Valeur& e = resultats[(std::size_t)s][i];
                if (e.nelem() != 1)
                    erreur("MATLAB:cellfun:NotAScalarOutput",
                           "Non-scalar in Uniform output. Set 'UniformOutput' to false.");
                v.re[i] = e.re.empty() ? 0.0 : e.re[0];
                if (!e.im.empty()) {
                    v.assurerImaginaire();
                    v.im[i] = e.im[0];
                }
                if (e.classe != Classe::Logique) logique = false;
            }
            if (logique && n > 0) v.classe = Classe::Logique;
            sortiesFinales.push_back(v);
        } else {
            Valeur v = Valeur::celluleDims(forme);
            for (std::size_t i = 0; i < n; ++i) v.cellules[i] = resultats[(std::size_t)s][i];
            sortiesFinales.push_back(v);
        }
    }
    return sortiesFinales;
}

FONCTION(fnCellfun) {
    INUTILISE
    exigerArguments(args, 2, 0, "cellfun");
    Options o = lireOptions(args, 2);
    Valeur fonction = args[0];
    if (fonction.estTexte() || fonction.estChaine()) {
        auto f = it.resoudrePoignee(fonction.versTexte());
        f->texte = "@" + fonction.versTexte();
        fonction = Valeur::poignee(f);
    }
    std::vector<Valeur> entrees(args.begin() + 1, args.begin() + (long)o.finDonnees);
    if (entrees.empty()) erreur("MATLAB:minrhs", "Not enough input arguments to 'cellfun'.");
    std::size_t n = entrees[0].nelem();
    return appliquerSur(it, fonction, entrees, true, o, nargout, entrees[0].dims, n);
}

FONCTION(fnArrayfun) {
    INUTILISE
    exigerArguments(args, 2, 0, "arrayfun");
    Options o = lireOptions(args, 2);
    Valeur fonction = args[0];
    if (fonction.estTexte() || fonction.estChaine()) {
        auto f = it.resoudrePoignee(fonction.versTexte());
        f->texte = "@" + fonction.versTexte();
        fonction = Valeur::poignee(f);
    }
    std::vector<Valeur> entrees(args.begin() + 1, args.begin() + (long)o.finDonnees);
    if (entrees.empty()) erreur("MATLAB:minrhs", "Not enough input arguments to 'arrayfun'.");
    std::size_t n = entrees[0].nelem();
    return appliquerSur(it, fonction, entrees, false, o, nargout, entrees[0].dims, n);
}

FONCTION(fnStructfun) {
    INUTILISE
    exigerArguments(args, 2, 0, "structfun");
    Options o = lireOptions(args, 2);
    const Valeur& s = args[1];
    const auto& noms = s.champs();
    std::vector<Valeur> valeurs;
    for (const auto& nom : noms) valeurs.push_back(s.champ(nom, 0));
    Valeur c = Valeur::celluleDims({(int)valeurs.size(), 1});
    for (std::size_t k = 0; k < valeurs.size(); ++k) c.cellules[k] = valeurs[k];
    std::vector<Valeur> entrees = {c};
    auto r = appliquerSur(it, args[0], entrees, true, o, nargout, c.dims, valeurs.size());
    if (!o.uniforme && !r.empty()) {
        Valeur sortie = Valeur::structureVide();
        for (std::size_t k = 0; k < noms.size(); ++k)
            sortie.poserChamp(noms[k], r[0].cellules[k]);
        return {sortie};
    }
    return r;
}

// ------------------------------------------------------------ évaluation

// run('script.m') : execute le fichier dans l'espace de travail courant.
// C'est la facon de lancer un script qui n'est pas sur le chemin de
// recherche — celui qu'on vient d'ecrire ailleurs, par exemple.
FONCTION(fnRun) {
    INUTILISE
    exigerArguments(args, 1, 1, "run");
    std::string chemin = args[0].versTexte();
    namespace fs = std::filesystem;
    std::error_code ec;
    if (!fs::is_regular_file(chemin, ec)) {
        // MATLAB accepte le nom sans extension.
        if (fs::is_regular_file(chemin + ".m", ec)) {
            chemin += ".m";
        } else {
            // ... et le cherche sur le chemin de recherche, comme il le
            // ferait pour un appel par son nom.
            std::string trouve;
            fs::path demande(chemin);
            std::string nom = demande.filename().string();
            if (demande.extension().empty()) nom += ".m";
            for (const std::string& dossierChemin : it.chemin()) {
                fs::path essai = fs::path(dossierChemin) / nom;
                if (fs::is_regular_file(essai, ec)) {
                    trouve = essai.string();
                    break;
                }
            }
            if (trouve.empty())
                erreur("MATLAB:run:FileNotFound",
                       "Unable to find file '" + chemin + "'.");
            chemin = trouve;
        }
    }
    std::ifstream f(chemin);
    if (!f) erreur("MATLAB:run:FileNotFound", "Unable to open file '" + chemin + "'.");
    std::ostringstream tampon;
    tampon << f.rdbuf();
    // Le dossier du script devient temporairement le dossier courant, comme
    // le fait MATLAB : un script trouve ainsi ses voisins.
    fs::path dossier = fs::path(chemin).parent_path();
    fs::path avant = fs::current_path(ec);
    if (!dossier.empty()) fs::current_path(dossier, ec);
    struct Restaurer {
        fs::path cible;
        bool actif;
        ~Restaurer() {
            if (actif) {
                std::error_code e;
                fs::current_path(cible, e);
            }
        }
    } restaurer{avant, !dossier.empty()};
    // Le fichier en cours doit etre connu de l'interpreteur : c'est ce qui
    // permet au debogueur de reconnaitre ses points d'arret, et a
    // mfilename de nommer le script.
    std::string fichierPrecedent = it.fichierCourant;
    it.fichierCourant = fs::absolute(chemin, ec).string();
    struct RestaurerFichier {
        Interpreteur& moteur;
        std::string valeur;
        ~RestaurerFichier() { moteur.fichierCourant = valeur; }
    } restaurerFichier{it, fichierPrecedent};
    // « return » dans le script arrete le script, comme quand on l'appelle
    // par son nom ; il ne quitte pas la fonction qui a appele « run ».
    try {
        it.executerTexte(tampon.str(), chemin);
    } catch (RetourFonction&) {
    }
    return {};
}

// MATLAB : « eval(texte) » execute ; « x = eval(texte) » evalue une
// expression et rend sa valeur. La seconde forme passe par des variables
// temporaires, effacees juste apres : c'est la seule facon de recuperer
// la valeur d'un texte qu'on ne connait qu'a l'execution.
static std::vector<Valeur> evaluerAvecSorties(Interpreteur& it, const std::string& code,
                                              int nargout) {
    std::string expression = code;
    while (!expression.empty() &&
           (std::isspace((unsigned char)expression.back()) || expression.back() == ';' ||
            expression.back() == ','))
        expression.pop_back();
    std::vector<std::string> temporaires;
    for (int k = 1; k <= nargout; ++k)
        temporaires.push_back("matlibre__eval" + std::to_string(k) + "__");
    std::string cible;
    if (nargout == 1) {
        cible = temporaires[0];
    } else {
        cible = "[";
        for (std::size_t k = 0; k < temporaires.size(); ++k) {
            if (k) cible += ", ";
            cible += temporaires[k];
        }
        cible += "]";
    }
    struct Nettoyer {
        Interpreteur& moteur;
        const std::vector<std::string>& noms;
        ~Nettoyer() {
            for (const auto& n : noms) moteur.effacerVariable(n);
        }
    } nettoyer{it, temporaires};
    it.executerTexte(cible + " = " + expression + ";", "<eval>");
    std::vector<Valeur> sorties;
    for (const auto& n : temporaires) {
        const Valeur* v = it.trouverVariable(n);
        if (!v)
            erreur("MATLAB:eval:noValue",
                   "Error: The expression to the left of the equals sign is not a valid "
                   "target for an assignment.");
        sorties.push_back(*v);
    }
    return sorties;
}

FONCTION(fnEval) {
    INUTILISE
    exigerArguments(args, 1, 2, "eval");
    std::string code = args[0].versTexte();
    try {
        if (nargout > 0) return evaluerAvecSorties(it, code, nargout);
        it.executerTexte(code, "<eval>");
    } catch (const ErreurMatlab& e) {
        if (args.size() > 1) {
            it.dernierMessage = e.message;
            if (nargout > 0) return evaluerAvecSorties(it, args[1].versTexte(), nargout);
            it.executerTexte(args[1].versTexte(), "<eval>");
            return {};
        }
        throw;
    }
    return {};
}

FONCTION(fnEvalc) {
    INUTILISE
    exigerArguments(args, 1, 1, "evalc");
    std::ostringstream tampon;
    // On restaure la sortie PRECEDENTE, et non la sortie par defaut : un
    // evalc dans un evalc laissait sinon echapper l'affichage du plus
    // interne vers la console.
    std::ostream* precedente = &it.sortie();
    it.definirSortie(&tampon);
    struct Restaurer {
        Interpreteur& moteur;
        std::ostream* valeur;
        ~Restaurer() { moteur.definirSortie(valeur); }
    } restaurer{it, precedente};
    it.executerTexte(args[0].versTexte(), "<evalc>");
    return {Valeur::texte(tampon.str())};
}

FONCTION(fnEvalin) {
    INUTILISE
    exigerArguments(args, 2, 2, "evalin");
    // evalin rend une valeur quand on la demande : on évalue alors
    // l'expression dans l'espace de travail visé, comme le fait MATLAB.
    std::string ou = args[0].versTexte();
    std::string texte = args[1].versTexte();
    // Dans les deux cas — avec ou sans sortie — le texte s'evalue DANS
    // l'espace de travail vise : c'est tout ce que evalin veut dire. Sans
    // cela, « evalin('base','x') » lisait la portee courante, et ne
    // trouvait pas ce qu'assignin venait d'ecrire dans la base.
    Portee& cible = ou == "base" ? it.porteeBase() : it.porteeAppelante();
    auto sauvegarde = std::make_shared<Portee>(cible);
    GardePortee garde(it, sauvegarde);
    struct Reporter {
        Portee& cible;
        const std::shared_ptr<Portee>& source;
        // Les variables creees ou modifiees repartent dans l'espace vise.
        ~Reporter() {
            for (const auto& kv : source->variables) cible.variables[kv.first] = kv.second;
        }
    } reporter{cible, sauvegarde};
    if (nargout > 0) {
        Analyseur analyseur(Lexeur(texte).analyser(), "<evalin>");
        NoeudPtr bloc = analyseur.analyserBloc();
        if (!bloc || bloc->enfants.empty()) return {Valeur::vide()};
        const NoeudPtr& derniere = bloc->enfants.back();
        for (std::size_t k = 0; k + 1 < bloc->enfants.size(); ++k)
            it.executerInstruction(bloc->enfants[k]);
        const NoeudPtr& expr = derniere->type == TypeN::Expression ? derniere->enfants[0]
                                                                   : derniere;
        return it.evaluerMulti(expr, std::max(nargout, 1));
    }
    it.executerTexte(texte, "<evalin>");
    return {};
}

FONCTION(fnAssignin) {
    INUTILISE
    exigerArguments(args, 3, 3, "assignin");
    std::string ou = args[0].versTexte();
    if (ou == "base") it.porteeBase().variables[args[1].versTexte()] = args[2];
    else it.porteeAppelante().variables[args[1].versTexte()] = args[2];
    return {};
}

FONCTION(fnExist) {
    INUTILISE
    exigerArguments(args, 1, 2, "exist");
    std::string nom = args[0].versTexte();
    std::string genre = args.size() > 1 ? args[1].versTexte() : "";
    if ((genre.empty() || genre == "var") && it.existeVariable(nom))
        return {Valeur::scalaire(1)};
    if (genre == "var") return {Valeur::scalaire(0)};
    if ((genre.empty() || genre == "file") && !nom.empty()) {
        std::error_code ec;
        if (std::filesystem::exists(nom, ec)) return {Valeur::scalaire(2)};
    }
    if (genre.empty() || genre == "file") {
        if (it.indexFichiers().count(nom)) return {Valeur::scalaire(2)};
    }
    if (genre.empty() || genre == "class") {
        if (it.classeDefinie(nom)) return {Valeur::scalaire(8)};
    }
    if (genre.empty() || genre == "builtin") {
        if (it.natif(nom)) return {Valeur::scalaire(5)};
    }
    return {Valeur::scalaire(0)};
}

FONCTION(fnIsvarname) {
    INUTILISE
    std::string s = args[0].versTexte();
    bool ok = !s.empty() && (std::isalpha((unsigned char)s[0]) || s[0] == '_');
    for (char c : s)
        if (!(std::isalnum((unsigned char)c) || c == '_')) ok = false;
    if (estMotCle(s)) ok = false;
    return {Valeur::booleen(ok)};
}

FONCTION(fnNarginFn) {
    INUTILISE
    if (args.empty()) return {Valeur::scalaire(it.portee().nargin)};
    // nargin('nom') : nombre d'entrées déclarées.
    auto f = it.fonctionFichier(args[0].versTexte());
    if (!f) return {Valeur::scalaire(-1)};
    return {Valeur::scalaire((double)f->entrees.size() * (f->variadiqueEntree() ? -1 : 1))};
}

FONCTION(fnNargoutFn) {
    INUTILISE
    if (args.empty()) return {Valeur::scalaire(it.portee().nargout)};
    auto f = it.fonctionFichier(args[0].versTexte());
    if (!f) return {Valeur::scalaire(-1)};
    return {Valeur::scalaire((double)f->sorties.size() * (f->variadiqueSortie() ? -1 : 1))};
}

FONCTION(fnNarginchk) {
    INUTILISE
    exigerArguments(args, 2, 2, "narginchk");
    int n = it.portee().nargin;
    if (n < (int)args[0].scal())
        erreur("MATLAB:narginchk:notEnoughInputs", "Not enough input arguments.");
    if (n > (int)args[1].scal())
        erreur("MATLAB:narginchk:tooManyInputs", "Too many input arguments.");
    return {};
}

FONCTION(fnNargoutchk) {
    INUTILISE
    return {};
}

FONCTION(fnInputname) {
    INUTILISE
    return {Valeur::texte("")};
}

FONCTION(fnFunctions) {
    INUTILISE
    exigerArguments(args, 1, 1, "functions");
    Valeur r = Valeur::structureVide();
    if (args[0].fn) {
        r.poserChamp("function", Valeur::texte(args[0].fn->nom.empty() ? args[0].fn->texte
                                                                       : args[0].fn->nom));
        const char* genre = args[0].fn->genre == Fonction::Anonyme
                                ? "anonymous"
                                : (args[0].fn->genre == Fonction::Native ? "simple"
                                                                         : "simple");
        r.poserChamp("type", Valeur::texte(genre));
        r.poserChamp("file", Valeur::texte(""));
    }
    return {r};
}

FONCTION(fnIsHandle) {
    INUTILISE
    return {Valeur::booleen(args[0].classe == Classe::Fonction)};
}

}  // namespace

void enregistrerFonctionnel(Interpreteur& it) {
    it.enregistrer("feval", fnFeval, "fonctionnel", "feval  Appelle une fonction nommee.");
    it.enregistrer("func2str", fnFunc2str, "fonctionnel", "func2str  Poignee -> texte.");
    it.enregistrer("str2func", fnStr2func, "fonctionnel", "str2func  Texte -> poignee.");
    it.enregistrer("cellfun", fnCellfun, "fonctionnel", "cellfun  Applique a chaque case.");
    it.enregistrer("arrayfun", fnArrayfun, "fonctionnel", "arrayfun  Applique a chaque element.");
    it.enregistrer("structfun", fnStructfun, "fonctionnel", "structfun  Applique a chaque champ.");
    it.enregistrer("eval", fnEval, "fonctionnel", "eval  Evalue du code.");
    it.enregistrer("run", fnRun, "fonctionnel",
                   "run  Execute un script, meme hors du chemin de recherche.");
    it.enregistrer("evalc", fnEvalc, "fonctionnel", "evalc  Evalue et capture l'affichage.");
    it.enregistrer("evalin", fnEvalin, "fonctionnel", "evalin  Evalue dans un autre espace.");
    it.enregistrer("assignin", fnAssignin, "fonctionnel", "assignin  Affecte dans un autre espace.");
    it.enregistrer("exist", fnExist, "fonctionnel", "exist  Le nom existe-t-il, et comme quoi.");
    it.enregistrer("isvarname", fnIsvarname, "fonctionnel", "isvarname  Nom de variable valide.");
    it.enregistrer("nargin", fnNarginFn, "fonctionnel", "nargin  Nombre d'arguments recus.");
    it.enregistrer("nargout", fnNargoutFn, "fonctionnel", "nargout  Nombre de sorties demandees.");
    it.enregistrer("narginchk", fnNarginchk, "fonctionnel", "narginchk  Verifie le nombre d'entrees.");
    it.enregistrer("nargoutchk", fnNargoutchk, "fonctionnel",
                   "nargoutchk  Verifie le nombre de sorties.");
    it.enregistrer("inputname", fnInputname, "fonctionnel", "inputname  Nom de l'argument appelant.");
    it.enregistrer("functions", fnFunctions, "fonctionnel", "functions  Information sur une poignee.");
    it.enregistrer("is_function_handle_", fnIsHandle, "fonctionnel", "Reserve.");
}

}  // namespace matlibre
