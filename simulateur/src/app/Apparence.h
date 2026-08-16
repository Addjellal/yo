// L'identité visuelle de l'application, en un seul endroit.
//
// Il n'y en avait aucune : Qt par défaut, gris, plus quatre feuilles de style
// écrites à la main dans quatre fichiers, qui se contredisaient sur les
// couleurs de survol. Une interface qui n'a pas de palette a autant de
// palettes que de développeurs — et ici il n'y en avait qu'un.
//
// Deux choses seulement vivent ici : les COULEURS et la FEUILLE DE STYLE
// qu'elles produisent. Les icônes sont à côté, dans Icones.h.
#pragma once

#include <QColor>
#include <QString>

namespace apparence {

// La palette. Un nom par rôle, pas par couleur : « accent » se relit dix ans
// plus tard, « bleu_moyen » ne se relit pas — et se retrouve employé pour un
// rôle qui n'a rien à voir dès qu'on change d'avis sur la teinte.
struct Palette {
    QColor fond;             // le fond de l'application
    QColor surface;          // panneaux, listes, champs
    QColor surface_haute;    // barres d'outils, en-têtes
    QColor bordure;
    QColor texte;
    QColor texte_doux;       // légendes, unités, texte de second plan
    QColor accent;           // ce qui est actif, sélectionné, en cours
    QColor accent_doux;      // le survol
    QColor accent_texte;     // ce qui s'écrit SUR l'accent
    QColor succes;
    QColor alerte;
    QColor erreur;
};

// Le thème clair, seul pour l'instant. Le sombre demandera de reprendre AUSSI
// les couleurs du schéma — grille, fils, symboles — sans quoi une feuille
// blanche resterait plantée au milieu d'une fenêtre noire.
const Palette& claire();

// La feuille de style de toute l'application, produite à partir d'une
// palette. C'est elle qui remplace les quatre feuilles éparpillées.
QString feuille(const Palette& p);

// La hauteur de référence d'un contrôle, en pixels. Sert aussi bien à la
// feuille de style qu'au code qui dimensionne à la main.
constexpr int kHauteurControle = 30;
constexpr int kRayon = 6;          // arrondi commun
constexpr int kEspace = 8;         // l'unité d'espacement

}   // namespace apparence
