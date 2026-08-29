#include "matlibre/Analyseur.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <memory>
#include <set>

#include "matlibre/Erreur.h"

namespace matlibre {

// La syntaxe « commande » — « hold on » plutôt que « hold('on') » — vaut
// en MATLAB pour N'IMPORTE QUELLE fonction, pas pour une liste choisie :
// « cvx_begin sdp », « maFonction argument » s'écrivent ainsi. La règle
// est syntaxique, à une réserve près : le nom ne doit pas être une
// variable, car « x -1 » soustrait quand x en est une et appelle
// x('-1') sinon. L'analyseur retient donc les noms affectés au fil de la
// lecture, comme le fait MATLAB.
//
// Cette liste-ci ne sert plus qu'aux quelques noms dont l'usage en
// commande est si répandu qu'on l'accepte même après une affectation du
// même nom — « hold on » après un « hold = ... » resterait une commande.
static const std::set<std::string>& commandesConnues() {
    static const std::set<std::string> c = {
        "format", "clc", "clear", "close", "hold", "grid", "warning", "more",
        "pkg", "help", "doc", "addpath", "rmpath", "path", "load", "save",
        "diary", "echo", "axis", "shading", "colormap", "who", "whos",
        "type", "what", "which", "dbstop", "dbclear", "profile", "syms",
        "figure", "cd", "ls", "dir", "delete", "mkdir", "rmdir", "beep",
        "commandwindow", "workspace", "graphics_toolkit", "pause"
    };
    return c;
}

Analyseur::Analyseur(std::vector<Jeton> jetons, std::string origine)
    : j_(std::move(jetons)), origine_(std::move(origine)) {}

const Jeton& Analyseur::jeton(int k) const {
    std::size_t p = i_ + (std::size_t)k;
    if (p >= j_.size()) return j_.back();
    return j_[p];
}

bool Analyseur::fini() const { return jeton().genre == Genre::Fin; }

bool Analyseur::accepterOp(const char* s) {
    if (jeton().estOp(s)) { avancer(); return true; }
    return false;
}

bool Analyseur::accepterMot(const char* s) {
    if (jeton().estMot(s)) { avancer(); return true; }
    return false;
}

void Analyseur::exigerOp(const char* s) {
    if (!accepterOp(s))
        erreurSyntaxe(std::string("Expected '") + s + "' but found '" + jeton().texte + "'.");
}

bool Analyseur::motFin() const {
    const Jeton& t = jeton();
    if (t.genre != Genre::MotCle) return false;
    return t.texte == "end" || t.texte == "endif" || t.texte == "endfor" ||
           t.texte == "endwhile" || t.texte == "endfunction" ||
           t.texte == "endswitch" || t.texte == "end_try_catch" ||
           t.texte == "end_unwind_protect";
}

void Analyseur::exigerMotFin() {
    if (!motFin()) erreurSyntaxe("Expected 'end'.");
    avancer();
}

void Analyseur::sauterFinsLignes() {
    while (jeton().genre == Genre::NouvelleLigne) avancer();
}

void Analyseur::sauterSeparateurs() {
    while (jeton().genre == Genre::NouvelleLigne || jeton().estOp(";") || jeton().estOp(","))
        avancer();
}

void Analyseur::erreurSyntaxe(const std::string& msg) const {
    erreur("MATLAB:parseError",
           formater("Parse error near line %d of %s: %s", jeton().ligne,
                    origine_.empty() ? "input" : origine_.c_str(), msg.c_str()));
}

// --------------------------------------------------------------- unité

UniteCompilee compiler(const std::string& source, const std::string& origine) {
    Lexeur l(source);
    Analyseur a(l.analyser(), origine);
    return a.analyserUnite();
}

NoeudPtr compilerBloc(const std::string& source, const std::string& origine) {
    Lexeur l(source);
    Analyseur a(l.analyser(), origine);
    return a.analyserBloc();
}

static std::string aideDeTete(const std::vector<Jeton>&) { return std::string(); }

UniteCompilee Analyseur::analyserUnite() {
    UniteCompilee u;
    sauterSeparateurs();
    if (jeton().estMot("classdef")) {
        // Un fichier de classe peut porter, après le bloc classdef, des
        // fonctions locales visibles depuis ses méthodes.
        while (!fini()) {
            sauterSeparateurs();
            if (fini()) break;
            if (jeton().estMot("classdef")) {
                u.classes.push_back(definitionClasse());
            } else if (jeton().estMot("function")) {
                u.fonctions.push_back(definitionFonction());
            } else {
                erreurSyntaxe("Only class definitions and local functions are allowed "
                              "in a classdef file.");
            }
        }
        return u;
    }
    fonctionsTerminees_ = detecterFonctionsTerminees();
    if (!jeton().estMot("function")) {
        u.script = bloc({"function"});
        if (u.script->enfants.empty()) u.script = nullptr;
    }
    while (!fini()) {
        sauterSeparateurs();
        if (fini()) break;
        if (jeton().estMot("function")) {
            u.fonctions.push_back(definitionFonction());
        } else if (u.script) {
            // Du code apres une definition de fonction, dans un script :
            // MATLAB veut les fonctions locales a la fin du fichier, et le
            // dit. « Unexpected token 'x' at file level » ne designait rien.
            erreurSyntaxe("Function definitions in a script must appear at the end of "
                          "the file.");
        } else {
            erreurSyntaxe("Unexpected token '" + jeton().texte + "' at file level.");
        }
    }
    (void)aideDeTete;
    return u;
}

// Un fichier dont les fonctions sont fermées par « end » se reconnaît à un
// « end » qui ne ferme aucun bloc de contrôle : c'est celui de la fonction.
// Les « end » d'indexation, entre parenthèses ou crochets, sont ignorés.
bool Analyseur::detecterFonctionsTerminees() const {
    static const std::set<std::string> ouvrants = {
        "if", "for", "parfor", "while", "switch", "try", "spmd", "do",
        "unwind_protect", "classdef", "methods", "properties", "events",
        "enumeration"};
    int profondeur = 0;
    int crochets = 0;
    bool vuFonction = false;
    for (const Jeton& t : j_) {
        if (t.genre == Genre::Operateur) {
            if (t.texte == "(" || t.texte == "[" || t.texte == "{") ++crochets;
            else if (t.texte == ")" || t.texte == "]" || t.texte == "}") --crochets;
            continue;
        }
        if (crochets > 0) continue;
        if (t.genre != Genre::MotCle) continue;
        if (t.texte == "function") { vuFonction = true; continue; }
        if (ouvrants.count(t.texte)) { ++profondeur; continue; }
        if (t.texte == "end" || t.texte.rfind("end", 0) == 0) {
            if (profondeur > 0) --profondeur;
            else if (vuFonction) return true;
        }
    }
    return false;
}

NoeudPtr Analyseur::analyserBloc() { return bloc({}); }

NoeudPtr Analyseur::bloc(const std::vector<std::string>& fins) {
    auto b = Noeud::creer(TypeN::Bloc);
    for (;;) {
        sauterSeparateurs();
        if (fini()) break;
        if (motFin()) break;
        const Jeton& t = jeton();
        if (t.genre == Genre::MotCle) {
            bool stop = false;
            for (const auto& f : fins)
                if (t.texte == f) stop = true;
            if (t.texte == "elseif" || t.texte == "else" || t.texte == "case" ||
                t.texte == "otherwise" || t.texte == "catch" || t.texte == "until" ||
                t.texte == "unwind_protect_cleanup")
                stop = true;
            if (stop) break;
        }
        b->enfants.push_back(instruction());
    }
    return b;
}

void Analyseur::terminer(NoeudPtr n) {
    // Le point-virgule éteint l'affichage ; la virgule et le retour à la
    // ligne le laissent.
    if (jeton().estOp(";")) {
        n->afficher = false;
        avancer();
        while (jeton().estOp(";")) avancer();
    } else if (jeton().estOp(",")) {
        n->afficher = true;
        avancer();
    } else if (jeton().genre == Genre::NouvelleLigne) {
        n->afficher = true;
        avancer();
    } else if (fini() || motFin() || jeton().genre == Genre::MotCle) {
        n->afficher = true;
    } else {
        erreurSyntaxe("Unexpected token '" + jeton().texte + "'.");
    }
}

bool Analyseur::ressembleCommande() const {
    const Jeton& t = jeton();
    if (t.genre != Genre::Ident) return false;
    // Une variable ne se commande pas : « x -1 » est une soustraction.
    if (variablesVues_.count(t.texte) && !commandesConnues().count(t.texte)) return false;
    const Jeton& s = jeton(1);
    if (!s.espaceAvant) return false;

    // Un mot-cle en argument reste un mot : « dbstop if error » et
    // « warning off all » sont des commandes, pas des « if » ni des
    // « for ». Le premier jeton, lui, ne peut pas etre un mot-cle : il a
    // deja fallu que ce soit un identifiant.
    if (s.genre == Genre::Ident || s.genre == Genre::Nombre || s.genre == Genre::MotCle) {
        const Jeton& u = jeton(2);
        // « format = 3 » est une affectation ; « x == 3 » une comparaison,
        // mais elle ne commence pas par un identifiant suivi d'un mot.
        if (u.estOp("=")) return false;
        // « f (x) » reste un appel : la parenthèse fait l'argument.
        if (u.estOp("(")) return false;
        // « a b + c » n'a pas de sens en commande ; « a b, c » ni « a b; »
        // en ont un, ce sont des séparateurs d'instruction. Un opérateur
        // collé au mot — « clear -all » — reste dans le mot.
        if (u.genre == Genre::Operateur && u.texte != "," && u.texte != ";" &&
            !(u.espaceAvant == false))
            return false;
        return true;
    }
    // « commande 'texte' » : le lexeur a pris l'apostrophe pour une
    // transposition, faute de savoir que « commande » n'est pas une
    // variable. Ici on le sait : elle ouvre une chaîne.
    if (s.genre == Genre::Litteral || s.genre == Genre::LitteralChaine) return true;
    if (s.genre == Genre::Operateur && s.texte == "'") return true;
    // « f -option », « f +x », « f ~x » : l'opérateur collé au mot qui suit
    // fait partie de l'argument. Avec une espace de part et d'autre, c'est
    // une opération.
    if (s.genre == Genre::Operateur && !s.espaceApres &&
        (s.texte == "-" || s.texte == "+" || s.texte == "~" || s.texte == "@"))
        return true;
    return false;
}

// Retient un nom affecté. Seul le nom compte : « a(3) = 1 » fait de « a »
// une variable tout autant que « a = 1 ».
void Analyseur::noterVariable(const NoeudPtr& cible) {
    if (!cible) return;
    if (cible->type == TypeN::Ident) {
        variablesVues_.insert(cible->texte);
        return;
    }
    if (cible->type == TypeN::Acces && !cible->enfants.empty())
        noterVariable(cible->enfants[0]);
}

NoeudPtr Analyseur::instructionCommande() {
    auto n = Noeud::creer(TypeN::Commande);
    n->ligne = jeton().ligne;
    n->texte = jeton().texte;
    avancer();

    // Les arguments d'une commande ne sont pas des expressions : ce sont
    // des mots, découpés sur les espaces, où l'apostrophe groupe. On
    // reconstitue donc le texte de la ligne à partir des jetons, puis on le
    // découpe soi-même — c'est ce que fait MATLAB, et c'est la seule façon
    // d'accepter « f 'un texte' », que le lexeur découpe en apostrophe de
    // transposition suivie de deux identifiants.
    std::string ligne;
    bool premier = true;
    while (!fini() && jeton().genre != Genre::NouvelleLigne && !jeton().estOp(";") &&
           !jeton().estOp(",")) {
        const Jeton& t = jeton();
        if (!premier && t.espaceAvant) ligne += ' ';
        premier = false;
        // Un littéral que le lexeur a su reconnaître a perdu ses
        // apostrophes : on les lui rend, pour que le découpage qui suit le
        // traite comme les autres.
        if (t.genre == Genre::Litteral || t.genre == Genre::LitteralChaine) {
            ligne += '\'';
            for (char c : t.texte) {
                ligne += c;
                if (c == '\'') ligne += c;
            }
            ligne += '\'';
        } else {
            ligne += t.texte;
        }
        avancer();
    }

    std::string mot;
    bool dansMot = false;
    for (std::size_t k = 0; k < ligne.size(); ++k) {
        char c = ligne[k];
        if (c == ' ' || c == '\t') {
            if (dansMot) { n->noms.push_back(mot); mot.clear(); dansMot = false; }
            continue;
        }
        dansMot = true;
        if (c != '\'') { mot += c; continue; }
        // Une apostrophe ouvre un groupe : tout y entre tel quel jusqu'à la
        // suivante, et « '' » y désigne une apostrophe.
        ++k;
        while (k < ligne.size()) {
            if (ligne[k] == '\'') {
                if (k + 1 < ligne.size() && ligne[k + 1] == '\'') { mot += '\''; k += 2; continue; }
                break;
            }
            mot += ligne[k];
            ++k;
        }
    }
    if (dansMot) n->noms.push_back(mot);
    terminer(n);
    return n;
}

NoeudPtr Analyseur::instruction() {
    const Jeton& t = jeton();
    if (t.genre == Genre::MotCle) {
        if (t.texte == "if") return instructionSi();
        if (t.texte == "for") return instructionPour(false);
        if (t.texte == "parfor") return instructionPour(true);
        if (t.texte == "while") return instructionTantQue();
        if (t.texte == "do") return instructionFaire();
        if (t.texte == "switch") return instructionChoix();
        if (t.texte == "try" || t.texte == "unwind_protect") return instructionEssayer();
        if (t.texte == "break") return instructionSimple(TypeN::Rupture);
        if (t.texte == "continue") return instructionSimple(TypeN::Continuer);
        if (t.texte == "return") return instructionSimple(TypeN::Retour);
        if (t.texte == "global") return instructionDeclaration(TypeN::Global);
        if (t.texte == "persistent") return instructionDeclaration(TypeN::Persistant);
        if (t.texte == "spmd") {
            avancer();
            // spmd (n) : le nombre de travailleurs demandé est accepté puis
            // ignoré ; c'est la taille du pool qui décide.
            if (accepterOp("(")) {
                expression();
                exigerOp(")");
            }
            auto corps = bloc({});
            exigerMotFin();
            corps->texte = "spmd";
            return corps;
        }
        erreurSyntaxe("Unexpected keyword '" + t.texte + "'.");
    }
    // « arguments » n'est pas un mot réservé : c'est un bloc seulement en
    // tête de fonction, suivi d'un retour à la ligne. Ailleurs, c'est un
    // nom de variable comme un autre.
    if (t.genre == Genre::Ident && t.texte == "arguments" &&
        jeton(1).genre == Genre::NouvelleLigne) {
        sauterBlocArguments();
        return Noeud::creer(TypeN::Rien);
    }
    if (ressembleCommande()) return instructionCommande();

    int ligne = t.ligne;
    NoeudPtr gauche = expression();

    static const char* composes[] = {"+=", "-=", "*=", "/=", "^=", nullptr};
    for (int k = 0; composes[k]; ++k) {
        if (jeton().estOp(composes[k])) {
            std::string op(1, composes[k][0]);
            avancer();
            auto droite = expression();
            auto bin = Noeud::creer(TypeN::OpBinaire);
            bin->texte = op;
            bin->enfants = {gauche, droite};
            auto n = Noeud::creer(TypeN::Affectation);
            n->ligne = ligne;
            n->cibles = {gauche};
            n->enfants = {bin};
            noterVariable(gauche);
            terminer(n);
            return n;
        }
    }
    if (jeton().estOp("++") || jeton().estOp("--")) {
        std::string op(1, jeton().texte[0]);
        avancer();
        auto bin = Noeud::creer(TypeN::OpBinaire);
        bin->texte = op;
        auto un = Noeud::creer(TypeN::Nombre);
        un->nombre = 1;
        bin->enfants = {gauche, un};
        auto n = Noeud::creer(TypeN::Affectation);
        n->ligne = ligne;
        n->cibles = {gauche};
        n->enfants = {bin};
        noterVariable(gauche);
        terminer(n);
        return n;
    }

    if (jeton().estOp("=")) {
        avancer();
        auto valeur = expression();
        auto n = Noeud::creer(TypeN::Affectation);
        n->ligne = ligne;
        if (gauche->type == TypeN::Matrice) {
            for (auto& rangee : gauche->rangees)
                for (auto& e : rangee) n->cibles.push_back(e);
        } else {
            n->cibles = {gauche};
        }
        for (auto& c : n->cibles) {
            if (c->type != TypeN::Ident && c->type != TypeN::Acces)
                erreurSyntaxe("Invalid assignment target.");
            noterVariable(c);
        }
        n->enfants = {valeur};
        terminer(n);
        return n;
    }

    auto n = Noeud::creer(TypeN::Expression);
    n->ligne = ligne;
    n->enfants = {gauche};
    terminer(n);
    return n;
}

NoeudPtr Analyseur::instructionSimple(TypeN t) {
    auto n = Noeud::creer(t);
    n->ligne = jeton().ligne;
    avancer();
    terminer(n);
    n->afficher = false;
    return n;
}

NoeudPtr Analyseur::instructionDeclaration(TypeN t) {
    auto n = Noeud::creer(t);
    n->ligne = jeton().ligne;
    avancer();
    while (jeton().genre == Genre::Ident) {
        n->noms.push_back(jeton().texte);
        avancer();
        if (jeton().estOp("=")) {  // persistent n = 0
            avancer();
            n->enfants.push_back(expression());
        } else {
            n->enfants.push_back(nullptr);
        }
        if (jeton().estOp(",")) avancer();
    }
    terminer(n);
    n->afficher = false;
    return n;
}

NoeudPtr Analyseur::instructionSi() {
    auto n = Noeud::creer(TypeN::Si);
    n->ligne = jeton().ligne;
    avancer();
    n->enfants.push_back(expression());
    n->enfants.push_back(bloc({"elseif", "else"}));
    while (jeton().estMot("elseif")) {
        avancer();
        n->enfants.push_back(expression());
        n->enfants.push_back(bloc({"elseif", "else"}));
    }
    if (accepterMot("else")) {
        n->drapeau = true;
        n->enfants.push_back(bloc({}));
    }
    exigerMotFin();
    return n;
}

NoeudPtr Analyseur::instructionPour(bool parallele) {
    auto n = Noeud::creer(TypeN::Pour);
    n->ligne = jeton().ligne;
    n->drapeau = parallele;
    avancer();
    bool paren = accepterOp("(");
    auto cible = postfixe();
    if (cible->type != TypeN::Ident && cible->type != TypeN::Acces)
        erreurSyntaxe("Invalid loop variable.");
    noterVariable(cible);
    exigerOp("=");
    auto plageExpr = expression();
    if (paren) {
        if (jeton().estOp(",")) {  // parfor (i = 1:n, M)
            avancer();
            expression();
        }
        exigerOp(")");
    }
    n->cibles = {cible};
    n->enfants = {plageExpr, bloc({})};
    exigerMotFin();
    return n;
}

NoeudPtr Analyseur::instructionTantQue() {
    auto n = Noeud::creer(TypeN::TantQue);
    n->ligne = jeton().ligne;
    avancer();
    n->enfants.push_back(expression());
    n->enfants.push_back(bloc({}));
    exigerMotFin();
    return n;
}

NoeudPtr Analyseur::instructionFaire() {
    auto n = Noeud::creer(TypeN::FaireJusqua);
    n->ligne = jeton().ligne;
    avancer();
    n->enfants.push_back(bloc({"until"}));
    if (!accepterMot("until")) erreurSyntaxe("Expected 'until'.");
    n->enfants.push_back(expression());
    return n;
}

NoeudPtr Analyseur::instructionChoix() {
    auto n = Noeud::creer(TypeN::Choix);
    n->ligne = jeton().ligne;
    avancer();
    n->enfants.push_back(expression());
    sauterSeparateurs();
    while (jeton().estMot("case")) {
        avancer();
        n->enfants.push_back(expression());
        n->enfants.push_back(bloc({"case", "otherwise"}));
    }
    if (accepterMot("otherwise")) {
        n->drapeau = true;
        n->enfants.push_back(bloc({"case"}));
    }
    exigerMotFin();
    return n;
}

NoeudPtr Analyseur::instructionEssayer() {
    auto n = Noeud::creer(TypeN::Essayer);
    n->ligne = jeton().ligne;
    avancer();
    n->enfants.push_back(bloc({"catch", "unwind_protect_cleanup"}));
    if (accepterMot("catch")) {
        if (jeton().genre == Genre::Ident &&
            (jeton(1).genre == Genre::NouvelleLigne || jeton(1).estOp(";") ||
             jeton(1).estOp(","))) {
            n->texte = jeton().texte;
            avancer();
        }
        n->enfants.push_back(bloc({}));
    } else if (accepterMot("unwind_protect_cleanup")) {
        n->drapeau = true;  // le bloc de nettoyage tourne toujours
        n->enfants.push_back(bloc({}));
    } else {
        n->enfants.push_back(Noeud::creer(TypeN::Bloc));
    }
    exigerMotFin();
    return n;
}

void Analyseur::sauterBlocArguments() {
    avancer();  // « arguments »
    int profondeur = 1;
    while (!fini() && profondeur > 0) {
        if (jeton().genre == Genre::MotCle) {
            const std::string& s = jeton().texte;
            if (s == "if" || s == "for" || s == "while" || s == "switch" || s == "try" ||
                s == "function" || s == "arguments")
                ++profondeur;
            else if (motFin())
                --profondeur;
        }
        avancer();
    }
}

// ---------------------------------------------------------- fonctions

std::shared_ptr<FonctionUtilisateur> Analyseur::definitionFonction() {
    auto f = std::make_shared<FonctionUtilisateur>();
    avancer();  // « function »
    // Formes : function nom, function nom(a), function s = nom(a),
    //          function [s1,s2] = nom(a,b)
    std::size_t sauve = i_;
    if (jeton().estOp("[")) {
        avancer();
        while (!jeton().estOp("]") && !fini()) {
            if (jeton().genre == Genre::Ident) { f->sorties.push_back(jeton().texte); avancer(); }
            else if (jeton().estOp("~")) { f->sorties.push_back("~"); avancer(); }
            else if (jeton().estOp(",")) avancer();
            else erreurSyntaxe("Invalid output argument list.");
        }
        exigerOp("]");
        exigerOp("=");
    } else if (jeton().genre == Genre::Ident && jeton(1).estOp("=")) {
        f->sorties.push_back(jeton().texte);
        avancer();
        avancer();
    } else {
        i_ = sauve;
    }
    // « end » est un nom de méthode valide : c'est celle qu'appelle
    // l'interpréteur pour résoudre « end » dans un indice.
    bool nomValide = jeton().genre == Genre::Ident ||
                     (jeton().genre == Genre::MotCle && jeton().texte == "end");
    if (!nomValide) erreurSyntaxe("Expected a function name.");
    f->nom = jeton().texte;
    avancer();
    // « get.Propriete » et « set.Propriete » gardent leur nom complet : ce
    // sont les accesseurs d'une propriété dépendante.
    while (jeton().estOp(".") && jeton(1).genre == Genre::Ident) {
        avancer();
        f->nom += "." + jeton().texte;
        avancer();
    }
    if (accepterOp("(")) {
        while (!jeton().estOp(")") && !fini()) {
            if (jeton().genre == Genre::Ident) { f->entrees.push_back(jeton().texte); avancer(); }
            else if (jeton().estOp("~")) { f->entrees.push_back("~"); avancer(); }
            else if (jeton().estOp(",")) avancer();
            else erreurSyntaxe("Invalid input argument list.");
            if (jeton().estOp("=")) {  // valeur par défaut (extension Octave)
                avancer();
                expression();
            }
        }
        exigerOp(")");
    }
    // MATLAB analyse chaque fonction pour elle-meme : ses parametres sont
    // des variables, et les variables de la fonction precedente ne le sont
    // plus. Sans cette remise a zero, un nom affecte dans une fonction
    // empecherait la syntaxe commande dans la suivante.
    std::set<std::string> variablesEnglobantes;
    variablesEnglobantes.swap(variablesVues_);
    for (const auto& nom : f->entrees) variablesVues_.insert(nom);
    for (const auto& nom : f->sorties) variablesVues_.insert(nom);
    f->corps = bloc({"function"});
    // Dans un fichier dont les fonctions sont fermées par « end », une
    // fonction écrite avant ce « end » est imbriquée : elle partage
    // l'espace de travail de celle qui l'entoure.
    if (fonctionsTerminees_) {
        sauterSeparateurs();
        while (jeton().estMot("function")) {
            auto sous = definitionFonction();
            sous->imbriquee = true;
            f->imbriquees[sous->nom] = sous;
            sauterSeparateurs();
        }
    }
    if (motFin()) avancer();
    variablesVues_.swap(variablesEnglobantes);
    return f;
}

std::shared_ptr<DefinitionClasse> Analyseur::definitionClasse() {
    auto c = std::make_shared<DefinitionClasse>();
    avancer();  // « classdef »
    if (accepterOp("(")) {  // attributs
        int p = 1;
        while (!fini() && p > 0) {
            if (jeton().estOp("(")) ++p;
            if (jeton().estOp(")")) --p;
            avancer();
        }
    }
    if (jeton().genre != Genre::Ident) erreurSyntaxe("Expected a class name.");
    c->nom = jeton().texte;
    avancer();
    if (accepterOp("<")) {
        for (;;) {
            if (jeton().genre != Genre::Ident) break;
            std::string parent = jeton().texte;
            avancer();
            while (jeton().estOp(".") && jeton(1).genre == Genre::Ident) {
                avancer();
                parent = jeton().texte;
                avancer();
            }
            c->parents.push_back(parent);
            if (parent == "handle") c->poignee = true;
            if (!accepterOp("&")) break;
        }
    }
    sauterSeparateurs();
    while (!fini() && !motFin()) {
        if (jeton().estMot("properties")) {
            avancer();
            std::vector<std::string> attributs;
            if (accepterOp("(")) {
                int p = 1;
                while (!fini() && p > 0) {
                    if (jeton().estOp("(")) ++p;
                    else if (jeton().estOp(")")) --p;
                    else if (jeton().genre == Genre::Ident) attributs.push_back(jeton().texte);
                    avancer();
                }
            }
            bool dependantes = false;
            bool constantes = false;
            for (const auto& a : attributs) {
                if (a == "Dependent") dependantes = true;
                if (a == "Constant") constantes = true;
            }
            sauterSeparateurs();
            while (!fini() && !motFin()) {
                if (jeton().genre != Genre::Ident) { avancer(); continue; }
                std::string nom = jeton().texte;
                avancer();
                // type et validateurs éventuels : on saute jusqu'au « = » ou
                // à la fin de la ligne.
                while (!fini() && jeton().genre != Genre::NouvelleLigne &&
                       !jeton().estOp("=") && !jeton().estOp(";"))
                    avancer();
                if (dependantes) c->dependantes.push_back(nom);
                else c->ordreProprietes.push_back(nom);
                if (constantes) c->constantes.push_back(nom);
                if (accepterOp("=")) c->defauts[nom] = expression();
                else c->defauts[nom] = nullptr;
                sauterSeparateurs();
            }
            exigerMotFin();
        } else if (jeton().estMot("methods")) {
            avancer();
            bool statiques = false;
            if (accepterOp("(")) {
                int p = 1;
                while (!fini() && p > 0) {
                    if (jeton().estOp("(")) ++p;
                    else if (jeton().estOp(")")) --p;
                    else if (jeton().genre == Genre::Ident && jeton().texte == "Static")
                        statiques = true;
                    avancer();
                }
            }
            sauterSeparateurs();
            while (!fini() && jeton().estMot("function")) {
                auto f = definitionFonction();
                c->methodes[f->nom] = f;
                if (statiques) c->statiques.push_back(f->nom);
                sauterSeparateurs();
            }
            exigerMotFin();
        } else if (jeton().estMot("events")) {
            avancer();
            sauterSeparateurs();
            while (!fini() && !motFin()) {
                if (jeton().genre == Genre::Ident) c->evenements.push_back(jeton().texte);
                avancer();
                sauterSeparateurs();
            }
            exigerMotFin();
        } else if (jeton().estMot("enumeration")) {
            avancer();
            sauterSeparateurs();
            while (!fini() && !motFin()) avancer();
            exigerMotFin();
        } else {
            avancer();
        }
        sauterSeparateurs();
    }
    exigerMotFin();
    return c;
}

// -------------------------------------------------------- expressions

NoeudPtr Analyseur::expression() { return ouCourt(); }

static NoeudPtr binaire(const std::string& op, NoeudPtr a, NoeudPtr b) {
    auto n = Noeud::creer(TypeN::OpBinaire);
    n->texte = op;
    n->enfants = {a, b};
    return n;
}

NoeudPtr Analyseur::ouCourt() {
    auto a = etCourt();
    while (jeton().estOp("||")) {
        avancer();
        a = binaire("||", a, etCourt());
    }
    return a;
}

NoeudPtr Analyseur::etCourt() {
    auto a = ouBinaire();
    while (jeton().estOp("&&")) {
        avancer();
        a = binaire("&&", a, ouBinaire());
    }
    return a;
}

NoeudPtr Analyseur::ouBinaire() {
    auto a = etBinaire();
    while (jeton().estOp("|")) {
        if (dansTableau_ && nouvelElement()) break;
        avancer();
        a = binaire("|", a, etBinaire());
    }
    return a;
}

NoeudPtr Analyseur::etBinaire() {
    auto a = comparaison();
    while (jeton().estOp("&")) {
        if (dansTableau_ && nouvelElement()) break;
        avancer();
        a = binaire("&", a, comparaison());
    }
    return a;
}

NoeudPtr Analyseur::comparaison() {
    auto a = plage();
    for (;;) {
        static const char* ops[] = {"==", "~=", "<=", ">=", "<", ">", nullptr};
        const char* trouve = nullptr;
        for (int k = 0; ops[k]; ++k)
            if (jeton().estOp(ops[k])) { trouve = ops[k]; break; }
        if (!trouve) break;
        if (dansTableau_ && nouvelElement()) break;
        avancer();
        a = binaire(trouve, a, plage());
    }
    return a;
}

NoeudPtr Analyseur::plage() {
    auto a = additif();
    if (!jeton().estOp(":")) return a;
    avancer();
    auto b = additif();
    auto n = Noeud::creer(TypeN::Plage);
    if (jeton().estOp(":")) {
        avancer();
        auto c = additif();
        n->enfants = {a, b, c};  // début, pas, fin
    } else {
        n->enfants = {a, nullptr, b};
    }
    return n;
}

NoeudPtr Analyseur::additif() {
    auto a = multiplicatif();
    for (;;) {
        if (!(jeton().estOp("+") || jeton().estOp("-"))) break;
        if (dansTableau_ && nouvelElement()) break;
        std::string op = jeton().texte;
        avancer();
        a = binaire(op, a, multiplicatif());
    }
    return a;
}

NoeudPtr Analyseur::multiplicatif() {
    auto a = unaire();
    for (;;) {
        static const char* ops[] = {"*", "/", "\\", ".*", "./", ".\\", nullptr};
        const char* trouve = nullptr;
        for (int k = 0; ops[k]; ++k)
            if (jeton().estOp(ops[k])) { trouve = ops[k]; break; }
        if (!trouve) break;
        if (dansTableau_ && nouvelElement()) break;
        avancer();
        a = binaire(trouve, a, unaire());
    }
    return a;
}

NoeudPtr Analyseur::unaire() {
    if (jeton().estOp("-") || jeton().estOp("+") || jeton().estOp("~") ||
        jeton().estOp("++") || jeton().estOp("--")) {
        std::string op = jeton().texte;
        avancer();
        auto n = Noeud::creer(TypeN::OpUnaire);
        n->texte = (op == "++" || op == "--") ? op.substr(0, 1) : op;
        if (op == "++" || op == "--") {
            // ++x : incrément préfixe, traité comme + x (rare, toléré)
            n->texte = "+";
        }
        n->enfants = {unaire()};
        return n;
    }
    return puissance();
}

NoeudPtr Analyseur::puissance() {
    auto a = postfixe();
    for (;;) {
        if (!(jeton().estOp("^") || jeton().estOp(".^"))) break;
        if (dansTableau_ && nouvelElement()) break;
        std::string op = jeton().texte;
        avancer();
        // Un signe unaire est permis juste après : 2^-1
        NoeudPtr b;
        if (jeton().estOp("-") || jeton().estOp("+") || jeton().estOp("~")) {
            std::string u = jeton().texte;
            avancer();
            auto nu = Noeud::creer(TypeN::OpUnaire);
            nu->texte = u;
            nu->enfants = {postfixe()};
            b = nu;
        } else {
            b = postfixe();
        }
        a = binaire(op, a, b);
    }
    return a;
}

std::vector<NoeudPtr> Analyseur::listeArguments(const char* fermeture) {
    std::vector<NoeudPtr> args;
    int sauveTableau = dansTableau_;
    dansTableau_ = 0;
    ++dansIndice_;
    sauterFinsLignes();
    if (!jeton().estOp(fermeture)) {
        for (;;) {
            sauterFinsLignes();
            if (jeton().estOp(":") &&
                (jeton(1).estOp(",") || jeton(1).estOp(fermeture))) {
                args.push_back(Noeud::creer(TypeN::DeuxPointsSeul));
                avancer();
            } else if (jeton().estOp("~") &&
                       (jeton(1).estOp(",") || jeton(1).estOp(fermeture))) {
                auto n = Noeud::creer(TypeN::Ident);
                n->texte = "~";
                args.push_back(n);
                avancer();
            } else {
                args.push_back(expression());
            }
            sauterFinsLignes();
            if (jeton().estOp(",")) { avancer(); continue; }
            break;
        }
    }
    sauterFinsLignes();
    exigerOp(fermeture);
    --dansIndice_;
    dansTableau_ = sauveTableau;
    return args;
}

NoeudPtr Analyseur::postfixe() {
    groupeParenthese_ = false;
    auto base = primaire();
    // « (a)(b) » : une parenthèse qui en suit une autre est presque
    // toujours une multiplication oubliée. MATLAB refuse à l'analyse, en
    // le disant ; sans ce test, on tentait d'indexer le résultat et l'on
    // rendait « Index in position 1 is invalid », qui ne désigne rien.
    const bool baseParenthesee = groupeParenthese_;
    NoeudPtr acces;
    auto ajouter = [&](ElementAcces e) {
        if (!acces) {
            acces = Noeud::creer(TypeN::Acces);
            acces->enfants = {base};
            acces->ligne = base->ligne;
        }
        acces->acces.push_back(std::move(e));
    };
    for (;;) {
        const Jeton& t = jeton();
        if (t.estOp("(") && !(dansTableau_ && t.espaceAvant)) {
            if (baseParenthesee && !acces)
                erreurSyntaxe("Invalid expression. Check for missing multiplication "
                              "operator, missing or unbalanced delimiters, or other "
                              "syntax error.");
            avancer();
            ElementAcces e;
            e.genre = '(';
            e.args = listeArguments(")");
            ajouter(std::move(e));
        } else if (t.estOp("{") && !(dansTableau_ && t.espaceAvant)) {
            avancer();
            ElementAcces e;
            e.genre = '{';
            e.args = listeArguments("}");
            ajouter(std::move(e));
        } else if (t.estOp(".") && (jeton(1).genre == Genre::Ident ||
                                    jeton(1).genre == Genre::MotCle)) {
            avancer();
            ElementAcces e;
            e.genre = '.';
            e.nom = jeton().texte;
            avancer();
            ajouter(std::move(e));
        } else if (t.estOp(".") && jeton(1).estOp("(")) {
            avancer();
            avancer();
            ElementAcces e;
            e.genre = '?';
            e.args = listeArguments(")");
            ajouter(std::move(e));
        } else if (t.estOp("'") || t.estOp(".'")) {
            avancer();
            auto n = Noeud::creer(TypeN::OpPostfixe);
            n->texte = t.texte;
            n->enfants = {acces ? acces : base};
            base = n;
            acces = nullptr;
        } else {
            break;
        }
    }
    return acces ? acces : base;
}

bool Analyseur::nouvelElement() const {
    // Appelée dans [ ] et { } : le jeton courant commence-t-il un nouvel
    // élément plutôt que de poursuivre l'expression en cours ?
    const Jeton& t = jeton();
    if (!t.espaceAvant) return false;
    if (t.genre == Genre::Operateur) {
        if (t.texte == "+" || t.texte == "-" || t.texte == "~" || t.texte == "@")
            return !t.espaceApres;
        if (t.texte == "(" || t.texte == "[" || t.texte == "{") return true;
        return false;
    }
    if (t.genre == Genre::Nombre || t.genre == Genre::Ident ||
        t.genre == Genre::Litteral || t.genre == Genre::LitteralChaine)
        return true;
    if (t.genre == Genre::MotCle && t.texte == "end") return dansIndice_ > 0;
    return false;
}

NoeudPtr Analyseur::litteralTableau(bool cellule) {
    auto n = Noeud::creer(cellule ? TypeN::Cellule : TypeN::Matrice);
    n->ligne = jeton().ligne;
    avancer();  // [ ou {
    ++dansTableau_;
    std::vector<NoeudPtr> rangee;
    const char* fermeture = cellule ? "}" : "]";
    for (;;) {
        while (jeton().genre == Genre::NouvelleLigne || jeton().estOp(";")) {
            avancer();
            if (!rangee.empty()) {
                n->rangees.push_back(rangee);
                rangee.clear();
            }
        }
        if (jeton().estOp(fermeture)) { avancer(); break; }
        if (fini()) erreurSyntaxe(std::string("Expected '") + fermeture + "'.");
        if (jeton().estOp(",")) { avancer(); continue; }
        if (jeton().estOp("~") && (jeton(1).estOp(",") || jeton(1).estOp(fermeture) ||
                                   jeton(1).estOp("]"))) {
            auto id = Noeud::creer(TypeN::Ident);
            id->texte = "~";
            rangee.push_back(id);
            avancer();
            continue;
        }
        rangee.push_back(expression());
    }
    if (!rangee.empty()) n->rangees.push_back(rangee);
    --dansTableau_;
    return n;
}

NoeudPtr Analyseur::primaire() {
    const Jeton& t = jeton();
    switch (t.genre) {
        case Genre::Nombre: {
            auto n = Noeud::creer(TypeN::Nombre);
            n->nombre = t.nombre;
            n->imaginaire = t.imaginaire;
            n->ligne = t.ligne;
            avancer();
            return n;
        }
        case Genre::Litteral: {
            auto n = Noeud::creer(TypeN::Litteral);
            n->texte = t.texte;
            n->ligne = t.ligne;
            avancer();
            return n;
        }
        case Genre::LitteralChaine: {
            auto n = Noeud::creer(TypeN::LitteralChaine);
            n->texte = t.texte;
            n->ligne = t.ligne;
            avancer();
            return n;
        }
        case Genre::Ident: {
            auto n = Noeud::creer(TypeN::Ident);
            n->texte = t.texte;
            n->ligne = t.ligne;
            avancer();
            return n;
        }
        case Genre::MotCle: {
            if (t.texte == "end" && dansIndice_ > 0) {
                auto n = Noeud::creer(TypeN::FinIndice);
                n->ligne = t.ligne;
                avancer();
                return n;
            }
            erreurSyntaxe("Unexpected keyword '" + t.texte + "' in an expression.");
        }
        case Genre::Operateur: {
            if (t.texte == "(") {
                avancer();
                int sauve = dansTableau_;
                dansTableau_ = 0;
                sauterFinsLignes();
                auto e = expression();
                sauterFinsLignes();
                dansTableau_ = sauve;
                exigerOp(")");
                groupeParenthese_ = true;
                return e;
            }
            if (t.texte == "[") return litteralTableau(false);
            if (t.texte == "{") return litteralTableau(true);
            if (t.texte == ":") {
                auto n = Noeud::creer(TypeN::DeuxPointsSeul);
                avancer();
                return n;
            }
            if (t.texte == "@") {
                avancer();
                if (jeton().estOp("(")) {
                    avancer();
                    auto n = Noeud::creer(TypeN::Anonyme);
                    n->ligne = t.ligne;
                    while (!jeton().estOp(")") && !fini()) {
                        if (jeton().genre == Genre::Ident) {
                            n->noms.push_back(jeton().texte);
                            avancer();
                        } else if (jeton().estOp("~")) {
                            n->noms.push_back("~");
                            avancer();
                        } else if (jeton().estOp(",")) {
                            avancer();
                        } else {
                            erreurSyntaxe("Invalid anonymous function parameter.");
                        }
                    }
                    exigerOp(")");
                    int sauve = dansTableau_;
                    dansTableau_ = 0;
                    n->enfants = {expression()};
                    dansTableau_ = sauve;
                    return n;
                }
                if (jeton().genre == Genre::Ident) {
                    auto n = Noeud::creer(TypeN::PoigneeNom);
                    n->texte = jeton().texte;
                    n->ligne = t.ligne;
                    avancer();
                    while (jeton().estOp(".") && jeton(1).genre == Genre::Ident) {
                        avancer();
                        n->texte += "." + jeton().texte;
                        avancer();
                    }
                    return n;
                }
                erreurSyntaxe("Invalid function handle.");
            }
            erreurSyntaxe("Unexpected operator '" + t.texte + "'.");
        }
        case Genre::NouvelleLigne:
        case Genre::Fin:
            erreurSyntaxe("Unexpected end of statement.");
    }
    erreurSyntaxe("Unexpected token.");
}

}  // namespace matlibre
