// Editeur.cpp — coloration et marge de l'éditeur.
#include "Editeur.h"

#include <QFile>
#include <QFontDatabase>
#include <QMouseEvent>
#include <QPainter>
#include <QPolygonF>
#include <QTextBlock>
#include <QKeyEvent>
#include <QRegularExpression>
#include <QTextStream>

#include "Theme.h"

namespace {

// La marge est un widget à part : QPlainTextEdit lui laisse la place par
// setViewportMargins, et lui délègue sa peinture.
class MargeNumeros : public QWidget {
public:
    explicit MargeNumeros(Editeur* editeur) : QWidget(editeur), editeur_(editeur) {
        setCursor(Qt::PointingHandCursor);
        setToolTip(QStringLiteral("Cliquez pour poser ou retirer un point d'arrêt"));
    }
    QSize sizeHint() const override { return QSize(editeur_->largeurMarge(), 0); }

protected:
    void paintEvent(QPaintEvent* evenement) override { editeur_->peindreMarge(evenement); }
    // Cliquer dans la marge pose un point d'arrêt sur la ligne visée :
    // c'est le geste de MATLAB, et de tous les éditeurs de code.
    void mousePressEvent(QMouseEvent* evenement) override {
        editeur_->clicMarge((int)evenement->position().y());
    }

private:
    Editeur* editeur_;
};

}  // namespace

ColorationMatlab::ColorationMatlab(QTextDocument* document) : QSyntaxHighlighter(document) {
    QTextCharFormat motCle;
    motCle.setForeground(theme::motCle());
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

    formatChaine_.setForeground(theme::chaine());
    formatCommentaire_.setForeground(theme::commentaire());
}

void ColorationMatlab::highlightBlock(const QString& texte) {
    // Une section « %% » : MATLAB la met en valeur sur toute la ligne, avec
    // un fond pale, et c'est ce qui rend un script decoupe en cellules
    // lisible d'un coup d'oeil.
    if (texte.trimmed().startsWith(QLatin1String("%%"))) {
        QTextCharFormat section;
        section.setForeground(theme::commentaire());
        section.setFontWeight(QFont::Bold);
        section.setBackground(theme::fondSection());
        setFormat(0, texte.size(), section);
        return;
    }
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
    // Le fond ne suit pas le theme du systeme : l'editeur de MATLAB est
    // blanc, et la coloration est reglee pour du texte sombre sur clair.
    QPalette palette = this->palette();
    palette.setColor(QPalette::Base, theme::fondTexte());
    palette.setColor(QPalette::Text, theme::texte());
    setPalette(palette);
    setFrameStyle(QFrame::NoFrame);
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
    // La place des numéros, plus celle de la pastille du point d'arrêt.
    return 14 + fontMetrics().height() + fontMetrics().horizontalAdvance(QLatin1Char('9')) * chiffres;
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
        s.format.setBackground(theme::ligneCourante());
        s.format.setProperty(QTextFormat::FullWidthSelection, true);
        s.cursor = textCursor();
        s.cursor.clearSelection();
        selections.append(s);
    }
    // La ligne où l'exécution est arrêtée passe devant : un fond vert
    // pâle, celui que MATLAB emploie.
    if (ligneArret_ >= 1 && ligneArret_ <= document()->blockCount()) {
        QTextEdit::ExtraSelection a;
        a.format.setBackground(QColor("#d8f0d8"));
        a.format.setProperty(QTextFormat::FullWidthSelection, true);
        a.cursor = QTextCursor(document()->findBlockByNumber(ligneArret_ - 1));
        a.cursor.clearSelection();
        selections.append(a);
    }
    setExtraSelections(selections);
}

void Editeur::peindreMarge(QPaintEvent* evenement) {
    QPainter peintre(marge_);
    peintre.setRenderHint(QPainter::Antialiasing, true);
    peintre.fillRect(evenement->rect(), theme::fondMarge());
    QTextBlock bloc = firstVisibleBlock();
    int numero = bloc.blockNumber();
    int haut = (int)blockBoundingGeometry(bloc).translated(contentOffset()).top();
    int bas = haut + (int)blockBoundingRect(bloc).height();
    int hauteurLigne = fontMetrics().height();
    int largeurPastille = hauteurLigne;
    while (bloc.isValid() && haut <= evenement->rect().bottom()) {
        if (bloc.isVisible() && bas >= evenement->rect().top()) {
            int ligne = numero + 1;
            // La pastille du point d'arrêt, à gauche du numéro.
            if (pointsArret_.contains(ligne)) {
                peintre.setPen(Qt::NoPen);
                peintre.setBrush(QColor("#c0392b"));
                double d = hauteurLigne * 0.62;
                peintre.drawEllipse(QPointF(2 + largeurPastille / 2.0, haut + hauteurLigne / 2.0),
                                    d / 2, d / 2);
            }
            // La flèche de la ligne où l'exécution est arrêtée.
            if (ligne == ligneArret_) {
                peintre.setPen(Qt::NoPen);
                peintre.setBrush(QColor("#1f8b24"));
                double y = haut + hauteurLigne / 2.0, x = 3.0;
                double h = hauteurLigne * 0.30, l = largeurPastille - 6.0;
                QPolygonF fleche({QPointF(x, y - h), QPointF(x + l * 0.55, y - h),
                                  QPointF(x + l, y), QPointF(x + l * 0.55, y + h),
                                  QPointF(x, y + h)});
                peintre.drawPolygon(fleche);
            }
            peintre.setPen(theme::numeroLigne());
            peintre.drawText(largeurPastille, haut, marge_->width() - largeurPastille - 6,
                             hauteurLigne, Qt::AlignRight, QString::number(ligne));
        }
        bloc = bloc.next();
        haut = bas;
        bas = haut + (int)blockBoundingRect(bloc).height();
        ++numero;
    }
}

