// Icone.h — l'icône de MatLibre, dessinée.
//
// Elle est tracée au vecteur plutôt que chargée : nette à toute taille,
// aucun fichier à installer à côté de l'exécutable, et c'est la même
// image qui sert à la fenêtre et au fichier .ico de Windows.
//
// Le dessin est propre à MatLibre : une sinusoïde blanche sur une grille,
// dans un carré arrondi bleu. Rien n'y reprend l'icône de MathWorks.
#pragma once

#include <QIcon>

QIcon iconeApplication();
void peindreIcone(class QPainter& peintre, double taille);
