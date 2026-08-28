// FenetreFigure.h — une figure dans sa propre fenêtre, comme MATLAB.
//
// MATLAB n'affiche pas ses figures dans un onglet du bureau : chaque
// « figure » est une fenêtre à part, qu'on déplace, redimensionne, met
// côte à côte et ferme indépendamment. C'est ce qu'on fait ici.
#pragma once

#include <QMainWindow>

#include "Moteur.h"

class VueFigure;

class FenetreFigure : public QMainWindow {
    Q_OBJECT
public:
    explicit FenetreFigure(int numero, QWidget* parent = nullptr);

    void definirFigure(const FigureCopiee& figure);
    int numero() const { return numero_; }
    VueFigure* vue() const { return vue_; }

signals:
    void fermee(int numero);

protected:
    void closeEvent(QCloseEvent* evenement) override;

private slots:
    void enregistrerImage();
    void copierImage();

private:
    int numero_;
    VueFigure* vue_;
};
