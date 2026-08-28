// Principal.cpp — point d'entrée de « matlibre-bureau ».
//
// Un seul exécutable : la fenêtre, l'interpréteur, l'éditeur et les
// figures dans le même processus. Rien à installer, rien à ouvrir dans un
// navigateur.
#include <QApplication>
#include <QDir>
#include <QFileInfo>

#include "FenetrePrincipale.h"

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

namespace {

// Les toolboxes vivent à côté de l'exécutable, comme pour la console.
void poserRacineToolbox(const QString& executable) {
    if (!qEnvironmentVariableIsEmpty("MATLIBRE_TOOLBOX")) return;
    QDir dossier = QFileInfo(executable).absoluteDir();
    const QStringList candidats = {dossier.filePath(QStringLiteral("../share/matlibre")),
                                   dossier.filePath(QStringLiteral("../toolbox")),
                                   dossier.filePath(QStringLiteral("toolbox"))};
    for (const QString& c : candidats) {
        QFileInfo info(c);
        if (info.isDir()) {
            qputenv("MATLIBRE_TOOLBOX", info.absoluteFilePath().toUtf8());
            return;
        }
    }
}

}  // namespace

int main(int argc, char** argv) {
    QApplication application(argc, argv);
    application.setApplicationName(QStringLiteral("MatLibre"));
    application.setOrganizationName(QStringLiteral("MatLibre"));
    poserRacineToolbox(QString::fromLocal8Bit(argv[0]));

    FenetrePrincipale fenetre;
    // Les fichiers passés en argument s'ouvrent dans l'éditeur.
    for (int k = 1; k < argc; ++k) {
        QString chemin = QString::fromLocal8Bit(argv[k]);
        if (QFileInfo(chemin).isFile()) fenetre.ouvrirFichier(chemin);
    }
    fenetre.show();
    return application.exec();
}
