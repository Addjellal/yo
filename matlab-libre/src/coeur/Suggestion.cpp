// Suggestion.cpp — « Did you mean: » après une faute de frappe.
//
// Quand une commande tapée échoue sur un nom inconnu, MATLAB propose la
// commande corrigée : « plott(x) » appelle « Did you mean: plot(x) ». Le
// nom proposé est le nom connu le plus proche au sens de la distance
// d'édition — variables visibles d'abord, puis fonctions natives,
// fichiers .m du chemin et du dossier courant, classes.
//
// La proposition n'est faite qu'à la console, et seulement quand l'erreur
// naît dans la commande elle-même : une faute dans un fichier que la
// commande appelle se corrige dans ce fichier, et le message d'erreur que
// voient « try/catch » et « MException » reste celui de MATLAB.
#include <algorithm>
#include <cctype>
#include <filesystem>
#include <string>
#include <tuple>
#include <vector>

#include "matlibre/Interpreteur.h"

namespace fs = std::filesystem;

namespace matlibre {

namespace {

std::string minuscules(std::string s) {
    for (char& c : s) c = (char)std::tolower((unsigned char)c);
    return s;
}

// Distance d'édition à transpositions (alignement optimal) : insertion,
// suppression, substitution, et échange de deux lettres voisines — la
// plus fréquente des fautes de frappe (« lenght »). Une lettre mise pour
// un chiffre compte double : le chiffre d'un nom a un sens (« plot3 »,
// « atan2 ») et se tape rarement par erreur, si bien que « plott »
// appelle « plot », non « plot3 ». Au-delà de MAX, le calcul s'arrête et
// rend MAX + 1.
std::size_t distanceEdition(const std::string& a, const std::string& b, std::size_t max) {
    const std::size_t n = a.size(), m = b.size();
    if (n > m + max || m > n + max) return max + 1;
    std::vector<std::size_t> avantDernier(m + 1), dernier(m + 1), courant(m + 1);
    for (std::size_t j = 0; j <= m; ++j) dernier[j] = j;
    for (std::size_t i = 1; i <= n; ++i) {
        courant[0] = i;
        std::size_t minimum = courant[0];
        for (std::size_t j = 1; j <= m; ++j) {
            const char x = a[i - 1], y = b[j - 1];
            const bool chiffreX = std::isdigit((unsigned char)x) != 0;
            const bool chiffreY = std::isdigit((unsigned char)y) != 0;
            const std::size_t prix = x == y ? 0 : (chiffreX != chiffreY ? 2 : 1);
            std::size_t d =
                std::min({dernier[j] + 1, courant[j - 1] + 1, dernier[j - 1] + prix});
            if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1])
                d = std::min(d, avantDernier[j - 2] + 1);
            courant[j] = d;
            minimum = std::min(minimum, d);
        }
        if (minimum > max) return max + 1;
        avantDernier.swap(dernier);
        dernier.swap(courant);
    }
    return dernier[m];
}

bool caractereIdentifiant(char c) { return std::isalnum((unsigned char)c) || c == '_'; }

// Remplace dans TEXTE la première occurrence du mot ANCIEN qui soit un
// nom — hors des chaînes, des commentaires et des noms de champ — par
// NOUVEAU. Rend une chaîne vide s'il n'y en a pas.
std::string remplacerNom(const std::string& texte, const std::string& ancien,
                         const std::string& nouveau) {
    char guillemet = 0;
    for (std::size_t i = 0; i < texte.size(); ++i) {
        const char c = texte[i];
        if (guillemet) {
            if (c == guillemet) {
                if (i + 1 < texte.size() && texte[i + 1] == guillemet) ++i;   // '' ou ""
                else guillemet = 0;
            }
            continue;
        }
        if (c == '%') break;
        if (c == '"') {
            guillemet = c;
            continue;
        }
        if (c == '\'') {
            // Collée à un nom, une valeur ou une parenthèse fermante,
            // l'apostrophe transpose ; ailleurs, elle ouvre un texte.
            const char p = i > 0 ? texte[i - 1] : 0;
            const bool transposee = p && (caractereIdentifiant(p) || p == ')' || p == ']' ||
                                          p == '}' || p == '.' || p == '\'');
            if (!transposee) guillemet = c;
            continue;
        }
        if (!caractereIdentifiant(c)) continue;
        std::size_t j = i;
        while (j < texte.size() && caractereIdentifiant(texte[j])) ++j;
        const bool champ = i > 0 && texte[i - 1] == '.';
        if (!champ && texte.compare(i, j - i, ancien) == 0 && j - i == ancien.size())
            return texte.substr(0, i) + nouveau + texte.substr(j);
        i = j - 1;
    }
    return std::string();
}

}  // namespace

