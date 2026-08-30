// ConsoleCommandes.h — la fenêtre de commandes de MATLAB.
//
// Le point important : on tape LÀ OÙ EST L'INVITE, dans le texte, pas
// dans une ligne de saisie posée en dessous. C'est ce qui distingue une
// fenêtre de commandes d'un terminal bricolé, et c'est ce que fait
// MATLAB. La zone avant l'invite n'est pas modifiable ; les flèches haut
// et bas rappellent l'historique ; Ctrl-C recopie ou interrompt.
#pragma once

#include <QPlainTextEdit>
#include <QStringList>

#include <functional>

class QListWidget;

class ConsoleCommandes : public QPlainTextEdit {
    Q_OBJECT
public:
    explicit ConsoleCommandes(QWidget* parent = nullptr);

    // Écrit de la sortie au-dessus de l'invite, puis réaffiche l'invite et
    // ce que l'utilisateur avait commencé à taper.
    void ecrireSortie(const QString& texte, const QColor& couleur);
    // Repose l'invite « >> » et rend la main à l'utilisateur.
    void poserInvite(const QString& invite = QStringLiteral(">> "));
    void masquerInvite();
    void effacer();

    QString commandeEnCours() const;
    const QStringList& historique() const { return historique_; }

    // Ce que la tabulation propose. Le fournisseur rend les completions
    // possibles du prefixe — chacune remplacera le prefixe entier.
    // « fichiers » dit dans quel monde on cherche : entre guillemets, ce
    // sont des noms de fichiers et de dossiers ; ailleurs, des noms de
    // fonctions et de variables. C'est la distinction que fait MATLAB.
    void definirCompletions(
        std::function<QStringList(const QString& prefixe, bool fichiers)> fournisseur);

    // Les completions du texte donne, curseur en « position ». Rendue
    // publique pour que les tests puissent l'interroger sans clavier.
    QStringList completionsDe(const QString& ligne, int position, QString* prefixe,
                              bool* fichiers) const;

signals:
    void commandeValidee(const QString& commande);
    void interruptionDemandee();

protected:
    void keyPressEvent(QKeyEvent* evenement) override;
    void mousePressEvent(QMouseEvent* evenement) override;
    bool eventFilter(QObject* objet, QEvent* evenement) override;

private:
    void allerEnFin();
    bool curseurDansZoneModifiable() const;
    void remplacerSaisie(const QString& texte);

    // --- completion ---
    void completer();
    void montrerChoix(const QStringList& choix);
    void fermerChoix();
    void appliquerChoix(const QString& choix);

    std::function<QStringList(const QString&, bool)> fournisseurCompletions_;
    QListWidget* choix_ = nullptr;
    int debutPrefixe_ = 0;     // position, dans le document, du prefixe complete

    int debutSaisie_ = 0;      // position du premier caractère modifiable
    QString invite_ = QStringLiteral(">> ");
    bool inviteVisible_ = false;
    QStringList historique_;
    int indexHistorique_ = -1;
    QString saisieAvantHistorique_;
};
