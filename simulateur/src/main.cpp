// Point d'entrée de l'application.
#include <QApplication>
#include <QFont>
#include <QPixmap>
#include <QStringList>
#include <QTextStream>
#include <QTimer>

#include "app/FenetrePrincipale.h"

int main(int argc, char** argv) {
    QApplication application(argc, argv);
    application.setApplicationName("Simulateur embarqué");
    application.setOrganizationName("Formation embarquée");
    application.setApplicationVersion("0.1.0");

    QFont police = application.font();
    police.setPointSizeF(police.pointSizeF() + 0.5);
    application.setFont(police);

    FenetrePrincipale fenetre;

    const QStringList arguments = application.arguments();
    const int position = arguments.indexOf("--capture");
    fenetre.definir_mode_silencieux(position >= 0 ||
                                    arguments.contains("--diagnostic"));

    // « --exemple N » choisit le montage d'exemple à charger (0 à 3).
    const int rang = arguments.indexOf("--exemple");
    if (rang >= 0 && rang + 1 < arguments.size()) {
        const int numero = arguments.at(rang + 1).toInt();
        fenetre.charger_exemple(
            static_cast<FenetrePrincipale::Exemple>(numero));
    }
    // « --base N » impose la base de temps de l'oscilloscope, en secondes.
    const int base = arguments.indexOf("--base");

    // « --onglet N » choisit le panneau du bas : 0 programme, 1 journal,
    // 2 moniteur série, 3 oscilloscope.
    const int onglet = arguments.indexOf("--onglet");
    if (onglet >= 0 && onglet + 1 < arguments.size())
        fenetre.afficher_onglet(arguments.at(onglet + 1).toInt());

    fenetre.show();
    if (base >= 0 && base + 1 < arguments.size())
        fenetre.definir_base_temps(arguments.at(base + 1).toDouble());

    // Vérification automatique : « --capture fichier.png [millisecondes] »
    // ouvre l'application, laisse tourner la simulation, enregistre une image
    // puis quitte. Sert de test de bout en bout sans intervention humaine.
    if (position >= 0 && position + 1 < arguments.size()) {
        const QString destination = arguments.at(position + 1);
        const int attente = position + 2 < arguments.size()
                                ? arguments.at(position + 2).toInt()
                                : 1500;
        QTimer::singleShot(300, &fenetre, [&fenetre] {
            fenetre.demarrage_automatique();
        });
        QTimer::singleShot(attente, &application, [&fenetre, destination] {
            fenetre.grab().save(destination);
            QTextStream(stdout)
                << "vitesse " << fenetre.vitesse() << " x temps reel" << Qt::endl;
            qApp->quit();
        });
    }
    // « --diagnostic » : compile, exécute une seconde, imprime l'état
    // complet du couplage puis quitte. Vérification sans écran.
    if (arguments.contains("--diagnostic")) {
        fenetre.definir_mode_silencieux(true);
        QTimer::singleShot(200, &fenetre, [&fenetre] {
            fenetre.demarrage_automatique();
        });
        QTimer::singleShot(1400, &application, [&fenetre] {
            QTextStream(stdout) << fenetre.diagnostic() << Qt::endl;
            qApp->quit();
        });
    }
    return application.exec();
}
