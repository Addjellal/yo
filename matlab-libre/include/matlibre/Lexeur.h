// Lexeur.h — découpage du texte source en jetons.
//
// Deux ambiguïtés du langage MATLAB se règlent ici, pas dans l'analyseur :
//
//   1. l'apostrophe est soit la transposition (A'), soit le début d'une
//      chaîne ('abc'). Elle transpose quand le jeton précédent termine une
//      valeur : identificateur, nombre, ), ], }, ' ou le mot « end ».
//   2. l'espace compte à l'intérieur de [ ] et { } : « [1 -2] » fait deux
//      éléments, « [1 - 2] » un seul. On mémorise donc, pour chaque jeton,
//      s'il est précédé et suivi d'un blanc ; l'analyseur tranche ensuite.
#pragma once

#include <string>
#include <vector>

namespace matlibre {

enum class Genre {
    Fin,          // fin du texte
    Nombre,
    Litteral,     // 'texte'  -> tableau de caractères
    LitteralChaine,  // "texte" -> string
    Ident,
    MotCle,
    Operateur,
    NouvelleLigne
};

struct Jeton {
    Genre genre = Genre::Fin;
    std::string texte;
    double nombre = 0.0;
    bool imaginaire = false;
    int ligne = 1;
    int colonne = 1;
    bool espaceAvant = false;
    bool espaceApres = false;

    bool est(const char* s) const { return texte == s; }
    bool estOp(const char* s) const { return genre == Genre::Operateur && texte == s; }
    bool estMot(const char* s) const { return genre == Genre::MotCle && texte == s; }
};

bool estMotCle(const std::string& s);

class Lexeur {
public:
    explicit Lexeur(std::string source);
    std::vector<Jeton> analyser();

private:
    std::string src_;
    std::size_t i_ = 0;
    int ligne_ = 1;
    int colonne_ = 1;
    std::vector<char> pile_;  // délimiteurs ouverts

    char actuel() const { return i_ < src_.size() ? src_[i_] : '\0'; }
    char suivant(int k = 1) const {
        return (i_ + (std::size_t)k) < src_.size() ? src_[i_ + (std::size_t)k] : '\0';
    }
    void avancer(int n = 1);
    bool finLigneCommentaire();
};

}  // namespace matlibre
