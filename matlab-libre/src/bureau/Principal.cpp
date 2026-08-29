// Principal.cpp — point d'entrée de « matlibre-bureau ».
//
// Un seul exécutable : la fenêtre, l'interpréteur, l'éditeur et les
// figures dans le même processus. Rien à installer, rien à ouvrir dans un
// navigateur.
#include <QApplication>
#include <QFileInfo>

#include "FenetrePrincipale.h"
#include "Icone.h"
#include "Theme.h"

int main(int argc, char** argv) {
    QApplication application(argc, argv);
    application.setApplicationName(QStringLiteral("MatLibre"));
    application.setOrganizationName(QStringLiteral("MatLibre"));
    theme::appliquer();
    application.setWindowIcon(iconeApplication());

    FenetrePrincipale fenetre;
    // Les fichiers passés en argument s'ouvrent dans l'éditeur.
    for (int k = 1; k < argc; ++k) {
        QString chemin = QString::fromLocal8Bit(argv[k]);
        if (QFileInfo(chemin).isFile()) fenetre.ouvrirFichier(chemin);
    }
    fenetre.show();
    return application.exec();
}
