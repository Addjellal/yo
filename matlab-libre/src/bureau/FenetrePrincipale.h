// FenetrePrincipale.h — le bureau : menus, panneaux, éditeur, commandes.
#pragma once

#include <functional>

#include <QMainWindow>
#include <QMap>
#include <QVector>

#include "Moteur.h"

class QAction;
class QListWidget;
class QPlainTextEdit;
class QTabWidget;
class QTableWidget;
class QThread;
class QLabel;
class Editeur;
class Ruban;
class ConsoleCommandes;
class VueFigure;
class FenetreFigure;
class FenetreProfileur;

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
    bool enPause() const { return enPause_; }
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
    void executerEtChronometrer();
    void montrerProfileur();
    void surProfil(const QVector<LigneProfil>& entrees, double duree);
    void surSortie(const QString& texte);
    void surEspaceTravail(const QVector<LigneEspaceTravail>& lignes);
    void surFigures(const QVector<FigureCopiee>& figures);
    void surDossier(const QString& chemin);
    void surCommandeFinie();
    void changerDossierParDialogue();
    void ouvrirDepuisListe();
    void effacerCommandes();
    void commenterSelection();
    void tracerSelection(const QString& fonction);
    void surArret(const QString& fichier, int ligne);
    void surReprise();
    void surPointArret(int ligne, bool pose);
    void continuerExecution();
    void pasAPas();
    void entrerDedans();
    void sortirDe();
    void quitterDebogage();
    void retirerTousPointsArret();
    void decommenterSelection();
    void aPropos();

private:
    void construireMenus();
    void construireDebogueur();
    void activerCommandesDebogueur(bool actif);
    void rafraichirPointsArret();
    // Appeler le moteur sans se soucier de l'etat de son fil : en file
    // quand il tourne, en direct quand il dort dans le crochet d'arret.
    void versMoteur(std::function<void()> action);
    Editeur* editeurDuFichier(const QString& fichier);
    void construirePanneaux();
    void ecrire(const QString& texte, const QString& couleur = QString());
    void envoyer(const QString& commande);
    Editeur* editeurCourant() const;
    FenetreProfileur* profileur();
    void rafraichirListeFichiers();

    QThread* filMoteur_;
    Moteur* moteur_;

    Ruban* ruban_ = nullptr;
    QTabWidget* onglets_;
    ConsoleCommandes* console_;
    QTableWidget* tableVariables_;
    QListWidget* listeFichiers_;
    QListWidget* historique_;
    QMap<int, FenetreFigure*> fenetresFigures_;
    FenetreProfileur* profileur_ = nullptr;
    // Les commandes du débogueur : grisées tant que rien n'est arrêté.
    QAction* aContinuer_ = nullptr;
    QAction* aPasAPas_ = nullptr;
    QAction* aEntrer_ = nullptr;
    QAction* aSortir_ = nullptr;
    QAction* aQuitterDebug_ = nullptr;
    QListWidget* listePointsArret_ = nullptr;
    bool enPause_ = false;
    QLabel* etat_;
    QLabel* etiquetteDossier_;
    QString dossierCourant_;
    bool occupe_ = false;
};
