// Moteur.cpp — l'interpréteur dans son fil, et ce qu'il publie.
#include "Moteur.h"

#include <QDir>
#include <QElapsedTimer>
#include <QFileInfo>
#include <QStringList>
#include <ostream>
#include <cstring>
#include <functional>
#include <sstream>
#include <streambuf>

#include "matlibre/Affichage.h"
#include "matlibre/Bibliotheque.h"
#include "matlibre/Erreur.h"
#include "matlibre/Deboguage.h"
#include "matlibre/Arbre.h"
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

// Empreinte du contenu d'une figure : ce qui, en changeant, doit faire
// repeindre et remonter la fenetre. On melange les nombres eux-memes, et
// pas seulement les tailles : « ax.XTick = [...] » ne change aucune
// dimension mais change bien l'image.
std::uint64_t melanger(std::uint64_t graine, std::uint64_t valeur) {
    graine ^= valeur + 0x9e3779b97f4a7c15ULL + (graine << 6) + (graine >> 2);
    return graine;
}

std::uint64_t melangerReels(std::uint64_t graine, const std::vector<double>& v) {
    graine = melanger(graine, v.size());
    // Un tracé d'un million de points ne se relit pas en entier a chaque
    // commande : on echantillonne, et l'on garde les deux bouts.
    std::size_t pas = v.size() > 512 ? v.size() / 512 : 1;
    for (std::size_t k = 0; k < v.size(); k += pas) {
        std::uint64_t bits;
        double x = v[k];
        std::memcpy(&bits, &x, sizeof(bits));
        graine = melanger(graine, bits);
    }
    if (!v.empty()) {
        std::uint64_t bits;
        double x = v.back();
        std::memcpy(&bits, &x, sizeof(bits));
        graine = melanger(graine, bits);
    }
    return graine;
}

std::uint64_t melangerTexte(std::uint64_t graine, const std::string& s) {
    return melanger(graine, std::hash<std::string>{}(s));
}

