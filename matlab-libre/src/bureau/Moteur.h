// Moteur.h — l'interpréteur, dans son propre fil.
//
// Le bureau ne doit jamais se figer pendant un calcul. L'interpréteur vit
// donc dans un fil à lui : la fenêtre lui envoie des commandes, il renvoie
// la sortie au fil de l'eau, puis l'état de l'espace de travail et les
// figures quand la commande est finie.
#pragma once

#include <QObject>
#include <QPair>
#include <QString>
#include <QVector>
#include <atomic>
#include <condition_variable>
#include <mutex>
#include <memory>

#include "matlibre/Graphique.h"

namespace matlibre {
class Interpreteur;
}

// Une variable telle que l'explorateur d'espace de travail la montre.
struct LigneEspaceTravail {
    QString nom;
    QString taille;
    QString classe;
    QString valeur;
};

// Une entrée du profil, telle que la fenêtre du profileur la montre : la
// même chose que « profile viewer » de MATLAB, plus le détail par ligne.
struct LigneProfil {
    QString nom;
    QString fichier;
    long long appels = 0;
    double total = 0.0;    // secondes, appels imbriqués compris
    double propre = 0.0;   // secondes, hors appels imbriqués
    QVector<QPair<int, long long>> lignes;  // ligne -> passages
};

// Une figure recopiée pour être peinte par le fil graphique : le fil de
// calcul peut continuer sans que la peinture lise une structure qui bouge.
struct FigureCopiee {
    int numero = 1;
    matlibre::Figure figure;
};

class Moteur : public QObject {
    Q_OBJECT

public:
    explicit Moteur(QObject* parent = nullptr);
    ~Moteur() override;

    // Vrai tant qu'une commande est en cours. Lu par le fil graphique.
    bool occupe() const { return occupe_.load(); }
    // Demande l'arrêt de la commande en cours (Ctrl-C).
    void demanderArret();

    // Vrai quand l'exécution est arrêtée sur un point d'arrêt.
    bool arrete() const { return arrete_.load(); }

public slots:
    void demarrer();                      // construit l'interpréteur dans ce fil
    void executer(const QString& texte);  // évalue, puis publie l'état
    // « Exécuter et chronométrer » du ruban de MATLAB : le profileur est
    // allumé le temps de la commande, puis son relevé part vers la fenêtre.
    void executerEtChronometrer(const QString& texte);
    void changerDossier(const QString& chemin);
    void reindexer();                     // apres l'ecriture d'un fichier

    // --- débogueur ------------------------------------------------------
    //
    // Attention au fil : pendant un arrêt, le fil de calcul dort DANS le
    // crochet, sa boucle d'événements ne tourne donc plus. Une connexion
    // en file n'y arriverait jamais — c'est le fil graphique qui appelle
    // « reprendre » et « evaluerALArret » directement. Ces deux-là ne
    // touchent que l'état gardé par « verrouArret_ », ce qui les rend sûrs
    // depuis n'importe quel fil ; les points d'arrêt, eux, passent en file
    // tant que le calcul tourne, et en direct quand il dort.
    void poserPointArret(const QString& fichier, int ligne);
    void retirerPointArret(const QString& fichier, int ligne);
    void retirerTousPointsArret();
    void reprendre(int action);           // ActionDebogueur, en entier
    void evaluerALArret(const QString& texte);
    // Réveille un fil arrêté et lui demande d'abandonner : sans cela, la
    // fenêtre se fermerait sur un fil qui dort, et Qt abandonne le
    // programme (« QThread: Destroyed while thread is still running »).
    void libererPourFermeture();

signals:
    void sortieProduite(const QString& texte);
    void commandeFinie();
    // L'exécution s'est arrêtée : le fichier et la ligne, pour que
    // l'éditeur y amène le regard.
    void arreteSur(const QString& fichier, int ligne);
    void repriseEffectuee();
    void espaceTravailChange(const QVector<LigneEspaceTravail>& lignes);
    void effacementDemande();   // « clc »
    void profilPret(const QVector<LigneProfil>& entrees, double duree);
    void figuresChangees(const QVector<FigureCopiee>& figures);
    void dossierChange(const QString& chemin);
    void pret();

private:
    void publierEtat();

    // Le fil de calcul dort ici pendant un arrêt, et se réveille sur une
    // reprise ou sur une expression à évaluer.
    std::mutex verrouArret_;
    std::condition_variable signalArret_;
    bool repriseDemandee_ = false;
    // L'action demandée voyage sous le verrou, et c'est le fil de calcul
    // qui la pose dans le débogueur : l'interpréteur n'est ainsi jamais
    // touché depuis le fil graphique.
    int actionDemandee_ = 0;
    QString aEvaluer_;
    std::atomic<bool> arrete_{false};
    std::atomic<bool> fermeture_{false};

    std::unique_ptr<matlibre::Interpreteur> it_;
    std::unique_ptr<std::streambuf> tampon_;
    std::unique_ptr<std::ostream> flux_;
    std::atomic<bool> occupe_{false};
};
