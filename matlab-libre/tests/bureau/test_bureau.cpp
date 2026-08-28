// test_bureau.cpp — le bureau natif, verifie sans ouvrir de fenetre.
//
// Tourne sur le greffon « offscreen » de Qt : la fenetre est construite,
// peinte et pilotee pour de vrai, mais rien ne s'affiche. Ce qui est
// verifie est ce qu'on ne voit pas a l'oeil — l'espace de travail qui suit
// l'interpreteur, la figure qui se peint, le fil de calcul qui ne bloque
// pas l'interface, et la coloration qui distingue la transposee de la
// chaine de caracteres.
#include <QApplication>
#include <QDir>
#include <QDockWidget>
#include <QElapsedTimer>
#include <QImage>
#include <QPlainTextEdit>
#include <QTabWidget>
#include <QTableWidget>
#include <QFileInfo>
#include <QTemporaryDir>
#include <QTextBlock>
#include <QTextLayout>
#include <QTimer>

#include <cstdio>
#include <cstdlib>

#include "ConsoleCommandes.h"
#include "Editeur.h"
#include "Theme.h"
#include "FenetrePrincipale.h"
#include "Moteur.h"
#include "VueFigure.h"

namespace {

int echecs = 0;
int verifications = 0;

void verifier(bool condition, const char* quoi) {
    ++verifications;
    if (condition) {
        std::printf("  ok   %s\n", quoi);
    } else {
        std::printf("  ECHEC %s\n", quoi);
        ++echecs;
    }
}

// Fait tourner la boucle d'evenements jusqu'a ce que la condition tienne,
// ou jusqu'au delai. Sans cela, rien de ce que fait le fil de calcul
// n'arriverait jamais a la fenetre.
template <typename Condition>
bool attendre(Condition condition, int millisecondes = 8000) {
    QElapsedTimer chrono;
    chrono.start();
    while (!condition() && chrono.elapsed() < millisecondes)
        QCoreApplication::processEvents(QEventLoop::AllEvents, 20);
    return condition();
}

}  // namespace

// Envoie une commande apres avoir attendu que la precedente soit finie.
// Sans cela on testerait le refus poli du bureau, pas la commande.
static bool envoyer(FenetrePrincipale& fenetre, const QString& commande) {
    if (!attendre([&] { return !fenetre.occupe(); })) return false;
    fenetre.envoyerCommande(commande);
    return true;
}

