// FenetreFigure.cpp — la fenêtre d'une figure et ce qu'on peut en faire.
#include "FenetreFigure.h"

#include <QAction>
#include <QApplication>
#include <QClipboard>
#include <QCloseEvent>
#include <QFileDialog>
#include <QImage>
#include <QMenuBar>
#include <QMessageBox>
#include <QPainter>
#include <QStatusBar>
#include <QToolBar>

#include "Icone.h"
#include "Ruban.h"
#include "Theme.h"
#include "VueFigure.h"

FenetreFigure::FenetreFigure(int numero, QWidget* parent)
    : QMainWindow(parent), numero_(numero) {
    setWindowTitle(QStringLiteral("Figure %1").arg(numero));
    setWindowIcon(iconeApplication());
    setAttribute(Qt::WA_DeleteOnClose, false);
    vue_ = new VueFigure;
    setCentralWidget(vue_);
    resize(700, 520);

    QMenu* fichier = menuBar()->addMenu(QStringLiteral("&Fichier"));
    QAction* aEnregistrer =
        fichier->addAction(iconeDessinee("enregistrer", 16),
                           QStringLiteral("&Enregistrer l'image…"), this,
                           &FenetreFigure::enregistrerImage);
    aEnregistrer->setShortcut(QKeySequence::Save);
    QAction* aCopier = fichier->addAction(QStringLiteral("&Copier l'image"), this,
                                          &FenetreFigure::copierImage);
    aCopier->setShortcut(QKeySequence::Copy);
    fichier->addSeparator();
    QAction* aFermer = fichier->addAction(QStringLiteral("&Fermer"), this, &QWidget::close);
    aFermer->setShortcut(QKeySequence::Close);

    QToolBar* barre = addToolBar(QStringLiteral("Figure"));
    barre->setObjectName(QStringLiteral("barreFigure"));
    barre->setMovable(false);
    barre->setToolButtonStyle(Qt::ToolButtonTextBesideIcon);
    barre->addAction(aEnregistrer);
    barre->addAction(aCopier);
}

void FenetreFigure::definirFigure(const FigureCopiee& figure) {
    vue_->definirFigure(figure);
    if (!figure.figure.nom.empty())
        setWindowTitle(QStringLiteral("Figure %1 — %2")
                           .arg(numero_)
                           .arg(QString::fromStdString(figure.figure.nom)));
}

void FenetreFigure::closeEvent(QCloseEvent* evenement) {
    emit fermee(numero_);
    evenement->accept();
}

void FenetreFigure::enregistrerImage() {
    QString chemin = QFileDialog::getSaveFileName(
        this, QStringLiteral("Enregistrer la figure"),
        QStringLiteral("figure%1.png").arg(numero_),
        QStringLiteral("Image PNG (*.png);;Image JPEG (*.jpg)"));
    if (chemin.isEmpty()) return;
    // On peint sur un fond blanc : une image à fond transparent est
    // illisible dans un document, et ce n'est pas ce que rend MATLAB.
    QImage image(vue_->size() * 2, QImage::Format_ARGB32);
    image.setDevicePixelRatio(2.0);
    image.fill(Qt::white);
    vue_->render(&image);
    if (!image.save(chemin))
        QMessageBox::warning(this, QStringLiteral("MatLibre"),
                             QStringLiteral("Impossible d'écrire « %1 ».").arg(chemin));
    else
        statusBar()->showMessage(QStringLiteral("Enregistré : %1").arg(chemin), 4000);
}

void FenetreFigure::copierImage() {
    QImage image(vue_->size() * 2, QImage::Format_ARGB32);
    image.setDevicePixelRatio(2.0);
    image.fill(Qt::white);
    vue_->render(&image);
    QApplication::clipboard()->setImage(image);
    statusBar()->showMessage(QStringLiteral("Figure copiée dans le presse-papiers"), 4000);
}
