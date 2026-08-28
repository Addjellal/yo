// Editeur.h — l'éditeur de scripts : numérotation et coloration MATLAB.
#pragma once

#include <QPlainTextEdit>
#include <QRegularExpression>
#include <QSyntaxHighlighter>
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

protected:
    void resizeEvent(QResizeEvent* evenement) override;

private slots:
    void ajusterMarge();
    void mettreAJourMarge(const QRect& rectangle, int dy);
    void surlignerLigneCourante();

private:
    QWidget* marge_;
    ColorationMatlab* coloration_;
    QString fichier_;
};