std::uint64_t empreinteFigure(const Figure& f) {
    std::uint64_t h = 1469598103934665603ULL;
    h = melanger(h, (std::uint64_t)f.lignes);
    h = melanger(h, (std::uint64_t)f.colonnes);
    h = melanger(h, (std::uint64_t)f.largeur);
    h = melanger(h, (std::uint64_t)f.hauteur);
    h = melangerTexte(h, f.nom);
    h = melanger(h, (std::uint64_t)f.axeCourant);
    for (const auto& a : f.axes) {
        if (!a) {
            h = melanger(h, 0);
            continue;
        }
        h = melangerTexte(h, a->titre);
        h = melangerTexte(h, a->etiquetteX);
        h = melangerTexte(h, a->etiquetteY);
        h = melangerTexte(h, a->etiquetteZ);
        h = melanger(h, (std::uint64_t)a->grille);
        h = melanger(h, (std::uint64_t)a->tenir);
        h = melanger(h, (std::uint64_t)a->logX);
        h = melanger(h, (std::uint64_t)a->logY);
        h = melanger(h, (std::uint64_t)a->boite);
        h = melanger(h, (std::uint64_t)a->axesVisibles);
        h = melanger(h, (std::uint64_t)a->proportions);
        h = melanger(h, (std::uint64_t)a->position);
        h = melanger(h, (std::uint64_t)a->rangee);
        h = melanger(h, (std::uint64_t)a->colonne);
        h = melanger(h, (std::uint64_t)a->limitesManuellesX);
        h = melanger(h, (std::uint64_t)a->limitesManuellesY);
        h = melangerReels(h, {a->xmin, a->xmax, a->ymin, a->ymax, a->taillePolice});
        h = melangerReels(h, a->ticksX);
        h = melangerReels(h, a->ticksY);
        h = melanger(h, (std::uint64_t)a->legendeVisible);
        for (const auto& e : a->legende) h = melangerTexte(h, e);
        for (const auto& e : a->etiquettesTicksX) h = melangerTexte(h, e);
        for (const auto& e : a->etiquettesTicksY) h = melangerTexte(h, e);
        for (const auto& s : a->series) {
            h = melanger(h, (std::uint64_t)s.genre);
            h = melangerTexte(h, s.couleur);
            h = melangerTexte(h, s.style);
            h = melangerTexte(h, s.marqueur);
            h = melangerTexte(h, s.etiquette);
            h = melangerReels(h, {s.epaisseur});
            h = melanger(h, (std::uint64_t)s.hauteurImage);
            h = melanger(h, (std::uint64_t)s.largeurImage);
            h = melangerReels(h, s.x);
            h = melangerReels(h, s.y);
            h = melangerReels(h, s.z);
        }
    }
    return h;
}

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
    // « doc nom » ouvre le navigateur d'aide au lieu d'imprimer.
    it_->crochetDocumentation = [this](const std::string& nom) {
        emit documentationDemandee(QString::fromStdString(nom));
    };

    // Le crochet d'arret : appele par l'interpreteur avant l'instruction
    // ou se pose un point d'arret. Il rend la main quand l'utilisateur
    // reprend. Le fil de calcul dort ici ; l'interface reste vivante.
    it_->crochetArret = [this](Interpreteur& moteur, const std::string& fichier, int ligne) {
        arrete_ = true;
        // L'espace de travail est publie AVANT de dormir, depuis ce fil :
        // le fil graphique n'a ainsi rien a lire dans une structure qui
        // pourrait bouger.
        publierEtat();
        flux_->flush();
        emit arreteSur(QString::fromStdString(fichier), ligne);
        int action = (int)ActionDebogueur::Continuer;
        for (;;) {
            QString expression;
            {
                std::unique_lock<std::mutex> garde(verrouArret_);
                signalArret_.wait(garde, [this] {
                    return repriseDemandee_ || !aEvaluer_.isEmpty();
                });
                if (repriseDemandee_) {
                    repriseDemandee_ = false;
                    action = actionDemandee_;
                    break;
                }
                expression = aEvaluer_;
                aEvaluer_.clear();
            }
            // « K>> » de MATLAB : on evalue dans l'espace de travail ou
            // l'execution s'est arretee, sans la reprendre.
            try {
                moteur.executerTexte(expression.toStdString(), "<K>>");
            } catch (const ErreurMatlab& e) {
                *flux_ << "Error: " << e.message << "\n";
            } catch (const std::exception& e) {
                *flux_ << "Error: " << e.what() << "\n";
            } catch (...) {
                // Rien ne doit remonter : ce fil finit dans une boucle
                // d'evenements Qt, qui n'accepte aucune exception.
                *flux_ << "Error: interrompu.\n";
            }
            flux_->flush();
            publierEtat();
        }
        // C'est ici, dans le fil de calcul, que l'action prend effet :
        // l'interpréteur n'est jamais écrit depuis le fil graphique.
        auto mode = (ActionDebogueur)action;
        moteur.debogueur.action = mode;
        if (mode == ActionDebogueur::PasAPas || mode == ActionDebogueur::SortirDe)
            moteur.debogueur.profondeurPause = moteur.profondeur();
        arrete_ = false;
        emit repriseEffectuee();
    };
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
    } catch (...) {
        // Idem : une exception qui traverserait Qt abattrait le bureau.
        *flux_ << "Error: interrompu.\n";
    }
    flux_->flush();
    occupe_ = false;
    publierEtat();
    emit commandeFinie();
}

