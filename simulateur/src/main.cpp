// Point d'entrée de l'application.
#include <QApplication>
#include <QDir>
#include <QDockWidget>
#include <QFileInfo>
#include <QFont>
#include <QGraphicsSceneMouseEvent>
#include <QPixmap>
#include <QStringList>
#include <QTextStream>
#include <QTimer>

#include "app/FenetrePrincipale.h"
#include "app/panels/PanneauPcb.h"
#include "app/schematic/ItemComposant.h"
#include "app/schematic/SceneSchema.h"

#include <functional>
#include <memory>

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

    // « --tailles » : imprime ce que chaque panneau exige comme place, puis
    // quitte. Quand un panneau ne peut plus être étiré, la cause est toujours
    // là — un widget qui réclame plus que l'écran fige tous les séparateurs à
    // leur butée, et l'on croit le redimensionnement cassé.
    if (arguments.contains("--tailles")) {
        fenetre.resize(1920, 1080);
        QTimer::singleShot(400, &fenetre, [&fenetre] {
            QTextStream sortie(stdout);
            auto ligne = [&sortie](const QString& nom, QWidget* widget) {
                sortie << nom << " taille=" << widget->width() << "x"
                       << widget->height()
                       << " minimum=" << widget->minimumSizeHint().width() << "x"
                       << widget->minimumSizeHint().height() << Qt::endl;
            };
            sortie << "-- ce qui réclame le plus de place --" << Qt::endl;
            for (QWidget* widget : fenetre.findChildren<QWidget*>())
                if (widget->minimumSizeHint().width() > 400
                    || widget->minimumSizeHint().height() > 300)
                    ligne(QString(widget->metaObject()->className()) + " "
                              + widget->objectName(),
                          widget);
            sortie << "-- l'ensemble --" << Qt::endl;
            ligne("fenetre", &fenetre);
            ligne("centre ", fenetre.centralWidget());
            for (QDockWidget* dock : fenetre.findChildren<QDockWidget*>())
                ligne("dock " + dock->windowTitle(), dock);
            qApp->quit();
        });
    }

    // Vérification automatique : « --capture fichier.png [millisecondes] »
    // ouvre l'application, laisse tourner la simulation, enregistre une image
    // puis quitte. Sert de test de bout en bout sans intervention humaine.
    const bool analyse_demandee =
        arguments.contains("--analyse") || arguments.contains("--pcb");
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

    // « --pcb dossier » : génère la carte depuis le schéma, en route ce qui
    // peut l'être automatiquement pour la vérification, et écrit les fichiers
    // de fabrication. Imprime l'état de la carte et la taille des fichiers.
    const int pcb = arguments.indexOf("--pcb");
    if (pcb >= 0 && pcb + 1 < arguments.size()) {
        fenetre.definir_mode_silencieux(true);
        const QString dossier = arguments.at(pcb + 1);
        QDir().mkpath(dossier);
        QTimer::singleShot(300, &application, [&fenetre, dossier] {
            QTextStream sortie(stdout);
            fenetre.ouvrir_pcb();
            sortie << "page affichee : " << fenetre.page_courante() << Qt::endl;
            sortie << fenetre.pcb()->rapport() << Qt::endl;
            sortie << fenetre.pcb()->resume() << Qt::endl;
            // Toutes les liaisons routées d'un trait : la vérification porte
            // sur la chaîne complète, pas sur l'adresse du routeur.
            coeur::CartePcb& carte = fenetre.pcb()->vue()->carte();
            for (const auto& liaison : carte.chevelu())
                if (!liaison.routee)
                    carte.pistes.push_back({liaison.net, liaison.x1, liaison.y1,
                                            liaison.x2, liaison.y2, 0.4, 0});
            // Reposer la carte fait recalculer l'état affiché : sans cela le
            // panneau annoncerait encore « 0 piste ».
            fenetre.pcb()->vue()->definir_carte(carte);
            int restantes = 0;
            for (const auto& liaison :
                 fenetre.pcb()->vue()->carte().chevelu())
                if (!liaison.routee) ++restantes;
            sortie << "liaisons restantes apres routage : " << restantes
                   << Qt::endl;
            // Second transfert : il ne doit rien casser. C'est la promesse
            // d'un « mettre à jour depuis le schéma » — le placement et le
            // routage déjà faits survivent.
            fenetre.ouvrir_pcb();
            sortie << "--- second transfert ---" << Qt::endl
                   << fenetre.pcb()->rapport() << Qt::endl
                   << fenetre.pcb()->resume() << Qt::endl;
            for (const QString& nom :
                 fenetre.pcb()->exporter_vers(dossier + "/carte"))
                sortie << nom << " : "
                       << QFileInfo(dossier + "/" + nom).size() << " octets"
                       << Qt::endl;
            // « --capture » peut accompagner « --pcb » : l'image montre la
            // carte routée, ce que les tailles de fichiers ne disent pas.
            const QStringList arguments = qApp->arguments();
            const int rang_image = arguments.indexOf("--capture");
            if (rang_image >= 0 && rang_image + 1 < arguments.size()) {
                const QString image = arguments.at(rang_image + 1);
                QTimer::singleShot(200, qApp, [&fenetre, image] {
                    fenetre.grab().save(image);
                    qApp->quit();
                });
                return;
            }
            qApp->quit();
        });
    }

    // « --gestes dossier » : joue une séance d'utilisateur — lancer, effacer
    // un composant en pleine simulation, arrêter, annuler, passer au circuit
    // imprimé et revenir — en enregistrant une image à chaque étape. C'est la
    // vérification des artefacts : ce qu'aucun test chiffré ne montre.
    const int gestes = arguments.indexOf("--gestes");
    if (gestes >= 0 && gestes + 1 < arguments.size()) {
        fenetre.definir_mode_silencieux(true);
        const QString dossier = arguments.at(gestes + 1);
        QDir().mkpath(dossier);
        // Les états de la séance vivent aussi longtemps que l'application :
        // les minuteries s'exécutent bien après la fin de ce bloc.
        auto etape = std::make_shared<int>(0);
        auto photographier = [&fenetre, dossier, etape](const QString& nom) {
            const QString chemin = QString("%1/%2-%3.png")
                                       .arg(dossier)
                                       .arg((*etape)++, 2, 10, QChar('0'))
                                       .arg(nom);
            fenetre.grab().save(chemin);
            QTextStream(stdout) << chemin << Qt::endl;
        };
        int retard = 200;
        auto plus_tard = [&retard, &fenetre](std::function<void()> action) {
            QTimer::singleShot(retard, &fenetre, action);
            retard += 700;
        };

        // Les actions différées capturent par valeur : elles s'exécutent
        // longtemps après la fin de ce bloc, et une référence à une variable
        // locale ne vaudrait plus rien.
        plus_tard([photographier] { photographier("schema"); });
        // Double-clic sur la carte : c'est ainsi qu'on ouvre son programme,
        // comme on ouvre le code d'un microcontrôleur ailleurs. On passe par
        // la scène, donc par le vrai chemin de la souris.
        plus_tard([&fenetre] {
            for (ItemComposant* composant : fenetre.scene()->composants()) {
                if (!composant->modele() || !composant->modele()->carte) continue;
                QGraphicsSceneMouseEvent deux(
                    QEvent::GraphicsSceneMouseDoubleClick);
                deux.setScenePos(composant->pos());
                deux.setButton(Qt::LeftButton);
                QApplication::sendEvent(fenetre.scene(), &deux);
                break;
            }
            QTextStream(stdout)
                << "double-clic carte -> onglet « "
                << fenetre.titre_onglet_courant() << " » ("
                << fenetre.onglet_courant() << "), carte "
                << fenetre.carte_affichee() << ", croquis "
                << (fenetre.programme_affiche().contains("void loop(") ? "oui"
                                                                       : "non")
                << Qt::endl;
        });
        plus_tard([photographier] { photographier("programme-de-la-carte"); });
        plus_tard([&fenetre] { fenetre.demarrage_automatique(); });
        plus_tard([photographier] { photographier("en-marche"); });
        // « --gestes dossier [REF] » : la référence à effacer en pleine
        // simulation. Par défaut R1 ; « U1 » efface la carte elle-même.
        const QString cible = (gestes + 2 < arguments.size()
                               && !arguments.at(gestes + 2).startsWith("--"))
                                  ? arguments.at(gestes + 2)
                                  : QString("R1");
        plus_tard([&fenetre, cible] {
            // On efface un composant en pleine simulation, comme on le ferait
            // sans y penser.
            for (ItemComposant* composant : fenetre.scene()->composants())
                if (composant->reference() == cible) composant->setSelected(true);
            fenetre.scene()->memoriser();
            fenetre.scene()->supprimer_selection();
        });
        plus_tard([photographier] { photographier("apres-suppression"); });
        plus_tard([&fenetre] { fenetre.arreter_simulation(); });
        plus_tard([photographier] { photographier("arrete"); });
        plus_tard([&fenetre] { fenetre.scene()->annuler(); });
        plus_tard([photographier] { photographier("annule"); });
        plus_tard([&fenetre] { fenetre.ouvrir_pcb(); });
        plus_tard([photographier] { photographier("circuit-imprime"); });
        plus_tard([&fenetre] { fenetre.afficher_page(0); });
        plus_tard([photographier] { photographier("retour-schema"); });
        plus_tard([] { qApp->quit(); });
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
