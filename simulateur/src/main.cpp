// Point d'entrée de l'application.
#include <QApplication>
#include <QDir>
#include <QFileInfo>
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

    // « --exemple N » choisit le montage d'exemple à charger (0 à 8).
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
    const bool analyse_demandee = arguments.contains("--analyse");
    if (position >= 0 && position + 1 < arguments.size() && !analyse_demandee) {
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
                << "vitesse " << fenetre.vitesse() << " x temps reel" << Qt::endl
                << fenetre.mesures_oscilloscope();
            qApp->quit();
        });
    }
    // « --analyse N [attente_ms] » : lance l'analyse N (0 balayage continu,
    // 1 réponse en fréquence, 2 spectre, 3 bruit) et imprime son compte rendu
    // chiffré.
    // Le spectre porte sur ce qui vient d'être simulé : la simulation doit
    // donc tourner d'abord.
    const int analyse = arguments.indexOf("--analyse");
    if (analyse >= 0 && analyse + 1 < arguments.size()) {
        fenetre.definir_mode_silencieux(true);
        const int numero = arguments.at(analyse + 1).toInt();
        const int attente = analyse + 2 < arguments.size()
                                ? arguments.at(analyse + 2).toInt()
                                : 600;
        if (numero == 2)
            QTimer::singleShot(200, &fenetre,
                               [&fenetre] { fenetre.demarrage_automatique(); });
        // « --capture » peut accompagner « --analyse » : l'image est alors
        // prise une fois la courbe tracée, ce qui la rend vérifiable à l'œil
        // autant qu'au chiffre.
        const QString image = (position >= 0 && position + 1 < arguments.size())
                                  ? arguments.at(position + 1)
                                  : QString();
        QTimer::singleShot(attente, &application, [&fenetre, numero, image] {
            fenetre.lancer_analyse(numero);
            QTextStream(stdout) << fenetre.resume_analyse() << Qt::endl;
            if (!image.isEmpty())
                QTimer::singleShot(200, qApp, [&fenetre, image] {
                    fenetre.grab().save(image);
                    qApp->quit();
                });
            else
                qApp->quit();
        });
    }

    // « --documents dossier » : produit tous les documents du projet et
    // imprime leur taille. Vérifie d'un coup nomenclature, contrôle des
    // règles, netlist KiCad, relevés et sortie graphique.
    const int documents = arguments.indexOf("--documents");
    if (documents >= 0 && documents + 1 < arguments.size()) {
        fenetre.definir_mode_silencieux(true);
        const QString dossier = arguments.at(documents + 1);
        QDir().mkpath(dossier);      // le dossier de sortie peut ne pas exister
        QTimer::singleShot(300, &application, [&fenetre, dossier] {
            QTextStream sortie(stdout);
            const struct { const char* nom; bool (FenetrePrincipale::*action)(const QString&); }
                travaux[] = {
                    {"nomenclature.csv", &FenetrePrincipale::exporter_nomenclature},
                    {"controle-regles.txt", &FenetrePrincipale::exporter_regles},
                    {"circuit.net", &FenetrePrincipale::exporter_netlist_kicad},
                    {"schema.pdf", &FenetrePrincipale::exporter_schema},
                    {"schema.png", &FenetrePrincipale::exporter_schema}};
            for (const auto& travail : travaux) {
                const QString chemin = dossier + "/" + travail.nom;
                const bool ok = (fenetre.*travail.action)(chemin);
                sortie << travail.nom << " : "
                       << (ok ? QString::number(QFileInfo(chemin).size())
                                    + " octets"
                              : QString("ECHEC"))
                       << Qt::endl;
            }
            qApp->quit();
        });
    }

    // « --aller-retour fichier » : enregistre le projet courant, le rouvre,
    // et imprime ce qui a survécu. Vérifie l'entrée/sortie sans interface.
    const int aller = arguments.indexOf("--aller-retour");
    if (aller >= 0 && aller + 1 < arguments.size()) {
        fenetre.definir_mode_silencieux(true);
        const QString chemin = arguments.at(aller + 1);
        QTimer::singleShot(200, &fenetre, [&fenetre, chemin] {
            QTextStream sortie(stdout);
            sortie << "--- avant ---" << Qt::endl << fenetre.diagnostic();
            if (!fenetre.enregistrer_vers(chemin)) {
                sortie << "ECHEC enregistrement" << Qt::endl;
                qApp->quit();
                return;
            }
            if (!fenetre.ouvrir_depuis(chemin)) {
                sortie << "ECHEC ouverture" << Qt::endl;
                qApp->quit();
                return;
            }
            sortie << "--- apres ---" << Qt::endl << fenetre.diagnostic();
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
