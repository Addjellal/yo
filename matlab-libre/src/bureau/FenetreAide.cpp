// FenetreAide.cpp — la page de documentation, mise en forme.
#include "FenetreAide.h"

#include <QAction>
#include <QDesktopServices>
#include <QFontDatabase>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QListWidget>
#include <QSplitter>
#include <QTextBrowser>
#include <QScrollBar>
#include <QStatusBar>
#include <QToolBar>
#include <QSignalBlocker>
#include <QUrl>
#include <QVBoxLayout>
#include <QWidget>

#include "Icone.h"
#include "Ruban.h"
#include "Theme.h"

namespace {

QString echapper(const QString& texte) {
    QString s = texte;
    s.replace(QLatin1Char('&'), QStringLiteral("&amp;"));
    s.replace(QLatin1Char('<'), QStringLiteral("&lt;"));
    s.replace(QLatin1Char('>'), QStringLiteral("&gt;"));
    return s;
}

// Un bloc de code : chasse fixe, fond léger, comme les exemples de MATLAB.
QString blocCode(const QStringList& lignes) {
    if (lignes.isEmpty()) return QString();
    QString corps;
    for (const QString& l : lignes) corps += echapper(l) + QStringLiteral("\n");
    return QStringLiteral(
               "<pre style='background:#f5f5f5;border:1px solid #e0e0e0;"
               "padding:8px;margin:4px 0 12px 0;'>%1</pre>")
        .arg(corps);
}

QString titreSection(const QString& texte) {
    return QStringLiteral("<h2 style='font-size:13pt;margin:18px 0 4px 0;"
                          "border-bottom:1px solid #e0e0e0;'>%1</h2>")
        .arg(echapper(texte));
}

}  // namespace

FenetreAide::FenetreAide(QWidget* parent) : QMainWindow(parent) {
    setWindowTitle(QStringLiteral("Aide MatLibre"));
    setWindowIcon(iconeDessinee(QStringLiteral("aide"), 32));
    resize(1000, 700);

    auto* barre = addToolBar(QStringLiteral("Navigation"));
    barre->setMovable(false);
    aReculer_ = barre->addAction(QStringLiteral("◀  Précédent"), this, &FenetreAide::reculer);
    aAvancer_ = barre->addAction(QStringLiteral("Suivant  ▶"), this, &FenetreAide::avancer);
    aReculer_->setEnabled(false);
    aAvancer_->setEnabled(false);
    barre->addSeparator();
    barre->addAction(iconeDessinee(QStringLiteral("aide"), 16),
                     QStringLiteral("Accueil"), this, [this] { naviguerVers(QString(), true); });

    auto* central = new QWidget;
    auto* horizontal = new QHBoxLayout(central);
    horizontal->setContentsMargins(0, 0, 0, 0);
    auto* separateur = new QSplitter(Qt::Horizontal);

    auto* gauche = new QWidget;
    auto* colonne = new QVBoxLayout(gauche);
    colonne->setContentsMargins(6, 6, 6, 6);
    colonne->setSpacing(4);
    recherche_ = new QLineEdit;
    recherche_->setPlaceholderText(QStringLiteral("Rechercher une fonction…"));
    recherche_->setClearButtonEnabled(true);
    colonne->addWidget(recherche_);
    liste_ = new QListWidget;
    liste_->setAlternatingRowColors(true);
    colonne->addWidget(liste_, 1);
    separateur->addWidget(gauche);

    page_ = new QTextBrowser;
    page_->setOpenExternalLinks(false);
    page_->setOpenLinks(false);
    separateur->addWidget(page_);
    separateur->setStretchFactor(0, 1);
    separateur->setStretchFactor(1, 3);
    horizontal->addWidget(separateur);
    setCentralWidget(central);

    etat_ = new QLabel;
    statusBar()->addWidget(etat_);

    connect(recherche_, &QLineEdit::textChanged, this, &FenetreAide::filtrer);
    connect(recherche_, &QLineEdit::returnPressed, this, [this] {
        // Entrée ouvre la première fonction de la liste filtrée.
        if (liste_->count() > 0) {
            liste_->setCurrentRow(0);
            ouvrirDepuisListe();
        }
    });
    connect(liste_, &QListWidget::itemActivated, this, &FenetreAide::ouvrirDepuisListe);
    connect(liste_, &QListWidget::currentRowChanged, this, [this](int) { ouvrirDepuisListe(); });
    // Les renvois « Voir aussi » sont des liens : on navigue au clic.
    connect(page_, &QTextBrowser::anchorClicked, this, [this](const QUrl& url) {
        if (url.scheme() == QLatin1String("aide")) naviguerVers(url.path(), true);
        else QDesktopServices::openUrl(url);
    });

    poserPageAccueil();
}

void FenetreAide::poserPageAccueil() {
    nomCourant_.clear();
    page_->setHtml(QStringLiteral(
        "<div style='font-family:sans-serif;padding:14px;'>"
        "<h1 style='font-size:18pt;'>Aide MatLibre</h1>"
        "<p>Choisissez une fonction dans la liste, ou tapez son nom dans la "
        "case de recherche.</p>"
        "<p>Depuis la fenêtre de commandes :</p>"
        "<ul>"
        "<li><code>help nom</code> — l'aide, dans la console ;</li>"
        "<li><code>doc nom</code> — la page complète, ici ;</li>"
        "<li><code>lookfor motif</code> — chercher dans les résumés.</li>"
        "</ul>"
        "<p>L'aide de vos propres fonctions vient du bloc de commentaires "
        "placé sous la ligne <code>function</code>, comme sous MATLAB.</p>"
        "</div>"));
    etat_->setText(QStringLiteral("%1 fonctions").arg(index_.size()));
}