std::string Interpreteur::nomProche(const std::string& nom) const {
    // Un nom d'une lettre a trop de voisins pour qu'en proposer un ait un
    // sens ; un nom de paquet (« a.b ») n'est pas une faute de frappe.
    if (nom.size() < 2 || nom.find('.') != std::string::npos) return std::string();
    const std::size_t max = nom.size() <= 4 ? 1 : 2;
    const std::string cherche = minuscules(nom);

    // Le meilleur : la distance la plus courte (la casse seule compte pour
    // zéro), puis la même initiale, puis la catégorie — une variable
    // avant une fonction —, puis l'écart de longueur, puis l'ordre
    // alphabétique, pour que la proposition ne dépende de rien d'autre.
    using Cle = std::tuple<std::size_t, int, int, std::size_t, std::string>;
    bool trouve = false;
    Cle meilleure;
    auto examiner = [&](const std::string& candidat, int categorie) {
        if (candidat == nom || candidat.size() < 2) return;
        if (candidat.compare(0, 9, "matlibre_") == 0) return;   // rouages internes
        const std::string bas = minuscules(candidat);
        const std::size_t d = bas == cherche ? 0 : distanceEdition(cherche, bas, max);
        if (d > max) return;
        const int initiale = bas[0] == cherche[0] ? 0 : 1;
        const std::size_t ecart = candidat.size() > nom.size() ? candidat.size() - nom.size()
                                                               : nom.size() - candidat.size();
        Cle cle{d, initiale, categorie, ecart, candidat};
        if (!trouve || cle < meilleure) {
            meilleure = cle;
            trouve = true;
        }
    };
    for (const auto& v : nomsVariables()) examiner(v, 0);
    for (const auto& kv : natifs_) examiner(kv.first, 1);
    for (const auto& kv : indexM_) examiner(kv.first, 2);
    std::error_code ec;
    for (fs::directory_iterator it(fs::current_path(ec), ec), fin; !ec && it != fin;
         it.increment(ec)) {
        const fs::path& p = it->path();
        if (p.extension() == ".m") examiner(p.stem().string(), 2);
    }
    for (const auto& kv : indexClasses_) examiner(kv.first, 3);
    return trouve ? std::get<4>(meilleure) : std::string();
}

std::string Interpreteur::correctionCommande(const ErreurMatlab& e,
                                             const std::string& commande) const {
    if (e.nomInconnu.empty() || !e.fonctionNative.empty()) return std::string();
    // Née dans un fichier que la commande appelait : rien à corriger ici.
    for (const auto& c : e.pile)
        if (!c.nom.empty() && c.ligne > 0) return std::string();
    std::string ligne = commande;
    while (!ligne.empty() && std::isspace((unsigned char)ligne.back())) ligne.pop_back();
    const std::size_t debut = ligne.find_first_not_of(" \t");
    if (debut == std::string::npos || ligne.find('\n') != std::string::npos)
        return std::string();
    ligne = ligne.substr(debut);
    const std::string proche = nomProche(e.nomInconnu);
    if (proche.empty()) return std::string();
    return remplacerNom(ligne, e.nomInconnu, proche);
}

}  // namespace matlibre
