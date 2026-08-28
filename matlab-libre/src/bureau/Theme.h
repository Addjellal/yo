// Theme.h — l'apparence de MATLAB, posée une fois pour toute l'application.
//
// Sans cela, Qt suit le thème du système : la fenêtre sort à moitié
// sombre et à moitié claire, parce que les couleurs qu'on fixe soi-même
// (le fond blanc de la console, le gris de la marge) ne suivent pas. On
// pose donc une palette complète, cohérente, et proche de celle de
// MATLAB — dont le bureau est clair par défaut.
#pragma once

#include <QColor>

namespace theme {

// --- fenêtre ---------------------------------------------------------
inline QColor fond()          { return QColor("#f0f0f0"); }  // gris des panneaux
inline QColor fondTexte()     { return QColor("#ffffff"); }  // éditeur, console
inline QColor texte()         { return QColor("#000000"); }
inline QColor texteEteint()   { return QColor("#707070"); }
inline QColor bordure()       { return QColor("#c0c0c0"); }
inline QColor selection()     { return QColor("#b5d5ff"); }
inline QColor titrePanneau()  { return QColor("#e4e4e4"); }

// --- éditeur ---------------------------------------------------------
inline QColor ligneCourante() { return QColor("#e8f2fe"); }
inline QColor fondMarge()     { return QColor("#f0f0f0"); }
inline QColor numeroLigne()   { return QColor("#787878"); }
inline QColor fondSection()   { return QColor("#fffde7"); }  // bloc %%
inline QColor traitSection()  { return QColor("#d0d0d0"); }

// --- coloration syntaxique : les couleurs exactes de MATLAB ----------
inline QColor motCle()        { return QColor("#0000ff"); }
inline QColor chaine()        { return QColor("#a020f0"); }
inline QColor commentaire()   { return QColor("#028009"); }
inline QColor nombre()        { return QColor("#000000"); }
inline QColor chaineOuverte() { return QColor("#e60000"); }

// --- console ---------------------------------------------------------
inline QColor invite()        { return QColor("#000000"); }
inline QColor erreur()        { return QColor("#e60000"); }
inline QColor avertissement() { return QColor("#c07000"); }

void appliquer();  // pose la palette sur QApplication

}  // namespace theme
