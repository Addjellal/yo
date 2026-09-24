// DialogueBloc.h — les réglages d'un bloc, comme Simulink les demande.
//
// Un double-clic sur un bloc ouvre ses paramètres. C'est le geste de
// Simulink, et c'est ce qui évite d'avoir à retenir quel nom va avec quel
// type : la boîte montre ceux que le bloc porte, avec leur valeur.
//
// Elle ne change rien elle-même. Ce qu'on y écrit ressort en couples
// nom-valeur, que l'éditeur traduit en SET_PARAM sur le modèle — l'espace
// de travail reste le seul état.
//
// Les valeurs sont du texte, et c'est voulu : un paramètre numérique de
// Simulink est une expression, évaluée à la simulation. Écrire « K » y
// est aussi légitime qu'écrire « 4 », et le champ ne doit donc pas
// n'accepter que des chiffres.
#pragma once

#include <QDialog>
#include <QString>
#include <QStringList>
#include <QVector>

class QComboBox;
class QLineEdit;

class DialogueBloc : public QDialog {
    Q_OBJECT
public:
    // CHOIX porte, pour chaque réglage, ses valeurs admises séparées par
    // « | » quand c'est un choix — la boîte montre alors une liste —, ou
    // une chaîne vide pour un réglage libre.
    DialogueBloc(const QString& nomBloc, const QString& type,
                 const QStringList& noms, const QStringList& valeurs,
                 const QStringList& choix = QStringList(), QWidget* parent = nullptr);

    // Le nom demandé, qui peut différer de celui d'origine.
    QString nomDemande() const;
    // Les réglages dont la valeur a changé, en couples nom-valeur.
    QVector<QPair<QString, QString>> changements() const;
    // Publiés pour que la boîte se vérifie sans être montrée.
    QLineEdit* champNom() const { return champNom_; }
    QLineEdit* champReglage(const QString& nom) const;
    QComboBox* listeReglage(const QString& nom) const;

private:
    QString valeurDe(int k) const;

    QString nomOrigine_;
    QStringList noms_;
    QStringList valeursOrigine_;
    QLineEdit* champNom_;
    // Un champ ou une liste par réglage : l'un des deux est nul.
    QVector<QLineEdit*> champs_;
    QVector<QComboBox*> listes_;
};
