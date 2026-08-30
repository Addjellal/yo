// FenetrePrincipale.h — le bureau : menus, panneaux, éditeur, commandes.
#pragma once

#include <functional>

#include <QMainWindow>
#include <QMap>
#include <QSet>
#include <QVector>

#include "Moteur.h"

class QAction;
class QToolButton;
class QListWidget;
class QTreeWidget;
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
class FenetreAide;
class DialogueRecherche;

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
    // Nombre de paquets de sortie recus du fil de calcul. Publie pour
    // qu'un test verifie que la sortie arrive groupee : un signal par
    // ligne noyait le fil graphique.
    int paquetsSortie() const { return paquetsSortie_; }
    void envoyerCommande(const QString& commande) { envoyer(commande); }
    // Relit le dossier courant. Public pour qu'un test puisse deposer des
    // fichiers et verifier ce que le panneau en montre.
    void rafraichirListeFichiers();
    // Ctrl-F : « Rechercher et remplacer » sur ce qui a le regard —
    // l'editeur courant, ou la console. Publiques pour la meme raison.
    void ouvrirRecherche();
    void chercherSuivant();
    // Ouvre un onglet d'editeur vide, comme le bouton « Nouveau script ».
    void ouvrirNouveauScript();

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
    void montrerAide(const QString& nom);
    void aideSurMotCourant();
    void interrompre();
    void surProfil(const QVector<LigneProfil>& entrees, double duree);
    void surSortie(const QString& texte);
    void surEspaceTravail(const QVector<LigneEspaceTravail>& lignes);
    void surFigures(const QVector<FigureCopiee>& figures, int courante);
    void surFermetureFigure(int numero);
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
    FenetreAide* fenetreAide();
    void poserOccupe(bool occupe);

    QThread* filMoteur_;
    Moteur* moteur_;

    Ruban* ruban_ = nullptr;
    QTabWidget* onglets_;
    ConsoleCommandes* console_;
    QTableWidget* tableVariables_;
    // Le panneau « Dossier courant » : un arbre à colonnes, comme celui de
    // MATLAB — nom, taille, type — et une icône par famille de fichier.
    QTreeWidget* listeFichiers_;
    QListWidget* historique_;
    QMap<int, FenetreFigure*> fenetresFigures_;
    // Ce qui est deja peint, pour ne remonter une fenetre que lorsque son
    // trace a change ; et les fermetures faites a la main, en attente que
    // le moteur en prenne acte.
    QMap<int, quint64> empreintesFigures_;
    QSet<int> fermeturesEnAttente_;
    int figureCouranteVue_ = 0;
    FenetreProfileur* profileur_ = nullptr;
    FenetreAide* fenetreAide_ = nullptr;
    // « Rechercher et remplacer » : une seule fenetre, qui suit le regard
    // — l'editeur courant, ou la console.
    DialogueRecherche* recherche_ = nullptr;
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
    // Ce que la tabulation propose dans la console : les noms que le
    // moteur connait, et ceux des variables de l'espace de travail.
    QStringList nomsConnus_;
    QStringList nomsVariables_;
    QStringList completions(const QString& prefixe, bool fichiers) const;
    bool occupe_ = false;
    // « MatLibre est occupé » se dit une fois par calcul, pas a chaque
    // frappe : repeter la phrase noyait la console.
    bool refusOccupeDit_ = false;
    int paquetsSortie_ = 0;
    QAction* aArreter_ = nullptr;
    QToolButton* bArreter_ = nullptr;
};
