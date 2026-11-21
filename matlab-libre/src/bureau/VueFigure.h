// VueFigure.h — une figure peinte à même le widget.
//
// Le dessin est celui du SVG (dessinerFigure, voir Toile.h), peint avec
// QPainter : net à toutes les tailles, redimensionné avec la fenêtre, sans
// autre dépendance que Qt.
#pragma once

#include <QWidget>

#include "Moteur.h"

class VueFigure : public QWidget {
    Q_OBJECT
public:
    explicit VueFigure(QWidget* parent = nullptr);

    void definirFigure(const FigureCopiee& figure);
    int numero() const { return figure_.numero; }

protected:
    void paintEvent(QPaintEvent* evenement) override;

private:
    FigureCopiee figure_;
    bool aFigure_ = false;
};
