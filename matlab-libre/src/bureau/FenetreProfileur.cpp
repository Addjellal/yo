// FenetreProfileur.cpp — la liste des fonctions, et le code ligne à ligne.
#include "FenetreProfileur.h"

#include <QFile>
#include <QFontDatabase>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QLabel>
#include <QPainter>
#include <QSplitter>
#include <QStyledItemDelegate>
#include <QTableWidget>
#include <QTextStream>
#include <QVBoxLayout>
#include <QWidget>
#include <algorithm>

#include "Icone.h"
#include "Ruban.h"
#include "Theme.h"

namespace {

QString secondes(double t) {
    if (t < 1e-3) return QStringLiteral("%1 µs").arg(t * 1e6, 0, 'f', 1);
    if (t < 1.0) return QStringLiteral("%1 ms").arg(t * 1e3, 0, 'f', 2);
    return QStringLiteral("%1 s").arg(t, 0, 'f', 3);
}

// La barre que MATLAB dessine dans sa colonne « Total Time Plot » : une
// proportion se lit d'un coup d'oeil, un nombre demande une comparaison.
// Elle est peinte, et non ecrite en caracteres pleins : une ligne
// selectionnee garde ainsi sa couleur.
class DelegueBarre : public QStyledItemDelegate {
public:
    using QStyledItemDelegate::QStyledItemDelegate;

    void paint(QPainter* peintre, const QStyleOptionViewItem& option,
               const QModelIndex& index) const override {
        QStyleOptionViewItem fond = option;
        initStyleOption(&fond, index);
        fond.text.clear();
        QStyledItemDelegate::paint(peintre, fond, index);

        double part = index.data(Qt::UserRole).toDouble();
        part = std::max(0.0, std::min(1.0, part));
        QRectF place = option.rect.adjusted(6, 5, -6, -5);
        peintre->save();
        peintre->setRenderHint(QPainter::Antialiasing, true);
        peintre->setPen(Qt::NoPen);
        peintre->setBrush(QColor("#e0e0e0"));
        peintre->drawRoundedRect(place, 2, 2);
        QRectF pleine = place;
        pleine.setWidth(place.width() * part);
        peintre->setBrush(QColor("#0072bd"));
        peintre->drawRoundedRect(pleine, 2, 2);
        peintre->restore();
    }
};

// Un element qui se trie sur le nombre, pas sur son ecriture : « 7.67 ms »
// et « 227.0 µs » ne se comparent pas lettre a lettre.
class ElementNombre : public QTableWidgetItem {
public:
    ElementNombre(const QString& texte, double valeur) : QTableWidgetItem(texte) {
        setData(Qt::UserRole, valeur);
    }
    bool operator<(const QTableWidgetItem& autre) const override {
        return data(Qt::UserRole).toDouble() < autre.data(Qt::UserRole).toDouble();
    }
};

QTableWidget* tableau(const QStringList& colonnes) {
    auto* t = new QTableWidget;
    t->setColumnCount(colonnes.size());
    t->setHorizontalHeaderLabels(colonnes);
    t->verticalHeader()->setVisible(false);
    t->setSelectionBehavior(QAbstractItemView::SelectRows);
    t->setSelectionMode(QAbstractItemView::SingleSelection);
    t->setEditTriggers(QAbstractItemView::NoEditTriggers);
    t->setAlternatingRowColors(true);
    t->horizontalHeader()->setStretchLastSection(true);
    return t;
}

}  // namespace

FenetreProfileur::FenetreProfileur(QWidget* parent) : QMainWindow(parent) {
    setWindowTitle(QStringLiteral("Profileur"));
    setWindowIcon(iconeDessinee(QStringLiteral("chronometre"), 32));
    resize(880, 620);

    auto* central = new QWidget;
    auto* vertical = new QVBoxLayout(central);
    vertical->setContentsMargins(8, 8, 8, 8);
    vertical->setSpacing(6);

    resume_ = new QLabel;
    resume_->setTextInteractionFlags(Qt::TextSelectableByMouse);
    QFont gras = resume_->font();
    gras.setBold(true);
    resume_->setFont(gras);
    vertical->addWidget(resume_);

    auto* separateur = new QSplitter(Qt::Vertical);
    fonctions_ = tableau({QStringLiteral("Fonction"), QStringLiteral("Appels"),
                          QStringLiteral("Temps total"), QStringLiteral("Temps propre"),
                          QStringLiteral("Part du total")});
    fonctions_->setItemDelegateForColumn(4, new DelegueBarre(fonctions_));
    // Les colonnes se trient au clic, comme celles du profileur de MATLAB.
    fonctions_->setSortingEnabled(true);
    fonctions_->horizontalHeader()->setSortIndicator(2, Qt::DescendingOrder);
    lignes_ = tableau({QStringLiteral("Ligne"), QStringLiteral("Passages"),
                       QStringLiteral("Code")});
    // Le code se lit en chasse fixe, comme dans l'éditeur.
    lignes_->setFont(QFontDatabase::systemFont(QFontDatabase::FixedFont));
    separateur->addWidget(fonctions_);
    separateur->addWidget(lignes_);
    separateur->setStretchFactor(0, 3);
    separateur->setStretchFactor(1, 4);
    vertical->addWidget(separateur, 1);
    setCentralWidget(central);

    connect(fonctions_, &QTableWidget::currentCellChanged, this,
            [this](int rangee, int, int, int) { montrerLignesDe(rangee); });
}

