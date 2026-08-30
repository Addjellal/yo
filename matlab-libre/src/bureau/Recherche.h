// Recherche.h — « Rechercher et remplacer », la fenêtre de MATLAB.
//
// Ctrl-F ouvre une fenêtre qui ne bloque pas : on cherche, on remplace,
// on continue à taper dans l'éditeur pendant qu'elle est ouverte. Elle
// vise l'éditeur courant, ou la fenêtre de commandes quand c'est elle
// qui a le regard — MATLAB fait de même, le remplacement en moins.
#pragma once

#include <QDialog>
#include <QPointer>

class QCheckBox;
class QLabel;
class QLineEdit;
class QPlainTextEdit;
class QPushButton;

class DialogueRecherche : public QDialog {
    Q_OBJECT
public:
    explicit DialogueRecherche(QWidget* parent = nullptr);

    // Change la zone de texte visée. Le remplacement est retiré quand
    // elle est en lecture seule — on ne réécrit pas la console.
    void viser(QPlainTextEdit* cible);
    QPlainTextEdit* cible() const { return cible_; }

    // Ce que la fenêtre ferait, sans passer par les boutons : les tests
    // s'en servent, et les raccourcis F3 aussi.
    bool chercherSuivant(bool versLeBas = true);
    int remplacerTout();
    bool remplacerCourant();

    void definirRecherche(const QString& texte);
    void definirRemplacement(const QString& texte);

private:
    void poserEtat(const QString& texte);

    QPointer<QPlainTextEdit> cible_;
    QLineEdit* chercher_;
    QLineEdit* remplacer_;
    QCheckBox* casse_;
    QCheckBox* motEntier_;
    QCheckBox* boucler_;
    QLabel* etat_;
    QPushButton* bRemplacer_;
    QPushButton* bRemplacerTout_;
};
