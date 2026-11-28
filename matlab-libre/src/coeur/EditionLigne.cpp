// EditionLigne.cpp — décodeur de touches, éditeur de ligne, lecteur au
// terminal. Voir EditionLigne.h pour ce que chaque touche fait.
#include "matlibre/EditionLigne.h"

#include <algorithm>
#include <cstdio>
#include <cstdlib>
#include <fstream>
#include <iostream>

#ifdef _WIN32
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <io.h>
#include <windows.h>
#else
#include <cerrno>
#include <fcntl.h>
#include <poll.h>
#include <sys/ioctl.h>
#include <termios.h>
#include <unistd.h>
#endif

namespace matlibre {

namespace {

bool continuation(unsigned char c) { return (c & 0xC0) == 0x80; }

// Le nombre de points de code : une colonne chacun. Les caractères larges
// (idéogrammes) et les diacritiques combinants ne sont pas comptés à part ;
// un texte de MATLAB n'en porte guère sur la ligne de commande.
std::size_t colonnes(const std::string& s, std::size_t debut = 0,
                     std::size_t fin = std::string::npos) {
    if (fin > s.size()) fin = s.size();
    std::size_t n = 0;
    for (std::size_t i = debut; i < fin; ++i)
        if (!continuation((unsigned char)s[i])) ++n;
    return n;
}

// L'octet où commence le point de code numéro K (ou la fin).
std::size_t octetDuPoint(const std::string& s, std::size_t k) {
    std::size_t i = 0;
    while (i < s.size()) {
        if (!continuation((unsigned char)s[i])) {
            if (k == 0) return i;
            --k;
        }
        ++i;
    }
    return s.size();
}

std::size_t pointPrecedent(const std::string& s, std::size_t i) {
    if (i == 0) return 0;
    --i;
    while (i > 0 && continuation((unsigned char)s[i])) --i;
    return i;
}

std::size_t pointSuivant(const std::string& s, std::size_t i) {
    if (i >= s.size()) return s.size();
    ++i;
    while (i < s.size() && continuation((unsigned char)s[i])) ++i;
    return i;
}

// Un mot, pour Ctrl-← et Ctrl-→ : lettres, chiffres, souligné, et tout ce
// qui n'est pas ASCII (une lettre accentuée).
bool lettreDeMot(unsigned char c) {
    return c >= 0x80 || (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z') ||
           (c >= 'A' && c <= 'Z') || c == '_';
}

std::string prefixeCommun(const std::vector<std::string>& v) {
    if (v.empty()) return std::string();
    std::string p = v.front();
    for (const std::string& s : v) {
        std::size_t k = 0;
        while (k < p.size() && k < s.size() && p[k] == s[k]) ++k;
        p.resize(k);
    }
    // Ne pas couper au milieu d'un caractère UTF-8.
    while (!p.empty() && continuation((unsigned char)p.back())) p.pop_back();
    if (!p.empty() && (unsigned char)p.back() >= 0xC0) p.pop_back();
    return p;
}

bool commencePar(const std::string& s, const std::string& debut) {
    return s.size() >= debut.size() && s.compare(0, debut.size(), debut) == 0;
}

}  // namespace

// ---------------------------------------------------------------------------
// Décodeur
// ---------------------------------------------------------------------------

void DecodeurTouches::pousser(unsigned char c, std::vector<Evenement>& sortie) {
    Evenement e;
    if (decoder(c, e)) sortie.push_back(e);
    // Un ESC suivi d'une lettre ordinaire : Échap, puis la lettre, qu'on
    // décode à son tour au lieu de la perdre.
    if (relire_) {
        relire_ = false;
        if (decoder(c, e)) sortie.push_back(e);
    }
}

bool DecodeurTouches::decoder(unsigned char c, Evenement& e) {
    e = Evenement{};
    // « \r\n », d'un texte collé venu de Windows, ne valide qu'une fois.
    const bool apresCR = apresCR_;
    apresCR_ = c == '\r';
    if (tampon_.empty()) {
        if (c == '\n' && apresCR) {
            e.touche = Touche::Ignoree;
            return true;
        }
        if (c == 0x1B) {
            tampon_.assign(1, (char)c);
            return false;
        }
        if (c >= 0x80) {
            std::size_t suite = (c & 0xE0) == 0xC0 ? 1 : (c & 0xF0) == 0xE0 ? 2
                                : (c & 0xF8) == 0xF0 ? 3 : 0;
            if (suite == 0) {          // octet de suite isolé, ou invalide
                e.touche = Touche::Ignoree;
                return true;
            }
            tampon_.assign(1, (char)c);
            utf8Attendus_ = suite;
            return false;
        }
        if (c >= 0x20 && c != 0x7F) {
            e.touche = Touche::Texte;
            e.texte.assign(1, (char)c);
            return true;
        }
        switch (c) {
            case '\r': case '\n': e.touche = Touche::Entree; break;
            case 0x7F: case 0x08: e.touche = Touche::RetourArriere; break;
            case 0x01: e.touche = Touche::Debut; break;          // Ctrl-A
            case 0x05: e.touche = Touche::Fin; break;            // Ctrl-E
            case 0x02: e.touche = Touche::Gauche; break;         // Ctrl-B
            case 0x06: e.touche = Touche::Droite; break;         // Ctrl-F
            case 0x10: e.touche = Touche::Haut; break;           // Ctrl-P
            case 0x0E: e.touche = Touche::Bas; break;            // Ctrl-N
            case 0x0B: e.touche = Touche::CouperFin; break;      // Ctrl-K
            case 0x15: e.touche = Touche::CouperDebut; break;    // Ctrl-U
            case 0x17: e.touche = Touche::CouperMot; break;      // Ctrl-W
            case 0x09: e.touche = Touche::Tabulation; break;
            case 0x03: e.touche = Touche::Interrompre; break;    // Ctrl-C
            case 0x04: e.touche = Touche::FinFichier; break;     // Ctrl-D
            case 0x0C: e.touche = Touche::EffacerEcran; break;   // Ctrl-L
            default: e.touche = Touche::Ignoree; break;
        }
        return true;
    }

    // Un caractère UTF-8 en cours.
    if ((unsigned char)tampon_[0] != 0x1B) {
        if (!continuation(c)) {
            // Tronqué : on l'oublie, et l'octet repart de zéro.
            tampon_.clear();
            utf8Attendus_ = 0;
            return decoder(c, e);
        }
        tampon_.push_back((char)c);
        if (--utf8Attendus_ > 0) return false;
        e.touche = Touche::Texte;
        e.texte.swap(tampon_);
        tampon_.clear();
        return true;
    }

    // Une séquence d'échappement en cours.
    tampon_.push_back((char)c);
    if (tampon_.size() == 2) {
        if (c == '[' || c == 'O') return false;
        // Alt + touche, comme readline : Alt-b, Alt-f, Alt-Retour arrière.
        tampon_.clear();
        if (c == 'b') {
            e.touche = Touche::MotGauche;
        } else if (c == 'f') {
            e.touche = Touche::MotDroite;
        } else if (c == 0x7F) {
            e.touche = Touche::CouperMot;
        } else {
            e.touche = Touche::Echap;
            relire_ = true;
        }
        return true;
    }
    const bool ss3 = tampon_[1] == 'O';
    const bool finale = ss3 ? true : (c >= 0x40 && c <= 0x7E);
    if (!finale) {
        if (tampon_.size() > 16) {     // séquence démesurée : on l'abandonne
            tampon_.clear();
            e.touche = Touche::Ignoree;
            return true;
        }
        return false;
    }
    const std::string parametres = tampon_.substr(2, tampon_.size() - 3);
    tampon_.clear();
    // « 1;5C » : Ctrl-→ ; « 1;3C » : Alt-→. L'un et l'autre vont par mot.
    const bool modifie = parametres.find(';') != std::string::npos;
    switch (c) {
        case 'A': e.touche = Touche::Haut; break;
        case 'B': e.touche = Touche::Bas; break;
        case 'C': e.touche = modifie ? Touche::MotDroite : Touche::Droite; break;
        case 'D': e.touche = modifie ? Touche::MotGauche : Touche::Gauche; break;
        case 'H': e.touche = Touche::Debut; break;
        case 'F': e.touche = Touche::Fin; break;
        case '~': {
            const std::string n = parametres.substr(0, parametres.find(';'));
            if (n == "1" || n == "7") e.touche = Touche::Debut;
            else if (n == "4" || n == "8") e.touche = Touche::Fin;
            else if (n == "3") e.touche = Touche::Supprimer;
            else e.touche = Touche::Ignoree;
            break;
        }
        default: e.touche = Touche::Ignoree; break;
    }
    return true;
}

bool DecodeurTouches::vider(Evenement& e) {
    if (tampon_.empty()) return false;
    e = Evenement{};
    e.touche = tampon_ == "\x1B" ? Touche::Echap : Touche::Ignoree;
    tampon_.clear();
    utf8Attendus_ = 0;
    return true;
}

// ---------------------------------------------------------------------------
// Éditeur
// ---------------------------------------------------------------------------

void EditeurLigne::commencer(const std::string& invite, const std::string& texte) {
    invite_ = invite;
    ligne_ = texte;
    curseur_ = ligne_.size();
    debutVue_ = 0;
    dansHistorique_ = false;
    indexHistorique_ = historique_.size();
    tape_.clear();
    choix_.clear();
    effacerEcran_ = false;
}

void EditeurLigne::inserer(const std::string& texte) {
    ligne_.insert(curseur_, texte);
    curseur_ += texte.size();
}

void EditeurLigne::remplacerLigne(const std::string& texte) {
    ligne_ = texte;
    curseur_ = ligne_.size();
}

EditeurLigne::Issue EditeurLigne::traiter(const Evenement& e) {
    // Toute touche qui modifie la ligne fait d'elle le nouveau filtre de
    // l'historique ; seules les flèches verticales y restent.
    const bool modifie = e.touche == Touche::Texte || e.touche == Touche::RetourArriere ||
                         e.touche == Touche::Supprimer || e.touche == Touche::CouperFin ||
                         e.touche == Touche::CouperDebut || e.touche == Touche::CouperMot ||
                         e.touche == Touche::Tabulation || e.touche == Touche::Echap;
    if (modifie) dansHistorique_ = false;

    switch (e.touche) {
        case Touche::Texte:
            inserer(e.texte);
            break;
        case Touche::Entree:
            return Issue::Valider;
        case Touche::Gauche:
            curseur_ = pointPrecedent(ligne_, curseur_);
            break;
        case Touche::Droite:
            curseur_ = pointSuivant(ligne_, curseur_);
            break;
        case Touche::MotGauche:
            while (curseur_ > 0 && !lettreDeMot((unsigned char)ligne_[curseur_ - 1]))
                curseur_ = pointPrecedent(ligne_, curseur_);
            while (curseur_ > 0 && lettreDeMot((unsigned char)ligne_[curseur_ - 1]))
                curseur_ = pointPrecedent(ligne_, curseur_);
            break;
        case Touche::MotDroite:
            while (curseur_ < ligne_.size() && !lettreDeMot((unsigned char)ligne_[curseur_]))
                curseur_ = pointSuivant(ligne_, curseur_);
            while (curseur_ < ligne_.size() && lettreDeMot((unsigned char)ligne_[curseur_]))
                curseur_ = pointSuivant(ligne_, curseur_);
            break;
        case Touche::Debut:
            curseur_ = 0;
            break;
        case Touche::Fin:
            curseur_ = ligne_.size();
            break;
        case Touche::RetourArriere:
            if (curseur_ > 0) {
                const std::size_t p = pointPrecedent(ligne_, curseur_);
                ligne_.erase(p, curseur_ - p);
                curseur_ = p;
            }
            break;
        case Touche::FinFichier:
            if (ligne_.empty()) return Issue::Fin;
            // Sur une ligne non vide, Ctrl-D efface sous le curseur.
            [[fallthrough]];
        case Touche::Supprimer:
            if (curseur_ < ligne_.size())
                ligne_.erase(curseur_, pointSuivant(ligne_, curseur_) - curseur_);
            break;
        case Touche::CouperFin:
            ligne_.erase(curseur_);
            break;
        case Touche::CouperDebut:
            ligne_.erase(0, curseur_);
            curseur_ = 0;
            break;
        case Touche::CouperMot: {
            // Comme Ctrl-W dans un terminal : les blancs, puis le mot
            // jusqu'au blanc précédent.
            std::size_t p = curseur_;
            while (p > 0 && (ligne_[p - 1] == ' ' || ligne_[p - 1] == '\t')) --p;
            while (p > 0 && ligne_[p - 1] != ' ' && ligne_[p - 1] != '\t') --p;
            ligne_.erase(p, curseur_ - p);
            curseur_ = p;
            break;
        }
        case Touche::Haut:
            rappeler(-1);
            break;
        case Touche::Bas:
            rappeler(+1);
            break;
        case Touche::Tabulation:
            completer();
            break;
        case Touche::Echap:
            remplacerLigne(std::string());
            break;
        case Touche::Interrompre:
            return Issue::Abandonner;
        case Touche::EffacerEcran:
            effacerEcran_ = true;
            break;
        case Touche::Ignoree:
            break;
    }
    return Issue::Continuer;
}

void EditeurLigne::rappeler(int sens) {
    if (!dansHistorique_) {
        tape_ = ligne_;
        indexHistorique_ = historique_.size();
        dansHistorique_ = true;
    }
    // On passe ce qui ne commence pas par ce qu'on a tapé, et ce qui est
    // déjà sur la ligne : une flèche change toujours quelque chose.
    auto convient = [&](std::size_t i) {
        return commencePar(historique_[i], tape_) && historique_[i] != ligne_;
    };
    if (sens < 0) {
        std::size_t i = indexHistorique_;
        while (i > 0) {
            --i;
            if (convient(i)) {
                indexHistorique_ = i;
                remplacerLigne(historique_[i]);
                return;
            }
        }
        return;   // rien de plus ancien : la ligne reste
    }
    for (std::size_t i = indexHistorique_ + 1; i < historique_.size(); ++i) {
        if (convient(i)) {
            indexHistorique_ = i;
            remplacerLigne(historique_[i]);
            return;
        }
    }
    // Au bas de la liste : ce qu'on avait tapé revient.
    indexHistorique_ = historique_.size();
    remplacerLigne(tape_);
}

void EditeurLigne::completer() {
    if (!completeur_) return;
    std::size_t debut = curseur_;
    std::vector<std::string> trouves = completeur_(ligne_, curseur_, debut);
    if (debut > curseur_) debut = curseur_;
    std::sort(trouves.begin(), trouves.end());
    trouves.erase(std::unique(trouves.begin(), trouves.end()), trouves.end());
    if (trouves.empty()) return;
    const std::string mot = ligne_.substr(debut, curseur_ - debut);
    const std::string commun = trouves.size() == 1 ? trouves.front() : prefixeCommun(trouves);
    // Aussi loin que les choix s'accordent ; quand il n'y a plus rien à
    // ajouter, on les montre.
    if (commun.size() > mot.size() || (trouves.size() == 1 && commun != mot)) {
        ligne_.replace(debut, curseur_ - debut, commun);
        curseur_ = debut + commun.size();
        return;
    }
    if (trouves.size() > 1) choix_ = std::move(trouves);
}

std::string EditeurLigne::rendu(int largeur) {
    const std::size_t largeurInvite = colonnes(invite_);
    const std::size_t place =
        largeur > (int)largeurInvite + 11 ? (std::size_t)largeur - largeurInvite - 1 : 10;
    const std::size_t total = colonnes(ligne_);
    const std::size_t cur = colonnes(ligne_, 0, curseur_);
    if (total <= place) {
        debutVue_ = 0;
    } else {
        if (cur < debutVue_) debutVue_ = cur;
        if (cur > debutVue_ + place) debutVue_ = cur - place;
        if (debutVue_ > total) debutVue_ = total;
    }
    const std::size_t a = octetDuPoint(ligne_, debutVue_);
    const std::size_t b = octetDuPoint(ligne_, debutVue_ + place);
    std::string s = "\r" + invite_ + ligne_.substr(a, b - a) + "\x1B[K\r";
    const std::size_t colonne = largeurInvite + cur - debutVue_;
    if (colonne > 0) s += "\x1B[" + std::to_string(colonne) + "C";
    return s;
}

std::vector<std::string> EditeurLigne::prendreChoix() {
    std::vector<std::string> v;
    v.swap(choix_);
    return v;
}

bool EditeurLigne::prendreEffacement() {
    const bool e = effacerEcran_;
    effacerEcran_ = false;
    return e;
}

namespace {
const std::size_t LIGNES_HISTORIQUE = 1000;
}

void EditeurLigne::ajouterHistorique(const std::string& ligne) {
    if (ligne.find_first_not_of(" \t") == std::string::npos) return;
    if (!historique_.empty() && historique_.back() == ligne) return;
    historique_.push_back(ligne);
    if (historique_.size() > LIGNES_HISTORIQUE)
        historique_.erase(historique_.begin(),
                          historique_.begin() + (historique_.size() - LIGNES_HISTORIQUE));
}

void EditeurLigne::definirHistorique(std::vector<std::string> h) {
    historique_.clear();
    for (std::string& l : h) ajouterHistorique(l);
}

// ---------------------------------------------------------------------------
// Lecteur
// ---------------------------------------------------------------------------

struct LecteurLignes::Etat {
    bool edition = false;
    bool brut = false;
    DecodeurTouches decodeur;
    EditeurLigne editeur;
    std::string fichierHistorique;
#ifdef _WIN32
    HANDLE entree = INVALID_HANDLE_VALUE;
    HANDLE sortie = INVALID_HANDLE_VALUE;
    DWORD modeEntree = 0;
    DWORD modeSortie = 0;
    wchar_t demiPaire = 0;
#else
    struct termios origine {};
#endif