// « Exécuter et chronométrer » : profile on, la commande, profile off, et
// le relevé part vers la fenêtre du profileur. MATLAB fait exactement
// cela quand on presse « Run and Time ».
void Moteur::executerEtChronometrer(const QString& texte) {
    if (!it_) return;
    occupe_ = true;
    it_->profil.effacer();
    it_->profil.demarrer();
    QElapsedTimer chrono;
    chrono.start();
    try {
        it_->executerTexte(texte.toStdString(), "<bureau>");
    } catch (const ErreurMatlab& e) {
        *flux_ << "Error: " << e.message << "\n";
    } catch (const std::exception& e) {
        *flux_ << "Error: " << e.what() << "\n";
    } catch (...) {
        *flux_ << "Error: interrompu.\n";
    }
    double duree = chrono.nsecsElapsed() / 1e9;
    it_->profil.arreter();
    flux_->flush();

    QVector<LigneProfil> entrees;
    for (const auto& e : it_->profil.classees()) {
        LigneProfil l;
        l.nom = QString::fromStdString(e.nom);
        l.appels = e.appels;
        l.total = e.tempsTotal;
        l.propre = e.tempsPropre;
        // Le fichier permet a la fenetre de montrer le code a cote des
        // compteurs : c'est ce qui rend un profil utile.
        if (auto f = it_->fonctionFichier(e.nom))
            l.fichier = QString::fromStdString(f->fichier);
        for (const auto& kv : e.lignes)
            l.lignes.push_back(qMakePair(kv.first, kv.second));
        entrees.push_back(l);
    }
    occupe_ = false;
    publierEtat();
    emit profilPret(entrees, duree);
    emit commandeFinie();
}

void Moteur::changerDossier(const QString& chemin) {
    if (!it_) return;
    QDir::setCurrent(chemin);
    it_->ajouterChemin(chemin.toStdString(), true);
    emit dossierChange(QDir::currentPath());
}

void Moteur::poserPointArret(const QString& fichier, int ligne) {
    if (!it_) return;
    // Le debogueur designe un fichier par son nom court, sans dossier ni
    // extension : c'est ainsi que MATLAB nomme « dbstop in monScript ».
    QFileInfo info(fichier);
    it_->debogueur.poser(info.completeBaseName().toStdString(), ligne, std::string());
}

void Moteur::retirerPointArret(const QString& fichier, int ligne) {
    if (!it_) return;
    QFileInfo info(fichier);
    it_->debogueur.retirer(info.completeBaseName().toStdString(), ligne);
}

void Moteur::retirerTousPointsArret() {
    if (!it_) return;
    it_->debogueur.toutRetirer();
}

// Appele depuis le fil graphique pendant que le fil de calcul dort : ne
// touche donc que l'etat garde par le verrou. L'action elle-meme est posee
// dans le debogueur par le fil de calcul, a son reveil.
void Moteur::reprendre(int action) {
    {
        std::lock_guard<std::mutex> garde(verrouArret_);
        actionDemandee_ = action;
        repriseDemandee_ = true;
    }
    signalArret_.notify_all();
}

void Moteur::evaluerALArret(const QString& texte) {
    {
        std::lock_guard<std::mutex> garde(verrouArret_);
        aEvaluer_ = texte;
    }
    signalArret_.notify_all();
}

// A la fermeture : on reveille le fil arrete en lui demandant de quitter le
// debogage, ce qui deroule le script et rend la main a la boucle
// d'evenements — sans quoi « quit() » n'aurait personne pour l'entendre.
void Moteur::libererPourFermeture() {
    fermeture_ = true;
    reprendre((int)ActionDebogueur::Quitter);
}

