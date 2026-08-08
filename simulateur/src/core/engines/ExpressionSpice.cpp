#include "core/engines/ExpressionSpice.h"

#include <algorithm>
#include <cctype>
#include <cmath>
#include <cstdlib>
#include <cstring>

namespace coeur {

namespace {

bool caractere_nom(char c) {
    return std::isalnum(static_cast<unsigned char>(c)) || c == '_' || c == '.'
           || c == '+' || c == '-';
}

// Découpe l'expression en jetons. Les noms de nœuds peuvent contenir des
// signes (« IN+ », « AM1_-P ») : on ne les sépare que dans un contexte où un
// opérateur est attendu, c'est-à-dire hors des parenthèses de V(...).
std::vector<std::string> decouper(const std::string& texte) {
    std::vector<std::string> jetons;
    size_t k = 0;
    bool dans_tension = false;      // entre « V( » et la parenthèse fermante
    while (k < texte.size()) {
        const char c = texte[k];
        if (std::isspace(static_cast<unsigned char>(c))) {
            ++k;
            continue;
        }
        // Opérateurs à deux caractères.
        if (k + 1 < texte.size()) {
            const std::string paire = texte.substr(k, 2);
            if (paire == ">=" || paire == "<=" || paire == "==" || paire == "!="
                || paire == "&&" || paire == "||") {
                jetons.push_back(paire);
                k += 2;
                continue;
            }
        }
        if (strchr("()+-*/<>!?:,", c) && !(dans_tension && (c == '+' || c == '-'))) {
            jetons.emplace_back(1, c);
            if (c == ')') dans_tension = false;
            ++k;
            continue;
        }
        // Nombre.
        if (std::isdigit(static_cast<unsigned char>(c))
            || (c == '.' && k + 1 < texte.size()
                && std::isdigit(static_cast<unsigned char>(texte[k + 1])))) {
            size_t debut = k;
            while (k < texte.size()
                   && (std::isdigit(static_cast<unsigned char>(texte[k]))
                       || texte[k] == '.'))
                ++k;
            if (k < texte.size() && (texte[k] == 'e' || texte[k] == 'E')) {
                size_t essai = k + 1;
                if (essai < texte.size() && (texte[essai] == '+' || texte[essai] == '-'))
                    ++essai;
                if (essai < texte.size()
                    && std::isdigit(static_cast<unsigned char>(texte[essai]))) {
                    k = essai;
                    while (k < texte.size()
                           && std::isdigit(static_cast<unsigned char>(texte[k])))
                        ++k;
                }
            }
            jetons.push_back(texte.substr(debut, k - debut));
            continue;
        }
        // Nom : fonction ou nœud.
        size_t debut = k;
        while (k < texte.size() && caractere_nom(texte[k])) {
            // Hors d'un V(...), « + » et « − » sont des opérateurs.
            if (!dans_tension && (texte[k] == '+' || texte[k] == '-')
                && k > debut)
                break;
            ++k;
        }
        if (k == debut) {   // caractère inconnu : on l'ignore
            ++k;
            continue;
        }
        std::string mot = texte.substr(debut, k - debut);
        jetons.push_back(mot);
        std::string minuscule = mot;
        std::transform(minuscule.begin(), minuscule.end(), minuscule.begin(),
                       [](unsigned char lettre) { return std::tolower(lettre); });
        if (minuscule == "v" && k < texte.size() && texte[k] == '(')
            dans_tension = true;
        continue;
    }
    return jetons;
}

}  // namespace

const std::string& ExpressionSpice::jeton() const {
    static const std::string vide;
    return position_ < jetons_.size() ? jetons_[position_] : vide;
}

bool ExpressionSpice::accepter(const std::string& attendu) {
    if (fin() || jetons_[position_] != attendu) return false;
    ++position_;
    return true;
}

int ExpressionSpice::ajouter(Noeud noeud) {
    arbre_.push_back(noeud);
    return static_cast<int>(arbre_.size()) - 1;
}

bool ExpressionSpice::compiler(
    const std::string& texte,
    const std::function<int(const std::string&)>& resoudre_noeud) {
    arbre_.clear();
    dependances_.clear();
    erreur_.clear();
    racine_ = -1;
    resoudre_ = resoudre_noeud;
    jetons_ = decouper(texte);
    position_ = 0;

    racine_ = lire_ternaire();
    if (racine_ < 0) {
        if (erreur_.empty()) erreur_ = "expression illisible : " + texte;
        return false;
    }
    if (!fin()) {
        erreur_ = "texte en trop après l'expression : " + jeton();
        racine_ = -1;
        return false;
    }
    std::sort(dependances_.begin(), dependances_.end());
    dependances_.erase(std::unique(dependances_.begin(), dependances_.end()),
                       dependances_.end());
    return true;
}

int ExpressionSpice::lire_ternaire() {
    const int condition = lire_ou();
    if (condition < 0) return -1;
    if (!accepter("?")) return condition;
    const int oui = lire_ternaire();
    if (oui < 0) return -1;
    if (!accepter(":")) {
        erreur_ = "« : » attendu dans l'expression conditionnelle";
        return -1;
    }
    const int non = lire_ternaire();
    if (non < 0) return -1;
    Noeud noeud;
    noeud.op = Op::Ternaire;
    noeud.a = condition;
    noeud.b = oui;
    noeud.c = non;
    return ajouter(noeud);
}

int ExpressionSpice::lire_ou() {
    int gauche = lire_et();
    if (gauche < 0) return -1;
    while (accepter("||")) {
        const int droite = lire_et();
        if (droite < 0) return -1;
        Noeud noeud;
        noeud.op = Op::Ou;
        noeud.a = gauche;
        noeud.b = droite;
        gauche = ajouter(noeud);
    }
    return gauche;
}

int ExpressionSpice::lire_et() {
    int gauche = lire_comparaison();
    if (gauche < 0) return -1;
    while (accepter("&&")) {
        const int droite = lire_comparaison();
        if (droite < 0) return -1;
        Noeud noeud;
        noeud.op = Op::Et;
        noeud.a = gauche;
        noeud.b = droite;
        gauche = ajouter(noeud);
    }
    return gauche;
}

int ExpressionSpice::lire_comparaison() {
    int gauche = lire_somme();
    if (gauche < 0) return -1;
    while (!fin()) {
        Op op;
        if (accepter(">")) op = Op::Sup;
        else if (accepter("<")) op = Op::Inf;
        else if (accepter(">=")) op = Op::SupEgal;
        else if (accepter("<=")) op = Op::InfEgal;
        else if (accepter("==")) op = Op::Egal;
        else if (accepter("!=")) op = Op::Different;
        else break;
        const int droite = lire_somme();
        if (droite < 0) return -1;
        Noeud noeud;
        noeud.op = op;
        noeud.a = gauche;
        noeud.b = droite;
        gauche = ajouter(noeud);
    }
    return gauche;
}

int ExpressionSpice::lire_somme() {
    int gauche = lire_produit();
    if (gauche < 0) return -1;
    while (!fin()) {
        Op op;
        if (accepter("+")) op = Op::Plus;
        else if (accepter("-")) op = Op::Moins;
        else break;
        const int droite = lire_produit();
        if (droite < 0) return -1;
        Noeud noeud;
        noeud.op = op;
        noeud.a = gauche;
        noeud.b = droite;
        gauche = ajouter(noeud);
    }
    return gauche;
}

int ExpressionSpice::lire_produit() {
    int gauche = lire_unaire();
    if (gauche < 0) return -1;
    while (!fin()) {
        Op op;
        if (accepter("*")) op = Op::Fois;
        else if (accepter("/")) op = Op::Divise;
        else break;
        const int droite = lire_unaire();
        if (droite < 0) return -1;
        Noeud noeud;
        noeud.op = op;
        noeud.a = gauche;
        noeud.b = droite;
        gauche = ajouter(noeud);
    }
    return gauche;
}

int ExpressionSpice::lire_unaire() {
    if (accepter("-")) {
        const int sous = lire_unaire();
        if (sous < 0) return -1;
        Noeud noeud;
        noeud.op = Op::Oppose;
        noeud.a = sous;
        return ajouter(noeud);
    }
    if (accepter("+")) return lire_unaire();
    if (accepter("!")) {
        const int sous = lire_unaire();
        if (sous < 0) return -1;
        Noeud noeud;
        noeud.op = Op::Non;
        noeud.a = sous;
        return ajouter(noeud);
    }
    return lire_terme();
}

int ExpressionSpice::lire_terme() {
    if (fin()) {
        erreur_ = "expression tronquée";
        return -1;
    }
    if (accepter("(")) {
        const int sous = lire_ternaire();
        if (sous < 0) return -1;
        if (!accepter(")")) {
            erreur_ = "parenthèse fermante manquante";
            return -1;
        }
        return sous;
    }

    const std::string mot = jeton();
    std::string minuscule = mot;
    std::transform(minuscule.begin(), minuscule.end(), minuscule.begin(),
                   [](unsigned char lettre) { return std::tolower(lettre); });

    // Nombre.
    if (!mot.empty()
        && (std::isdigit(static_cast<unsigned char>(mot[0])) || mot[0] == '.')) {
        ++position_;
        Noeud noeud;
        noeud.op = Op::Nombre;
        noeud.valeur = std::strtod(mot.c_str(), nullptr);
        return ajouter(noeud);
    }

    // Tension d'un nœud, ou différence entre deux.
    if (minuscule == "v") {
        ++position_;
        if (!accepter("(")) {
            erreur_ = "« V » sans parenthèse";
            return -1;
        }
        Noeud noeud;
        noeud.op = Op::Tension;
        noeud.noeud_plus = resoudre_ ? resoudre_(jeton()) : -1;
        if (noeud.noeud_plus >= 0) dependances_.push_back(noeud.noeud_plus);
        ++position_;
        if (accepter(",")) {
            noeud.noeud_moins = resoudre_ ? resoudre_(jeton()) : -1;
            if (noeud.noeud_moins >= 0) dependances_.push_back(noeud.noeud_moins);
            ++position_;
        }
        if (!accepter(")")) {
            erreur_ = "parenthèse fermante manquante après V(";
            return -1;
        }
        return ajouter(noeud);
    }

    // Fonctions.
    struct Table { const char* nom; Op op; int arguments; };
    static const Table table[] = {
        {"min", Op::Mini, 2},        {"max", Op::Maxi, 2},
        {"abs", Op::Valeur_absolue, 1}, {"exp", Op::Exponentielle, 1},
        {"log", Op::Logarithme, 1},  {"ln", Op::Logarithme, 1},
        {"sqrt", Op::Racine, 1}};
    for (const Table& entree : table) {
        if (minuscule != entree.nom) continue;
        ++position_;
        if (!accepter("(")) {
            erreur_ = std::string(entree.nom) + " sans parenthèse";
            return -1;
        }
        Noeud noeud;
        noeud.op = entree.op;
        noeud.a = lire_ternaire();
        if (noeud.a < 0) return -1;
        if (entree.arguments == 2) {
            if (!accepter(",")) {
                erreur_ = std::string(entree.nom) + " attend deux arguments";
                return -1;
            }
            noeud.b = lire_ternaire();
            if (noeud.b < 0) return -1;
        }
        if (!accepter(")")) {
            erreur_ = "parenthèse fermante manquante";
            return -1;
        }
        return ajouter(noeud);
    }

    erreur_ = "terme inconnu dans l'expression : " + mot;
    return -1;
}

double ExpressionSpice::evaluer(const std::vector<double>& tensions) const {
    if (racine_ < 0) return 0.0;
    return evaluer_noeud(racine_, tensions);
}

double ExpressionSpice::evaluer_noeud(int rang,
                                      const std::vector<double>& tensions) const {
    const Noeud& noeud = arbre_[rang];
    auto lire = [&tensions](int indice) {
        return indice >= 0 && indice < static_cast<int>(tensions.size())
                   ? tensions[indice]
                   : 0.0;
    };
    switch (noeud.op) {
        case Op::Nombre: return noeud.valeur;
        case Op::Tension: return lire(noeud.noeud_plus) - lire(noeud.noeud_moins);
        case Op::Plus:
            return evaluer_noeud(noeud.a, tensions)
                   + evaluer_noeud(noeud.b, tensions);
        case Op::Moins:
            return evaluer_noeud(noeud.a, tensions)
                   - evaluer_noeud(noeud.b, tensions);
        case Op::Fois:
            return evaluer_noeud(noeud.a, tensions)
                   * evaluer_noeud(noeud.b, tensions);
        case Op::Divise: {
            const double diviseur = evaluer_noeud(noeud.b, tensions);
            if (std::fabs(diviseur) < 1e-300) return 0.0;
            return evaluer_noeud(noeud.a, tensions) / diviseur;
        }
        case Op::Oppose: return -evaluer_noeud(noeud.a, tensions);
        case Op::Non: return evaluer_noeud(noeud.a, tensions) != 0.0 ? 0.0 : 1.0;
        case Op::Sup:
            return evaluer_noeud(noeud.a, tensions)
                           > evaluer_noeud(noeud.b, tensions) ? 1.0 : 0.0;
        case Op::Inf:
            return evaluer_noeud(noeud.a, tensions)
                           < evaluer_noeud(noeud.b, tensions) ? 1.0 : 0.0;
        case Op::SupEgal:
            return evaluer_noeud(noeud.a, tensions)
                           >= evaluer_noeud(noeud.b, tensions) ? 1.0 : 0.0;
        case Op::InfEgal:
            return evaluer_noeud(noeud.a, tensions)
                           <= evaluer_noeud(noeud.b, tensions) ? 1.0 : 0.0;
        case Op::Egal:
            return evaluer_noeud(noeud.a, tensions)
                           == evaluer_noeud(noeud.b, tensions) ? 1.0 : 0.0;
        case Op::Different:
            return evaluer_noeud(noeud.a, tensions)
                           != evaluer_noeud(noeud.b, tensions) ? 1.0 : 0.0;
        case Op::Et:
            return (evaluer_noeud(noeud.a, tensions) != 0.0
                    && evaluer_noeud(noeud.b, tensions) != 0.0) ? 1.0 : 0.0;
        case Op::Ou:
            return (evaluer_noeud(noeud.a, tensions) != 0.0
                    || evaluer_noeud(noeud.b, tensions) != 0.0) ? 1.0 : 0.0;
        case Op::Ternaire:
            return evaluer_noeud(noeud.a, tensions) != 0.0
                       ? evaluer_noeud(noeud.b, tensions)
                       : evaluer_noeud(noeud.c, tensions);
        case Op::Mini:
            return std::min(evaluer_noeud(noeud.a, tensions),
                            evaluer_noeud(noeud.b, tensions));
        case Op::Maxi:
            return std::max(evaluer_noeud(noeud.a, tensions),
                            evaluer_noeud(noeud.b, tensions));
        case Op::Valeur_absolue:
            return std::fabs(evaluer_noeud(noeud.a, tensions));
        case Op::Exponentielle:
            return std::exp(std::min(80.0, evaluer_noeud(noeud.a, tensions)));
        case Op::Logarithme: {
            const double valeur = evaluer_noeud(noeud.a, tensions);
            return valeur > 0 ? std::log(valeur) : 0.0;
        }
        case Op::Racine: {
            const double valeur = evaluer_noeud(noeud.a, tensions);
            return valeur > 0 ? std::sqrt(valeur) : 0.0;
        }
    }
    return 0.0;
}

}  // namespace coeur