void Editeur::clicMarge(int y) {
    // Retrouve la ligne sous le clic.
    QTextBlock bloc = firstVisibleBlock();
    int haut = (int)blockBoundingGeometry(bloc).translated(contentOffset()).top();
    while (bloc.isValid()) {
        int bas = haut + (int)blockBoundingRect(bloc).height();
        if (y >= haut && y < bas) {
            basculerPointArret(bloc.blockNumber() + 1);
            return;
        }
        bloc = bloc.next();
        haut = bas;
    }
}

void Editeur::basculerPointArret(int ligne) {
    if (ligne < 1) return;
    bool pose;
    if (pointsArret_.contains(ligne)) {
        pointsArret_.remove(ligne);
        pose = false;
    } else {
        pointsArret_.insert(ligne);
        pose = true;
    }
    marge_->update();
    emit pointArretBascule(ligne, pose);
}

void Editeur::definirLigneArret(int ligne) {
    ligneArret_ = ligne;
    surlignerLigneCourante();
    marge_->update();
    if (ligne >= 1) {
        // Amener la ligne sous les yeux : un arrêt hors de l'écran ne se
        // verrait pas.
        QTextCursor c(document()->findBlockByNumber(ligne - 1));
        setTextCursor(c);
        centerCursor();
    }
}

QString Editeur::indentationDe(const QString& ligne) const {
    int k = 0;
    while (k < ligne.size() && (ligne[k] == QLatin1Char(' ') || ligne[k] == QLatin1Char('\t')))
        ++k;
    return ligne.left(k);
}

void Editeur::keyPressEvent(QKeyEvent* evenement) {
    if (evenement->key() == Qt::Key_Return || evenement->key() == Qt::Key_Enter) {
        // Indentation automatique, comme MATLAB : la ligne suivante reprend
        // l'indentation de la precedente, et gagne un cran apres un mot-cle
        // qui ouvre un bloc.
        QString ligne = textCursor().block().text();
        QString marge = indentationDe(ligne);
        static const QRegularExpression ouvrant(
            QStringLiteral("^\\s*(if|for|while|switch|try|function|parfor|spmd|"
                           "classdef|properties|methods|events|enumeration|else|"
                           "elseif|case|otherwise|catch)\\b"));
        if (ouvrant.match(ligne).hasMatch()) marge += QStringLiteral("    ");
        QPlainTextEdit::keyPressEvent(evenement);
        insertPlainText(marge);
        return;
    }
    if (evenement->key() == Qt::Key_Tab && textCursor().hasSelection()) {
        // Tab sur une selection indente le bloc, il ne l'efface pas.
        QTextCursor c = textCursor();
        int debut = c.selectionStart(), fin = c.selectionEnd();
        c.setPosition(debut);
        int premier = c.blockNumber();
        c.setPosition(fin);
        int dernier = c.blockNumber();
        c.beginEditBlock();
        for (int b = premier; b <= dernier; ++b) {
            QTextCursor l(document()->findBlockByNumber(b));
            l.insertText(QStringLiteral("    "));
        }
        c.endEditBlock();
        return;
    }
    QPlainTextEdit::keyPressEvent(evenement);
}

void Editeur::commenter() {
    QTextCursor c = textCursor();
    int debut = c.selectionStart(), fin = c.selectionEnd();
    c.setPosition(debut);
    int premier = c.blockNumber();
    c.setPosition(fin);
    int dernier = c.blockNumber();
    c.beginEditBlock();
    for (int b = premier; b <= dernier; ++b) {
        QTextCursor l(document()->findBlockByNumber(b));
        l.insertText(QStringLiteral("% "));
    }
    c.endEditBlock();
}

void Editeur::decommenter() {
    QTextCursor c = textCursor();
    int debut = c.selectionStart(), fin = c.selectionEnd();
    c.setPosition(debut);
    int premier = c.blockNumber();
    c.setPosition(fin);
    int dernier = c.blockNumber();
    c.beginEditBlock();
    for (int b = premier; b <= dernier; ++b) {
        QTextBlock bloc = document()->findBlockByNumber(b);
        QString texte = bloc.text();
        int p = 0;
        while (p < texte.size() && texte[p].isSpace()) ++p;
        if (p >= texte.size() || texte[p] != QLatin1Char('%')) continue;
        int aRetirer = 1;
        if (p + 1 < texte.size() && texte[p + 1] == QLatin1Char(' ')) aRetirer = 2;
        QTextCursor l(bloc);
        l.setPosition(bloc.position() + p);
        l.setPosition(bloc.position() + p + aRetirer, QTextCursor::KeepAnchor);
        l.removeSelectedText();
    }
    c.endEditBlock();
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
