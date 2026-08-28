// Editeur.cpp — coloration et marge de l'éditeur.
#include "Editeur.h"

#include <QFile>
#include <QFontDatabase>
#include <QPainter>
#include <QTextBlock>
#include <QTextStream>

namespace {

// La marge est un widget à part : QPlainTextEdit lui laisse la place par
// setViewportMargins, et lui délègue sa peinture.
class MargeNumeros : public QWidget {
public:
    explicit MargeNumeros(Editeur* editeur) : QWidget(editeur), editeur_(editeur) {}
    QSize sizeHint() const override { return QSize(editeur_->largeurMarge(), 0); }

protected:
    void paintEvent(QPaintEvent* evenement) override { editeur_->peindreMarge(evenement); }

private:
    Editeur* editeur_;
};

}  // namespace

ColorationMatlab::ColorationMatlab(QTextDocument* document) : QSyntaxHighlighter(document) {
    QTextCharFormat motCle;
    motCle.setForeground(QColor("#0000ff"));
    motCle.setFontWeight(QFont::Bold);
    const char* mots[] = {"function", "end",     "if",       "elseif",   "else",
                          "for",      "while",   "switch",   "case",     "otherwise",
                          "break",    "continue", "return",  "try",      "catch",
                          "global",   "persistent", "classdef", "properties", "methods",
                          "events",   "enumeration", "parfor", "spmd",   "arguments"};
    for (const char* mot : mots) {
        Regle r;
        r.motif = QRegularExpression(QStringLiteral("\\b%1\\b").arg(QLatin1String(mot)));
        r.format = motCle;
        regles_.push_back(r);
    }

    QTextCharFormat nombre;
    nombre.setForeground(QColor("#7f3fbf"));
    Regle rn;
    rn.motif = QRegularExpression(QStringLiteral("\\b\\d+\\.?\\d*([eE][-+]?\\d+)?[ij]?\\b"));
    rn.format = nombre;
    regles_.push_back(rn);

    formatChaine_.setForeground(QColor("#a020f0"));
    formatCommentaire_.setForeground(QColor("#028002"));
    formatCommentaire_.setFontItalic(true);
}

void ColorationMatlab::highlightBlock(const QString& texte) {
    for (const Regle& r : regles_) {
        auto it = r.motif.globalMatch(texte);
        while (it.hasNext()) {
            auto m = it.next();
            setFormat(m.capturedStart(), m.capturedLength(), r.format);
        }
    }

    // Chaînes et commentaires, en un seul balayage de gauche à droite :
    // c'est le seul moyen de distinguer l'apostrophe de transposition de
    // l'ouverture d'une chaîne. Après un identifiant, une parenthèse
    // fermante, un crochet fermant, un chiffre ou une autre apostrophe,
    // « ' » transpose ; partout ailleurs il ouvre une chaîne.
    int k = 0;
    bool precedentValeur = false;
    while (k < texte.size()) {
        QChar c = texte[k];
        if (c == QLatin1Char('%') || (c == QLatin1Char('.') && k + 1 < texte.size() &&
                                      texte[k + 1] == QLatin1Char('.') &&
                                      k + 2 < texte.size() &&
                                      texte[k + 2] == QLatin1Char('.'))) {
            setFormat(k, texte.size() - k, formatCommentaire_);
            return;
        }
        if (c == QLatin1Char('"')) {
            int debut = k++;
            while (k < texte.size() && texte[k] != QLatin1Char('"')) ++k;
            if (k < texte.size()) ++k;
            setFormat(debut, k - debut, formatChaine_);
            precedentValeur = true;
            continue;
        }
        if (c == QLatin1Char('\'') && !precedentValeur) {
            int debut = k++;
            while (k < texte.size()) {
                if (texte[k] == QLatin1Char('\'')) {
                    // Deux apostrophes de suite : une apostrophe littérale.
                    if (k + 1 < texte.size() && texte[k + 1] == QLatin1Char('\'')) k += 2;
                    else { ++k; break; }
                } else {
                    ++k;
                }
            }
            setFormat(debut, k - debut, formatChaine_);
            precedentValeur = true;
            continue;
        }
        precedentValeur = c.isLetterOrNumber() || c == QLatin1Char('_') ||
                          c == QLatin1Char(')') || c == QLatin1Char(']') ||
                          c == QLatin1Char('}') || c == QLatin1Char('\'');
        ++k;
    }
}