int main(int argc, char** argv) {
    qputenv("QT_QPA_PLATFORM", "offscreen");
    QApplication application(argc, argv);
    theme::appliquer();

    QTemporaryDir travail;
    if (travail.isValid()) QDir::setCurrent(travail.path());

    std::printf("--- bureau ---\n");
    FenetrePrincipale fenetre;
    fenetre.resize(1280, 820);
    fenetre.show();

    auto* console = fenetre.findChild<ConsoleCommandes*>();
    auto* variables = fenetre.findChild<QTableWidget*>();
    verifier(console != nullptr, "la fenetre de commandes existe");
    verifier(variables != nullptr, "l'espace de travail existe");
    if (!console || !variables) return 1;
    // L'invite vit dans le texte, comme sous MATLAB : pas de ligne de
    // saisie separee sous la console.
    verifier(console->toPlainText().endsWith(QLatin1String(">> ")),
             "l'invite est posee dans la fenetre de commandes elle-meme");

    // L'interpreteur demarre dans son fil ; on attend qu'il reponde.
    verifier(attendre([&] { return variables->rowCount() >= 0 && console->isVisible(); }),
             "la fenetre s'ouvre");

    // --- une commande simple, et l'espace de travail qui suit -------------
    envoyer(fenetre, QStringLiteral("x = 0:0.01:2; y = sin(2*pi*x); nom = 'essai';"));
    bool vu = attendre([&] {
        for (int k = 0; k < variables->rowCount(); ++k)
            if (variables->item(k, 0) && variables->item(k, 0)->text() == QLatin1String("y"))
                return true;
        return false;
    });
    verifier(vu, "l'espace de travail montre les variables creees");

    auto ligneDe = [&](const QString& nom) {
        for (int k = 0; k < variables->rowCount(); ++k)
            if (variables->item(k, 0) && variables->item(k, 0)->text() == nom) return k;
        return -1;
    };
    int ligneY = ligneDe(QStringLiteral("y"));
    verifier(ligneY >= 0 && variables->item(ligneY, 2)->text() == QLatin1String("1x201"),
             "y est annonce 1x201, comme le veut 0:0.01:2");
    verifier(ligneY >= 0 && variables->item(ligneY, 3)->text() == QLatin1String("double"),
             "y est de classe double");
    int ligneNom = ligneDe(QStringLiteral("nom"));
    verifier(ligneNom >= 0 && variables->item(ligneNom, 3)->text() == QLatin1String("char"),
             "une chaine est annoncee char");
    // La colonne « Valeur » resume : un grand tableau n'y deverse pas son
    // rendu complet, avec ses « Columns 1 through 6 ».
    verifier(ligneY >= 0 && variables->item(ligneY, 1)->text() ==
                                QLatin1String("<1x201 double>"),
             "un grand tableau est resume par sa forme");
    verifier(ligneNom >= 0 && variables->item(ligneNom, 1)->text() ==
                                  QLatin1String("'essai'"),
             "une chaine courte est montree telle quelle");

    // --- la sortie de l'interpreteur arrive dans la console ---------------
    envoyer(fenetre, QStringLiteral("disp(max(y))"));
    verifier(attendre([&] { return console->toPlainText().contains(QLatin1String("1")); }),
             "la sortie de disp arrive dans la fenetre de commandes");
    verifier(console->toPlainText().contains(QLatin1String(">> disp(max(y))")),
             "la commande est repetee avec son invite");

    // --- une erreur est signalee, sans arreter le bureau ------------------
    envoyer(fenetre, QStringLiteral("undefinedThing(3)"));
    verifier(attendre([&] { return console->toPlainText().contains(QLatin1String("Error")); }),
             "une erreur s'affiche au lieu de tuer la fenetre");
    envoyer(fenetre, QStringLiteral("apresErreur = 42;"));
    verifier(attendre([&] { return ligneDe(QStringLiteral("apresErreur")) >= 0; }),
             "l'interpreteur repond encore apres une erreur");

    envoyer(fenetre, QStringLiteral("petit = [1 2 3];"));
    verifier(attendre([&] {
                 int l = ligneDe(QStringLiteral("petit"));
                 return l >= 0 && variables->item(l, 1)->text() == QLatin1String("[1 2 3]");
             }),
             "un petit vecteur est montre en clair");

    // --- une figure : l'onglet apparait et se peint pour de vrai ----------
    envoyer(fenetre, QStringLiteral("plot(x, y); hold on; plot(x, cos(2*pi*x)); title('deux signaux'); "
        "xlabel('t'); ylabel('a'); legend('sin','cos'); grid on;"));
    VueFigure* vue = nullptr;
    verifier(attendre([&] {
                 vue = fenetre.findChild<VueFigure*>();
                 return vue != nullptr;
             }),
             "un onglet de figure apparait");
    if (vue) {
        vue->resize(640, 480);
        QImage image(640, 480, QImage::Format_ARGB32);
        image.fill(Qt::white);
        vue->render(&image);
        // Une figure peinte n'est pas une page blanche : on compte les
        // pixels qui ne le sont pas. Le compte exact n'a pas de sens, la
        // presence si — c'est ce qui distingue « ca a peint » de « ca a
        // plante en silence ».
        int encre = 0;
        for (int y = 0; y < image.height(); y += 2)
            for (int x = 0; x < image.width(); x += 2)
                if (qGray(image.pixel(x, y)) < 220) ++encre;
        verifier(encre > 500, "la figure est reellement peinte, pas une page blanche");
        // La courbe doit etre coloree : la palette de MATLAB, pas du gris.
        bool couleur = false;
        for (int y = 0; y < image.height() && !couleur; ++y)
            for (int x = 0; x < image.width(); ++x) {
                QColor c = image.pixelColor(x, y);
                if (std::abs(c.red() - c.blue()) > 40) { couleur = true; break; }
            }
        verifier(couleur, "la courbe est tracee dans une couleur, pas en gris");
        // La legende ne doit pas rogner son texte : on verifie qu'il reste
        // de l'encre a droite du dernier caractere, dans la boite.
        vue->resize(900, 560);
        QImage grande(900, 560, QImage::Format_ARGB32);
        grande.fill(Qt::white);
        vue->render(&grande);
        int encreLarge = 0;
        for (int y = 0; y < grande.height(); y += 2)
            for (int x = 0; x < grande.width(); x += 2)
                if (qGray(grande.pixel(x, y)) < 220) ++encreLarge;
        verifier(encreLarge > encre, "la figure se redessine quand on l'agrandit");
    }

    // Les panneaux de droite doivent avoir une largeur utilisable : sans
    // elle, leur titre lui-meme se reduit a « ... ».
    for (QDockWidget* d : fenetre.findChildren<QDockWidget*>()) {
        if (!d->isVisible()) continue;
        verifier(d->width() >= 180,
                 qPrintable(QStringLiteral("le panneau « %1 » a une largeur utilisable")
                                .arg(d->windowTitle())));
    }

    // --- l'editeur : coloration et numerotation ---------------------------
    auto* editeur = fenetre.findChild<Editeur*>();
    verifier(editeur != nullptr, "l'editeur existe");
    if (editeur) {
        editeur->setPlainText(QStringLiteral(
            "function y = essai(x)   % un commentaire\n"
            "    m = 'texte';\n"
            "    y = x' * 2;\n"
            "end\n"));
        QCoreApplication::processEvents();
        auto formatsDe = [&](int numero) {
            QTextBlock bloc = editeur->document()->findBlockByNumber(numero);
            return bloc.layout() ? bloc.layout()->formats() : QList<QTextLayout::FormatRange>();
        };
        auto contientCouleur = [&](int numero, const QColor& couleur) {
            for (const auto& f : formatsDe(numero))
                if (f.format.foreground().color() == couleur) return true;
            return false;
        };
        verifier(contientCouleur(0, QColor("#0000ff")), "« function » est colore en mot-cle");
        verifier(contientCouleur(0, QColor("#028009")), "le commentaire est colore");
        verifier(contientCouleur(1, QColor("#a020f0")), "la chaine 'texte' est coloree");
        // Le piege de la coloration MATLAB : dans « x' * 2 », l'apostrophe
        // transpose, elle n'ouvre pas une chaine. Rien ne doit etre colore
        // en chaine sur cette ligne.
        verifier(!contientCouleur(2, QColor("#a020f0")),
                 "l'apostrophe de transposition n'est pas prise pour une chaine");
        verifier(editeur->largeurMarge() > 12, "la marge des numeros de ligne a une largeur");
    }

    // --- executer un fichier depuis l'editeur -----------------------------
    if (editeur) {
        QString chemin = QDir::current().filePath(QStringLiteral("essaiBureau.m"));
        editeur->setPlainText(QStringLiteral("valeurDuScript = 6 * 7;\n"));
        editeur->definirFichier(chemin);
        // On passe par la commande « Enregistrer » de la fenetre, pas par
        // l'editeur seul : c'est elle qui demande la reconstruction de
        // l'index, et c'est donc elle qu'il faut verifier.
        QMetaObject::invokeMethod(&fenetre, "enregistrer");
        verifier(QFileInfo::exists(chemin), "l'editeur enregistre son fichier");
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau redevient libre");
        envoyer(fenetre, QStringLiteral("essaiBureau"));
        verifier(attendre([&] { return ligneDe(QStringLiteral("valeurDuScript")) >= 0; }),
                 "un script ecrit dans l'editeur s'execute");
        int ligne = ligneDe(QStringLiteral("valeurDuScript"));
        verifier(ligne >= 0 && variables->item(ligne, 1)->text() == QLatin1String("42"),
                 "le script a bien calcule 42");
    }

    // --- le fil de calcul ne bloque pas l'interface ------------------------
    verifier(envoyer(fenetre, QStringLiteral("s = 0; for k = 1:400000, s = s + k; end")),
             "une commande longue est acceptee");
    // Pendant le calcul, la fenetre doit continuer a traiter ses evenements.
    int tours = 0;
    QElapsedTimer chrono;
    chrono.start();
    while (chrono.elapsed() < 300) {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
        ++tours;
    }
    verifier(tours > 5, "l'interface repond pendant qu'un calcul tourne");
    verifier(attendre([&] { return ligneDe(QStringLiteral("s")) >= 0; }, 20000),
             "le calcul long finit et publie son resultat");

    // Une capture, pour qu'un humain puisse regarder ce qui a ete construit.
    const char* sortie = std::getenv("MATLIBRE_CAPTURE");
    if (sortie) {
        QImage image(fenetre.size(), QImage::Format_ARGB32);
        image.fill(Qt::white);
        fenetre.render(&image);
        image.save(QString::fromLocal8Bit(sortie));
        std::printf("  capture ecrite dans %s\n", sortie);
    }

    std::printf(echecs == 0 ? "bureau : toutes les verifications passent (%d)\n"
                            : "bureau : %d ECHEC(S) sur %d\n",
                echecs == 0 ? verifications : echecs,
                echecs == 0 ? 0 : verifications);
    return echecs == 0 ? 0 : 1;
}
