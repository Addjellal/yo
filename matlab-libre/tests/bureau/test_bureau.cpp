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
#include <QFileDialog>
#include <QDockWidget>
#include <QElapsedTimer>
#include <QImage>
#include <QMenu>
#include <QPlainTextEdit>
#include <QFontMetrics>
#include <QTabWidget>
#include <QToolButton>
#include <QTableWidget>
#include <QTreeWidget>
#include <QTextBrowser>
#include <QLineEdit>
#include <QListWidget>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QTemporaryDir>
#include <QTextBlock>
#include <QTextLayout>
#include <QTimer>

#include <cstdio>
#include <cstdlib>

#include "ConsoleCommandes.h"
#include "Editeur.h"
#include "FenetreAide.h"
#include "FenetreFigure.h"
#include "FenetreProfileur.h"
#include "Icone.h"
#include "Ruban.h"
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
    // Sortie ligne a ligne : si le test meurt en cours de route, on garde
    // tout ce qui a deja ete verifie au lieu de perdre le tampon.
    std::setvbuf(stdout, nullptr, _IOLBF, 0);
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
    FenetreFigure* fenetreFigure = nullptr;
    verifier(attendre([&] {
                 fenetreFigure = fenetre.findChild<FenetreFigure*>();
                 vue = fenetreFigure ? fenetreFigure->vue() : nullptr;
                 return vue != nullptr;
             }),
             "une fenetre de figure s'ouvre, comme sous MATLAB");
    if (fenetreFigure) {
        verifier(fenetreFigure->isWindow(), "la figure est une fenetre a part entiere");
        verifier(fenetreFigure->windowTitle().startsWith(QLatin1String("Figure 1")),
                 "la fenetre s'appelle « Figure 1 »");
        verifier(!fenetreFigure->windowIcon().isNull(), "la fenetre de figure a une icone");
    }
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

    // --- l'echelle logarithmique se voit a l'ecran ------------------------
    //
    // « semilogx » doit dessiner une abscisse logarithmique dans la
    // fenetre, comme il le fait deja dans le SVG. Le controle est celui
    // qu'un oeil ferait : sur cinq decades, une droite y = x remplit la
    // largeur ; en echelle lineaire elle serait ecrasee contre le bord
    // gauche.
    {
        envoyer(fenetre, QStringLiteral("figure; w = logspace(-5, 5, 400); "
                                        "semilogx(w, w); grid on;"));
        VueFigure* vueLog = nullptr;
        verifier(attendre([&] {
                     for (FenetreFigure* f : fenetre.findChildren<FenetreFigure*>())
                         if (!f->isHidden() &&
                             f->windowTitle().startsWith(QLatin1String("Figure 2")))
                             vueLog = f->vue();
                     return vueLog != nullptr;
                 }),
                 "la figure de la courbe logarithmique s'ouvre");
        if (vueLog) {
            vueLog->resize(640, 480);
            QCoreApplication::processEvents();
            QImage image(640, 480, QImage::Format_ARGB32);
            image.fill(Qt::white);
            vueLog->render(&image);
            int colonnesEncrees = 0;
            for (int x = 0; x < image.width(); ++x) {
                bool encre = false;
                for (int y = 0; y < image.height() && !encre; ++y) {
                    QColor c = image.pixelColor(x, y);
                    if (c.blue() - c.red() > 60) encre = true;  // le bleu du trace
                }
                if (encre) ++colonnesEncrees;
            }
            verifier(colonnesEncrees > image.width() / 2,
                     "l'abscisse logarithmique etale la courbe sur la largeur");
            const char* capture = std::getenv("MATLIBRE_CAPTURE_FIGURE");
            if (capture) image.save(QString::fromLocal8Bit(capture));
        }
        // Refermer la sienne : la suite compte les fenetres ouvertes.
        envoyer(fenetre, QStringLiteral("close(2)"));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
    }

    // --- la vie des fenetres de figure ------------------------------------
    //
    // Trois choses que MATLAB fait, et que le bureau ne faisait pas : une
    // commande sans rapport ne remonte pas les figures au premier plan,
    // « close all » les ferme vraiment, et une figure fermee a la main
    // reste fermee au lieu de revenir a la commande suivante.
    {
        auto fenetresOuvertes = [&] {
            int n = 0;
            for (FenetreFigure* f : fenetre.findChildren<FenetreFigure*>())
                if (!f->isHidden()) ++n;
            return n;
        };
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        verifier(fenetresOuvertes() == 1, "une figure est ouverte");

        // Une commande qui ne trace rien ne doit pas toucher aux figures.
        FenetreFigure* premiere = fenetre.findChild<FenetreFigure*>();
        premiere->hide();
        envoyer(fenetre, QStringLiteral("sansRapport = 1 + 1;"));
        verifier(attendre([&] { return ligneDe(QStringLiteral("sansRapport")) >= 0; }),
                 "la commande sans rapport passe");
        verifier(premiere->isHidden(),
                 "une commande sans trace ne rouvre pas la figure");

        // Tracer dedans la ramene, comme sous MATLAB.
        envoyer(fenetre, QStringLiteral("plot(1:10);"));
        verifier(attendre([&] { return !premiere->isHidden(); }),
                 "tracer dedans la ramene au premier plan");

        // Fermer la fenetre ferme la figure : elle ne revient pas.
        int numero = premiere->numero();
        premiere->close();
        QCoreApplication::processEvents();
        envoyer(fenetre, QStringLiteral("encoreSansRapport = 2;"));
        verifier(attendre([&] { return ligneDe(QStringLiteral("encoreSansRapport")) >= 0; }),
                 "la commande suivante passe");
        verifier(attendre([&] { return fenetresOuvertes() == 0; }, 4000),
                 "une figure fermee a la main ne revient pas");
        verifier(numero == 1, "c'etait bien la figure 1");

        // Deux figures, puis « close all » : les deux fenetres s'en vont.
        envoyer(fenetre, QStringLiteral("figure(1); plot(1:5); figure(2); plot(1:5);"));
        verifier(attendre([&] { return fenetresOuvertes() == 2; }, 8000),
                 "deux figures, deux fenetres");
        envoyer(fenetre, QStringLiteral("close all"));
        verifier(attendre([&] { return fenetresOuvertes() == 0; }, 8000),
                 "« close all » ferme vraiment les fenetres");

        // On repart d'une figure pour la suite des verifications.
        envoyer(fenetre, QStringLiteral("figure(1); plot(x, y); title('deux signaux');"));
        verifier(attendre([&] { return fenetresOuvertes() == 1; }, 8000),
                 "on peut retracer apres « close all »");
        vue = nullptr;
        for (FenetreFigure* f : fenetre.findChildren<FenetreFigure*>())
            if (!f->isHidden()) vue = f->vue();
        verifier(vue != nullptr, "la nouvelle figure a sa vue");
    }

    // L'application a son icone : sur le fichier comme sur la fenetre.
    verifier(!iconeApplication().isNull(), "l'icone de l'application existe");
    verifier(iconeApplication().availableSizes().size() >= 5,
             "l'icone est fournie en plusieurs tailles");

    // --- le ruban ---------------------------------------------------------
    auto* ruban = fenetre.findChild<QTabWidget*>(QString(), Qt::FindChildrenRecursively);
    QTabWidget* bandeau = nullptr;
    for (QTabWidget* t : fenetre.findChildren<QTabWidget*>())
        if (t->count() >= 2 && t->tabText(0) == QLatin1String("Accueil")) bandeau = t;
    (void)ruban;
    verifier(bandeau != nullptr, "le ruban a ses onglets");
    if (bandeau) {
        verifier(bandeau->tabText(1) == QString::fromUtf8("Tracés"),
                 "l'onglet des traces est la");
        // Les fleches de defilement de la barre d'onglets sont aussi des
        // QToolButton, sans texte : ce ne sont pas des boutons du ruban.
        QList<QToolButton*> boutons;
        for (QToolButton* b : bandeau->findChildren<QToolButton*>())
            if (!b->text().isEmpty()) boutons << b;
        verifier(boutons.size() >= 10, "le ruban porte ses boutons");
        int avecIcone = 0, assezLarges = 0;
        for (QToolButton* b : boutons) {
            if (!b->icon().isNull()) ++avecIcone;
            // Un bouton doit etre assez large pour son libelle : sinon Qt
            // elide, et « Nouveau script » sort en « ouveau scrip ».
            QFontMetrics m(b->font());
            int large = 0;
            for (const QString& mot : b->text().split(QLatin1Char('\n')))
                large = qMax(large, m.horizontalAdvance(mot));
            if (b->width() >= large) ++assezLarges;
        }
        verifier(avecIcone == boutons.size(), "chaque bouton du ruban a son icone");
        verifier(assezLarges == boutons.size(),
                 "aucun libelle du ruban n'est rogne");
    }

    // Les panneaux de droite doivent avoir une largeur utilisable : sans
    // elle, leur titre lui-meme se reduit a « ... ».
    for (QDockWidget* d : fenetre.findChildren<QDockWidget*>()) {
        if (!d->isVisible()) continue;
        verifier(d->width() >= 180,
                 qPrintable(QStringLiteral("le panneau « %1 » a une largeur utilisable")
                                .arg(d->windowTitle())));
    }

    // « clc » efface la fenetre au lieu d'y ecrire « [2J[H » : une
    // interface graphique n'interprete pas les sequences ANSI.
    envoyer(fenetre, QStringLiteral("clc"));
    verifier(attendre([&] {
                 return !console->toPlainText().contains(QLatin1String("[2J")) &&
                        console->toPlainText().count(QLatin1Char('\n')) < 4;
             }),
             "« clc » efface la console sans y ecrire de sequence ANSI");

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
        // Un fichier dont le nom n'est pas un identifiant MATLAB doit
        // s'executer aussi : c'est le cas de « sans-titre.m », le nom que
        // le bureau propose par defaut.
        {
            QString avecTiret = QDir::current().filePath(QStringLiteral("sans-titre.m"));
            editeur->setPlainText(QStringLiteral("valeurAvecTiret = 5 * 5;\n"));
            editeur->definirFichier(avecTiret);
            QMetaObject::invokeMethod(&fenetre, "enregistrer");
            verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
            QMetaObject::invokeMethod(&fenetre, "executerScript");
            verifier(attendre([&] { return ligneDe(QStringLiteral("valeurAvecTiret")) >= 0; }),
                     "un fichier nomme « sans-titre.m » s'execute quand meme");
        }

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

    // --- les toolboxes sont la ---------------------------------------------
    //
    // Le bureau doit voir les 1067 fonctions ecrites en langage MATLAB, pas
    // seulement les natives : elles vivent dans toolbox/, qu'il faut
    // trouver a cote de l'executable. Le jour ou les binaires ont demenage
    // dans build/bin, la recherche a cesse d'aboutir et le bureau s'est
    // retrouve sans ses toolboxes — et sans les fiches d'aide.
    envoyer(fenetre, QStringLiteral("[bb, aa] = butter(2, 0.2);"));
    verifier(attendre([&] { return ligneDe(QStringLiteral("bb")) >= 0; }, 20000),
             "une fonction de toolbox repond dans le bureau");
    envoyer(fenetre, QStringLiteral("prixAppel = blsprice(100, 100, 0.05, 1, 0.2);"));
    verifier(attendre([&] { return ligneDe(QStringLiteral("prixAppel")) >= 0; }, 20000),
             "et une autre, prise dans une toolbox differente");
    envoyer(fenetre, QStringLiteral("clear bb aa prixAppel"));
    verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");

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

    // --- le debogueur ------------------------------------------------------
    //
    // Un bureau MATLAB sans points d'arret n'en est pas un. Ce qui suit
    // pose un point d'arret, verifie que l'execution s'y arrete, que la
    // ligne est montree, qu'on peut lire ET MODIFIER une variable a
    // l'arret — le « K>> » de MATLAB —, puis avancer et reprendre.
    if (editeur) {
        QString scriptDebug = QDir::current().filePath(QStringLiteral("essaiDebug.m"));
        editeur->setPlainText(QStringLiteral("a = 1;\n"
                                             "b = a + 1;\n"
                                             "c = b * 10;\n"
                                             "d = c + 5;\n"));
        editeur->definirFichier(scriptDebug);
        QMetaObject::invokeMethod(&fenetre, "enregistrer");
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");

        // Le clic dans la marge pose le point d'arret ; ici on appelle le
        // meme chemin que ce clic.
        editeur->basculerPointArret(3);
        verifier(editeur->pointsArret().contains(3),
                 "le point d'arret est pose sur la ligne 3");

        fenetre.envoyerCommande(QStringLiteral("run('") + scriptDebug + QStringLiteral("')"));
        verifier(attendre([&] { return editeur->ligneArret() == 3; }, 15000),
                 "l'execution s'arrete sur le point d'arret");
        verifier(fenetre.enPause(), "le bureau se sait en pause");

        // A l'arret, les variables deja calculees sont visibles.
        verifier(attendre([&] {
                     int l = ligneDe(QStringLiteral("b"));
                     return l >= 0 && variables->item(l, 1)->text() == QLatin1String("2");
                 }),
                 "les variables sont lisibles a l'arret");
        // ... et « c » ne l'est pas encore : la ligne 3 n'a pas tourne.
        verifier(ligneDe(QStringLiteral("c")) < 0,
                 "la ligne ou l'on est arrete n'a pas encore tourne");
        // L'invite est passee a « K>> ».
        verifier(console->toPlainText().contains(QLatin1String("K>> ")),
                 "l'invite passe a « K>> », comme sous MATLAB");

        // On modifie une variable a l'arret : c'est ce qui distingue un
        // vrai debogueur d'un simple point d'observation.
        fenetre.envoyerCommande(QStringLiteral("b = 7;"));
        verifier(attendre([&] {
                     int l = ligneDe(QStringLiteral("b"));
                     return l >= 0 && variables->item(l, 1)->text() == QLatin1String("7");
                 }),
                 "on peut modifier une variable a l'arret");

        // Pas a pas : la ligne 3 s'execute, on s'arrete ligne 4.
        QMetaObject::invokeMethod(&fenetre, "pasAPas");
        verifier(attendre([&] { return editeur->ligneArret() == 4; }, 15000),
                 "le pas a pas avance d'une ligne");
        verifier(attendre([&] {
                     int l = ligneDe(QStringLiteral("c"));
                     return l >= 0 && variables->item(l, 1)->text() == QLatin1String("70");
                 }),
                 "la ligne franchie a bien calcule, avec la valeur modifiee");

        // Reprise : le script finit.
        QMetaObject::invokeMethod(&fenetre, "continuerExecution");
        verifier(attendre([&] { return !fenetre.enPause() && !fenetre.occupe(); }, 15000),
                 "l'execution reprend et le script finit");
        verifier(editeur->ligneArret() == 0, "la fleche d'arret disparait");
        int ligneD = ligneDe(QStringLiteral("d"));
        verifier(ligneD >= 0 && variables->item(ligneD, 1)->text() == QLatin1String("75"),
                 "le script rend 75, la modification comprise");

        // Retirer le point d'arret : le script ne s'arrete plus.
        QMetaObject::invokeMethod(&fenetre, "retirerTousPointsArret");
        verifier(editeur->pointsArret().isEmpty(), "les points d'arret sont retires");
        fenetre.envoyerCommande(QStringLiteral("clear c d"));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        fenetre.envoyerCommande(QStringLiteral("run('") + scriptDebug + QStringLiteral("')"));
        verifier(attendre([&] {
                     return !fenetre.occupe() && ligneDe(QStringLiteral("d")) >= 0;
                 }, 15000),
                 "sans point d'arret, le script tourne d'un trait");
        verifier(!fenetre.enPause(), "et ne s'arrete pas");
    }

    // --- le ruban qui se replie --------------------------------------------
    //
    // Quand la fenetre retrecit, MATLAB ne rogne pas les libelles : il
    // replie les groupes en un bouton a menu. Ce qui suit verifie les deux
    // sens — retrecir replie, elargir redeploie — et surtout qu'aucun
    // libelle visible n'est jamais elide.
    {
        // Un libelle est elide si le bouton est plus etroit que son plus
        // long mot : c'est exactement ce que l'oeil voit comme « ouveau
        // scrip ».
        auto aucunLibelleRogne = [&](FenetrePrincipale& f) {
            for (GroupeRuban* g : f.findChildren<GroupeRuban*>()) {
                if (g->compact()) continue;
                for (QToolButton* b : g->findChildren<QToolButton*>()) {
                    if (!b->isVisibleTo(g) || b->text().isEmpty()) continue;
                    QFontMetrics metrique(b->font());
                    int plusLong = 0;
                    for (const QString& mot : b->text().split(QLatin1Char('\n')))
                        plusLong = qMax(plusLong, metrique.horizontalAdvance(mot));
                    if (b->width() < plusLong) return false;
                }
            }
            return true;
        };
        auto nombreReplies = [&](FenetrePrincipale& f) {
            int n = 0;
            for (GroupeRuban* g : f.findChildren<GroupeRuban*>())
                if (g->compact()) ++n;
            return n;
        };

        QSize avant = fenetre.size();
        fenetre.resize(1500, avant.height());
        QCoreApplication::processEvents();
        int repliesLarge = nombreReplies(fenetre);
        verifier(aucunLibelleRogne(fenetre), "au large, aucun libelle du ruban n'est rogne");

        fenetre.resize(760, avant.height());
        QCoreApplication::processEvents();
        int repliesEtroit = nombreReplies(fenetre);
        verifier(repliesEtroit > repliesLarge,
                 "a l'etroit, le ruban replie des groupes au lieu de rogner");
        verifier(aucunLibelleRogne(fenetre), "et ce qui reste deploye reste lisible");

        // Un groupe replie garde ses commandes : elles passent dans un menu.
        GroupeRuban* replie = nullptr;
        for (GroupeRuban* g : fenetre.findChildren<GroupeRuban*>())
            if (g->compact() && !replie) replie = g;
        verifier(replie != nullptr, "un groupe replie existe");
        if (replie) {
            QToolButton* bouton = nullptr;
            for (QToolButton* b : replie->findChildren<QToolButton*>())
                if (b->menu()) bouton = b;
            verifier(bouton != nullptr && bouton->menu() &&
                         !bouton->menu()->actions().isEmpty(),
                     "il porte ses commandes dans un menu");
        }

        // Reelargir doit rendre exactement l'etat de depart : le repli est
        // une fonction de la largeur, pas un chemin sans retour.
        fenetre.resize(1500, avant.height());
        verifier(attendre([&] { return nombreReplies(fenetre) == repliesLarge; }, 4000),
                 "en reelargissant, le ruban se redeploie");
        verifier(aucunLibelleRogne(fenetre), "et rien n'est rogne au retour");
        fenetre.resize(avant);
        QCoreApplication::processEvents();
    }

    // --- Ctrl-C ------------------------------------------------------------
    //
    // Un calcul long doit pouvoir etre coupe : sans cela, afficher un
    // vecteur de dix millions d'elements fige la fenetre pour de bon.
    {
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        fenetre.envoyerCommande(
            QStringLiteral("interminable = 0; for k = 1:2000000000, "
                           "interminable = interminable + 1; end"));
        verifier(attendre([&] { return fenetre.occupe(); }, 8000),
                 "le calcul interminable est parti");
        // Pendant qu'il tourne, l'interface repond encore.
        int tours = 0;
        QElapsedTimer patience;
        patience.start();
        while (patience.elapsed() < 200) {
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
            ++tours;
        }
        verifier(tours > 5, "l'interface repond pendant le calcul interminable");
        QMetaObject::invokeMethod(&fenetre, "interrompre");
        verifier(attendre([&] { return !fenetre.occupe(); }, 15000),
                 "Ctrl-C coupe le calcul et rend l'invite");
        verifier(console->toPlainText().contains(
                     QLatin1String("Operation terminated by user")),
                 "le message est celui de MATLAB");
        // Et le bureau repart : l'interpreteur n'est pas casse.
        envoyer(fenetre, QStringLiteral("apresArret = 7;"));
        verifier(attendre([&] { return ligneDe(QStringLiteral("apresArret")) >= 0; }),
                 "on peut retravailler juste apres");

        // Une sortie abondante ne doit pas noyer le fil graphique : elle
        // arrive groupee, pas un signal par ligne. Sans cela la fenetre
        // cessait de repondre, et Windows proposait de la tuer.
        int paquetsAvant = fenetre.paquetsSortie();
        fenetre.envoyerCommande(
            QStringLiteral("for k = 1:20000, fprintf('ligne %d\\n', k); end"));
        verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                 "la sortie abondante finit");
        int paquets = fenetre.paquetsSortie() - paquetsAvant;
        // Vingt mille lignes doivent arriver en quelques centaines de
        // paquets, pas en vingt mille signaux : c'est la file du fil
        // graphique qui debordait, et la fenetre cessait de repondre.
        std::printf("  (paquets recus : %d pour 20000 lignes)\n", paquets);
        verifier(paquets > 0 && paquets < 500,
                 "vingt mille lignes arrivent groupees, pas une par signal");
        verifier(console->toPlainText().contains(QLatin1String("ligne 20000")),
                 "et rien n'est perdu en chemin");

        // L'affichage d'un tableau enorme se coupe aussi : c'est la que le
        // bureau se figeait. Un million d'elements font seize megaoctets
        // de texte ; la fenetre doit les voir arriver au fil de l'eau,
        // rester vivante pendant, et s'arreter au Ctrl-C.
        fenetre.envoyerCommande(QStringLiteral("enorme = 0:0.0001:100;"));
        verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                 "le grand vecteur est construit");
        paquetsAvant = fenetre.paquetsSortie();
        QElapsedTimer chronoAffichage;
        chronoAffichage.start();
        fenetre.envoyerCommande(QStringLiteral("enorme"));
        verifier(attendre([&] { return fenetre.occupe(); }, 8000),
                 "son affichage est parti");
        // Au fil de l'eau : du texte paraît AVANT la fin. Tant que
        // l'affichage se rendait dans une seule chaine, rien ne sortait
        // avant la derniere colonne — seize megaoctets plus tard.
        verifier(attendre([&] {
                     return fenetre.paquetsSortie() > paquetsAvant && fenetre.occupe();
                 }, 15000),
                 "le texte paraît pendant l'affichage, pas seulement a la fin");
        std::printf("  (premier texte apres %lld ms)\n",
                    (long long)chronoAffichage.elapsed());
        // Et la fenetre repond toujours, sous le flot : c'est ce qui
        // permet au Ctrl-C d'arriver jusqu'au moteur.
        tours = 0;
        patience.restart();
        while (patience.elapsed() < 200) {
            QCoreApplication::processEvents(QEventLoop::AllEvents, 5);
            ++tours;
        }
        verifier(tours > 5, "l'interface repond pendant l'affichage enorme");
        chronoAffichage.restart();
        QMetaObject::invokeMethod(&fenetre, "interrompre");
        verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                 "l'affichage d'un tableau enorme se coupe");
        std::printf("  (coupe apres %lld ms)\n", (long long)chronoAffichage.elapsed());
        envoyer(fenetre, QStringLiteral("clear enorme interminable"));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");

        // Un Ctrl-C qui arrive alors qu'il n'y a plus rien a couper ne
        // doit pas couper la commande suivante.
        QMetaObject::invokeMethod(&fenetre, "interrompre");
        envoyer(fenetre, QStringLiteral("apresCtrlC = 1 + 1;"));
        verifier(attendre([&] { return ligneDe(QStringLiteral("apresCtrlC")) >= 0; }),
                 "un Ctrl-C sans calcul a couper ne gene pas la commande suivante");
    }

    // --- le navigateur d'aide ----------------------------------------------
    //
    // MATLAB n'imprime pas « doc fft » dans la console : il ouvre une
    // fenetre, avec la liste des fonctions, la page mise en forme, et des
    // renvois cliquables. Ce qui suit verifie que c'est bien ce qui se
    // passe — y compris pour une fonction ecrite par l'utilisateur.
    {
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        envoyer(fenetre, QStringLiteral("doc fft"));
        FenetreAide* aide = nullptr;
        verifier(attendre([&] {
                     aide = fenetre.findChild<FenetreAide*>();
                     return aide && aide->page() &&
                            aide->page()->toPlainText().contains(QLatin1String("Fourier"));
                 }, 15000),
                 "« doc fft » ouvre le navigateur d'aide sur la bonne page");
        if (aide) {
            QString texte = aide->page()->toPlainText();
            verifier(texte.contains(QLatin1String("Syntaxe")),
                     "la page montre la syntaxe");
            verifier(texte.contains(QLatin1String("Exemples")),
                     "la page montre des exemples");
            verifier(texte.contains(QLatin1String("Voir aussi")),
                     "la page montre les fonctions voisines");
            verifier(aide->page()->toHtml().contains(QLatin1String("aide:ifft")),
                     "les voisines sont des liens cliquables");
            verifier(attendre([&] { return aide->liste()->count() > 300; }, 20000),
                     "la liste des fonctions est remplie");

            // La recherche filtre, comme la case de MATLAB.
            aide->recherche()->setText(QStringLiteral("fft"));
            QCoreApplication::processEvents();
            int filtrees = aide->liste()->count();
            verifier(filtrees > 0 && filtrees < 100,
                     "la recherche reduit la liste aux fonctions qui collent");
            aide->recherche()->clear();
            QCoreApplication::processEvents();

            // L'aide d'une fonction ecrite par l'utilisateur vient de son
            // bloc de commentaires : c'est la regle de MATLAB.
            QString fonctionAMoi = QDir::current().filePath(QStringLiteral("maFonctionAMoi.m"));
            {
                QFile f(fonctionAMoi);
                if (f.open(QIODevice::WriteOnly | QIODevice::Text))
                    f.write(
                        "function y = maFonctionAMoi(x)\n"
                        "%MAFONCTIONAMOI Double son argument, et rien de plus.\n"
                        "%   Y = MAFONCTIONAMOI(X) rend 2*X.\n"
                        "%\n"
                        "%   Exemples\n"
                        "%      maFonctionAMoi(21)   % 42\n"
                        "%\n"
                        "%   Voir aussi TIMES, PLUS.\n"
                        "    y = 2 * x;\n"
                        "end\n");
            }
            envoyer(fenetre, QStringLiteral("rehash"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "le chemin est reindexe");
            envoyer(fenetre, QStringLiteral("doc maFonctionAMoi"));
            verifier(attendre([&] {
                         return aide->page()->toPlainText().contains(
                             QLatin1String("Double son argument"));
                     }, 15000),
                     "l'aide d'une fonction ecrite par l'utilisateur s'affiche");
            QString mienne = aide->page()->toPlainText();
            verifier(mienne.contains(QLatin1String("maFonctionAMoi(21)")),
                     "ses exemples sont repris");
            verifier(mienne.contains(QLatin1String("Voir aussi")),
                     "ses renvois aussi");
            verifier(mienne.contains(QLatin1String("maFonctionAMoi.m")),
                     "la page dit dans quel fichier elle est definie");

            // F1 sur un mot de l'editeur ouvre sa page.
            if (editeur) {
                editeur->setPlainText(QStringLiteral("y = fftshift(x);"));
                QTextCursor curseur = editeur->textCursor();
                curseur.setPosition(6);
                editeur->setTextCursor(curseur);
                QMetaObject::invokeMethod(&fenetre, "aideSurMotCourant");
                verifier(attendre([&] {
                             return aide->nomCourant() == QLatin1String("fftshift");
                         }, 8000),
                         "F1 ouvre l'aide du mot sous le curseur");
            }
        }
    }

    // --- le profileur ------------------------------------------------------
    //
    // « Executer et chronometrer » de MATLAB : on mesure un script qui
    // appelle une fonction chere, et on verifie que la fenetre du
    // profileur nomme cette fonction, compte ses appels, et montre son
    // code ligne a ligne avec le nombre de passages.
    if (editeur) {
        QString scriptProfil = QDir::current().filePath(QStringLiteral("essaiProfil.m"));
        {
            QFile f(scriptProfil);
            if (f.open(QIODevice::WriteOnly | QIODevice::Text))
                f.write(
                    "total = 0;\n"
                    "for k = 1:40\n"
                    "    total = total + coutDEssai(k);\n"
                    "end\n");
        }
        {
            QFile f(QDir::current().filePath(QStringLiteral("coutDEssai.m")));
            if (f.open(QIODevice::WriteOnly | QIODevice::Text))
                f.write(
                    "function r = coutDEssai(n)\n"
                    "    r = 0;\n"
                    "    for j = 1:200\n"
                    "        r = r + j * n;\n"
                    "    end\n"
                    "end\n");
        }
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        // Le dossier vient de changer de contenu : sans reindexation, la
        // fonction reste introuvable — comme sous MATLAB.
        envoyer(fenetre, QStringLiteral("rehash"));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le chemin est reindexe");

        editeur->definirFichier(scriptProfil);
        editeur->setPlainText(QString::fromUtf8(
            "total = 0;\nfor k = 1:40\n    total = total + coutDEssai(k);\nend\n"));
        QMetaObject::invokeMethod(&fenetre, "enregistrer");
        verifier(attendre([&] { return !fenetre.occupe(); }), "le script mesure est ecrit");

        QMetaObject::invokeMethod(&fenetre, "executerEtChronometrer");
        verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                 "la mesure finit");

        FenetreProfileur* profileur = fenetre.findChild<FenetreProfileur*>();
        verifier(profileur != nullptr, "la fenetre du profileur s'ouvre d'elle-meme");
        if (profileur) {
            QTableWidget* mesures = profileur->tableFonctions();
            int rangeeCout = -1;
            for (int k = 0; k < mesures->rowCount(); ++k)
                if (mesures->item(k, 0) &&
                    mesures->item(k, 0)->text() == QLatin1String("coutDEssai"))
                    rangeeCout = k;
            verifier(rangeeCout >= 0, "le profil nomme la fonction mesuree");
            if (rangeeCout >= 0) {
                verifier(mesures->item(rangeeCout, 1)->text() == QLatin1String("40"),
                         "il compte ses quarante appels");
                // Le temps est mesure, pas invente : il est non nul.
                verifier(!mesures->item(rangeeCout, 2)->text().isEmpty(),
                         "il donne un temps total");
                mesures->selectRow(rangeeCout);
                QCoreApplication::processEvents();
                QTableWidget* detail = profileur->tableLignes();
                verifier(detail->rowCount() >= 6,
                         "le detail montre le code de la fonction, ligne a ligne");
                bool corpsCompte = false;
                for (int k = 0; k < detail->rowCount(); ++k) {
                    if (!detail->item(k, 2) || !detail->item(k, 1)) continue;
                    if (detail->item(k, 2)->text().contains(QLatin1String("r + j * n")) &&
                        detail->item(k, 1)->text().toLongLong() >= 8000)
                        corpsCompte = true;
                }
                verifier(corpsCompte,
                         "la ligne chaude porte ses 8000 passages, avec son code");
            }
            verifier(profileur->resume().contains(QLatin1String("fonction")),
                     "le resume annonce ce qui a ete mesure");
        }
    }

    // Fermer le bureau pendant un arret : le fil de calcul dort dans le
    // crochet et n'entend plus rien. S'il n'est pas libere, Qt abandonne
    // le programme sur « QThread: Destroyed while thread is still
    // running ». Ce bloc est la pour que cela ne revienne pas.
    {
        auto* second = new FenetrePrincipale;
        QString scriptFermeture =
            QDir::current().filePath(QStringLiteral("essaiFermeture.m"));
        {
            QFile f(scriptFermeture);
            if (f.open(QIODevice::WriteOnly | QIODevice::Text))
                f.write("x = 1;\ny = x + 1;\nz = y + 1;\n");
        }
        second->ouvrirFichier(scriptFermeture);
        auto* editeurFermeture =
            qobject_cast<Editeur*>(second->findChild<Editeur*>());
        bool pose = false;
        for (Editeur* e : second->findChildren<Editeur*>())
            if (e->fichier() == scriptFermeture) {
                e->basculerPointArret(2);
                editeurFermeture = e;
                pose = true;
            }
        verifier(pose, "le second bureau ouvre le script et y pose un point d'arret");
        (void)editeurFermeture;
        second->envoyerCommande(QStringLiteral("run('") + scriptFermeture +
                                QStringLiteral("')"));
        verifier(attendre([&] { return second->enPause(); }, 15000),
                 "le second bureau s'arrete sur son point d'arret");
        // C'est le geste qui faisait tomber le programme : detruire la
        // fenetre alors que le fil de calcul dort dans le crochet.
        delete second;
        verifier(true, "fermer le bureau pendant un arret ne tue pas le programme");
    }

    // « doc » sur une classe : le navigateur ouvre sa page comme pour une
    // fonction. Il ne trouvait plus rien depuis que tf est une classe.
    {
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        envoyer(fenetre, QStringLiteral("doc tf"));
        verifier(attendre([&] {
                     FenetreAide* a = fenetre.findChild<FenetreAide*>();
                     return a && a->page() &&
                            a->page()->toPlainText().contains(
                                QLatin1String("fonction de transfert"));
                 }, 15000),
                 "« doc tf » ouvre la page d'une classe");
    }

    // --- le panneau « Dossier courant » ------------------------------------
    //
    // MATLAB y montre TOUT le dossier — fichiers et sous-dossiers, quelle
    // que soit l'extension —, avec la taille, le type et une icone par
    // famille. Il n'a longtemps montre ici que les .m, ce qui cachait les
    // donnees a cote desquelles on travaille.
    {
        QDir dossier = QDir::current();
        dossier.mkdir(QStringLiteral("resultats"));
        auto ecrire = [&](const QString& nom, const QByteArray& contenu) {
            QFile f(dossier.filePath(nom));
            if (f.open(QIODevice::WriteOnly)) f.write(contenu);
        };
        ecrire(QStringLiteral("mesures.csv"), "a,b\n1,2\n");
        ecrire(QStringLiteral("notes.txt"), "quelques notes\n");
        ecrire(QStringLiteral("courbe.svg"), "<svg/>");
        ecrire(QStringLiteral("donnees.mat"), QByteArray(64, '\0'));
        fenetre.rafraichirListeFichiers();
        auto* arbre = fenetre.findChild<QTreeWidget*>();
        verifier(arbre != nullptr, "le panneau du dossier courant est un arbre a colonnes");
        if (arbre) {
            auto ligneDe = [&](const QString& nom) -> QTreeWidgetItem* {
                for (int k = 0; k < arbre->topLevelItemCount(); ++k)
                    if (arbre->topLevelItem(k)->text(0) == nom) return arbre->topLevelItem(k);
                return nullptr;
            };
            verifier(arbre->columnCount() == 3, "il a les colonnes nom, taille et type");
            verifier(ligneDe(QStringLiteral("mesures.csv")) != nullptr,
                     "un fichier qui n'est pas un .m y figure");
            verifier(ligneDe(QStringLiteral("notes.txt")) != nullptr,
                     "un fichier texte aussi");
            verifier(ligneDe(QStringLiteral("donnees.mat")) != nullptr,
                     "un fichier de donnees aussi");
            verifier(ligneDe(QStringLiteral("resultats")) != nullptr,
                     "un sous-dossier aussi");
            verifier(ligneDe(QStringLiteral("..")) != nullptr, "et le dossier parent");
            QTreeWidgetItem* csv = ligneDe(QStringLiteral("mesures.csv"));
            QTreeWidgetItem* dos = ligneDe(QStringLiteral("resultats"));
            verifier(csv && !csv->text(1).isEmpty(), "la taille est donnee");
            verifier(csv && csv->text(2) == QLatin1String("Fichier CSV"),
                     "le type nomme ce qu'est le fichier");
            QTreeWidgetItem* mat = ligneDe(QStringLiteral("donnees.mat"));
            verifier(mat && mat->text(2) == QLatin1String("Fichier MAT"),
                     "et il distingue les familles entre elles");
            verifier(dos && dos->text(2) == QLatin1String("Dossier"),
                     "un dossier est annonce comme tel");
            verifier(csv && !csv->icon(0).isNull(), "chaque entree porte son icone");
            // Deux familles differentes ne portent pas la meme icone :
            // c'est ce qui permet de les distinguer d'un coup d'oeil.
            QTreeWidgetItem* m = ligneDe(QStringLiteral("sans-titre.m"));
            if (!m) m = ligneDe(QStringLiteral("essaiProfil.m"));
            if (m && csv) {
                QImage a = m->icon(0).pixmap(16, 16).toImage();
                QImage b = csv->icon(0).pixmap(16, 16).toImage();
                verifier(a != b, "un .m et un .csv n'ont pas la meme icone");
            }
            QImage c = dos ? dos->icon(0).pixmap(16, 16).toImage() : QImage();
            QImage d = csv ? csv->icon(0).pixmap(16, 16).toImage() : QImage();
            verifier(!c.isNull() && c != d, "un dossier et un fichier non plus");
        }
    }

    // Le dialogue « Dossier courant » montre les fichiers en plus des
    // dossiers : c'est a eux qu'on se repere. Qt les cache par defaut.
    {
        QFileDialog sonde(&fenetre, QStringLiteral("essai"), QDir::currentPath());
        sonde.setFileMode(QFileDialog::Directory);
        sonde.setOption(QFileDialog::ShowDirsOnly, false);
        sonde.setOption(QFileDialog::DontUseNativeDialog, true);
        verifier(!sonde.testOption(QFileDialog::ShowDirsOnly),
                 "le dialogue de dossier ne se limite pas aux dossiers");
    }

    // Une capture, pour qu'un humain puisse regarder ce qui a ete construit.
    const char* sortie = std::getenv("MATLIBRE_CAPTURE");
    if (sortie) {
        QImage image(fenetre.size(), QImage::Format_ARGB32);
        image.fill(Qt::white);
        fenetre.render(&image);
        image.save(QString::fromLocal8Bit(sortie));
        std::printf("  capture ecrite dans %s\n", sortie);
        // Le navigateur d'aide a sa fenetre : capture aussi.
        if (auto* aide = fenetre.findChild<FenetreAide*>()) {
            QString chemin = QString::fromLocal8Bit(sortie);
            chemin.replace(QRegularExpression(QStringLiteral("\\.png$")),
                           QStringLiteral("-aide.png"));
            aide->resize(1000, 700);
            QCoreApplication::processEvents();
            QImage vue(aide->size(), QImage::Format_ARGB32);
            vue.fill(Qt::white);
            aide->render(&vue);
            vue.save(chemin);
            std::printf("  capture de l'aide ecrite dans %s\n",
                        chemin.toLocal8Bit().constData());
        }
        // Le profileur a sa fenetre : elle merite sa propre capture.
        if (auto* profileur = fenetre.findChild<FenetreProfileur*>()) {
            QString chemin = QString::fromLocal8Bit(sortie);
            chemin.replace(QRegularExpression(QStringLiteral("\\.png$")),
                           QStringLiteral("-profileur.png"));
            QImage vue(profileur->size(), QImage::Format_ARGB32);
            vue.fill(Qt::white);
            profileur->render(&vue);
            vue.save(chemin);
            std::printf("  capture du profileur ecrite dans %s\n",
                        chemin.toLocal8Bit().constData());
        }
    }

    std::printf(echecs == 0 ? "bureau : toutes les verifications passent (%d)\n"
                            : "bureau : %d ECHEC(S) sur %d\n",
                echecs == 0 ? verifications : echecs,
                echecs == 0 ? 0 : verifications);
    return echecs == 0 ? 0 : 1;
}
