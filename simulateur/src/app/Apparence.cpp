#include "app/Apparence.h"

#include <QApplication>
#include <QCoreApplication>
#include <QPalette>
#include <QSettings>
#include <QStyleFactory>

namespace apparence {

const Palette& claire() {
    // Les teintes tirent très légèrement vers le vert, comme la grille du
    // schéma — c'est ce qui fait que le cadre et la feuille appartiennent au
    // même dessin plutôt que de se juxtaposer.
    //
    // L'accent est un BLEU PÉTROLE, et ce choix est contraint : le schéma
    // emploie déjà le rouge et le vert pour les tensions, et le bleu vif pour
    // les références. Un accent rouge ou vert dans le cadre entrerait en
    // concurrence avec une information électrique — l'utilisateur croirait
    // lire un état du circuit là où il n'y a qu'un bouton actif.
    static const Palette p{
        QColor("#f2f5f2"),   // fond
        QColor("#ffffff"),   // surface
        QColor("#fafbfa"),   // surface haute
        QColor("#dde3dd"),   // bordure
        QColor("#1b211d"),   // texte
        QColor("#6c7671"),   // texte doux
        QColor("#1f6f8b"),   // accent
        QColor("#e8f1f5"),   // accent doux
        QColor("#ffffff"),   // texte sur accent
        QColor("#2e7d32"),   // succès
        QColor("#b26a00"),   // alerte
        QColor("#c62828"),   // erreur
    };
    return p;
}

const Palette& sombre() {
    // Le sombre n'est pas le clair inversé : les gris tirent vers le bleu-vert
    // pour rester de la même famille que la feuille, et l'accent s'éclaircit
    // — un bleu pétrole foncé sur fond foncé ne se verrait plus.
    static const Palette p{
        QColor("#1a1f1d"),   // fond
        QColor("#232927"),   // surface
        QColor("#1f2523"),   // surface haute
        QColor("#39413e"),   // bordure
        QColor("#e6ebe8"),   // texte
        QColor("#9aa5a0"),   // texte doux
        QColor("#4aa8c9"),   // accent
        QColor("#2b3a40"),   // accent doux
        QColor("#0f1513"),   // texte sur accent
        QColor("#6ec36e"),   // succès
        QColor("#e0a54a"),   // alerte
        QColor("#ef6b6b"),   // erreur
    };
    return p;
}

QString feuille(const Palette& p) {
    auto c = [](const QColor& couleur) { return couleur.name(); };
    return QString(R"(
/* ---------- fond général et texte ---------- */
QMainWindow, QDialog { background: %FOND%; }
QWidget { color: %TEXTE%; font-size: 10.5pt; }

/* ---------- barres d'outils ---------- */
QToolBar {
    background: %SURFACE_HAUTE%;
    border: 0;
    border-bottom: 1px solid %BORDURE%;
    spacing: 2px;
    padding: 5px 8px;
}
QToolBar::separator {
    background: %BORDURE%;
    width: 1px;
    margin: 4px 8px;
}
QToolButton {
    padding: 5px 10px;
    border-radius: %RAYON%px;
    border: 1px solid transparent;
    color: %TEXTE%;
}
QToolButton:hover { background: %ACCENT_DOUX%; }
QToolButton:pressed { background: %ACCENT_DOUX%; border-color: %BORDURE%; }
QToolButton:checked {
    background: %ACCENT%;
    color: %ACCENT_TEXTE%;
    font-weight: 600;
}
QToolButton:disabled { color: %TEXTE_DOUX%; }
/* DEUX BARRES, DEUX RÔLES, DEUX ASPECTS.
   La barre des PAGES dit où l'on est : sa case active est pleine, comme un
   onglet. La barre des OUTILS dit ce que fait le clic : sa case active est
   seulement cerclée. Les deux étaient identiques, et deux boutons pleins
   côte à côte se disputaient l'attention sans qu'on sache lequel répondait
   à quelle question. */
QToolBar#barre_principale QToolButton:checked {
    background: %ACCENT_DOUX%;
    color: %ACCENT%;
    border-color: %ACCENT%;
    font-weight: 600;
}
QToolButton::menu-indicator { image: none; }

/* ---------- barre de menus ---------- */
QMenuBar {
    background: %SURFACE_HAUTE%;
    border-bottom: 1px solid %BORDURE%;
    padding: 2px 4px;
}
QMenuBar::item { padding: 5px 10px; border-radius: 5px; }
QMenuBar::item:selected { background: %ACCENT_DOUX%; }
QMenu {
    background: %SURFACE%;
    border: 1px solid %BORDURE%;
    padding: 5px;
}
QMenu::item { padding: 6px 26px 6px 22px; border-radius: 5px; }
QMenu::item:selected { background: %ACCENT_DOUX%; }
QMenu::separator { height: 1px; background: %BORDURE%; margin: 5px 8px; }

/* ---------- panneaux ancrés ---------- */
QDockWidget {
    titlebar-close-icon: none;
    titlebar-normal-icon: none;
    font-weight: 600;
}
QDockWidget::title {
    background: %SURFACE_HAUTE%;
    border: 1px solid %BORDURE%;
    border-bottom: 0;
    padding: 7px 10px;
    text-align: left;
}
QMainWindow::separator { background: %FOND%; width: 6px; height: 6px; }
QMainWindow::separator:hover { background: %ACCENT%; }

/* ---------- listes, arbres, tableaux ---------- */
QTreeWidget, QTreeView, QListWidget, QListView, QTableWidget, QTableView,
QPlainTextEdit, QTextEdit {
    background: %SURFACE%;
    border: 1px solid %BORDURE%;
    border-radius: %RAYON%px;
    selection-background-color: %ACCENT%;
    selection-color: %ACCENT_TEXTE%;
}
QTreeWidget::item, QListWidget::item { padding: 3px 2px; border-radius: 4px; }
QTreeWidget::item:hover, QListWidget::item:hover { background: %ACCENT_DOUX%; }
QHeaderView::section {
    background: %SURFACE_HAUTE%;
    border: 0;
    border-bottom: 1px solid %BORDURE%;
    padding: 6px 8px;
    font-weight: 600;
}

/* ---------- onglets ---------- */
QTabWidget::pane {
    border: 1px solid %BORDURE%;
    border-radius: %RAYON%px;
    top: -1px;
}
QTabBar::tab {
    background: transparent;
    color: %TEXTE_DOUX%;
    padding: 7px 14px;
    margin-right: 2px;
    border: 1px solid transparent;
    border-top-left-radius: %RAYON%px;
    border-top-right-radius: %RAYON%px;
}
QTabBar::tab:hover { background: %ACCENT_DOUX%; color: %TEXTE%; }
QTabBar::tab:selected {
    background: %SURFACE%;
    color: %ACCENT%;
    border-color: %BORDURE%;
    border-bottom-color: %SURFACE%;
    font-weight: 600;
}

/* ---------- champs de saisie ---------- */
QLineEdit, QSpinBox, QDoubleSpinBox, QComboBox {
    background: %SURFACE%;
    border: 1px solid %BORDURE%;
    border-radius: %RAYON%px;
    padding: 4px 8px;
    min-height: %HAUTEUR%px;
}
QLineEdit:focus, QSpinBox:focus, QDoubleSpinBox:focus, QComboBox:focus {
    border-color: %ACCENT%;
}
QComboBox::drop-down { border: 0; width: 18px; }
QComboBox QAbstractItemView {
    background: %SURFACE%;
    border: 1px solid %BORDURE%;
    selection-background-color: %ACCENT%;
    selection-color: %ACCENT_TEXTE%;
}

/* ---------- boutons ---------- */
QPushButton {
    background: %SURFACE%;
    border: 1px solid %BORDURE%;
    border-radius: %RAYON%px;
    padding: 6px 14px;
    min-height: %HAUTEUR%px;
}
QPushButton:hover { background: %ACCENT_DOUX%; border-color: %ACCENT%; }
QPushButton:pressed { background: %ACCENT_DOUX%; }
QPushButton:disabled { color: %TEXTE_DOUX%; background: %FOND%; }
/* Le bouton qui compte sur une page se réclame « principal » : il porte
   l'accent, et il est alors le seul. Deux boutons principaux dans une même
   vue, c'est aucun bouton principal. */
QPushButton[principal="true"] {
    background: %ACCENT%;
    color: %ACCENT_TEXTE%;
    border-color: %ACCENT%;
    font-weight: 600;
}
QPushButton[principal="true"]:hover { background: %TEXTE%; border-color: %TEXTE%; }

/* L'îlot posé SUR la feuille : il flotte, donc il porte une ombre portée
   simulée par une bordure plus marquée, et ses boutons sont carrés et petits
   — ils ne doivent pas manger le dessin qu'ils servent à regarder. */
QWidget#ilot_vue {
    background: %SURFACE%;
    border: 1px solid %BORDURE%;
    border-radius: 9px;
}
QPushButton[ilot="true"] {
    min-width: 26px;
    min-height: 24px;
    padding: 2px 8px;
    border: 0;
    background: transparent;
    font-weight: 600;
    color: %TEXTE_DOUX%;
}
QPushButton[ilot="true"]:hover { background: %ACCENT_DOUX%; color: %ACCENT%; }

/* ---------- barres de défilement ---------- */
QScrollBar:vertical, QScrollBar:horizontal {
    background: transparent;
    width: 11px;
    height: 11px;
    margin: 0;
}
QScrollBar::handle:vertical, QScrollBar::handle:horizontal {
    background: #c6cec8;
    border-radius: 5px;
    min-height: 28px;
    min-width: 28px;
}
QScrollBar::handle:hover { background: %TEXTE_DOUX%; }
QScrollBar::add-line, QScrollBar::sub-line { height: 0; width: 0; }
QScrollBar::add-page, QScrollBar::sub-page { background: transparent; }

/* ---------- barre d'état ---------- */
QStatusBar {
    background: %SURFACE_HAUTE%;
    border-top: 1px solid %BORDURE%;
    color: %TEXTE_DOUX%;
}
QStatusBar::item { border: 0; }
QStatusBar QLabel { padding: 0 4px; }

/* ---------- divers ---------- */
QGroupBox {
    border: 1px solid %BORDURE%;
    border-radius: %RAYON%px;
    margin-top: 10px;
    padding-top: 10px;
    font-weight: 600;
}
QGroupBox::title { subcontrol-origin: margin; left: 10px; padding: 0 4px; }
QToolTip {
    background: %TEXTE%;
    color: %SURFACE%;
    border: 0;
    padding: 6px 9px;
    border-radius: 5px;
}
QSplitter::handle { background: %BORDURE%; }
QCheckBox::indicator, QRadioButton::indicator { width: 15px; height: 15px; }
)")
        .replace("%FOND%", c(p.fond))
        .replace("%SURFACE_HAUTE%", c(p.surface_haute))
        .replace("%SURFACE%", c(p.surface))
        .replace("%BORDURE%", c(p.bordure))
        .replace("%TEXTE_DOUX%", c(p.texte_doux))
        .replace("%TEXTE%", c(p.texte))
        .replace("%ACCENT_DOUX%", c(p.accent_doux))
        .replace("%ACCENT_TEXTE%", c(p.accent_texte))
        .replace("%ACCENT%", c(p.accent))
        .replace("%RAYON%", QString::number(kRayon))
        .replace("%HAUTEUR%", QString::number(kHauteurControle - 12));
}

