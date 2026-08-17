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

class QWidget;

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

// Les deux thèmes. La FEUILLE du schéma reste claire dans les deux : c'est du
// papier, et un schéma d'électronique se lit sur du blanc — KiCad, Altium et
// LTspice font tous ce choix, cadre sombre et feuille claire. Ce qui change,
// c'est tout le reste.
const Palette& claire();
const Palette& sombre();

enum class Theme { Clair, Sombre };

// Pose le thème sur TOUTE l'application : style, palette Qt et feuille de
// style d'un seul geste.
//
// La feuille de style seule ne suffit pas, et c'est ce qui donnait ce mélange
// de gris sombres et de blancs : ce qu'elle ne nomme pas garde la palette du
// SYSTÈME. Sur un Windows réglé en sombre, les fenêtres, les menus et les
// boîtes de dialogue arrivaient donc en sombre au milieu d'une interface
// claire. Poser la palette Qt ferme cette porte — plus rien ne dépend du
// réglage du poste.
void appliquer(Theme theme);

// Le thème enregistré, et son enregistrement. Le choix se garde d'une session
// à l'autre : le changer à chaque lancement serait le pire des deux mondes.
Theme theme_enregistre();
void enregistrer_theme(Theme theme);

// La feuille de style de toute l'application, produite à partir d'une
// palette. C'est elle qui remplace les quatre feuilles éparpillées.
QString feuille(const Palette& p);

// LE TON D'UNE ÉTIQUETTE, et non sa couleur.
//
// Une étiquette qui porte « color: #444 » dans sa propre feuille de style
// l'emporte sur celle de l'application : elle ne suit aucun thème, et la
// teinte choisie pour un fond clair devient illisible sur un fond sombre.
// C'est arrivé sept fois, dont une sur la lecture des curseurs de
// l'oscilloscope — gris foncé sur gris foncé.
//
// Un ton est un rôle : la couleur vient de la palette du thème en cours, et
// reposer la feuille de l'application les repeint toutes d'un coup.
enum class Ton { Normal, Doux, Accent, Succes, Alerte, Erreur };
void poser_ton(QWidget* widget, Ton ton);

// La palette du thème en cours. Pour le texte enrichi — le HTML d'une boîte de
// dialogue — qu'aucun sélecteur de feuille de style n'atteint : il faut alors
// écrire la couleur, et autant qu'elle vienne d'ici.
const Palette& courante();

// La hauteur de référence d'un contrôle, en pixels. Sert aussi bien à la
// feuille de style qu'au code qui dimensionne à la main.
constexpr int kHauteurControle = 30;
constexpr int kRayon = 6;          // arrondi commun
constexpr int kEspace = 8;         // l'unité d'espacement

}   // namespace apparence
