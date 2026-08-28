// Moteur.h — l'interpréteur, dans son propre fil.
//
// Le bureau ne doit jamais se figer pendant un calcul. L'interpréteur vit
// donc dans un fil à lui : la fenêtre lui envoie des commandes, il renvoie
// la sortie au fil de l'eau, puis l'état de l'espace de travail et les
// figures quand la commande est finie.
#pragma once

#include <QObject>
#include <QString>
#include <QVector>
#include <atomic>
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

public slots:
    void demarrer();                      // construit l'interpréteur dans ce fil
    void executer(const QString& texte);  // évalue, puis publie l'état
    void changerDossier(const QString& chemin);
    void reindexer();                     // apres l'ecriture d'un fichier

signals:
    void sortieProduite(const QString& texte);
    void commandeFinie();
    void espaceTravailChange(const QVector<LigneEspaceTravail>& lignes);
    void figuresChangees(const QVector<FigureCopiee>& figures);
    void dossierChange(const QString& chemin);
    void pret();

private:
    void publierEtat();

    std::unique_ptr<matlibre::Interpreteur> it_;
    std::unique_ptr<std::streambuf> tampon_;
    std::unique_ptr<std::ostream> flux_;
    std::atomic<bool> occupe_{false};
};
