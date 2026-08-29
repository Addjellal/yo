// Editeur.h — l'éditeur de scripts : numérotation et coloration MATLAB.
#pragma once

#include <QPlainTextEdit>
#include <QRegularExpression>
#include <QSyntaxHighlighter>
#include <QSet>
#include <QVector>

// Coloration du langage MATLAB : mots-clés, chaînes, commentaires,
// nombres, et la transposée qui ressemble à une apostrophe sans en être
// une — c'est le piège de la coloration MATLAB, et il est traité.
class ColorationMatlab : public QSyntaxHighlighter {
    Q_OBJECT
public:
    explicit ColorationMatlab(QTextDocument* document);

protected:
    void highlightBlock(const QString& texte) override;

private:
    struct Regle {
        QRegularExpression motif;
        QTextCharFormat format;
    };
    QVector<Regle> regles_;
    QTextCharFormat formatCommentaire_;
    QTextCharFormat formatChaine_;
};

// Marge de gauche : numéros de ligne et pastilles de point d'arrêt.
class Editeur : public QPlainTextEdit {
    Q_OBJECT
public:
    explicit Editeur(QWidget* parent = nullptr);

    void peindreMarge(QPaintEvent* evenement);
    int largeurMarge() const;

    QString fichier() const { return fichier_; }
    void definirFichier(const QString& chemin) { fichier_ = chemin; }
    bool chargerFichier(const QString& chemin);
    bool enregistrerFichier(const QString& chemin);

    // --- points d'arrêt et ligne d'exécution ----------------------------
    const QSet<int>& pointsArret() const { return pointsArret_; }
    void basculerPointArret(int ligne);
    // Ligne où l'exécution est arrêtée, 0 pour aucune. Elle est surlignée
    // et une flèche la désigne dans la marge, comme sous MATLAB.
    void definirLigneArret(int ligne);
    int ligneArret() const { return ligneArret_; }

    // Commente ou décommente les lignes sélectionnées : Ctrl-R et Ctrl-T,
    // les raccourcis de MATLAB.
    void commenter();
    void decommenter();

    // Appelée par la marge quand on y clique : la ligne visée y bascule.
    void clicMarge(int y);

signals:
    void pointArretBascule(int ligne, bool pose);

protected:
    void resizeEvent(QResizeEvent* evenement) override;
    void keyPressEvent(QKeyEvent* evenement) override;

private slots:
    void ajusterMarge();
    void mettreAJourMarge(const QRect& rectangle, int dy);
    void surlignerLigneCourante();

private:
    QString indentationDe(const QString& ligne) const;

    QWidget* marge_;
    ColorationMatlab* coloration_;
    QString fichier_;
    QSet<int> pointsArret_;      // numéros de ligne, à partir de 1
    int ligneArret_ = 0;
};
