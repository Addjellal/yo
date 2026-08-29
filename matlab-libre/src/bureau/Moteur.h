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
#include <QStringList>
#include <QVector>
#include <atomic>
#include <cstdint>
#include <map>
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

// Une fiche d'aide, découpée en sections : c'est ce que montre le
// navigateur d'aide, et c'est ce que le fil de calcul en sait.
struct FicheAide {
    QString nom;
    QString resume;
    QString description;
    QStringList syntaxe;
    QStringList exemples;
    QStringList voirAussi;
    QString texte;
    QString source;    // « native », « fichier », « script »
    QString fichier;
    bool trouvee = false;
};

// Une entrée de l'index : le nom, son groupe, et sa première ligne d'aide.
struct EntreeIndexAide {
    QString nom;
    QString groupe;
    QString resume;
};

// Une figure recopiée pour être peinte par le fil graphique : le fil de
// calcul peut continuer sans que la peinture lise une structure qui bouge.
//
// L'empreinte résume le contenu. Le fil de calcul ne recopie une figure
// que si son empreinte a changé : sans cela, chaque commande tapée dans
// la console recopiait un tracé d'un million de points — et la fenêtre
// remontait au premier plan alors que rien n'avait bougé.
struct FigureCopiee {
    int numero = 1;
    std::uint64_t empreinte = 0;
    bool contenu = false;   // vrai quand « figure » porte la copie a jour
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

    // La fenêtre a fini d'écrire un paquet de sortie. Sans cet accusé, le
    // fil de calcul produit plus vite que la fenêtre ne consomme : la file
    // d'événements enfle, la fenêtre ne répond plus — Windows propose de
    // tuer le programme — et le Ctrl-C qui l'aurait arrêtée n'est jamais
    // lu, puisqu'il faudrait justement que la fenêtre réponde.
    void accuserSortie();
    // Appelé par le tampon de sortie, dans le fil de calcul, avant chaque
    // envoi : attend que la fenêtre ait rattrapé son retard.
    void attendreLaFenetre();

public slots:
    void demarrer();                      // construit l'interpréteur dans ce fil
    void executer(const QString& texte);  // évalue, puis publie l'état
    // « Exécuter et chronométrer » du ruban de MATLAB : le profileur est
    // allumé le temps de la commande, puis son relevé part vers la fenêtre.
    void executerEtChronometrer(const QString& texte);
    void changerDossier(const QString& chemin);
    void reindexer();                     // apres l'ecriture d'un fichier
    // La fenêtre d'une figure vient d'être fermée à la main : la figure
    // disparaît du moteur, sinon la commande suivante la ferait revenir.
    void fermerFigure(int numero);
    // Le navigateur d'aide demande une fiche, ou l'index complet ; le fil
    // de calcul répond par un signal, sans jamais bloquer la fenêtre.
    void demanderAide(const QString& nom);
    void demanderIndexAide();

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
    void aidePrete(const FicheAide& fiche);
    void indexAidePret(const QVector<EntreeIndexAide>& entrees);
    // « doc nom » tapé dans la console : la fenêtre d'aide s'ouvre.
    void documentationDemandee(const QString& nom);
    void profilPret(const QVector<LigneProfil>& entrees, double duree);
    void figuresChangees(const QVector<FigureCopiee>& figures, int courante);
    void dossierChange(const QString& chemin);
    void pret();

private:
    void publierEtat();
    // Purge complète de la sortie en attente vers le fil graphique.
    void viderSortie();
    // Au plus ce nombre de paquets en vol vers la fenêtre. Huit paquets de
    // seize kilooctets : de quoi peindre sans à-coups, pas de quoi noyer.
    static const int PAQUETS_MAX = 8;
    std::mutex verrouSortie_;
    std::condition_variable signalSortie_;
    int paquetsEnVol_ = 0;

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

    // Ce qui a deja ete envoye au fil graphique, pour ne pas recopier deux
    // fois la meme figure.
    std::map<int, std::uint64_t> empreintesEnvoyees_;

    // Releve a la construction, dans le fil graphique.
    QString cheminExecutable_;

    std::unique_ptr<matlibre::Interpreteur> it_;
    std::unique_ptr<std::streambuf> tampon_;
    // Le meme tampon, dans son type concret : la purge complete n'est pas
    // dans l'interface de std::streambuf.
    std::streambuf* tamponConcret_ = nullptr;
    std::unique_ptr<std::ostream> flux_;
    std::atomic<bool> occupe_{false};
};
