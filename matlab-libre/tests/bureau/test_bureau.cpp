// test_bureau.cpp — le bureau natif, verifie sans ouvrir de fenetre.
//
// Tourne sur le greffon « offscreen » de Qt : la fenetre est construite,
// peinte et pilotee pour de vrai, mais rien ne s'affiche. Ce qui est
// verifie est ce qu'on ne voit pas a l'oeil — l'espace de travail qui suit
// l'interpreteur, la figure qui se peint, le fil de calcul qui ne bloque
// pas l'interface, et la coloration qui distingue la transposee de la
// chaine de caracteres.
#include <algorithm>

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
#include <QLabel>
#include <QToolBar>
#include <QListWidget>
#include <QFile>
#include <QFileInfo>
#include <QRegularExpression>
#include <QKeyEvent>
#include <QTemporaryDir>
#include <QTextBlock>
#include <QTextLayout>
#include <QTimer>

#include <cmath>
#include <cstdio>
#include <cstdlib>

#include "ConsoleCommandes.h"
#include "Editeur.h"
#include "FenetreAide.h"
#include "FenetreFigure.h"
#include "FenetreProfileur.h"
#include "FenetreSimulink.h"
#include "DialogueBloc.h"
#include "ToileSimulink.h"
#include "Icone.h"
#include "Recherche.h"
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

    // --- une figure d'automatique, comme celles du BE ----------------------
    //
    // Quatre cases, un diagramme de Bode dans l'une d'elles : c'est la
    // figure que produit un sujet de travaux pratiques. On verifie que
    // chaque case porte de l'encre — donc que le Bode n'a pas deplace les
    // autres — et que l'abscisse logarithmique s'etale.
    {
        envoyer(fenetre, QStringLiteral(
                    "figure(7); G = tf(200, [10 1]) * tf(1, [0.05 1])^2; "
                    "K = mixsyn(G, tf(10, [1 0.1]), 0.1, []); "
                    "L = loopsens(G, K); w = logspace(-2, 3, 200); "
                    "subplot(2,2,1), bodemag(L.So, w), title('sensibilite'); "
                    "subplot(2,2,2), bodemag(L.To, w), title('complementaire'); "
                    "subplot(2,2,3), step(feedback(series(K, ss(G)), 1)), title('indicielle'); "
                    "subplot(2,2,4), bode(L.So, w);"));
        VueFigure* vueBe = nullptr;
        verifier(attendre([&] {
                     for (FenetreFigure* f : fenetre.findChildren<FenetreFigure*>())
                         if (!f->isHidden() &&
                             f->windowTitle().startsWith(QLatin1String("Figure 7")))
                             vueBe = f->vue();
                     return vueBe != nullptr;
                 }),
                 "la figure du BE s'ouvre");
        if (vueBe) {
            vueBe->resize(900, 700);
            QCoreApplication::processEvents();
            QImage image(900, 700, QImage::Format_ARGB32);
            image.fill(Qt::white);
            vueBe->render(&image);
            // Chaque quart de l'image doit porter de l'encre : c'est ce
            // qui dit que les quatre cases sont dessinees, et qu'aucune
            // n'a ete recouverte par le decoupage d'une autre.
            auto encreDans = [&](int x0, int y0, int x1, int y1) {
                int n = 0;
                for (int y = y0; y < y1; y += 2)
                    for (int x = x0; x < x1; x += 2)
                        if (qGray(image.pixel(x, y)) < 220) ++n;
                return n;
            };
            verifier(encreDans(0, 0, 450, 350) > 200, "la case en haut a gauche est dessinee");
            verifier(encreDans(450, 0, 900, 350) > 200, "celle en haut a droite aussi");
            verifier(encreDans(0, 350, 450, 700) > 200, "celle en bas a gauche aussi");
            verifier(encreDans(450, 350, 900, 700) > 200, "celle en bas a droite aussi");
            const char* capture = std::getenv("MATLIBRE_CAPTURE_BE");
            if (capture) image.save(QString::fromLocal8Bit(capture));
        }
        envoyer(fenetre, QStringLiteral("close(7)"));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
    }

    // --- les traces neufs : contour, pie, quiver, texte --------------------
    //
    // Quatre cases, quatre familles de trace qui n'existaient pas : les
    // lignes de niveau par marching squares, le diagramme circulaire fait
    // de polygones, le champ de vecteurs, et un texte pose dans l'axe.
    // On verifie que chaque case porte de l'encre, et que le texte est
    // bien rendu par le peintre Qt — c'est lui, et non le SVG, qui montre
    // ce que l'utilisateur voit.
    {
        envoyer(fenetre, QStringLiteral(
                    "figure(8); [X, Y] = meshgrid(linspace(-3,3,60), linspace(-2,2,40)); "
                    "Z = X .* exp(-X.^2 - Y.^2); "
                    "subplot(2,2,1), contour(X, Y, Z, 10), title('lignes de niveau'); "
                    "subplot(2,2,2), pie([3 1 1], [0 0 1], {'un','deux','trois'}); "
                    "subplot(2,2,3), quiver(X(1:4:end,1:6:end), Y(1:4:end,1:6:end), "
                    "  -Y(1:4:end,1:6:end), X(1:4:end,1:6:end)), title('champ'); "
                    "subplot(2,2,4), plot(1:10, (1:10).^2), "
                    "  text(3, 60, 'un texte pose'), title('texte');"));
        VueFigure* vueTraces = nullptr;
        verifier(attendre([&] {
                     for (FenetreFigure* f : fenetre.findChildren<FenetreFigure*>())
                         if (!f->isHidden() &&
                             f->windowTitle().startsWith(QLatin1String("Figure 8")))
                             vueTraces = f->vue();
                     return vueTraces != nullptr;
                 }),
                 "la figure des traces neufs s'ouvre");
        if (vueTraces) {
            vueTraces->resize(900, 700);
            QCoreApplication::processEvents();
            QImage image(900, 700, QImage::Format_ARGB32);
            image.fill(Qt::white);
            vueTraces->render(&image);
            auto encreDans = [&](int x0, int y0, int x1, int y1) {
                int n = 0;
                for (int y = y0; y < y1; y += 2)
                    for (int x = x0; x < x1; x += 2)
                        if (qGray(image.pixel(x, y)) < 220) ++n;
                return n;
            };
            verifier(encreDans(0, 0, 450, 350) > 200, "les lignes de niveau sont dessinees");
            verifier(encreDans(450, 0, 900, 350) > 200, "le diagramme circulaire aussi");
            verifier(encreDans(0, 350, 450, 700) > 200, "le champ de vecteurs aussi");
            verifier(encreDans(450, 350, 900, 700) > 200, "la courbe et son texte aussi");
            // Le secteur decolle est colorie : la case du haut a droite
            // porte des pixels franchement colores, non du seul trait noir.
            int colores = 0;
            for (int y = 20; y < 340; y += 2)
                for (int x = 470; x < 880; x += 2) {
                    QRgb p = image.pixel(x, y);
                    int maximum = std::max(qRed(p), std::max(qGreen(p), qBlue(p)));
                    int minimum = std::min(qRed(p), std::min(qGreen(p), qBlue(p)));
                    if (maximum - minimum > 60) ++colores;
                }
            verifier(colores > 300, "les secteurs du camembert sont remplis");
            const char* capture = std::getenv("MATLIBRE_CAPTURE_TRACES");
            if (capture) image.save(QString::fromLocal8Bit(capture));
        }
        envoyer(fenetre, QStringLiteral("close(8)"));
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

    // --- le clic droit dans le dossier courant -----------------------------
    //
    // MATLAB y met de quoi travailler sans quitter la fenetre : creer,
    // renommer, supprimer, copier le chemin. On verifie le menu lui-meme,
    // puis chacun des gestes sur un dossier d'essai.
    {
        QTemporaryDir bac;
        verifier(bac.isValid(), "un dossier d'essai pour le menu contextuel");
        envoyer(fenetre, QStringLiteral("cd('%1')").arg(bac.path()));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau y est alle");
        fenetre.rafraichirListeFichiers();

        // Creer : un script, une fonction, un dossier.
        fenetre.creerDansDossier(QStringLiteral("script"), QStringLiteral("essai_menu.m"));
        fenetre.creerDansDossier(QStringLiteral("fonction"), QStringLiteral("ma_fonction.m"));
        fenetre.creerDansDossier(QStringLiteral("dossier"), QStringLiteral("sous_dossier"));
        verifier(QFile::exists(QDir(bac.path()).filePath(QStringLiteral("essai_menu.m"))),
                 "le script est cree");
        verifier(QDir(bac.path()).exists(QStringLiteral("sous_dossier")),
                 "le dossier est cree");
        // Une fonction neuve porte deja son en-tete.
        QFile modele(QDir(bac.path()).filePath(QStringLiteral("ma_fonction.m")));
        modele.open(QIODevice::ReadOnly | QIODevice::Text);
        QString texteModele = QString::fromUtf8(modele.readAll());
        modele.close();
        verifier(texteModele.contains(QLatin1String("function sortie = ma_fonction")),
                 "la fonction neuve porte sa ligne de definition");

        // Le panneau les montre.
        fenetre.rafraichirListeFichiers();
        auto* liste = fenetre.findChild<QTreeWidget*>();
        auto trouver = [&](const QString& nom) -> QTreeWidgetItem* {
            for (int k = 0; k < liste->topLevelItemCount(); ++k)
                if (liste->topLevelItem(k)->text(0) == nom) return liste->topLevelItem(k);
            return nullptr;
        };
        verifier(trouver(QStringLiteral("essai_menu.m")) != nullptr,
                 "le panneau montre le fichier cree");

        // Le menu du clic droit : ce qu'il propose depend de ce qui est
        // choisi.
        QTreeWidgetItem* cible = trouver(QStringLiteral("essai_menu.m"));
        liste->setCurrentItem(cible);
        verifier(fenetre.selectionFichiers() == QStringList{QStringLiteral("essai_menu.m")},
                 "la selection est celle qu'on croit");

        // Renommer.
        fenetre.renommerSelection(QStringLiteral("renomme.m"));
        verifier(!QFile::exists(QDir(bac.path()).filePath(QStringLiteral("essai_menu.m"))) &&
                     QFile::exists(QDir(bac.path()).filePath(QStringLiteral("renomme.m"))),
                 "le fichier est renomme");

        // Supprimer, y compris un dossier et son contenu.
        fenetre.rafraichirListeFichiers();
        liste->setCurrentItem(trouver(QStringLiteral("renomme.m")));
        fenetre.supprimerSelection(true);
        verifier(!QFile::exists(QDir(bac.path()).filePath(QStringLiteral("renomme.m"))),
                 "le fichier est supprime");
        fenetre.rafraichirListeFichiers();
        liste->setCurrentItem(trouver(QStringLiteral("sous_dossier")));
        fenetre.supprimerSelection(true);
        verifier(!QDir(bac.path()).exists(QStringLiteral("sous_dossier")),
                 "le dossier est supprime avec son contenu");

        // Le dossier parent ne fait jamais partie d'une selection : on ne
        // renomme ni ne supprime « .. ».
        fenetre.rafraichirListeFichiers();
        if (QTreeWidgetItem* parent = trouver(QStringLiteral(".."))) {
            liste->setCurrentItem(parent);
            verifier(fenetre.selectionFichiers().isEmpty(),
                     "le dossier parent n'est pas une cible");
        }

        // Un nom deja pris ne remplace rien en silence.
        fenetre.creerDansDossier(QStringLiteral("script"), QStringLiteral("unique.m"));
        QFile pris(QDir(bac.path()).filePath(QStringLiteral("unique.m")));
        pris.open(QIODevice::WriteOnly | QIODevice::Text);
        pris.write("% ne pas effacer\n");
        pris.close();
        fenetre.creerDansDossier(QStringLiteral("script"), QStringLiteral("unique.m"));
        QFile relu(QDir(bac.path()).filePath(QStringLiteral("unique.m")));
        relu.open(QIODevice::ReadOnly | QIODevice::Text);
        verifier(QString::fromUtf8(relu.readAll()).contains(QLatin1String("ne pas effacer")),
                 "un fichier existant n'est pas ecrase");
        relu.close();
    }

    // --- Ctrl-F : rechercher et remplacer ---------------------------------
    //
    // MATLAB ouvre une fenetre qui ne bloque pas, cherche dans les deux
    // sens, boucle, et remplace. Elle vise l'editeur courant, ou la
    // console — ou l'on ne remplace pas.
    {
        fenetre.ouvrirRecherche();
        auto* recherche = fenetre.findChild<DialogueRecherche*>();
        verifier(recherche != nullptr, "Ctrl-F ouvre « Rechercher et remplacer »");
        if (recherche) {
            verifier(recherche->isVisible(), "la fenetre de recherche s'affiche");
            verifier(!recherche->isModal(), "elle ne bloque pas le reste");
            verifier(recherche->cible() != nullptr, "elle vise une zone de texte");

            // Un editeur avec du texte : on cherche, on remplace.
            fenetre.ouvrirNouveauScript();
            fenetre.ouvrirRecherche();
            auto* editeur = qobject_cast<Editeur*>(recherche->cible());
            verifier(editeur != nullptr, "un editeur s'ouvre pour la recherche");
            if (editeur) {
                editeur->setPlainText(QStringLiteral(
                    "alpha = 1;\nbeta = alpha + 2;\ngamma = alpha * beta;\n"));
                QTextCursor debut = editeur->textCursor();
                debut.movePosition(QTextCursor::Start);
                editeur->setTextCursor(debut);
                recherche->definirRecherche(QStringLiteral("alpha"));
                verifier(recherche->chercherSuivant(true), "la premiere occurrence est trouvee");
                verifier(editeur->textCursor().selectedText() == QLatin1String("alpha"),
                         "elle est selectionnee");
                verifier(recherche->chercherSuivant(true), "la deuxieme aussi");
                verifier(recherche->chercherSuivant(true), "la troisieme aussi");
                // Boucler : la quatrieme recherche revient a la premiere.
                verifier(recherche->chercherSuivant(true),
                         "la recherche boucle au lieu de s'arreter");
                recherche->definirRemplacement(QStringLiteral("delta"));
                int faits = recherche->remplacerTout();
                verifier(faits == 3, "les trois occurrences sont remplacees");
                verifier(!editeur->toPlainText().contains(QLatin1String("alpha")),
                         "il n'en reste aucune");
                verifier(editeur->toPlainText().contains(QLatin1String("delta = 1;")),
                         "le texte remplace est le bon");
                recherche->definirRecherche(QStringLiteral("introuvableIci"));
                verifier(!recherche->chercherSuivant(true),
                         "ce qui n'y est pas n'est pas trouve");
            }
            recherche->close();
        }
    }

    // --- la tabulation complete, comme dans MATLAB ------------------------
    //
    // Entre guillemets, MATLAB propose des fichiers coherents avec ce
    // qu'on a deja ecrit : « load('K » ne doit proposer que ce qui
    // commence par K. Ailleurs, ce sont les noms de fonctions et de
    // variables.
    {
        QTemporaryDir bac;
        verifier(bac.isValid(), "un dossier d'essai pour la completion");
        QDir(bac.path()).mkdir(QStringLiteral("Fig"));
        for (const char* nom : {"Khinf.mat", "Kbis.mat", "analyse.m"}) {
            QFile f(QDir(bac.path()).filePath(QLatin1String(nom)));
            f.open(QIODevice::WriteOnly);
            f.write("1\n");
            f.close();
        }
        envoyer(fenetre, QStringLiteral("cd('%1')").arg(bac.path()));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau a change de dossier");

        QString prefixe;
        bool fichiers = false;
        QString ligne = QStringLiteral("load('K");
        QStringList choix = console->completionsDe(ligne, ligne.size(), &prefixe, &fichiers);
        verifier(fichiers, "entre guillemets, ce sont des fichiers qu'on propose");
        verifier(prefixe == QLatin1String("K"), "le prefixe est ce qui suit le guillemet");
        verifier(choix.contains(QStringLiteral("Khinf.mat")) &&
                     choix.contains(QStringLiteral("Kbis.mat")),
                 "les deux fichiers en K sont proposes");
        verifier(!choix.contains(QStringLiteral("analyse.m")),
                 "un fichier qui ne commence pas par K ne l'est pas");

        // Un dossier se termine par une barre : on continue a taper dedans.
        ligne = QStringLiteral("cd('F");
        choix = console->completionsDe(ligne, ligne.size(), &prefixe, &fichiers);
        verifier(choix.contains(QStringLiteral("Fig/")), "un dossier propose sa barre");

        // Hors guillemets, ce sont les noms qu'on peut ecrire.
        ligne = QStringLiteral("bodem");
        choix = console->completionsDe(ligne, ligne.size(), &prefixe, &fichiers);
        verifier(!fichiers, "hors guillemets, ce ne sont pas des fichiers");
        verifier(choix.contains(QStringLiteral("bodemag")),
                 "une fonction de toolbox est proposee");
        // Les variables de l'espace de travail aussi, et en premier.
        envoyer(fenetre, QStringLiteral("resultatDeLEssai = 42;"));
        verifier(attendre([&] { return ligneDe(QStringLiteral("resultatDeLEssai")) >= 0; }),
                 "la variable d'essai est creee");
        ligne = QStringLiteral("resultatD");
        choix = console->completionsDe(ligne, ligne.size(), &prefixe, &fichiers);
        verifier(!choix.isEmpty() && choix.first() == QLatin1String("resultatDeLEssai"),
                 "une variable de l'espace de travail est proposee la premiere");

        // Et la touche elle-meme : une seule proposition s'ecrit d'emblee.
        console->poserInvite();
        for (QChar lettre : QStringLiteral("bodema")) {
            QKeyEvent frappe(QEvent::KeyPress, 0, Qt::NoModifier, QString(lettre));
            QCoreApplication::sendEvent(console, &frappe);
        }
        QKeyEvent tabulation(QEvent::KeyPress, Qt::Key_Tab, Qt::NoModifier,
                             QStringLiteral("\t"));
        QCoreApplication::sendEvent(console, &tabulation);
        verifier(console->commandeEnCours() == QLatin1String("bodemag"),
                 "la tabulation ecrit la seule proposition");
        console->effacer();
        envoyer(fenetre, QStringLiteral("clear resultatDeLEssai"));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
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


    // --- une surface remplie, peinte comme le SVG la rend ---------------
    //
    // La toile du bureau et le SVG doivent montrer la meme chose. La toile
    // figeait l'opacite a 0,4 et prenait le contour sur la couleur de
    // fond : un polygone blanc au bord noir y perdait son bord, et un
    // fond opaque y paraissait delave. C'est ce que ces deux mesures
    // attrapent, en comptant des pixels plutot qu'en croyant le code.
    {
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        envoyer(fenetre, QStringLiteral(
            "figure(11); hold on; "
            "patch([0.05 0.45 0.45 0.05], [0.2 0.2 0.8 0.8], [1 1 1], "
            "'EdgeColor', [0 0 0], 'FaceAlpha', 1); "
            "patch([0.55 0.95 0.95 0.55], [0.2 0.2 0.8 0.8], [1 0 0], "
            "'FaceAlpha', 1); "
            "axis([0 1 0 1]); axis off;"));
        VueFigure* vuePatch = nullptr;
        verifier(attendre([&] {
                     for (FenetreFigure* f : fenetre.findChildren<FenetreFigure*>())
                         if (!f->isHidden() &&
                             f->windowTitle().startsWith(QLatin1String("Figure 11")))
                             vuePatch = f->vue();
                     return vuePatch != nullptr;
                 }),
                 "la figure des surfaces remplies s'ouvre");
        if (vuePatch) {
            vuePatch->resize(600, 400);
            QCoreApplication::processEvents();
            QImage image(600, 400, QImage::Format_ARGB32);
            image.fill(Qt::white);
            vuePatch->render(&image);
            // Le polygone blanc doit garder son contour : de l'encre
            // sombre quelque part dans sa moitie de l'image.
            int sombres = 0;
            for (int y = 0; y < 400; ++y)
                for (int x = 0; x < 300; ++x)
                    if (qGray(image.pixel(x, y)) < 100) ++sombres;
            verifier(sombres > 200,
                     "un polygone blanc garde le contour noir qu'on lui a donne");
            // Le polygone rouge doit etre franc, non delave : au centre,
            // le vert doit avoir cede la place.
            QRgb centre = image.pixel(450, 200);
            verifier(qRed(centre) > 180 && qGreen(centre) < 90,
                     "et un fond opaque est peint opaque, non a quatre dixiemes");
        }
        envoyer(fenetre, QStringLiteral("close(11)"));
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
    }

    // --- Simulink dans le bureau --------------------------------------
    //
    // MATLAB donne a Simulink un bouton et une fenetre. Ici la fenetre
    // montre la bibliotheque de blocs a gauche et, a droite, les modeles
    // que porte l'espace de travail — car un modele MatLibre est une
    // valeur, non un fichier. Ce qui se verifie : que le bouton ouvre la
    // fenetre, que la bibliotheque ne ment pas sur ce qu'elle propose, et
    // que l'espace de travail est bien le meme des deux cotes.
    {
        verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est libre");
        QMetaObject::invokeMethod(&fenetre, "montrerSimulink");
        QCoreApplication::processEvents();
        FenetreSimulink* simulink = fenetre.findChild<FenetreSimulink*>();
        verifier(simulink != nullptr, "le bouton du ruban ouvre la fenetre Simulink");
        if (simulink) {
            QTreeWidget* biblio = simulink->bibliotheque();
            int familles = biblio->topLevelItemCount();
            int types = 0;
            for (int k = 0; k < familles; ++k) types += biblio->topLevelItem(k)->childCount();
            verifier(!simulink->findChildren<QToolBar*>().isEmpty(),
                     "l'editeur a sa barre d'outils, comme une fenetre a part entiere");
            verifier(simulink->findChildren<QDockWidget*>().size() >= 2,
                     "la bibliotheque et les modeles sont des volets detachables");
            verifier(simulink->centralWidget() != nullptr &&
                         simulink->toile() != nullptr,
                     "et le schema occupe le centre");
            verifier(simulink->width() >= 1000 && simulink->height() >= 600,
                     "la fenetre est pleine, non un panneau");
            verifier(familles >= 6, "la bibliotheque range les blocs par famille");
            bool accentsIntacts = false;
            for (int k = 0; k < familles; ++k)
                if (biblio->topLevelItem(k)->text(0) == QString::fromUtf8("Opérations"))
                    accentsIntacts = true;
            verifier(accentsIntacts,
                     "et les nomme sans abimer leurs accents : le fichier est en UTF-8");
            verifier(types >= 35, "et propose au moins trente-cinq blocs");

            // Choisir un bloc donne la ligne qui le pose, et « Inserer »
            // l'ecrit dans l'editeur : c'est la que vit un modele, qui est
            // un programme.
            QTreeWidgetItem* familleSources = biblio->topLevelItem(0);
            verifier(familleSources->childCount() > 0, "la premiere famille a des blocs");
            biblio->setCurrentItem(familleSources->child(0));
            QCoreApplication::processEvents();
            const QString ligne = simulink->ligneInsertion();
            verifier(ligne.startsWith(QLatin1String("m = add_block(m, 'constant'")),
                     "le bloc choisi donne sa ligne ADD_BLOCK");
            verifier(simulink->description()->text().contains(QLatin1String("add_block")),
                     "et la fenetre la montre avant de l'ecrire");

            if (editeur) {
                // L'insertion vise l'editeur courant : on amene celui qu'on
                // observe au premier plan, comme le ferait un clic d'onglet.
                for (QTabWidget* t : fenetre.findChildren<QTabWidget*>())
                    if (t->indexOf(editeur) >= 0) t->setCurrentWidget(editeur);
                QCoreApplication::processEvents();
                editeur->setPlainText(QStringLiteral("m = new_system('depuisRuban');"));
                QMetaObject::invokeMethod(simulink, "insererBloc");
                QCoreApplication::processEvents();
                verifier(editeur->toPlainText().contains(ligne),
                         "« Inserer » ecrit la ligne dans l'editeur");
            }

            // L'espace de travail est partage : un modele cree a la console
            // apparait dans la liste de la fenetre, sans qu'on la rafraichisse.
            envoyer(fenetre, QStringLiteral(
                "modeleDuBureau = add_block(new_system('modeleDuBureau'), "
                "'integrator', 'x');"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "le modele est cree");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         return simulink->listeModeles()->count() > 0;
                     }),
                     "le modele de l'espace de travail apparait dans la fenetre");
            bool nomme = false;
            for (int k = 0; k < simulink->listeModeles()->count(); ++k)
                if (simulink->listeModeles()->item(k)->text() ==
                    QLatin1String("modeleDuBureau"))
                    nomme = true;
            verifier(nomme, "et il y porte son nom");



            // Une variable qui n'est pas un modele n'y entre pas : la liste
            // dit ce qu'elle promet.
            envoyer(fenetre, QStringLiteral("pasUnModele = struct('a', 1);"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "la structure est creee");
            QCoreApplication::processEvents();
            bool intrus = false;
            for (int k = 0; k < simulink->listeModeles()->count(); ++k)
                if (simulink->listeModeles()->item(k)->text() ==
                    QLatin1String("pasUnModele"))
                    intrus = true;
            verifier(!intrus, "une structure quelconque n'est pas prise pour un modele");

            // Le squelette du bouton « Nouveau modele » n'est pas un
            // decor : il tourne.
            const QString squelette = FenetreSimulink::squeletteModele();
            verifier(squelette.contains(QLatin1String("new_system")) &&
                         squelette.contains(QLatin1String("add_line")),
                     "le modele de depart pose des blocs et les cable");
            verifier(!squelette.contains(QLatin1String("open_system")),
                     "et n'appelle pas OPEN_SYSTEM : c'est l'editeur qui dessine");
            QString fichierSquelette =
                QDir::current().absoluteFilePath(QStringLiteral("essaiSquelette.m"));
            {
                QFile f(fichierSquelette);
                if (f.open(QIODevice::WriteOnly | QIODevice::Text))
                    f.write(squelette.toUtf8());
            }
            int avant = console->toPlainText().size();
            envoyer(fenetre, QStringLiteral("run('%1'); disp('SQUELETTE OK')")
                                 .arg(fichierSquelette));
            verifier(attendre([&] { return !fenetre.occupe(); }, 30000),
                     "le modele de depart s'execute");
            QString sortie = console->toPlainText().mid(avant);
            verifier(sortie.contains(QLatin1String("SQUELETTE OK")),
                     "et il va jusqu'au bout, schema et simulation compris");
            QFile::remove(fichierSquelette);

            // La bibliotheque ne propose que des blocs qui existent : chacun
            // est pose puis simule. Sans ce controle, un bloc offert au
            // clic pourrait ne pas etre reconnu par SIM.
            QString essaiTous = QStringLiteral("signal = [0 0; 1 1];\n");
            for (const BlocBibliotheque* b = bibliothequeSimulink(); b->famille; ++b) {
                essaiTous += QStringLiteral("m = new_system('t');\n");
                essaiTous += QStringLiteral("m = add_block(m, '%1', '%1'").arg(
                    QLatin1String(b->type));
                if (*b->parametres) essaiTous += QStringLiteral(", ") +
                                                 QString::fromUtf8(b->parametres);
                essaiTous += QStringLiteral(");\n");
                essaiTous += QStringLiteral("sim(m, 0.02, 0.01);\n");
            }
            essaiTous += QStringLiteral("disp('TOUS LES BLOCS OK')\n");
            QString fichierTous =
                QDir::current().absoluteFilePath(QStringLiteral("essaiBlocs.m"));
            {
                QFile f(fichierTous);
                if (f.open(QIODevice::WriteOnly | QIODevice::Text))
                    f.write(essaiTous.toUtf8());
            }
            avant = console->toPlainText().size();
            envoyer(fenetre, QStringLiteral("run('%1')").arg(fichierTous));
            verifier(attendre([&] { return !fenetre.occupe(); }, 60000),
                     "les blocs de la bibliotheque se posent tous");
            sortie = console->toPlainText().mid(avant);
            verifier(sortie.contains(QLatin1String("TOUS LES BLOCS OK")),
                     "et se simulent tous : la bibliotheque ne propose rien qui n'existe");
            QFile::remove(fichierTous);

            // La toile porte le schema du modele choisi : c'est le fil de
            // calcul qui le trace, et l'editeur qui le peint. C'est la
            // difference avec la fenetre utilitaire d'avant — ici le
            // schema est au centre, et MATLAB reste derriere.
            for (int k = 0; k < simulink->listeModeles()->count(); ++k)
                if (simulink->listeModeles()->item(k)->text() ==
                    QLatin1String("modeleDuBureau"))
                    simulink->listeModeles()->setCurrentRow(k);
            verifier(attendre([&] {
                         return simulink->modeleChoisi() ==
                                QLatin1String("modeleDuBureau");
                     }),
                     "le modele choisi est celui qu'on a designe");
            verifier(attendre([&] {
                         return simulink->modeleAffiche() ==
                                QLatin1String("modeleDuBureau");
                     }, 20000),
                     "et la toile porte son schema");
            verifier(simulink->toile()->modele() == QLatin1String("modeleDuBureau"),
                     "la toile porte bien ce modele");

            // L'explorateur nomme les blocs et les liens du modele.
            auto compter = [&](const QString& rubrique) {
                for (int k = 0; k < simulink->explorateur()->topLevelItemCount(); ++k) {
                    QTreeWidgetItem* item = simulink->explorateur()->topLevelItem(k);
                    if (item->text(0).startsWith(rubrique)) return item->childCount();
                }
                return -1;
            };
            verifier(compter(QStringLiteral("Blocs")) == 1,
                     "l'explorateur compte le bloc du modele");
            verifier(compter(QStringLiteral("Liens")) == 0,
                     "et ses liens, qu'il n'y en ait pas");

            // L'espace de travail est partage jusqu'au bout : un bloc
            // ajoute a la console apparait sur la toile sans qu'on
            // touche a la fenetre.
            envoyer(fenetre, QStringLiteral(
                "modeleDuBureau = add_block(modeleDuBureau, 'gain', 'k', 'Gain', 2); "
                "modeleDuBureau = add_line(modeleDuBureau, 'x', 'k');"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "le modele grandit");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         return compter(QStringLiteral("Blocs")) == 2 &&
                                compter(QStringLiteral("Liens")) == 1;
                     }, 20000),
                     "et le schema le montre : deux blocs, un lien, sans un clic");

            // Un vrai asservissement, avec sa contre-reaction : c'est ce
            // que l'editeur doit savoir montrer, et c'est ce qu'on garde
            // en image.
            envoyer(fenetre, QStringLiteral(
                "K = 4; modeleDuBureau = new_system('modeleDuBureau'); "
                "modeleDuBureau = add_block(modeleDuBureau, 'step', 'consigne', "
                "'Time', 0, 'After', 1); "
                "modeleDuBureau = add_block(modeleDuBureau, 'sum', 'ecart', "
                "'Signs', '+-'); "
                "modeleDuBureau = add_block(modeleDuBureau, 'gain', 'correcteur', "
                "'Gain', 'K'); "
                "modeleDuBureau = add_block(modeleDuBureau, 'integrator', 'sortie'); "
                "modeleDuBureau = add_block(modeleDuBureau, 'scope', 'oscillo'); "
                "modeleDuBureau = add_line(modeleDuBureau, 'consigne', 'ecart', 1); "
                "modeleDuBureau = add_line(modeleDuBureau, 'sortie', 'ecart', 2); "
                "modeleDuBureau = add_line(modeleDuBureau, 'ecart', 'correcteur'); "
                "modeleDuBureau = add_line(modeleDuBureau, 'correcteur', 'sortie'); "
                "modeleDuBureau = add_line(modeleDuBureau, 'sortie', 'oscillo');"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "l'asservissement est bati");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         return compter(QStringLiteral("Blocs")) == 5 &&
                                compter(QStringLiteral("Liens")) == 5;
                     }, 20000),
                     "l'editeur suit : cinq blocs, cinq liens, dont la contre-reaction");

            // --- les gestes sur la toile ---------------------------
            //
            // C'est ce qui separe un editeur d'une image : on prend un
            // bloc, on le deplace, on tire un fil, on efface. Chaque
            // geste devient une commande sur le modele, si bien qu'une
            // modification a la souris se relit au clavier.
            // Ce que la fenetre demande a la console : chaque geste doit
            // s'y retrouver, sans quoi la souris et le clavier ne
            // travailleraient pas sur le meme modele.
            QString commandeVue;
            QObject::connect(simulink, &FenetreSimulink::commandeDemandee,
                             [&commandeVue](const QString& c) { commandeVue = c; });
            ToileSimulink* toile = simulink->toile();
            simulink->resize(1180, 780);
            QCoreApplication::processEvents();
            toile->ajusterVue();
            QCoreApplication::processEvents();

            verifier(ToileSimulink::nombreEntrees(QStringLiteral("sum"),
                                                  QStringLiteral("+-+")) == 3,
                     "une sommation a autant d'entrees que de signes");
            verifier(ToileSimulink::nombreEntrees(QStringLiteral("gain"),
                                                  QString()) == 1,
                     "un gain n'en a qu'une");
            verifier(ToileSimulink::nombreEntrees(QStringLiteral("step"),
                                                  QString()) == 0,
                     "et une source aucune : un fil ne s'y raccroche pas");

            auto viser = [&](const QString& nom) {
                return toile->cadreEcranDe(nom).center();
            };
            auto glisser = [&](QPointF depuis, QPointF vers) {
                QMouseEvent presse(QEvent::MouseButtonPress, depuis,
                                   toile->mapToGlobal(depuis), Qt::LeftButton,
                                   Qt::LeftButton, Qt::NoModifier);
                QCoreApplication::sendEvent(toile, &presse);
                QMouseEvent bouge(QEvent::MouseMove, vers, toile->mapToGlobal(vers),
                                  Qt::NoButton, Qt::LeftButton, Qt::NoModifier);
                QCoreApplication::sendEvent(toile, &bouge);
                QMouseEvent lache(QEvent::MouseButtonRelease, vers,
                                  toile->mapToGlobal(vers), Qt::LeftButton,
                                  Qt::NoButton, Qt::NoModifier);
                QCoreApplication::sendEvent(toile, &lache);
                QCoreApplication::processEvents();
            };

            // Deplacer un bloc : sa place part dans le modele, et le
            // schema revient avec elle.
            const QPointF avantDeplacement = viser(QStringLiteral("correcteur"));
            verifier(!avantDeplacement.isNull(),
                     "la toile sait ou se trouve chaque bloc");
            commandeVue.clear();
            glisser(avantDeplacement, avantDeplacement + QPointF(0, 90));
            verifier(commandeVue.contains(QLatin1String("set_param")) &&
                         commandeVue.contains(QLatin1String("'Position'")),
                     "deplacer un bloc pose sa POSITION dans le modele");
            verifier(commandeVue.startsWith(QLatin1String("matlibre_sl_pile('poser'")),
                     "et l'etat d'avant est mis en reserve, pour Ctrl+Z");
            verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                     "la commande de deplacement passe");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         const QPointF apres = viser(QStringLiteral("correcteur"));
                         return !apres.isNull() && apres.y() > avantDeplacement.y() + 20;
                     }, 20000),
                     "et le bloc reste ou on l'a laisse");

            // Tirer un fil : depuis le bord droit d'un bloc jusqu'a un
            // autre. Le port vise depend de l'endroit ou l'on lache.
            envoyer(fenetre, QStringLiteral(
                "modeleDuBureau = add_block(modeleDuBureau, 'gain', 'ajout', "
                "'Gain', 1, 'Position', [2 4 3.7 5]);"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "un bloc de plus");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         return !toile->cadreEcranDe(QStringLiteral("ajout")).isNull();
                     }, 20000),
                     "il parait sur la toile");
            const QRectF cadreSortie = toile->cadreEcranDe(QStringLiteral("sortie"));
            commandeVue.clear();
            glisser(QPointF(cadreSortie.right() - 2, cadreSortie.center().y()),
                    viser(QStringLiteral("ajout")));
            verifier(commandeVue.contains(QLatin1String("add_line")) &&
                         commandeVue.contains(QLatin1String("'ajout'")),
                     "tirer depuis le bord droit cable les deux blocs");
            verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                     "le cablage passe");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         return compter(QStringLiteral("Liens")) == 6;
                     }, 20000),
                     "et le lien de plus est dans le modele");

            // Un fil ne se raccroche pas a une source : elle n'a pas
            // d'entree, et le dire vaut mieux que poser un lien mort.
            const QRectF cadreAjout = toile->cadreEcranDe(QStringLiteral("ajout"));
            commandeVue.clear();
            glisser(QPointF(cadreAjout.right() - 2, cadreAjout.center().y()),
                    viser(QStringLiteral("consigne")));
            verifier(commandeVue.isEmpty(),
                     "un fil vers une source est refuse, non pose");

            // « Suppr » sur le bloc choisi l'enleve, avec ses liens.
            QMouseEvent choix(QEvent::MouseButtonPress, viser(QStringLiteral("ajout")),
                              toile->mapToGlobal(viser(QStringLiteral("ajout"))),
                              Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(toile, &choix);
            QMouseEvent relache(QEvent::MouseButtonRelease,
                                viser(QStringLiteral("ajout")),
                                toile->mapToGlobal(viser(QStringLiteral("ajout"))),
                                Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
            QCoreApplication::sendEvent(toile, &relache);
            QCoreApplication::processEvents();
            verifier(toile->blocChoisi() == QLatin1String("ajout"),
                     "un clic choisit le bloc");
            commandeVue.clear();
            QKeyEvent suppr(QEvent::KeyPress, Qt::Key_Delete, Qt::NoModifier);
            QCoreApplication::sendEvent(toile, &suppr);
            QCoreApplication::processEvents();
            verifier(commandeVue.contains(QLatin1String("delete_block")),
                     "« Suppr » retire le bloc choisi");
            verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                     "la suppression passe");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         return compter(QStringLiteral("Blocs")) == 5 &&
                                compter(QStringLiteral("Liens")) == 5;
                     }, 20000),
                     "et le modele revient a cinq blocs et cinq liens");

            // --- la boite de reglages -------------------------------
            //
            // Le double-clic ouvre les parametres du bloc, comme dans
            // Simulink. Ce qu'on y ecrit ressort en SET_PARAM ; ce qu'on
            // n'a pas touche n'en sort pas, sans quoi on ecrirait dans le
            // modele des reglages que personne n'a demande de changer.
            {
                DialogueBloc boite(QStringLiteral("correcteur"),
                                   QStringLiteral("gain"),
                                   {QStringLiteral("Gain")}, {QStringLiteral("K")});
                verifier(boite.nomDemande() == QLatin1String("correcteur"),
                         "la boite montre le nom du bloc");
                verifier(boite.champReglage(QStringLiteral("Gain")) != nullptr &&
                             boite.champReglage(QStringLiteral("Gain"))->text() ==
                                 QLatin1String("K"),
                         "et la valeur de son reglage, expression comprise");
                verifier(boite.changements().isEmpty(),
                         "sans rien toucher, rien n'en ressort");
                boite.champReglage(QStringLiteral("Gain"))->setText(QStringLiteral("7"));
                verifier(boite.changements().size() == 1 &&
                             boite.changements()[0].second == QLatin1String("7"),
                         "un champ modifie ressort seul");
                boite.champNom()->setText(QStringLiteral("regulateur"));
                verifier(boite.nomDemande() == QLatin1String("regulateur"),
                         "et le nom demande est celui qu'on a ecrit");
            }

            // Le chemin entier : double-clic, boite, commande. La boite est
            // modale ; un rendez-vous differe la remplit et la valide de
            // l'interieur de sa propre boucle d'evenements.
            commandeVue.clear();
            QStringList commandesVues;
            QMetaObject::Connection lien = QObject::connect(
                simulink, &FenetreSimulink::commandeDemandee,
                [&commandesVues](const QString& c) { commandesVues << c; });
            QTimer::singleShot(0, [&] {
                auto* ouverte = simulink->findChild<DialogueBloc*>(
                    QStringLiteral("dialogueBloc"));
                if (!ouverte) return;
                if (auto* champ = ouverte->champReglage(QStringLiteral("Gain")))
                    champ->setText(QStringLiteral("9"));
                ouverte->champNom()->setText(QStringLiteral("regulateur"));
                ouverte->accept();
            });
            QMetaObject::invokeMethod(simulink, "surBlocOuvert",
                                      Q_ARG(QString, QStringLiteral("correcteur")));
            QCoreApplication::processEvents();
            QObject::disconnect(lien);
            // Une seule commande, et non deux : la console refuse ce qu'on
            // lui envoie pendant qu'elle calcule, si bien que la seconde
            // se perdrait.
            verifier(commandesVues.size() == 1, "une seule commande part");
            if (commandesVues.size() == 1) {
                verifier(commandesVues[0].contains(QLatin1String("'Gain', '9'")),
                         "le reglage change y est");
                verifier(commandesVues[0].contains(QLatin1String("'Name', 'regulateur'")),
                         "le renommage aussi");
                verifier(commandesVues[0].indexOf(QLatin1String("'Gain'")) <
                             commandesVues[0].indexOf(QLatin1String("'Name'")),
                         "et le renommage vient apres, quand l'ancien nom designe "
                         "encore le bloc");
            }
            verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                     "les commandes passent");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         return !toile->cadreEcranDe(QStringLiteral("regulateur"))
                                     .isNull();
                     }, 20000),
                     "le bloc renomme parait sous son nouveau nom");
            envoyer(fenetre, QStringLiteral(
                "modeleDuBureau = set_param(modeleDuBureau, 'regulateur', "
                "'Name', 'correcteur');"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "et on le remet");

            // --- choisir plusieurs blocs, et defaire ----------------
            //
            // Un rectangle trace sur le vide prend ce qu'il touche ; les
            // deplacer les deplace tous, « Suppr » les enleve tous. Et
            // Ctrl+Z rend l'etat d'avant, puisque chaque modification l'a
            // mis en reserve.
            const QRectF cadreConsigne = toile->cadreEcranDe(QStringLiteral("consigne"));
            const QRectF cadreEcart = toile->cadreEcranDe(QStringLiteral("ecart"));
            const QRectF englobant =
                cadreConsigne.united(cadreEcart).adjusted(-12, -12, 12, 12);
            glisser(englobant.topLeft(), englobant.bottomRight());
            verifier(toile->blocsChoisis().size() >= 2,
                     "un rectangle trace sur le vide prend ce qu'il touche");
            const QStringList lot = toile->blocsChoisis();
            verifier(lot.contains(QStringLiteral("consigne")) &&
                         lot.contains(QStringLiteral("ecart")),
                     "et il prend bien ceux qu'on visait");

            commandeVue.clear();
            const QPointF avantLot = toile->cadreEcranDe(QStringLiteral("consigne")).center();
            glisser(avantLot, avantLot + QPointF(0, -60));
            verifier(commandeVue.count(QLatin1String("'Position'")) >= 2,
                     "les deplacer les deplace tous, en une seule commande");
            verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                     "la commande passe");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         const QRectF apres =
                             toile->cadreEcranDe(QStringLiteral("ecart"));
                         return !apres.isNull() &&
                                apres.center().y() < cadreEcart.center().y() - 15;
                     }, 20000),
                     "et les deux ont bouge dans le modele");

            // Ctrl+Z rend l'etat d'avant.
            commandeVue.clear();
            QKeyEvent defaire(QEvent::KeyPress, Qt::Key_Z, Qt::ControlModifier);
            QCoreApplication::sendEvent(toile, &defaire);
            QCoreApplication::processEvents();
            verifier(commandeVue.contains(QLatin1String("matlibre_sl_pile('annuler'")),
                     "Ctrl+Z demande l'etat d'avant");
            verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                     "l'annulation passe");
            verifier(attendre([&] {
                         QCoreApplication::processEvents();
                         const QRectF revenu =
                             toile->cadreEcranDe(QStringLiteral("ecart"));
                         return !revenu.isNull() &&
                                std::abs(revenu.center().y() -
                                         cadreEcart.center().y()) < 6;
                     }, 20000),
                     "et les blocs reviennent ou ils etaient");

            // Ctrl+A prend tout.
            QKeyEvent tout(QEvent::KeyPress, Qt::Key_A, Qt::ControlModifier);
            QCoreApplication::sendEvent(toile, &tout);
            QCoreApplication::processEvents();
            verifier(toile->blocsChoisis().size() == 5, "Ctrl+A prend tous les blocs");
            QKeyEvent echap(QEvent::KeyPress, Qt::Key_Escape, Qt::NoModifier);
            QCoreApplication::sendEvent(toile, &echap);
            QCoreApplication::processEvents();
            verifier(toile->blocsChoisis().isEmpty(), "« Echap » lache tout");

            // Une capture de la fenetre Simulink, pour qu'un humain puisse
            // regarder ce qui a ete construit.
            if (const char* capture = std::getenv("MATLIBRE_CAPTURE")) {
                QString chemin = QString::fromLocal8Bit(capture);
                chemin.replace(QRegularExpression(QStringLiteral("\\.png$")),
                               QStringLiteral("-simulink.png"));
                simulink->resize(1180, 780);
                QCoreApplication::processEvents();
                QImage vue(simulink->size(), QImage::Format_ARGB32);
                vue.fill(Qt::white);
                simulink->render(&vue);
                vue.save(chemin);
                std::printf("  capture de Simulink ecrite dans %s\n",
                            chemin.toLocal8Bit().constData());
            }




            // « Simuler » et « Enregistrer » passent par la console, et le
            // releve reste dans l'espace de travail.
            QMetaObject::invokeMethod(simulink, "simuler");
            QCoreApplication::processEvents();
            verifier(commandeVue.startsWith(
                         QLatin1String("resultatSimulink = sim(modeleDuBureau, 10)")),
                     "« Simuler » lance SIM sur la duree affichee");
            verifier(attendre([&] { return !fenetre.occupe(); }, 30000),
                     "et la simulation aboutit");
            commandeVue.clear();
            QMetaObject::invokeMethod(simulink, "enregistrerModele");
            QCoreApplication::processEvents();
            verifier(commandeVue == QLatin1String("save_system(modeleDuBureau)"),
                     "« Enregistrer » ecrit le .m qui rebatit le modele");
            verifier(attendre([&] { return !fenetre.occupe(); }, 20000),
                     "et l'enregistrement aboutit");
            QFile::remove(QDir::current().absoluteFilePath(
                QStringLiteral("modeleDuBureau.m")));
            envoyer(fenetre, QStringLiteral("clear modeleDuBureau pasUnModele; close all"));
            verifier(attendre([&] { return !fenetre.occupe(); }), "le bureau est rendu net");
            QCoreApplication::processEvents();
            bool subsiste = false;
            for (int k = 0; k < simulink->listeModeles()->count(); ++k)
                if (simulink->listeModeles()->item(k)->text() ==
                    QLatin1String("modeleDuBureau"))
                    subsiste = true;
            verifier(!subsiste,
                     "efface de l'espace de travail, le modele quitte la liste");
        }
    }

    std::printf(echecs == 0 ? "bureau : toutes les verifications passent (%d)\n"
                            : "bureau : %d ECHEC(S) sur %d\n",
                echecs == 0 ? verifications : echecs,
                echecs == 0 ? 0 : verifications);
    return echecs == 0 ? 0 : 1;
}
