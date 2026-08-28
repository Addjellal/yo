// Moteur.cpp — l'interpréteur dans son fil, et ce qu'il publie.
#include "Moteur.h"

#include <QDir>
#include <QStringList>
#include <ostream>
#include <sstream>
#include <streambuf>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

using namespace matlibre;

namespace {

// Tampon de sortie qui pousse le texte vers le fil graphique au fil de
// l'eau : une boucle qui affiche pendant une minute se voit avancer, au
// lieu de tout livrer à la fin.
class TamponVersSignal : public std::streambuf {
public:
    explicit TamponVersSignal(Moteur* moteur) : moteur_(moteur) {}

protected:
    int overflow(int c) override {
        if (c == EOF) return 0;
        attente_ += (char)c;
        if (c == '\n' || attente_.size() > 4096) vider();
        return c;
    }
    std::streamsize xsputn(const char* s, std::streamsize n) override {
        attente_.append(s, (std::size_t)n);
        if (attente_.find('\n') != std::string::npos || attente_.size() > 4096) vider();
        return n;
    }
    int sync() override {
        vider();
        return 0;
    }

private:
    void vider() {
        if (attente_.empty()) return;
        emit moteur_->sortieProduite(QString::fromUtf8(attente_.c_str()));
        attente_.clear();
    }
    Moteur* moteur_;
    std::string attente_;
};

QString dimensionsTexte(const Valeur& v) {
    QString s;
    for (std::size_t k = 0; k < v.dims.size(); ++k) {
        if (k) s += QStringLiteral("x");
        s += QString::number(v.dims[k]);
    }
    return s;
}

QString classeTexte(const Valeur& v) {
    switch (v.classe) {
        case Classe::Double:    return QStringLiteral("double");
        case Classe::Simple:    return QStringLiteral("single");
        case Classe::Logique:   return QStringLiteral("logical");
        case Classe::Caractere: return QStringLiteral("char");
        case Classe::Chaine:    return QStringLiteral("string");
        case Classe::Cellule:   return QStringLiteral("cell");
        case Classe::Structure: return QStringLiteral("struct");
        case Classe::Fonction:  return QStringLiteral("function_handle");
        case Classe::Objet:
            return v.nomObjet.empty() ? QStringLiteral("object")
                                      : QString::fromStdString(v.nomObjet);
        case Classe::Int8:      return QStringLiteral("int8");
        case Classe::Int16:     return QStringLiteral("int16");
        case Classe::Int32:     return QStringLiteral("int32");
        case Classe::Int64:     return QStringLiteral("int64");
        case Classe::UInt8:     return QStringLiteral("uint8");
        case Classe::UInt16:    return QStringLiteral("uint16");
        case Classe::UInt32:    return QStringLiteral("uint32");
        case Classe::UInt64:    return QStringLiteral("uint64");
    }
    return QStringLiteral("double");
}

// Le resume que montre la colonne « Valeur », comme l'explorateur de
// MATLAB : la valeur elle-meme quand elle tient, sinon sa forme. Le rendu
// complet, avec ses « Columns 1 through 6 », n'a pas sa place dans une
// case de tableau.
QString resumeValeur(Interpreteur& it, const Valeur& v) {
    if (v.estScalaire() && v.estNumerique() && !v.estComplexe()) {
        std::ostringstream o;
        o << v.re[0];
        return QString::fromStdString(o.str());
    }
    if (v.estTexte() && v.nlignes() <= 1)
        return QStringLiteral("'") + QString::fromStdString(v.versTexte()).left(60) +
               QStringLiteral("'");
    // Un petit vecteur numerique se lit d'un coup d'oeil : on le montre.
    if (v.estNumerique() && !v.estComplexe() && v.dims.size() == 2 &&
        (v.nlignes() == 1 || v.ncolonnes() == 1) && v.re.size() <= 8 && !v.re.empty()) {
        QStringList morceaux;
        for (double x : v.re) morceaux << QString::number(x, 'g', 5);
        return QStringLiteral("[") + morceaux.join(QLatin1Char(' ')) + QStringLiteral("]");
    }
    // Sinon sa forme, entre chevrons, comme le fait MATLAB.
    QString dims = dimensionsTexte(v);
    return QStringLiteral("<%1 %2>").arg(dims, classeTexte(v));
}

}  // namespace

Moteur::Moteur(QObject* parent) : QObject(parent) {}

Moteur::~Moteur() = default;

void Moteur::demarrer() {
    it_ = std::make_unique<Interpreteur>();
    tampon_ = std::make_unique<TamponVersSignal>(this);
    flux_ = std::make_unique<std::ostream>(tampon_.get());
    it_->installerBibliotheque();
    it_->definirSortie(flux_.get());
    it_->modeInteractif = true;
    // « clc » efface la fenetre au lieu d'y ecrire « [2J[H ».
    it_->effacerEcran = [this] { emit effacementDemande(); };
    // Sans cela, un script pose dans le dossier courant reste introuvable :
    // c'est la premiere chose qu'on fait dans un bureau — ecrire un
    // fichier a cote, et l'executer.
    it_->ajouterChemin(QDir::currentPath().toStdString(), true);
    emit dossierChange(QDir::currentPath());
    emit pret();
    publierEtat();
}

void Moteur::demanderArret() {
    // L'interpréteur n'a pas encore de point d'interruption : le bouton
    // reste donc grisé tant que ce n'est pas implémenté, plutôt que de
    // promettre un arrêt qui n'arrive pas.
}

void Moteur::executer(const QString& texte) {
    if (!it_) return;
    occupe_ = true;
    try {
        it_->executerTexte(texte.toStdString(), "<bureau>");
    } catch (const ErreurMatlab& e) {
        *flux_ << "Error: " << e.message << "\n";
    } catch (const std::exception& e) {
        *flux_ << "Error: " << e.what() << "\n";
    }
    flux_->flush();
    occupe_ = false;
    publierEtat();
    emit commandeFinie();
}

void Moteur::changerDossier(const QString& chemin) {
    if (!it_) return;
    QDir::setCurrent(chemin);
    it_->ajouterChemin(chemin.toStdString(), true);
    emit dossierChange(QDir::currentPath());
}

void Moteur::reindexer() {
    // Un fichier qu'on vient d'ecrire doit etre visible tout de suite :
    // MATLAB reconstruit son index a l'enregistrement, on fait de meme.
    if (!it_) return;
    it_->reindexerChemin();
}

void Moteur::publierEtat() {
    if (!it_) return;
    QVector<LigneEspaceTravail> lignes;
    for (const auto& nom : it_->nomsVariables()) {
        Valeur v = it_->lireVariable(nom);
        LigneEspaceTravail l;
        l.nom = QString::fromStdString(nom);
        l.taille = dimensionsTexte(v);
        l.classe = classeTexte(v);
        l.valeur = resumeValeur(*it_, v);
        lignes.push_back(l);
    }
    emit espaceTravailChange(lignes);

    QVector<FigureCopiee> figures;
    for (const auto& kv : it_->figures) {
        if (!kv.second) continue;
        FigureCopiee f;
        f.numero = kv.first;
        // Copie profonde : le fil graphique peint pendant que le calcul
        // repart, et ne doit pas lire des axes en cours de modification.
        f.figure = *kv.second;
        f.figure.axes.clear();
        for (const auto& a : kv.second->axes)
            f.figure.axes.push_back(a ? std::make_shared<Axes>(*a) : nullptr);
        figures.push_back(f);
    }
    emit figuresChangees(figures);
}