Editeur::Editeur(QWidget* parent) : QPlainTextEdit(parent) {
    QFont police = QFontDatabase::systemFont(QFontDatabase::FixedFont);
    police.setPointSize(11);
    setFont(police);
    setTabStopDistance(4 * QFontMetricsF(police).horizontalAdvance(QLatin1Char(' ')));
    marge_ = new MargeNumeros(this);
    coloration_ = new ColorationMatlab(document());
    connect(this, &Editeur::blockCountChanged, this, &Editeur::ajusterMarge);
    connect(this, &Editeur::updateRequest, this, &Editeur::mettreAJourMarge);
    connect(this, &Editeur::cursorPositionChanged, this, &Editeur::surlignerLigneCourante);
    ajusterMarge();
    surlignerLigneCourante();
}

int Editeur::largeurMarge() const {
    int chiffres = 1;
    int lignes = qMax(1, blockCount());
    while (lignes >= 10) { lignes /= 10; ++chiffres; }
    return 12 + fontMetrics().horizontalAdvance(QLatin1Char('9')) * chiffres;
}

void Editeur::ajusterMarge() { setViewportMargins(largeurMarge(), 0, 0, 0); }

void Editeur::mettreAJourMarge(const QRect& rectangle, int dy) {
    if (dy) marge_->scroll(0, dy);
    else marge_->update(0, rectangle.y(), marge_->width(), rectangle.height());
    if (rectangle.contains(viewport()->rect())) ajusterMarge();
}

void Editeur::resizeEvent(QResizeEvent* evenement) {
    QPlainTextEdit::resizeEvent(evenement);
    QRect cadre = contentsRect();
    marge_->setGeometry(QRect(cadre.left(), cadre.top(), largeurMarge(), cadre.height()));
}

void Editeur::surlignerLigneCourante() {
    QList<QTextEdit::ExtraSelection> selections;
    if (!isReadOnly()) {
        QTextEdit::ExtraSelection s;
        s.format.setBackground(QColor("#f0f0f8"));
        s.format.setProperty(QTextFormat::FullWidthSelection, true);
        s.cursor = textCursor();
        s.cursor.clearSelection();
        selections.append(s);
    }
    setExtraSelections(selections);
}

void Editeur::peindreMarge(QPaintEvent* evenement) {
    QPainter peintre(marge_);
    peintre.fillRect(evenement->rect(), QColor("#f4f4f4"));
    QTextBlock bloc = firstVisibleBlock();
    int numero = bloc.blockNumber();
    int haut = (int)blockBoundingGeometry(bloc).translated(contentOffset()).top();
    int bas = haut + (int)blockBoundingRect(bloc).height();
    while (bloc.isValid() && haut <= evenement->rect().bottom()) {
        if (bloc.isVisible() && bas >= evenement->rect().top()) {
            peintre.setPen(QColor("#909090"));
            peintre.drawText(0, haut, marge_->width() - 6, fontMetrics().height(),
                             Qt::AlignRight, QString::number(numero + 1));
        }
        bloc = bloc.next();
        haut = bas;
        bas = haut + (int)blockBoundingRect(bloc).height();
        ++numero;
    }
}

bool Editeur::chargerFichier(const QString& chemin) {
    QFile f(chemin);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return false;
    QTextStream flux(&f);
    setPlainText(flux.readAll());
    fichier_ = chemin;
    document()->setModified(false);
    return true;
}

bool Editeur::enregistrerFichier(const QString& chemin) {
    QFile f(chemin);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text)) return false;
    QTextStream flux(&f);
    flux << toPlainText();
    fichier_ = chemin;
    document()->setModified(false);
    return true;
}
