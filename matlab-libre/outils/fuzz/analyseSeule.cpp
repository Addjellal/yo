// analyseSeule.cpp — passe des fichiers .m dans le lexeur et l'analyseur,
// sans rien exécuter : le banc du fuzzeur (outils/fuzz/fuzzer.py).
//
//   analyseSeule fichier.m...
//
// Avec ANALYSE_BAVARDE=1 dans l'environnement, chaque erreur de syntaxe
// est aussi écrite (« SYNTAXE fichier : message ») : de quoi passer du
// code MATLAB réel dans l'analyseur sans rien en exécuter.
//
// Une erreur de syntaxe est la réponse juste à un texte mutilé ; une
// exception C++ qui n'est pas une erreur MATLAB est un défaut (le code
// de retour vaut alors 3), un plantage aussi. Se compile contre la
// bibliothèque d'un arbre de construction, de préférence assaini :
//
//   g++ -std=c++17 -g -fsanitize=address,undefined -Iinclude \
//       outils/fuzz/analyseSeule.cpp build-asan/lib/libmatlibre_coeur.a \
//       -lpthread -o build-asan/bin/analyseSeule
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

#include "matlibre/Analyseur.h"
#include "matlibre/Erreur.h"

int main(int argc, char** argv) {
    int code = 0;
    for (int k = 1; k < argc; ++k) {
        std::ifstream f(argv[k], std::ios::binary);
        std::stringstream ss;
        ss << f.rdbuf();
        const std::string source = ss.str();
        for (int mode = 0; mode < 2; ++mode) {
            try {
                if (mode == 0) matlibre::compiler(source, argv[k]);
                else matlibre::compilerBloc(source, argv[k]);
            } catch (const matlibre::ErreurMatlab& e) {
                // la réponse attendue à un texte mal formé
                if (mode == 0 && std::getenv("ANALYSE_BAVARDE"))
                    std::cout << "SYNTAXE " << argv[k] << " : " << e.message << "\n";
            } catch (const std::exception& e) {
                std::cout << "INTERNE " << argv[k] << " (mode " << mode << ") : " << e.what()
                          << "\n";
                code = 3;
            }
        }
    }
    return code;
}