// L'aide vient de l'interpreteur, dans son fil : « matlibre_aide_structuree »
// fait tout le travail, on ne fait que traduire en Qt.
void Moteur::demanderAide(const QString& nom) {
    FicheAide fiche;
    fiche.nom = nom;
    if (!it_) {
        emit aidePrete(fiche);
        return;
    }
    auto texteDe = [](const Valeur& s, const char* champ) {
        if (!s.aChamp(champ)) return QString();
        return QString::fromStdString(s.champ(champ).versTexte());
    };
    auto listeDe = [](const Valeur& s, const char* champ) {
        QStringList liste;
        if (!s.aChamp(champ)) return liste;
        Valeur v = s.champ(champ);
        if (v.classe == Classe::Cellule)
            for (const auto& c : v.cellules) liste << QString::fromStdString(c.versTexte());
        return liste;
    };
    try {
        std::vector<Valeur> args = {Valeur::texte(nom.toStdString())};
        auto sortie = it_->appeler("matlibre_aide_structuree", args, 1);
        if (!sortie.empty()) {
            const Valeur& s = sortie[0];
            fiche.resume = texteDe(s, "Resume");
            fiche.description = texteDe(s, "Description");
            fiche.texte = texteDe(s, "Texte");
            fiche.source = texteDe(s, "Source");
            fiche.fichier = texteDe(s, "Fichier");
            fiche.syntaxe = listeDe(s, "Syntaxe");
            fiche.exemples = listeDe(s, "Exemples");
            fiche.voirAussi = listeDe(s, "VoirAussi");
            fiche.trouvee = !fiche.texte.isEmpty();
        }
    } catch (...) {
        // Une aide introuvable n'est pas une erreur : la fenetre le dira.
    }
    emit aidePrete(fiche);
}

void Moteur::demanderIndexAide() {
    QVector<EntreeIndexAide> entrees;
    if (!it_) {
        emit indexAidePret(entrees);
        return;
    }
    for (const auto& nom : it_->nomsNatifs()) {
        // Les rouages internes ne sont pas de la documentation : MATLAB ne
        // liste pas non plus ses fonctions privees.
        if (nom.rfind("matlibre_", 0) == 0) continue;
        EntreeIndexAide e;
        e.nom = QString::fromStdString(nom);
        const EntreeNative* n = it_->natif(nom);
        e.groupe = n ? QString::fromStdString(n->groupe) : QString();
        // Le resume est la premiere ligne de l'aide, nom retire.
        std::vector<Valeur> args = {Valeur::texte(nom)};
        try {
            auto sortie = it_->appeler("matlibre_aide_structuree", args, 1);
            if (!sortie.empty() && sortie[0].aChamp("Resume"))
                e.resume = QString::fromStdString(sortie[0].champ("Resume").versTexte());
        } catch (...) {
        }
        entrees.push_back(e);
    }
    emit indexAidePret(entrees);
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
    std::map<int, std::uint64_t> presentes;
    for (const auto& kv : it_->figures) {
        if (!kv.second) continue;
        FigureCopiee f;
        f.numero = kv.first;
        f.empreinte = empreinteFigure(*kv.second);
        presentes[f.numero] = f.empreinte;
        auto ancienne = empreintesEnvoyees_.find(f.numero);
        f.contenu = ancienne == empreintesEnvoyees_.end() || ancienne->second != f.empreinte;
        if (f.contenu) {
            // Copie profonde : le fil graphique peint pendant que le calcul
            // repart, et ne doit pas lire des axes en cours de
            // modification. On ne la paie que si le tracé a bougé.
            f.figure = *kv.second;
            f.figure.axes.clear();
            for (const auto& a : kv.second->axes)
                f.figure.axes.push_back(a ? std::make_shared<Axes>(*a) : nullptr);
        }
        figures.push_back(f);
    }
    empreintesEnvoyees_.swap(presentes);
    emit figuresChangees(figures, it_->figureCourante);
}

// La fenetre d'une figure fermee a la main : la figure quitte le moteur,
// sinon la prochaine publication la ferait reapparaitre.
void Moteur::fermerFigure(int numero) {
    if (!it_) return;
    it_->figures.erase(numero);
    if (!it_->figures.count(it_->figureCourante))
        it_->figureCourante = it_->figures.empty() ? 0 : it_->figures.begin()->first;
    empreintesEnvoyees_.erase(numero);
    publierEtat();
}
