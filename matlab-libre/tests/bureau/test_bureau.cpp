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
#include <QMenu>
#include <QPlainTextEdit>
#include <QFontMetrics>
#include <QTabWidget>
#include <QToolButton>
#include <QTableWidget>
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

    // Une capture, pour qu'un humain puisse regarder ce qui a ete construit.
    const char* sortie = std::getenv("MATLIBRE_CAPTURE");
    if (sortie) {
        QImage image(fenetre.size(), QImage::Format_ARGB32);
        image.fill(Qt::white);
        fenetre.render(&image);
        image.save(QString::fromLocal8Bit(sortie));
        std::printf("  capture ecrite dans %s\n", sortie);
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
