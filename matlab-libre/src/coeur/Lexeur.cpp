#include "matlibre/Lexeur.h"

#include <cctype>
#include <cstdlib>
#include <cstring>
#include <set>

#include "matlibre/Erreur.h"

namespace matlibre {

static const std::set<std::string>& motsCles() {
    static const std::set<std::string> m = {
        "if", "elseif", "else", "end", "for", "parfor", "while", "do", "until",
        "switch", "case", "otherwise", "break", "continue", "return", "function",
        "try", "catch", "global", "persistent", "classdef", "properties",
        "methods", "events", "enumeration", "spmd", "endif",
        "endfor", "endwhile", "endfunction", "endswitch", "end_try_catch",
        "unwind_protect", "unwind_protect_cleanup", "end_unwind_protect"
    };
    return m;
}

bool estMotCle(const std::string& s) { return motsCles().count(s) > 0; }

Lexeur::Lexeur(std::string source) : src_(std::move(source)) {}

void Lexeur::avancer(int n) {
    for (int k = 0; k < n && i_ < src_.size(); ++k) {
        if (src_[i_] == '\n') {
            ++ligne_;
            colonne_ = 1;
        } else {
            ++colonne_;
        }
        ++i_;
    }
}

bool Lexeur::finLigneCommentaire() {
    // Renvoie vrai si l'on vient de consommer un commentaire jusqu'au bout de
    // la ligne (sans consommer le saut de ligne lui-même).
    if (actuel() == '%' || actuel() == '#') {
        while (i_ < src_.size() && src_[i_] != '\n') avancer();
        return true;
    }
    return false;
}

static bool estDebutIdent(char c) { return std::isalpha((unsigned char)c) || c == '_'; }
static bool estIdent(char c) { return std::isalnum((unsigned char)c) || c == '_'; }

std::vector<Jeton> Lexeur::analyser() {
    std::vector<Jeton> jetons;
    bool blocCommentaire = false;

    auto precedentTermineValeur = [&]() -> bool {
        if (jetons.empty()) return false;
        const Jeton& p = jetons.back();
        if (p.genre == Genre::Nombre || p.genre == Genre::Ident ||
            p.genre == Genre::Litteral || p.genre == Genre::LitteralChaine)
            return true;
        if (p.genre == Genre::MotCle && p.texte == "end") return true;
        if (p.genre == Genre::Operateur)
            return p.texte == ")" || p.texte == "]" || p.texte == "}" ||
                   p.texte == "'" || p.texte == ".'";
        return false;
    };

    while (i_ < src_.size()) {
        bool blanc = false;
        // --- blancs, continuations, commentaires ---
        for (;;) {
            while (actuel() == ' ' || actuel() == '\t' || actuel() == '\r') {
                blanc = true;
                avancer();
            }
            // bloc %{ ... %}
            if (!blocCommentaire && (actuel() == '%' || actuel() == '#') && suivant() == '{') {
                std::size_t j = i_ + 2;
                bool seul = true;
                while (j < src_.size() && src_[j] != '\n') {
                    if (!std::isspace((unsigned char)src_[j])) { seul = false; break; }
                    ++j;
                }
                if (seul) {
                    blocCommentaire = true;
                    while (i_ < src_.size() && src_[i_] != '\n') avancer();
                }
            }
            if (blocCommentaire) {
                // avaler jusqu'à %} sur sa propre ligne
                while (i_ < src_.size()) {
                    if (src_[i_] == '\n') {
                        avancer();
                        std::size_t j = i_;
                        while (j < src_.size() && (src_[j] == ' ' || src_[j] == '\t')) ++j;
                        if (j + 1 < src_.size() && (src_[j] == '%' || src_[j] == '#') &&
                            src_[j + 1] == '}') {
                            while (i_ < src_.size() && src_[i_] != '\n') avancer();
                            blocCommentaire = false;
                            break;
                        }
                    } else {
                        avancer();
                    }
                }
                blanc = true;
                continue;
            }
            if (actuel() == '.' && suivant() == '.' && suivant(2) == '.') {
                while (i_ < src_.size() && src_[i_] != '\n') avancer();
                if (i_ < src_.size()) avancer();  // le saut de ligne
                blanc = true;
                continue;
            }
            if (finLigneCommentaire()) {
                blanc = true;
                continue;
            }
            break;
        }
        if (i_ >= src_.size()) break;

        Jeton j;
        j.ligne = ligne_;
        j.colonne = colonne_;
        j.espaceAvant = blanc;
        char c = actuel();

        if (c == '\n') {
            avancer();
            bool dansParenthese = !pile_.empty() && pile_.back() == '(';
            if (dansParenthese) continue;  // les parenthèses avalent les retours
            j.genre = Genre::NouvelleLigne;
            j.texte = "\n";
            jetons.push_back(j);
            continue;
        }

        // --- nombres ---
        if (std::isdigit((unsigned char)c) ||
            (c == '.' && std::isdigit((unsigned char)suivant()))) {
            std::string s;
            if (c == '0' && (suivant() == 'x' || suivant() == 'X')) {
                avancer(2);
                std::string h;
                while (std::isxdigit((unsigned char)actuel())) { h += actuel(); avancer(); }
                j.genre = Genre::Nombre;
                j.nombre = (double)std::strtoull(h.c_str(), nullptr, 16);
                j.texte = "0x" + h;
                jetons.push_back(j);
                continue;
            }
            if (c == '0' && (suivant() == 'b' || suivant() == 'B') &&
                (suivant(2) == '0' || suivant(2) == '1')) {
                avancer(2);
                std::string h;
                while (actuel() == '0' || actuel() == '1') { h += actuel(); avancer(); }
                j.genre = Genre::Nombre;
                j.nombre = (double)std::strtoull(h.c_str(), nullptr, 2);
                j.texte = "0b" + h;
                jetons.push_back(j);
                continue;
            }
            while (std::isdigit((unsigned char)actuel())) { s += actuel(); avancer(); }
            if (actuel() == '.' && !(suivant() == '*' || suivant() == '/' ||
                                     suivant() == '\\' || suivant() == '^' ||
                                     suivant() == '\'')) {
                s += '.';
                avancer();
                while (std::isdigit((unsigned char)actuel())) { s += actuel(); avancer(); }
            }
            if (actuel() == 'e' || actuel() == 'E' || actuel() == 'd' || actuel() == 'D') {
                std::size_t sauve = i_;
                std::string e;
                e += 'e';
                avancer();
                if (actuel() == '+' || actuel() == '-') { e += actuel(); avancer(); }
                if (std::isdigit((unsigned char)actuel())) {
                    while (std::isdigit((unsigned char)actuel())) { e += actuel(); avancer(); }
                    s += e;
                } else {
                    i_ = sauve;
                }
            }
            j.genre = Genre::Nombre;
            j.nombre = std::atof(s.c_str());
            j.texte = s;
            if (actuel() == 'i' || actuel() == 'j' || actuel() == 'I' || actuel() == 'J') {
                if (!estIdent(suivant())) {
                    j.imaginaire = true;
                    avancer();
                }
            }
            j.espaceApres = (actuel() == ' ' || actuel() == '\t');
            jetons.push_back(j);
            continue;
        }

        // --- identificateurs et mots-clés ---
        if (estDebutIdent(c)) {
            std::string s;
            while (estIdent(actuel())) { s += actuel(); avancer(); }
            j.texte = s;
            j.genre = estMotCle(s) ? Genre::MotCle : Genre::Ident;
            j.espaceApres = (actuel() == ' ' || actuel() == '\t');
            jetons.push_back(j);
            continue;
        }

        // --- chaînes ---
        // Dans « [a 'x'] » l'espace fait la différence : à l'intérieur de
        // crochets ou d'accolades, une apostrophe précédée d'un blanc ouvre
        // une chaîne au lieu de transposer.
        bool dansTableau = !pile_.empty() && (pile_.back() == '[' || pile_.back() == '{');
        if (c == '\'' && !(precedentTermineValeur() && !(dansTableau && blanc))) {
            avancer();
            std::string s;
            for (;;) {
                if (i_ >= src_.size() || actuel() == '\n')
                    erreur("MATLAB:unterminatedString",
                           "Character vector is not terminated properly.");
                if (actuel() == '\'') {
                    if (suivant() == '\'') { s += '\''; avancer(2); continue; }
                    avancer();
                    break;
                }
                s += actuel();
                avancer();
            }
            j.genre = Genre::Litteral;
            j.texte = s;
            j.espaceApres = (actuel() == ' ' || actuel() == '\t');
            jetons.push_back(j);
            continue;
        }
        if (c == '"') {
            avancer();
            std::string s;
            for (;;) {
                if (i_ >= src_.size() || actuel() == '\n')
                    erreur("MATLAB:unterminatedString", "String is not terminated properly.");
                if (actuel() == '"') {
                    if (suivant() == '"') { s += '"'; avancer(2); continue; }
                    avancer();
                    break;
                }
                s += actuel();
                avancer();
            }
            j.genre = Genre::LitteralChaine;
            j.texte = s;
            j.espaceApres = (actuel() == ' ' || actuel() == '\t');
            jetons.push_back(j);
            continue;
        }

        // --- opérateurs ---
        static const char* deux[] = {".*", "./", ".\\", ".^", ".'", "==", "~=", "!=",
                                     "<=", ">=", "&&", "||", "+=", "-=", "*=", "/=",
                                     "^=", "++", "--", nullptr};
        std::string op;
        for (int k = 0; deux[k]; ++k) {
            if (src_.compare(i_, 2, deux[k]) == 0) { op = deux[k]; break; }
        }
        if (op.empty()) op = std::string(1, c);
        avancer((int)op.size());
        if (op == "!") op = "~";
        if (op == "!=") op = "~=";
        if (op == "(" || op == "[" || op == "{") pile_.push_back(op[0]);
        if (op == ")" || op == "]" || op == "}") {
            if (!pile_.empty()) pile_.pop_back();
        }
        j.genre = Genre::Operateur;
        j.texte = op;
        j.espaceApres = (actuel() == ' ' || actuel() == '\t' || actuel() == '\n' ||
                         actuel() == '\0');
        jetons.push_back(j);
    }

    Jeton fin;
    fin.genre = Genre::Fin;
    fin.ligne = ligne_;
    jetons.push_back(fin);
    return jetons;
}

}  // namespace matlibre
