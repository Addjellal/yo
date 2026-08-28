// Theme.cpp — pose la palette.
#include "Theme.h"

#include <QApplication>
#include <QPalette>
#include <QStyleFactory>

namespace theme {

void appliquer() {
    // Fusion plutôt que le style natif : c'est le seul qui honore une
    // palette complète sur les trois systèmes. Sans lui, Windows impose
    // ses propres couleurs à une partie des widgets, et la fenêtre sort
    // panachée quand le système est en thème sombre.
    QApplication::setStyle(QStyleFactory::create(QStringLiteral("Fusion")));

    QPalette p;
    p.setColor(QPalette::Window, fond());
    p.setColor(QPalette::WindowText, texte());
    p.setColor(QPalette::Base, fondTexte());
    p.setColor(QPalette::AlternateBase, QColor("#f7f7f7"));
    p.setColor(QPalette::Text, texte());
    p.setColor(QPalette::Button, fond());
    p.setColor(QPalette::ButtonText, texte());
    p.setColor(QPalette::Highlight, selection());
    p.setColor(QPalette::HighlightedText, texte());
    p.setColor(QPalette::ToolTipBase, QColor("#ffffe1"));
    p.setColor(QPalette::ToolTipText, texte());
    p.setColor(QPalette::PlaceholderText, texteEteint());
    p.setColor(QPalette::Disabled, QPalette::Text, texteEteint());
    p.setColor(QPalette::Disabled, QPalette::ButtonText, texteEteint());
    p.setColor(QPalette::Disabled, QPalette::WindowText, texteEteint());
    QApplication::setPalette(p);

    // Les titres de panneau et la barre d'outils : MATLAB les pose sur un
    // gris légèrement plus soutenu que le fond, avec un filet.
    QApplication::instance()->setProperty("matlibreTheme", true);
    qApp->setStyleSheet(QStringLiteral(
        "QMainWindow::separator { background:%1; width:4px; height:4px; }"
        "QDockWidget { titlebar-close-icon:none; titlebar-normal-icon:none; }"
        "QDockWidget::title { background:%2; padding:5px 8px; "
        "  border-bottom:1px solid %1; text-align:left; }"
        "QToolBar { background:%2; border:0; border-bottom:1px solid %1; padding:3px; "
        "  spacing:2px; }"
        "QToolBar QToolButton { padding:4px 10px; border:1px solid transparent; "
        "  border-radius:3px; }"
        "QToolBar QToolButton:hover { background:#dceaff; border:1px solid #a8c8f0; }"
        "QToolBar QToolButton:pressed { background:#c4dbf7; }"
        "QMenuBar { background:%2; border-bottom:1px solid %1; }"
        "QMenuBar::item { padding:5px 10px; }"
        "QMenuBar::item:selected { background:#dceaff; }"
        "QTabBar::tab { background:%2; border:1px solid %1; border-bottom:0; "
        "  padding:5px 12px; margin-right:1px; }"
        "QTabBar::tab:selected { background:%3; }"
        "QTabWidget::pane { border:1px solid %1; background:%3; }"
        "QHeaderView::section { background:%2; border:0; "
        "  border-right:1px solid %1; border-bottom:1px solid %1; padding:4px; }"
        "QStatusBar { background:%2; border-top:1px solid %1; }"
        "QTableWidget, QListWidget { border:0; }")
                            .arg(bordure().name(), titrePanneau().name(),
                                 fondTexte().name()));
}

}  // namespace theme
