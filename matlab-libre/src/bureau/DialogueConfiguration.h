// DialogueConfiguration.h — les « Paramètres de configuration » d'un modèle.
//
// Simulink règle une simulation dans une boîte à volets, qu'ouvre Ctrl+E :
// le temps de début et de fin, le type de solveur et le solveur lui-même,
// son pas ou ses tolérances, et les diagnostics — que faire d'une boucle
// algébrique, d'une entrée laissée en l'air. C'est cette boîte.
//
// Elle ne change rien elle-même. Ce qu'on y règle ressort en couples
// nom-valeur, que l'éditeur traduit en un seul SET_PARAM sur le modèle :
// les réglages voyagent avec lui, SAVE_SYSTEM les écrit, SIM les applique.
#pragma once

#include <QDialog>
#include <QMap>
#include <QString>
#include <QStringList>
#include <QVector>

class QComboBox;
class QLineEdit;
class QListWidget;
class QStackedWidget;

class DialogueConfiguration : public QDialog {
    Q_OBJECT
public:
    // VALEURS porte la configuration du modèle, réglage par réglage, en
    // texte. FIXES et VARIABLES sont les solveurs disponibles de chaque
    // type.
    DialogueConfiguration(const QString& modele, const QMap<QString, QString>& valeurs,
                          const QStringList& fixes, const QStringList& variables,
                          QWidget* parent = nullptr);

    // Les réglages dont la valeur a changé, dans l'ordre des volets.
    QVector<QPair<QString, QString>> changements() const;

    // Publiés pour que la boîte se vérifie sans être montrée.
    QComboBox* choixType() const { return type_; }
    QComboBox* choixSolveur() const { return solveur_; }
    QLineEdit* champ(const QString& nom) const;
    QComboBox* liste(const QString& nom) const;
    QListWidget* volets() const { return volets_; }

private:
    void typeChange();
    void solveurChange();
    QString valeurDe(const QString& nom) const;

    // Les valeurs affichées à l'ouverture, réglage par réglage.
    QMap<QString, QString> affiches_;
    QStringList fixes_, variables_;
    QListWidget* volets_;
    QStackedWidget* pages_;
    QComboBox* type_;
    QComboBox* solveur_;
    QMap<QString, QLineEdit*> champs_;
    QMap<QString, QComboBox*> listes_;
    // L'ordre dans lequel les changements ressortent : celui des volets.
    QStringList ordre_;
};
