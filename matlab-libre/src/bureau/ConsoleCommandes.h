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

signals:
    void commandeValidee(const QString& commande);
    void interruptionDemandee();

protected:
    void keyPressEvent(QKeyEvent* evenement) override;
    void mousePressEvent(QMouseEvent* evenement) override;

private:
    void allerEnFin();
    bool curseurDansZoneModifiable() const;
    void remplacerSaisie(const QString& texte);

    int debutSaisie_ = 0;      // position du premier caractère modifiable
    QString invite_ = QStringLiteral(">> ");
    bool inviteVisible_ = false;
    QStringList historique_;
    int indexHistorique_ = -1;
    QString saisieAvantHistorique_;
};
