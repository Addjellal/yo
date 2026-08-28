// VueFigure.h — une figure peinte à même le widget.
//
// Le noyau sait rendre une figure en SVG ; ici on peint directement avec
// QPainter à partir du même modèle. C'est net à toutes les tailles, ça se
// redimensionne avec la fenêtre, et ça n'ajoute aucune dépendance.
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
    void peindreAxes(QPainter& peintre, const matlibre::Axes& axes, const QRectF& cadre);

    FigureCopiee figure_;
    bool aFigure_ = false;
};
