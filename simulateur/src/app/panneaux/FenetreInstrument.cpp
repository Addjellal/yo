#include "app/panneaux/FenetreInstrument.h"

#include <QComboBox>
#include <QFont>
#include <QHBoxLayout>
#include <QMap>
#include <QLabel>
#include <QPushButton>
#include <QTimer>
#include <QVBoxLayout>

#include <algorithm>
#include <cmath>

#include "app/Apparence.h"
#include "app/schema/ItemComposant.h"
#include "coeur/Device.h"

namespace {

// Sépare « 12.80 mA » en nombre et unité, pour pouvoir recalculer des
// extrêmes sans redemander l'instrument.
bool decouper(const QString& texte, double& valeur, QString& unite) {
    static const QString prefixes = "GMkmµn";
    const QStringList morceaux = texte.split(' ', Qt::SkipEmptyParts);
    if (morceaux.size() < 2) return false;
    bool ok = false;
    valeur = morceaux[0].toDouble(&ok);
    if (!ok) return false;
    unite = morceaux[1];
    if (unite.size() >= 2 && prefixes.contains(unite[0])) {
        static const QMap<QChar, double> facteurs = {
            {'G', 1e9}, {'M', 1e6}, {'k', 1e3},
            {'m', 1e-3}, {QChar(0x00B5), 1e-6}, {'n', 1e-9}};
        valeur *= facteurs.value(unite[0], 1.0);
        unite = unite.mid(1);
    }
    return true;
}

QString formater(double valeur, const QString& unite) {
    const double absolue = std::fabs(valeur);
    double reduite = valeur;
    QString prefixe;
    if (absolue >= 1e6) { reduite = valeur / 1e6; prefixe = "M"; }
    else if (absolue >= 1e3) { reduite = valeur / 1e3; prefixe = "k"; }
    else if (absolue < 1e-9) { reduite = 0; }
    else if (absolue < 1e-6) { reduite = valeur * 1e9; prefixe = "n"; }
    else if (absolue < 1e-3) { reduite = valeur * 1e6; prefixe = "µ"; }
    else if (absolue < 1.0) { reduite = valeur * 1e3; prefixe = "m"; }
    return QString("%1 %2%3").arg(reduite, 0, 'f', 2).arg(prefixe, unite);
}

}  // namespace

FenetreInstrument::FenetreInstrument(
    ItemComposant* composant, std::function<bool(ItemComposant*)> toujours_la,
    std::function<QString(ItemComposant*)> designation, QWidget* parent)
    : QWidget(parent, Qt::Window),
      composant_(composant),
      toujours_la_(std::move(toujours_la)),
      designation_(std::move(designation)) {
    const coeur::Modele* modele = composant_->modele();
    setWindowTitle(composant_->reference() + " — "
                   + (modele ? QString::fromStdString(modele->libelle)
                             : QString("instrument")));
    resize(320, 230);

    auto* colonne = new QVBoxLayout(this);
    colonne->setContentsMargins(14, 12, 14, 12);

    description_ = new QLabel(
        modele ? QString::fromStdString(modele->libelle) : QString());
    apparence::poser_ton(description_, apparence::Ton::Doux);
    colonne->addWidget(description_);

    valeur_ = new QLabel("—");
    QFont grande = valeur_->font();
    grande.setPointSizeF(grande.pointSizeF() * 2.6);
    grande.setBold(true);
    valeur_->setFont(grande);
    valeur_->setAlignment(Qt::AlignCenter);
    valeur_->setMinimumHeight(64);
    colonne->addWidget(valeur_, 1);

    extremes_ = new QLabel("—");
    extremes_->setAlignment(Qt::AlignCenter);
    apparence::poser_ton(extremes_, apparence::Ton::Doux);
    colonne->addWidget(extremes_);

    // Sélecteur de position, quand l'appareil en a un : c'est le commutateur
    // d'un multimètre, à la même place que sur la face avant d'un vrai.
    if (modele) {
        for (const coeur::Propriete& propriete : modele->proprietes) {
            if (propriete.genre != coeur::Propriete::Genre::Choix) continue;
            auto* ligne = new QHBoxLayout;
            ligne->addWidget(new QLabel(
                QString::fromStdString(propriete.libelle) + " :"));
            auto* position = new QComboBox;
            for (const std::string& choix : propriete.choix)
                position->addItem(QString::fromStdString(choix));
            const auto actuel = composant_->textes.find(propriete.cle);
            position->setCurrentText(QString::fromStdString(
                actuel == composant_->textes.end() ? propriete.defaut_texte
                                                   : actuel->second));
            const std::string cle = propriete.cle;
            connect(position, &QComboBox::currentTextChanged, this,
                    [this, cle](const QString& valeur) {
                        composant_->textes[cle] = valeur.toStdString();
                        premiere_ = true;      // les extrêmes changent de sens
                        somme_ = 0;
                        compte_ = 0;
                    });
            ligne->addWidget(position, 1);
            colonne->addLayout(ligne);
            break;
        }
    }

    auto* sonder = new QPushButton("Suivre à l'oscilloscope");
    connect(sonder, &QPushButton::clicked, this, [this] {
        // LE COMPOSANT A PU MOURIR PENDANT QUE LA FENÊTRE RESTAIT OUVERTE.
        //
        // `rafraichir()` le vérifiait, ce bouton non : supprimer le composant
        // du schéma puis cliquer « Suivre » avant le prochain top du minuteur
        // — cent millisecondes — déréférençait un objet détruit. La
        // suppression est synchrone dans la scène, il n'y a pas de sursis.
        if (!designation_ || !toujours_la_ || !toujours_la_(composant_)) return;
        const QString signal = designation_(composant_);
        if (!signal.isEmpty()) emit sonde_demandee(signal);
    });
    colonne->addWidget(sonder);

    auto* remise = new QPushButton("Remettre les extrêmes à zéro");
    connect(remise, &QPushButton::clicked, this, [this] {
        premiere_ = true;
        somme_ = 0;
        compte_ = 0;
    });
    colonne->addWidget(remise);

    // Un relevé dix fois par seconde : l'œil n'en demande pas plus, et cela
    // n'ajoute aucune charge à la simulation.
    auto* horloge = new QTimer(this);
    connect(horloge, &QTimer::timeout, this, &FenetreInstrument::rafraichir);
    horloge->start(100);
    rafraichir();
}

void FenetreInstrument::rafraichir() {
    // Le composant a pu être effacé du schéma pendant que la fenêtre était
    // ouverte : elle se referme d'elle-même plutôt que de lire un objet mort.
    if (toujours_la_ && !toujours_la_(composant_)) {
        close();
        deleteLater();
        return;
    }

    const QString texte = composant_->mesure();
    if (texte.isEmpty()) {
        valeur_->setText("—");
        extremes_->setText("simulation à l'arrêt");
        return;
    }
    valeur_->setText(texte);

    double valeur = 0;
    QString unite;
    if (!decouper(texte, valeur, unite)) return;
    unite_ = unite;
    if (premiere_) {
        mini_ = maxi_ = valeur;
        premiere_ = false;
    } else {
        mini_ = std::min(mini_, valeur);
        maxi_ = std::max(maxi_, valeur);
    }
    somme_ += valeur;
    ++compte_;
    extremes_->setText(QString("min %1   ·   moy %2   ·   max %3")
                           .arg(formater(mini_, unite_),
                                formater(compte_ ? somme_ / compte_ : 0.0, unite_),
                                formater(maxi_, unite_)));
}
