// FenetrePrincipale.h — le bureau : menus, panneaux, éditeur, commandes.
#pragma once

#include <QMainWindow>
#include <QVector>

#include "Moteur.h"

class QAction;
class QLineEdit;
class QListWidget;
class QPlainTextEdit;
class QTabWidget;
class QTableWidget;
class QThread;
class QLabel;
class Editeur;
class VueFigure;

class FenetrePrincipale : public QMainWindow {
    Q_OBJECT
public:
    FenetrePrincipale();
    ~FenetrePrincipale() override;

    // Ouvre un fichier dans un onglet de l'éditeur ; le rend au premier plan.
    void ouvrirFichier(const QString& chemin);

    // Vrai tant qu'une commande tourne. Publié pour que le bureau se pilote
    // depuis un test, sans ouvrir de fenêtre.
    bool occupe() const { return occupe_; }
    void envoyerCommande(const QString& commande) { envoyer(commande); }

protected:
    void closeEvent(QCloseEvent* evenement) override;

private slots:
    void nouveauFichier();
    void ouvrirParDialogue();
    void enregistrer();
    void enregistrerSous();
    void executerScript();
    void executerSelection();
    void validerCommande();
    void surSortie(const QString& texte);
    void surEspaceTravail(const QVector<LigneEspaceTravail>& lignes);
    void surFigures(const QVector<FigureCopiee>& figures);
    void surDossier(const QString& chemin);
    void surCommandeFinie();
    void changerDossierParDialogue();
    void ouvrirDepuisListe();
    void effacerCommandes();
    void aPropos();

private:
    void construireMenus();
    void construirePanneaux();
    void ecrire(const QString& texte, const QString& couleur = QString());
    void envoyer(const QString& commande);
    Editeur* editeurCourant() const;
    void rafraichirListeFichiers();

    QThread* filMoteur_;
    Moteur* moteur_;

    QTabWidget* onglets_;
    QPlainTextEdit* console_;
    QLineEdit* saisie_;
    QTableWidget* tableVariables_;
    QListWidget* listeFichiers_;
    QListWidget* historique_;
    QTabWidget* ongletsFigures_;
    QLabel* etat_;
    QString dossierCourant_;
    QVector<QString> commandesPassees_;
    int indexHistorique_ = -1;
    bool occupe_ = false;
};
