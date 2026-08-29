// FenetreProfileur.h — le profileur, dans sa fenêtre, comme MATLAB.
//
// MATLAB montre le profil dans une fenêtre à part : en haut la liste des
// fonctions, triée par temps, avec appels, temps total et temps propre ;
// en bas, quand on choisit une fonction, son code ligne à ligne, avec le
// nombre de passages et les lignes chaudes teintées. C'est ce qu'on fait
// ici, avec les mesures que l'interpréteur prend déjà.
#pragma once

#include <QMainWindow>
#include <QVector>

#include "Moteur.h"

class QLabel;
class QTableWidget;

class FenetreProfileur : public QMainWindow {
    Q_OBJECT
public:
    explicit FenetreProfileur(QWidget* parent = nullptr);

    // Reçoit un relevé et l'affiche. La fenêtre se montre d'elle-même.
    void definirProfil(const QVector<LigneProfil>& entrees, double duree);

    // Publiés pour que le profileur se vérifie sans ouvrir de fenêtre.
    QTableWidget* tableFonctions() const { return fonctions_; }
    QTableWidget* tableLignes() const { return lignes_; }
    QString resume() const;

private slots:
    void montrerLignesDe(int rangee);

private:
    QVector<LigneProfil> entrees_;
    double duree_ = 0.0;
    QLabel* resume_;
    QTableWidget* fonctions_;
    QTableWidget* lignes_;
};
