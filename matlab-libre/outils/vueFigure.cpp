// vueFigure.cpp — peint dans la fenêtre du bureau (VueFigure) les figures
// d'un script, hors écran, et les écrit en PNG.
//
// Le SVG et la fenêtre partagent le dessin (src/graphique/Dessin.cpp, sur
// une Toile) ; ce banc montre ce que la fenêtre peint vraiment, pour le
// comparer à la capture du SVG. Il se construit et se lance avec
// outils/vueFigure.sh.
//
// Usage : vueFigure DOSSIER_TOOLBOX SCRIPT.m DOSSIER_PNG
#include <QApplication>
#include <QImage>

#include "VueFigure.h"
#include "matlibre/Graphique.h"
#include "matlibre/Installation.h"
#include "matlibre/Interpreteur.h"

using namespace matlibre;

int main(int argc, char** argv) {
    if (argc != 4) return 2;
    QApplication application(argc, argv);
    Interpreteur it;
    it.installerBibliotheque();
    chargerToolboxes(it, argv[1]);
    it.executerFichier(argv[2]);
    int rang = 0;
    for (auto& [numero, figure] : it.figures) {
        VueFigure vue;
        FigureCopiee copie;
        copie.numero = numero;
        copie.figure = *figure;
        copie.contenu = true;
        vue.definirFigure(copie);
        vue.resize(figure->largeur, figure->hauteur);
        QImage image(figure->largeur, figure->hauteur, QImage::Format_ARGB32);
        image.fill(Qt::white);
        vue.render(&image);
        image.save(QString("%1/fenetre%2.png").arg(argv[3]).arg(++rang, 2, 10, QChar('0')));
    }
    return 0;
}