void FenetreAide::poserIndex(const QVector<EntreeIndexAide>& entrees) {
    index_ = entrees;
    filtrer(recherche_->text());
    if (nomCourant_.isEmpty()) poserPageAccueil();
}

void FenetreAide::filtrer(const QString& motif) {
    QString m = motif.trimmed().toLower();
    const QSignalBlocker garde(liste_);
    liste_->clear();
    for (const EntreeIndexAide& e : index_) {
        if (!m.isEmpty() && !e.nom.toLower().contains(m) &&
            !e.resume.toLower().contains(m))
            continue;
        auto* element = new QListWidgetItem(e.nom);
        element->setToolTip(e.resume);
        element->setData(Qt::UserRole, e.nom);
        liste_->addItem(element);
    }
    etat_->setText(QStringLiteral("%1 fonction(s) sur %2")
                       .arg(liste_->count())
                       .arg(index_.size()));
}

void FenetreAide::ouvrirDepuisListe() {
    QListWidgetItem* element = liste_->currentItem();
    if (!element) return;
    naviguerVers(element->data(Qt::UserRole).toString(), true);
}

void FenetreAide::afficher(const QString& nom) {
    if (nom.trimmed().isEmpty()) {
        poserPageAccueil();
        return;
    }
    naviguerVers(nom.trimmed(), true);
}

void FenetreAide::naviguerVers(const QString& nom, bool empiler) {
    if (empiler) {
        // On coupe ce qui suit : naviguer depuis le milieu de l'historique
        // repart de là, comme dans un navigateur.
        while (historique_.size() > positionHistorique_ + 1) historique_.removeLast();
        historique_.append(nom);
        positionHistorique_ = historique_.size() - 1;
    }
    aReculer_->setEnabled(positionHistorique_ > 0);
    aAvancer_->setEnabled(positionHistorique_ + 1 < historique_.size());
    if (nom.isEmpty()) {
        poserPageAccueil();
        return;
    }
    nomCourant_ = nom;
    emit pageDemandee(nom);
}

void FenetreAide::reculer() {
    if (positionHistorique_ <= 0) return;
    --positionHistorique_;
    naviguerVers(historique_[positionHistorique_], false);
}

void FenetreAide::avancer() {
    if (positionHistorique_ + 1 >= historique_.size()) return;
    ++positionHistorique_;
    naviguerVers(historique_[positionHistorique_], false);
}

void FenetreAide::poserFiche(const FicheAide& fiche) {
    if (!fiche.trouvee) {
        page_->setHtml(QStringLiteral(
                           "<div style='font-family:sans-serif;padding:14px;'>"
                           "<h1 style='font-size:18pt;'>%1</h1>"
                           "<p>Aucune documentation pour ce nom.</p>"
                           "<p>Vérifiez l'orthographe, ou cherchez avec "
                           "<code>lookfor</code>.</p></div>")
                           .arg(echapper(fiche.nom)));
        etat_->setText(QStringLiteral("« %1 » : introuvable").arg(fiche.nom));
        return;
    }

    QString html;
    html += QStringLiteral("<div style='font-family:sans-serif;padding:14px;'>");
    html += QStringLiteral("<h1 style='font-size:20pt;margin-bottom:2px;'>%1</h1>")
                .arg(echapper(fiche.nom));
    if (!fiche.resume.isEmpty())
        html += QStringLiteral("<p style='font-size:12pt;color:#444;margin-top:0;'>%1</p>")
                    .arg(echapper(fiche.resume));

    if (!fiche.description.isEmpty()) {
        html += titreSection(QStringLiteral("Description"));
        // Les paragraphes sont séparés par une ligne vide ; à l'intérieur,
        // on garde les retours à la ligne de l'auteur.
        const QStringList paragraphes =
            fiche.description.split(QStringLiteral("\n\n"), Qt::SkipEmptyParts);
        for (const QString& p : paragraphes)
            html += QStringLiteral("<p style='margin:6px 0;'>%1</p>")
                        .arg(echapper(p).replace(QStringLiteral("\n"), QStringLiteral("<br>")));
    }
    if (!fiche.syntaxe.isEmpty()) {
        html += titreSection(QStringLiteral("Syntaxe"));
        html += blocCode(fiche.syntaxe);
    }
    if (!fiche.exemples.isEmpty()) {
        html += titreSection(QStringLiteral("Exemples"));
        html += blocCode(fiche.exemples);
    }
    if (!fiche.voirAussi.isEmpty()) {
        html += titreSection(QStringLiteral("Voir aussi"));
        QStringList liens;
        for (const QString& v : fiche.voirAussi)
            liens << QStringLiteral("<a href='aide:%1'>%1</a>").arg(echapper(v));
        html += QStringLiteral("<p>%1</p>").arg(liens.join(QStringLiteral(" &middot; ")));
    }

    html += QStringLiteral("<hr style='border:none;border-top:1px solid #e0e0e0;margin:18px 0;'>");
    if (fiche.source == QLatin1String("native"))
        html += QStringLiteral("<p style='color:#666;'>Fonction native de MatLibre.</p>");
    else if (!fiche.fichier.isEmpty())
        html += QStringLiteral("<p style='color:#666;'>Définie dans <code>%1</code></p>")
                    .arg(echapper(fiche.fichier));
    html += QStringLiteral("</div>");
    page_->setHtml(html);
    page_->verticalScrollBar()->setValue(0);
    etat_->setText(fiche.nom);
}
