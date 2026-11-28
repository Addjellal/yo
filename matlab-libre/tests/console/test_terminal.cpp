// test_terminal.cpp — la console sous un vrai terminal.
//
//   matlibre_tests_terminal <chemin de matlibre> <dossier toolbox>
//
// Les tests en langage passent l'entrée par un tube : l'édition de ligne
// n'y est pas en jeu. Ici, matlibre tourne dans un pseudo-terminal (POSIX,
// sans bibliothèque), et l'on tape comme au clavier : une commande, la
// flèche du haut qui la rappelle, une correction, une complétion par Tab,
// Ctrl-D pour finir. On lit ce que le terminal affiche, et l'historique
// que la session a laissé sur le disque.
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <termios.h>
#include <unistd.h>

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace {

int echecs = 0;
int total = 0;

void verifier(bool condition, const std::string& description) {
    ++total;
    if (!condition) {
        ++echecs;
        std::cout << "  ECHEC : " << description << "\n";
    }
}

int maitre = -1;
std::string sortie;

// Lit ce que le terminal affiche jusqu'à voir MOTIF après la position
// DEPUIS, ou jusqu'au délai. Rend vrai si le motif est venu.
bool attendre(const std::string& motif, std::size_t depuis, int secondes = 20) {
    const auto fin = std::chrono::steady_clock::now() + std::chrono::seconds(secondes);
    while (sortie.find(motif, depuis) == std::string::npos) {
        if (std::chrono::steady_clock::now() > fin) return false;
        struct pollfd p {};
        p.fd = maitre;
        p.events = POLLIN;
        if (poll(&p, 1, 100) <= 0) continue;
        char tampon[4096];
        const ssize_t n = read(maitre, tampon, sizeof tampon);
        if (n <= 0) return sortie.find(motif, depuis) != std::string::npos;
        sortie.append(tampon, (std::size_t)n);
    }
    return true;
}

// Lit ce qui est déjà là, sans attendre : un terminal qu'on ne lit pas
// finit par bloquer le programme qui écrit dedans.
void vider() {
    struct pollfd p {};
    p.fd = maitre;
    p.events = POLLIN;
    while (poll(&p, 1, 0) > 0) {
        char tampon[4096];
        const ssize_t n = read(maitre, tampon, sizeof tampon);
        if (n <= 0) return;
        sortie.append(tampon, (std::size_t)n);
    }
}

void taper(const std::string& octets) {
    ssize_t n = write(maitre, octets.data(), octets.size());
    (void)n;
}

}  // namespace

int main(int argc, char** argv) {
    if (argc < 3) {
        std::cerr << "usage : matlibre_tests_terminal <matlibre> <toolbox>\n";
        return 2;
    }
    char modele[] = "/tmp/matlibre_historique_XXXXXX";
    const int fdHistorique = mkstemp(modele);
    if (fdHistorique < 0) {
        std::perror("mkstemp");
        return 2;
    }
    close(fdHistorique);
    const std::string historique = modele;
    {
        std::ofstream h(historique);
        h << "plot(1:3)\n";   // une session d'avant
    }

    maitre = posix_openpt(O_RDWR | O_NOCTTY);
    if (maitre < 0 || grantpt(maitre) != 0 || unlockpt(maitre) != 0) {
        std::perror("posix_openpt");
        return 2;
    }
    const std::string nomEsclave = ptsname(maitre);
    struct winsize taille {};
    taille.ws_col = 80;
    taille.ws_row = 24;
    ioctl(maitre, TIOCSWINSZ, &taille);

    const pid_t pid = fork();
    if (pid == 0) {
        setsid();
        const int esclave = open(nomEsclave.c_str(), O_RDWR);
        if (esclave < 0) _exit(126);
        ioctl(esclave, TIOCSCTTY, 0);
        dup2(esclave, 0);
        dup2(esclave, 1);
        dup2(esclave, 2);
        if (esclave > 2) close(esclave);
        setenv("MATLIBRE_HISTORIQUE", historique.c_str(), 1);
        setenv("TERM", "xterm", 1);
        unsetenv("MATLIBRE_EDITION");
        execl(argv[1], argv[1], "-q", "--path", argv[2], (char*)nullptr);
        _exit(127);
    }

    std::cout << "[terminal]\n";
    verifier(attendre(">> ", 0), "l'invite paraît");

    // Une commande, puis ↑ qui la rappelle, Retour arrière, une frappe :
    // la commande corrigée s'exécute. Le résultat commence une ligne ; la
    // ligne redessinée, elle, commence par l'invite.
    std::size_t d = sortie.size();
    taper("x = 41\r");
    verifier(attendre("\nx = 41", d), "la commande tapée s'exécute");
    d = sortie.size();
    taper("\x1b[A");
    verifier(attendre(">> x = 41", d), "↑ rappelle la commande");
    taper("\x7f" "2\r");
    verifier(attendre("\nx = 42", d), "rappelée, corrigée, exécutée : x = 42");

    // ↑ filtré par ce qu'on a tapé : « pl » rappelle la session d'avant,
    // relue dans le fichier d'historique. Échap efface la ligne.
    d = sortie.size();
    taper("pl\x1b[A");
    verifier(attendre(">> plot(1:3)", d), "« pl » puis ↑ : la commande d'une session d'avant");
    taper("\x1b");

    // Tab complète le nom de la fonction.
    d = sortie.size();
    taper("y = linspa\t");
    verifier(attendre(">> y = linspace", d), "Tab complète linspa en linspace");
    taper("(0, 1, 3)\r");
    verifier(attendre("0.5000", d), "la ligne complétée s'exécute");

    // Ctrl-C abandonne la ligne ; la session continue.
    d = sortie.size();
    taper("ceci n'est pas exécuté\x03");
    taper("disp(6*7)\r");
    verifier(attendre("42", d), "Ctrl-C abandonne la ligne, la suivante s'exécute");

    // Ctrl-D sur une ligne vide finit la session, code 0.
    taper("\x04");
    int statut = -1;
    const auto fin = std::chrono::steady_clock::now() + std::chrono::seconds(20);
    while (waitpid(pid, &statut, WNOHANG) == 0) {
        if (std::chrono::steady_clock::now() > fin) {
            kill(pid, SIGKILL);
            waitpid(pid, &statut, 0);
            break;
        }
        vider();
        usleep(50000);
    }
    verifier(WIFEXITED(statut) && WEXITSTATUS(statut) == 0, "Ctrl-D finit la session, code 0");

    std::ifstream h(historique);
    std::stringstream lu;
    lu << h.rdbuf();
    const std::string texte = lu.str();
    verifier(texte.find("x = 41\nx = 42\n") != std::string::npos,
             "l'historique garde les commandes, dans l'ordre");
    verifier(texte.find("y = linspace(0, 1, 3)\n") != std::string::npos,
             "l'historique garde la ligne telle qu'exécutée, complétée");
    verifier(texte.find("pas exécuté") == std::string::npos,
             "une ligne abandonnée n'entre pas dans l'historique");
    std::remove(historique.c_str());

    if (echecs) {
        std::cout << "--- ce que le terminal a affiché ---\n";
        for (char c : sortie) {
            if (c == '\x1b') std::cout << "<ESC>";
            else if (c == '\r') std::cout << "<CR>";
            else std::cout << c;
        }
        std::cout << "\n";
    }
    std::cout << "\n" << (total - echecs) << " / " << total << " verifications passees\n";
    return echecs == 0 ? 0 : 1;
}