// ---------------------------------------------------------------------------
// Poser le thème sur toute l'application
// ---------------------------------------------------------------------------
static QSettings reglages() {
    return QSettings(QCoreApplication::organizationName(),
                     QCoreApplication::applicationName());
}

Theme theme_enregistre() {
    return reglages().value("apparence/theme").toString() == "sombre"
               ? Theme::Sombre
               : Theme::Clair;
}

void enregistrer_theme(Theme theme) {
    QSettings r = reglages();
    r.setValue("apparence/theme",
               theme == Theme::Sombre ? "sombre" : "clair");
}

void appliquer(Theme theme) {
    const Palette& p = theme == Theme::Sombre ? sombre() : claire();

    // FUSION, ET PAS LE STYLE DU SYSTÈME.
    //
    // Le style natif de Windows dessine ses propres fonds, que la feuille de
    // style ne peut pas toujours reprendre : d'où des cadres clairs autour de
    // widgets sombres, et l'inverse. Fusion dessine tout lui-même, à partir de
    // la palette qu'on lui donne — c'est le seul moyen qu'une application Qt
    // ait exactement la même tête sur les trois systèmes.
    QApplication::setStyle(QStyleFactory::create("Fusion"));

    QPalette palette;
    palette.setColor(QPalette::Window, p.fond);
    palette.setColor(QPalette::WindowText, p.texte);
    palette.setColor(QPalette::Base, p.surface);
    palette.setColor(QPalette::AlternateBase, p.surface_haute);
    palette.setColor(QPalette::Text, p.texte);
    palette.setColor(QPalette::Button, p.surface);
    palette.setColor(QPalette::ButtonText, p.texte);
    palette.setColor(QPalette::Highlight, p.accent);
    palette.setColor(QPalette::HighlightedText, p.accent_texte);
    palette.setColor(QPalette::ToolTipBase, p.texte);
    palette.setColor(QPalette::ToolTipText, p.surface);
    palette.setColor(QPalette::PlaceholderText, p.texte_doux);
    palette.setColor(QPalette::Link, p.accent);
    palette.setColor(QPalette::Disabled, QPalette::Text, p.texte_doux);
    palette.setColor(QPalette::Disabled, QPalette::ButtonText, p.texte_doux);
    palette.setColor(QPalette::Disabled, QPalette::WindowText, p.texte_doux);
    QApplication::setPalette(palette);

    qApp->setStyleSheet(feuille(p));
}

}  // namespace apparence