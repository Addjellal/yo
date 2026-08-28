// Analyseur.h — grammaire du langage MATLAB.
//
// Descente récursive, avec les priorités documentées par MathWorks, de la
// plus forte à la plus faible :
//   ' .' ^ .^   |  + - ~ (unaires)  |  * / \ .* ./ .\  |  + -  |  :
//   < <= > >= == ~=  |  &  |  |  |  &&  |  ||
// La puissance est associative à gauche : 2^3^2 vaut 64, comme dans MATLAB.
#pragma once

#include <set>
#include <string>
#include <vector>

#include "matlibre/Arbre.h"
#include "matlibre/Lexeur.h"

namespace matlibre {

class Analyseur {
public:
    Analyseur(std::vector<Jeton> jetons, std::string origine);

    UniteCompilee analyserUnite();  // un fichier entier
    NoeudPtr analyserBloc();        // une suite d'instructions (eval, REPL)

private:
    std::vector<Jeton> j_;
    std::size_t i_ = 0;
    std::string origine_;
    int dansIndice_ = 0;   // « end » et « : » ont un sens particulier
    int dansTableau_ = 0;  // les blancs séparent les éléments

    const Jeton& jeton(int k = 0) const;
    bool fini() const;
    void avancer() { if (i_ + 1 < j_.size()) ++i_; }
    bool accepterOp(const char* s);
    bool accepterMot(const char* s);
    void exigerOp(const char* s);
    void exigerMotFin();
    bool motFin() const;
    void sauterSeparateurs();
    void sauterFinsLignes();
    [[noreturn]] void erreurSyntaxe(const std::string& msg) const;

    NoeudPtr bloc(const std::vector<std::string>& fins);
    NoeudPtr instruction();
    NoeudPtr instructionSi();
    NoeudPtr instructionPour(bool parallele);
    bool fonctionsTerminees_ = false;  // le fichier ferme ses fonctions par « end »
    bool detecterFonctionsTerminees() const;
    NoeudPtr instructionTantQue();
    NoeudPtr instructionFaire();
    NoeudPtr instructionChoix();
    NoeudPtr instructionEssayer();
    NoeudPtr instructionSimple(TypeN t);
    NoeudPtr instructionDeclaration(TypeN t);
    NoeudPtr instructionCommande();
    void terminer(NoeudPtr n);
    bool ressembleCommande() const;
    // Noms deja vus comme cible d'affectation, variable de boucle, entree
    // ou sortie de fonction. MATLAB s'en sert pour trancher entre la
    // syntaxe commande et une expression : « x -1 » soustrait quand x est
    // une variable, et appelle x('-1') quand c'est une fonction.
    std::set<std::string> variablesVues_;
    void noterVariable(const NoeudPtr& cible);

    std::shared_ptr<FonctionUtilisateur> definitionFonction();
    std::shared_ptr<DefinitionClasse> definitionClasse();
    void sauterBlocArguments();

    NoeudPtr expression();
    NoeudPtr ouCourt();
    NoeudPtr etCourt();
    NoeudPtr ouBinaire();
    NoeudPtr etBinaire();
    NoeudPtr comparaison();
    NoeudPtr plage();
    NoeudPtr additif();
    NoeudPtr multiplicatif();
    NoeudPtr unaire();
    NoeudPtr puissance();
    NoeudPtr postfixe();
    NoeudPtr primaire();
    NoeudPtr litteralTableau(bool cellule);
    std::vector<NoeudPtr> listeArguments(const char* fermeture);
    bool nouvelElement() const;
};

UniteCompilee compiler(const std::string& source, const std::string& origine);
NoeudPtr compilerBloc(const std::string& source, const std::string& origine);

}  // namespace matlibre