QString FenetreProfileur::resume() const { return resume_->text(); }

void FenetreProfileur::definirProfil(const QVector<LigneProfil>& entrees, double duree) {
    entrees_ = entrees;
    duree_ = duree;
    resume_->setText(
        QStringLiteral("Profil : %1 fonction(s) mesurée(s), %2 au total")
            .arg(entrees.size())
            .arg(secondes(duree)));

    double maximum = 0.0;
    for (const auto& e : entrees) maximum = std::max(maximum, e.total);
    if (maximum <= 0.0) maximum = 1.0;

    // Le tri est suspendu pendant le remplissage : sinon chaque ligne
    // posee deplacerait les precedentes.
    fonctions_->setSortingEnabled(false);
    fonctions_->setRowCount(entrees.size());
    for (int k = 0; k < entrees.size(); ++k) {
        const LigneProfil& e = entrees[k];
        auto* nom = new QTableWidgetItem(e.nom);
        // La rangee retient l'indice de son entree : le tri la deplace,
        // mais le detail par ligne doit suivre la bonne fonction.
        nom->setData(Qt::UserRole + 1, k);
        fonctions_->setItem(k, 0, nom);
        fonctions_->setItem(k, 1,
                            new ElementNombre(QString::number(e.appels), (double)e.appels));
        fonctions_->setItem(k, 2, new ElementNombre(secondes(e.total), e.total));
        fonctions_->setItem(k, 3, new ElementNombre(secondes(e.propre), e.propre));
        auto* trait = new ElementNombre(QString(), e.total);
        trait->setData(Qt::UserRole, e.total / maximum);
        fonctions_->setItem(k, 4, trait);
    }
    fonctions_->setSortingEnabled(true);
    fonctions_->sortItems(2, Qt::DescendingOrder);
    // « sortItems » ne touche pas la fleche de l'en-tete : sans cela elle
    // montrerait un tri croissant sur une liste decroissante.
    fonctions_->horizontalHeader()->setSortIndicator(2, Qt::DescendingOrder);
    for (int c = 0; c < 4; ++c) fonctions_->resizeColumnToContents(c);
    lignes_->setRowCount(0);
    if (!entrees.isEmpty()) {
        fonctions_->selectRow(0);
        montrerLignesDe(0);
    }
}

// Le code de la fonction choisie, ligne à ligne, avec ses passages. Les
// lignes les plus visitées sont teintées : c'est ce qu'on vient chercher.
void FenetreProfileur::montrerLignesDe(int rangee) {
    lignes_->setRowCount(0);
    if (rangee < 0 || rangee >= fonctions_->rowCount()) return;
    QTableWidgetItem* nom = fonctions_->item(rangee, 0);
    if (!nom) return;
    int indice = nom->data(Qt::UserRole + 1).toInt();
    if (indice < 0 || indice >= entrees_.size()) return;
    const LigneProfil& e = entrees_[indice];

    QMap<int, long long> passages;
    long long plusChaude = 0;
    for (const auto& kv : e.lignes) {
        passages[kv.first] = kv.second;
        plusChaude = std::max(plusChaude, kv.second);
    }

    QStringList source;
    QFile fichier(e.fichier);
    if (!e.fichier.isEmpty() && fichier.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream flux(&fichier);
        while (!flux.atEnd()) source << flux.readLine();
    }

    // Sans le fichier — une fonction native, un fichier deplace — on montre
    // au moins les compteurs : mieux qu'un panneau vide.
    QList<int> numeros = passages.keys();
    if (!source.isEmpty()) {
        numeros.clear();
        for (int k = 1; k <= source.size(); ++k) numeros << k;
    }
    std::sort(numeros.begin(), numeros.end());

    lignes_->setRowCount(numeros.size());
    for (int k = 0; k < numeros.size(); ++k) {
        int numero = numeros[k];
        long long compte = passages.value(numero, 0);
        auto* colonneNumero = new QTableWidgetItem(QString::number(numero));
        auto* colonneCompte =
            new QTableWidgetItem(compte ? QString::number(compte) : QString());
        QString texte = numero >= 1 && numero <= source.size() ? source[numero - 1]
                                                               : QString();
        auto* colonneCode = new QTableWidgetItem(texte);
        if (compte > 0 && plusChaude > 0) {
            // Du jaune pâle au rouge pâle, selon la chaleur de la ligne.
            double part = (double)compte / (double)plusChaude;
            QColor teinte = QColor::fromHsvF(0.13 * (1.0 - part), 0.35 + 0.35 * part, 1.0);
            for (QTableWidgetItem* c : {colonneNumero, colonneCompte, colonneCode})
                c->setBackground(teinte);
        }
        lignes_->setItem(k, 0, colonneNumero);
        lignes_->setItem(k, 1, colonneCompte);
        lignes_->setItem(k, 2, colonneCode);
    }
    lignes_->resizeColumnToContents(0);
    lignes_->resizeColumnToContents(1);
}
