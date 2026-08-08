// Fenêtre d'un instrument posé sur le schéma.
//
// Un voltmètre affiche déjà sa mesure sous son symbole, mais en petit et au
// milieu du dessin. Double-cliquer l'appareil ouvre sa propre fenêtre : la
// valeur en grand, ce qu'elle a fait depuis, et de quoi l'envoyer à
// l'oscilloscope. C'est la lecture d'un appareil de paillasse, pas un panneau
// de plus dans l'interface principale.
#pragma once

#include <QString>
#include <QWidget>

#include <deque>
#include <functional>

class QLabel;
class ItemComposant;

class FenetreInstrument : public QWidget {
    Q_OBJECT

public:
    // `toujours_la` dit si le composant existe encore : la fenêtre se ferme
    // toute seule quand on efface l'appareil du schéma.
    // `designation` donne le signal à suivre à l'oscilloscope (nœud d'une
    // borne, ou courant de l'appareil) : seule la scène sait le calculer.
    FenetreInstrument(ItemComposant* composant,
                      std::function<bool(ItemComposant*)> toujours_la,
                      std::function<QString(ItemComposant*)> designation,
                      QWidget* parent = nullptr);

    ItemComposant* composant() const { return composant_; }

signals:
    // L'utilisateur demande à suivre ce point à l'oscilloscope.
    void sonde_demandee(const QString& designation);

private:
    ItemComposant* composant_ = nullptr;
    std::function<bool(ItemComposant*)> toujours_la_;
    std::function<QString(ItemComposant*)> designation_;

    QLabel* valeur_ = nullptr;
    QLabel* extremes_ = nullptr;
    QLabel* description_ = nullptr;

    // Petit historique, pour dire d'où vient la valeur affichée.
    std::deque<double> historique_;
    bool premiere_ = true;
    double mini_ = 0, maxi_ = 0, somme_ = 0;
    int compte_ = 0;
    QString unite_;

    void rafraichir();
};