    int largeur() const;
    bool passerEnBrut();
    void revenir();
    // Rend 1 et l'octet, 0 en fin de fichier, -1 si rien n'est venu dans
    // le délai (millisecondes ; négatif : attendre).
    int lireOctet(unsigned char& c, int delai);
    std::string octetsEnAttente;
};

namespace {
// Pour remettre le terminal en état si le programme s'arrête pendant une
// lecture (exit depuis un rappel, par exemple).
LecteurLignes::Etat* etatOuvert = nullptr;
extern "C" void remettreTerminal() {
    if (etatOuvert) etatOuvert->revenir();
}

void ecrire(const std::string& s) {
    std::fwrite(s.data(), 1, s.size(), stdout);
    std::fflush(stdout);
}
}  // namespace

#ifdef _WIN32

int LecteurLignes::Etat::largeur() const {
    CONSOLE_SCREEN_BUFFER_INFO info;
    if (GetConsoleScreenBufferInfo(sortie, &info))
        return info.srWindow.Right - info.srWindow.Left + 1;
    return 80;
}

bool LecteurLignes::Etat::passerEnBrut() {
    if (brut) return true;
    if (!GetConsoleMode(entree, &modeEntree) || !GetConsoleMode(sortie, &modeSortie))
        return false;
    // Les touches arrivent en séquences VT, comme sous Unix, et Ctrl-C
    // comme un caractère : le même décodeur sert aux deux systèmes.
    DWORD in = (modeEntree | ENABLE_VIRTUAL_TERMINAL_INPUT) &
               ~(ENABLE_LINE_INPUT | ENABLE_ECHO_INPUT | ENABLE_PROCESSED_INPUT);
    DWORD out = modeSortie | ENABLE_VIRTUAL_TERMINAL_PROCESSING | ENABLE_PROCESSED_OUTPUT;
    if (!SetConsoleMode(entree, in)) return false;
    if (!SetConsoleMode(sortie, out)) {
        SetConsoleMode(entree, modeEntree);
        return false;
    }
    brut = true;
    return true;
}

void LecteurLignes::Etat::revenir() {
    if (!brut) return;
    SetConsoleMode(entree, modeEntree);
    SetConsoleMode(sortie, modeSortie);
    brut = false;
}

int LecteurLignes::Etat::lireOctet(unsigned char& c, int delai) {
    if (!octetsEnAttente.empty()) {
        c = (unsigned char)octetsEnAttente.front();
        octetsEnAttente.erase(0, 1);
        return 1;
    }
    if (delai >= 0 && WaitForSingleObject(entree, (DWORD)delai) != WAIT_OBJECT_0) return -1;
    for (;;) {
        wchar_t w = 0;
        DWORD lus = 0;
        if (!ReadConsoleW(entree, &w, 1, &lus, nullptr) || lus == 0) return 0;
        char32_t point;
        if (w >= 0xD800 && w <= 0xDBFF) {      // première moitié d'une paire
            demiPaire = w;
            continue;
        }
        if (w >= 0xDC00 && w <= 0xDFFF && demiPaire) {
            point = 0x10000 + (((char32_t)demiPaire - 0xD800) << 10) + (w - 0xDC00);
            demiPaire = 0;
        } else {
            point = w;
        }
        std::string u;
        if (point < 0x80) {
            u += (char)point;
        } else if (point < 0x800) {
            u += (char)(0xC0 | (point >> 6));
            u += (char)(0x80 | (point & 0x3F));
        } else if (point < 0x10000) {
            u += (char)(0xE0 | (point >> 12));
            u += (char)(0x80 | ((point >> 6) & 0x3F));
            u += (char)(0x80 | (point & 0x3F));
        } else {
            u += (char)(0xF0 | (point >> 18));
            u += (char)(0x80 | ((point >> 12) & 0x3F));
            u += (char)(0x80 | ((point >> 6) & 0x3F));
            u += (char)(0x80 | (point & 0x3F));
        }
        c = (unsigned char)u[0];
        octetsEnAttente += u.substr(1);
        return 1;
    }
}

#else

int LecteurLignes::Etat::largeur() const {
    struct winsize w {};
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 && w.ws_col > 0) return w.ws_col;
    return 80;
}

bool LecteurLignes::Etat::passerEnBrut() {
    if (brut) return true;
    if (tcgetattr(STDIN_FILENO, &origine) != 0) return false;
    struct termios t = origine;
    t.c_iflag &= ~(tcflag_t)(BRKINT | ICRNL | INPCK | ISTRIP | IXON);
    t.c_cflag |= CS8;
    // ISIG coupé : Ctrl-C arrive comme un caractère et abandonne la ligne ;
    // il redevient un signal, qui interrompt le calcul, dès qu'on rend la
    // main. OPOST reste : « \n » continue d'aller en début de ligne.
    t.c_lflag &= ~(tcflag_t)(ECHO | ICANON | IEXTEN | ISIG);
    t.c_cc[VMIN] = 1;
    t.c_cc[VTIME] = 0;
    // TCSADRAIN et non TCSAFLUSH : ce qui a été tapé ou collé d'avance ne
    // doit pas être jeté.
    if (tcsetattr(STDIN_FILENO, TCSADRAIN, &t) != 0) return false;
    brut = true;
    return true;
}

void LecteurLignes::Etat::revenir() {
    if (!brut) return;
    tcsetattr(STDIN_FILENO, TCSADRAIN, &origine);
    brut = false;
}

int LecteurLignes::Etat::lireOctet(unsigned char& c, int delai) {
    if (delai >= 0) {
        struct pollfd p {};
        p.fd = STDIN_FILENO;
        p.events = POLLIN;
        int r;
        do {
            r = poll(&p, 1, delai);
        } while (r < 0 && errno == EINTR);
        if (r == 0) return -1;
    }
    for (;;) {
        const ssize_t n = read(STDIN_FILENO, &c, 1);
        if (n == 1) return 1;
        if (n < 0 && errno == EINTR) continue;   // SIGWINCH, par exemple
        return 0;
    }
}

#endif

LecteurLignes::LecteurLignes() : etat_(new Etat) {
    const char* refus = std::getenv("MATLIBRE_EDITION");
    if (refus && std::string(refus) == "0") return;
#ifdef _WIN32
    etat_->entree = GetStdHandle(STD_INPUT_HANDLE);
    etat_->sortie = GetStdHandle(STD_OUTPUT_HANDLE);
    if (!_isatty(_fileno(stdin)) || !_isatty(_fileno(stdout))) return;
    // Essai à blanc : une console trop ancienne pour les séquences VT
    // garde la lecture ligne à ligne.
    if (!etat_->passerEnBrut()) return;
    etat_->revenir();
    etat_->edition = true;
#else
    if (!isatty(STDIN_FILENO) || !isatty(STDOUT_FILENO)) return;
    const char* term = std::getenv("TERM");
    if (term && std::string(term) == "dumb") return;
    etat_->edition = true;
#endif
    etatOuvert = etat_.get();
    std::atexit(remettreTerminal);
}

LecteurLignes::~LecteurLignes() {
    etat_->revenir();
    if (etatOuvert == etat_.get()) etatOuvert = nullptr;
}

bool LecteurLignes::editionPossible() const { return etat_->edition; }

void LecteurLignes::definirCompleteur(EditeurLigne::Completeur c) {
    etat_->editeur.definirCompleteur(std::move(c));
}

LecteurLignes::Resultat LecteurLignes::lire(const std::string& invite, std::string& ligne,
                                            const std::string& texteInitial) {
    Etat& e = *etat_;
    if (!e.edition || !e.passerEnBrut()) {
        if (!invite.empty()) {
            std::cout << invite << std::flush;
        }
        if (!std::getline(std::cin, ligne)) return Resultat::FinFichier;
        if (!ligne.empty() && ligne.back() == '\r') ligne.pop_back();
        return Resultat::Ligne;
    }
    EditeurLigne& ed = e.editeur;
    ed.commencer(invite, texteInitial);
    ecrire(ed.rendu(e.largeur()));
    for (;;) {
        unsigned char c = 0;
        Evenement ev;
        // Après un ESC, on attend un instant la suite : rien ne vient, et
        // c'était la touche Échap.
        const int r = e.lireOctet(c, e.decodeur.enCours() ? 50 : -1);
        if (r == 0) {
            e.revenir();
            ecrire("\r\n");
            return Resultat::FinFichier;
        }
        std::vector<Evenement> evenements;
        if (r < 0) {
            if (e.decodeur.vider(ev)) evenements.push_back(ev);
        } else {
            e.decodeur.pousser(c, evenements);
        }
        for (const Evenement& touche : evenements) {
            const EditeurLigne::Issue issue = ed.traiter(touche);
            switch (issue) {
                case EditeurLigne::Issue::Valider:
                    ligne = ed.ligne();
                    // La ligne entière, curseur au bout, avant de passer à la
                    // suivante : une ligne qui défilait se relit telle quelle.
                    ed.traiter(Evenement{Touche::Fin, std::string()});
                    ecrire(ed.rendu(e.largeur()) + "\r\n");
                    e.revenir();
                    return Resultat::Ligne;
                case EditeurLigne::Issue::Abandonner:
                    ecrire("^C\r\n");
                    e.revenir();
                    ligne.clear();
                    return Resultat::Abandon;
                case EditeurLigne::Issue::Fin:
                    ecrire("\r\n");
                    e.revenir();
                    return Resultat::FinFichier;
                case EditeurLigne::Issue::Continuer:
                    break;
            }
            if (ed.prendreEffacement()) ecrire("\x1B[H\x1B[2J");
            std::vector<std::string> choix = ed.prendreChoix();
            if (!choix.empty()) {
                // En colonnes, sous la ligne, puis la ligne de nouveau.
                const std::size_t max = 200;
                std::size_t large = 0;
                for (const std::string& s : choix) large = std::max(large, colonnes(s));
                large += 2;
                const std::size_t parLigne =
                    std::max<std::size_t>(1, (std::size_t)e.largeur() / large);
                std::string liste = "\r\n";
                const std::size_t n = std::min(choix.size(), max);
                for (std::size_t k = 0; k < n; ++k) {
                    liste += choix[k];
                    const bool finLigne = (k + 1) % parLigne == 0 || k + 1 == n;
                    if (finLigne) liste += "\r\n";
                    else liste += std::string(large - colonnes(choix[k]), ' ');
                }
                if (choix.size() > max)
                    liste += "(" + std::to_string(choix.size() - max) + " de plus)\r\n";
                ecrire(liste);
            }
            ecrire(ed.rendu(e.largeur()));
        }
    }
}

std::string LecteurLignes::cheminHistoriqueParDefaut() {
    if (const char* h = std::getenv("MATLIBRE_HISTORIQUE")) return h;
#ifdef _WIN32
    const char* maison = std::getenv("USERPROFILE");
    const char separateur = '\\';
#else
    const char* maison = std::getenv("HOME");
    const char separateur = '/';
#endif
    if (!maison || !*maison) return std::string();
    std::string chemin = maison;
    if (chemin.back() != '/' && chemin.back() != '\\') chemin += separateur;
    return chemin + ".matlibre_historique";
}

void LecteurLignes::ouvrirHistorique(const std::string& chemin) {
    etat_->fichierHistorique = chemin;
    if (chemin.empty()) return;
    std::ifstream f(chemin);
    if (!f) return;
    std::vector<std::string> lignes;
    std::string l;
    while (std::getline(f, l)) {
        if (!l.empty() && l.back() == '\r') l.pop_back();
        lignes.push_back(l);
    }
    f.close();
    // Le fichier grandit d'une ligne par commande ; on le ramène aux
    // mille dernières quand il en a le double.
    if (lignes.size() > 2 * LIGNES_HISTORIQUE) {
        lignes.erase(lignes.begin(), lignes.end() - LIGNES_HISTORIQUE);
        std::ofstream reecrit(chemin, std::ios::trunc);
        for (const std::string& x : lignes) reecrit << x << '\n';
    }
    etat_->editeur.definirHistorique(std::move(lignes));
}

void LecteurLignes::retenir(const std::string& ligne) {
    EditeurLigne& ed = etat_->editeur;
    const std::size_t avant = ed.historique().size();
    const std::string dernier = avant ? ed.historique().back() : std::string();
    ed.ajouterHistorique(ligne);
    const bool ajoutee = ed.historique().size() != avant ||
                         (!ed.historique().empty() && ed.historique().back() != dernier);
    if (!ajoutee || etat_->fichierHistorique.empty()) return;
#ifdef _WIN32
    std::ofstream f(etat_->fichierHistorique, std::ios::app);
    if (f) f << ligne << '\n';
#else
    // Lisible de son seul propriétaire : une commande peut porter un mot
    // de passe (webread, ftp).
    const int fd = ::open(etat_->fichierHistorique.c_str(), O_WRONLY | O_APPEND | O_CREAT,
                          0600);
    if (fd < 0) return;
    const std::string s = ligne + "\n";
    ssize_t ecrits = ::write(fd, s.data(), s.size());
    (void)ecrits;
    ::close(fd);
#endif
}

}  // namespace matlibre
