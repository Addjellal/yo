#include "matlibre/Graphique.h"

#include <algorithm>
#include <cmath>
#include <climits>
#include <cstdlib>
#include <fstream>
#include <memory>
#include <sstream>

#include "matlibre/Erreur.h"
#include "matlibre/Interpreteur.h"

namespace matlibre {

std::shared_ptr<Axes> ajouterAxes(Figure& f) {
    auto a = std::make_shared<Axes>();
    a->identifiant = f.prochainIdentifiant++;
    f.axes.push_back(a);
    return a;
}

std::shared_ptr<Figure> figureCourante(Interpreteur& it) {
    if (it.figureCourante == 0 || !it.figures.count(it.figureCourante)) {
        int numero = it.figureCourante ? it.figureCourante : 1;
        while (it.figures.count(numero)) ++numero;
        auto f = std::make_shared<Figure>();
        f->numero = numero;
        ajouterAxes(*f);
        it.figures[numero] = f;
        it.figureCourante = numero;
    }
    return it.figures[it.figureCourante];
}

std::shared_ptr<Axes> axesCourants(Interpreteur& it) {
    auto f = figureCourante(it);
    if (f->axes.empty()) ajouterAxes(*f);
    if (f->axeCourant >= (int)f->axes.size()) f->axeCourant = 0;
    return f->axes[(std::size_t)f->axeCourant];
}

// --------------------------------------------------------------- rendu SVG

namespace {

std::string echapperXml(const std::string& s) {
    std::string r;
    for (char c : s) {
        switch (c) {
            case '<': r += "&lt;"; break;
            case '>': r += "&gt;"; break;
            case '&': r += "&amp;"; break;
            case '"': r += "&quot;"; break;
            default: r += c; break;
        }
    }
    return r;
}

struct Echelle {
    double min = 0, max = 1;
    int pixelsMin = 0, pixelsMax = 100;
    bool log = false;
    double versPixel(double v) const {
        double a = log ? std::log10(std::max(v, 1e-300)) : v;
        double lo = log ? std::log10(std::max(min, 1e-300)) : min;
        double hi = log ? std::log10(std::max(max, 1e-300)) : max;
        if (hi == lo) return (pixelsMin + pixelsMax) / 2.0;
        return pixelsMin + (a - lo) / (hi - lo) * (pixelsMax - pixelsMin);
    }
};

}  // namespace

std::vector<std::size_t> indicesVisibles(const std::vector<double>& x,
                                         const std::vector<double>& y, double xmin,
                                         double xmax, int colonnes, bool logX) {
    std::size_t n = std::min(x.size(), y.size());
    std::vector<std::size_t> gardes;
    // Sur un axe logarithmique, les colonnes de l'ecran sont egales en
    // decades : c'est le logarithme de x qui se repartit.
    if (logX) {
        if (xmin > 0 && xmax > 0) {
            xmin = std::log10(xmin);
            xmax = std::log10(xmax);
        } else {
            logX = false;
        }
    }
    // En dessous de quatre points par colonne il n'y a rien a gagner, et le
    // trace garde exactement les points d'origine.
    if (colonnes < 2 || n <= (std::size_t)colonnes * 4 || !(xmax > xmin)) {
        gardes.reserve(n);
        for (std::size_t k = 0; k < n; ++k) gardes.push_back(k);
        return gardes;
    }
    gardes.reserve((std::size_t)colonnes * 4 + 8);
    std::size_t k = 0;
    long long colonneCourante = LLONG_MIN;
    std::size_t premier = 0, dernier = 0, bas = 0, haut = 0;
    bool ouverte = false;
    auto fermer = [&]() {
        if (!ouverte) return;
        // Premier, minimum, maximum, dernier — dans l'ordre des indices, et
        // sans doublon : c'est ce qui rend l'enveloppe a l'identique.
        std::size_t quatre[4] = {premier, bas, haut, dernier};
        std::sort(quatre, quatre + 4);
        for (int i = 0; i < 4; ++i)
            if (i == 0 || quatre[i] != quatre[i - 1]) gardes.push_back(quatre[i]);
        ouverte = false;
    };
    for (; k < n; ++k) {
        if (!std::isfinite(x[k]) || !std::isfinite(y[k])) {
            // Une coupure separe deux morceaux : elle se garde telle quelle.
            fermer();
            gardes.push_back(k);
            colonneCourante = LLONG_MIN;
            continue;
        }
        // un x negatif ou nul n'a pas de place sur un axe logarithmique :
        // il forme sa propre colonne, a gauche de toutes
        double abscisse = x[k];
        if (logX) abscisse = abscisse > 0 ? std::log10(abscisse) : xmin - (xmax - xmin);
        long long colonne =
            (long long)((abscisse - xmin) / (xmax - xmin) * (double)colonnes);
        if (!ouverte || colonne != colonneCourante) {
            fermer();
            colonneCourante = colonne;
            premier = dernier = bas = haut = k;
            ouverte = true;
            continue;
        }
        dernier = k;
        if (y[k] < y[bas]) bas = k;
        if (y[k] > y[haut]) haut = k;
    }
    fermer();
    return gardes;
}

namespace {

std::vector<double> graduations(double min, double max, int cible) {
    std::vector<double> t;
    if (!std::isfinite(min) || !std::isfinite(max) || max <= min) {
        t.push_back(min);
        t.push_back(max);
        return t;
    }
    double brut = (max - min) / std::max(1, cible);
    double magnitude = std::pow(10.0, std::floor(std::log10(brut)));
    double normalise = brut / magnitude;
    double pas = magnitude * (normalise < 1.5 ? 1 : normalise < 3 ? 2 : normalise < 7 ? 5 : 10);
    // Des multiples entiers du pas, non une somme de pas : -0,4 + 4 x 0,1
    // donnait -2,78e-17, et l'axe l'écrivait au lieu de 0.
    long long premier = (long long)std::ceil(min / pas - 1e-9);
    long long dernier = (long long)std::floor(max / pas + 1e-9);
    for (long long k = premier; k <= dernier; ++k) {
        double v = (double)k * pas;
        t.push_back(k == 0 ? 0.0 : v);
    }
    return t;
}

std::string nombreCourt(double v) {
    if (v == 0) return "0";
    double a = std::fabs(v);
    if (a >= 1e5 || a < 1e-3) return formater("%.3g", v);
    std::string s = formater("%.6g", v);
    return s;
}

// Le motif d'un trait : ce que le SVG appelle « stroke-dasharray ».
std::string motifTrait(const std::string& style) {
    if (style == "--") return " stroke-dasharray=\"8,4\"";
    if (style == ":") return " stroke-dasharray=\"2,3\"";
    if (style == "-.") return " stroke-dasharray=\"8,3,2,3\"";
    return std::string();
}

// L'etiquette d'une graduation. Sur un axe logarithmique, MATLAB ecrit les
// puissances de dix en exposant — 10 puissance moins deux, et non 0,01 ;
// le SVG le rend avec un « tspan » releve.
// La chasse d'un texte en Helvetica (Arial et Liberation Sans ont les
// mêmes), d'après les métriques AFM : de quoi dimensionner une légende
// sans couper son texte.
double largeurTexte(const std::string& texte, double police) {
    static const int chasses[95] = {
        278, 278, 355, 556, 556, 889, 667, 191, 333, 333, 389, 584, 278, 333, 278, 278,
        556, 556, 556, 556, 556, 556, 556, 556, 556, 556, 278, 278, 584, 584, 584, 556,
        1015, 667, 667, 722, 722, 667, 611, 778, 722, 278, 500, 667, 556, 833, 722, 778,
        667, 778, 722, 667, 611, 722, 667, 944, 667, 667, 611, 278, 278, 278, 469, 556,
        333, 556, 556, 500, 556, 556, 278, 556, 556, 222, 222, 500, 222, 833, 556, 556,
        556, 556, 333, 500, 278, 556, 500, 722, 500, 500, 500, 334, 260, 334, 584};
    double milliemes = 0;
    for (std::size_t i = 0; i < texte.size(); ++i) {
        unsigned char c = (unsigned char)texte[i];
        if ((c & 0xC0) == 0x80) continue;  // suite d'un caractère UTF-8
        milliemes += (c >= 32 && c < 127) ? chasses[c - 32] : 556;
    }
    return milliemes / 1000.0 * police;
}

// Un marqueur de MATLAB en SVG. BORD et FACE sont des couleurs SVG, FACE
// pouvant valoir « none ».
void ecrireMarqueur(std::ostream& out, const FormeMarqueur& f, double px, double py,
                    const std::string& bord, const std::string& face) {
    switch (f.genre) {
        case FormeMarqueur::Rien:
            return;
        case FormeMarqueur::Cercle:
            out << "<circle cx=\"" << formater("%.2f", px) << "\" cy=\"" << formater("%.2f", py)
                << "\" r=\"" << formater("%.2f", f.rayon) << "\" fill=\""
                << (f.toujoursPlein ? bord : face) << "\" stroke=\"" << bord << "\"/>\n";
            return;
        case FormeMarqueur::Polygone: {
            out << "<path d=\"";
            for (std::size_t k = 0; k < f.points.size(); ++k)
                out << (k ? " L " : "M ") << formater("%.2f", px + f.points[k].first) << " "
                    << formater("%.2f", py + f.points[k].second);
            out << " Z\" fill=\"" << face << "\" stroke=\"" << bord << "\"/>\n";
            return;
        }
        case FormeMarqueur::Traits: {
            out << "<path d=\"";
            for (std::size_t k = 0; k + 1 < f.points.size(); k += 2)
                out << "M " << formater("%.2f", px + f.points[k].first) << " "
                    << formater("%.2f", py + f.points[k].second) << " L "
                    << formater("%.2f", px + f.points[k + 1].first) << " "
                    << formater("%.2f", py + f.points[k + 1].second) << " ";
            out << "\" stroke=\"" << bord << "\" fill=\"none\"/>\n";
            return;
        }
    }
}

// Les couleurs de bord et de face des marqueurs d'une série.
void couleursMarqueur(const Serie& s, const std::string& couleur, std::string& bord,
                      std::string& face) {
    bord = s.couleurBordMarqueur.empty() || s.couleurBordMarqueur == "auto"
               ? couleur
               : s.couleurBordMarqueur;
    if (s.couleurFaceMarqueur.empty() || s.couleurFaceMarqueur == "none")
        face = "none";
    else if (s.couleurFaceMarqueur == "auto")
        face = couleur;
    else
        face = s.couleurFaceMarqueur;
}

std::string etiquetteGraduation(double v, bool log) {
    if (log && v > 0) {
        double e = std::log10(v);
        double arrondi = std::round(e);
        if (std::fabs(e - arrondi) < 1e-9)
            return "10<tspan baseline-shift=\"super\" font-size=\"9px\">" +
                   formater("%d", (int)arrondi) + "</tspan>";
    }
    return echapperXml(nombreCourt(v));
}

}  // namespace

// « axis square » d'abord — elle change la boite —, puis « axis equal »,
// qui elargit les bornes de l'axe qui a trop de place pour que les deux
// echelles aient le meme nombre d'unites par pixel.
std::vector<double> graduationsAxe(double bas, double haut, int cible, bool log) {
    if (!log) return graduations(bas, haut, cible);
    std::vector<double> valeurs;
    double lo = std::log10(std::max(bas, 1e-300));
    double hi = std::log10(std::max(haut, 1e-300));
    if (!(hi > lo)) return valeurs;
    int premier = (int)std::ceil(lo - 1e-9), dernier = (int)std::floor(hi + 1e-9);
    int decades = dernier - premier + 1;
    if (decades >= 2) {
        // Dix décades sur trois cents pixels : une graduation sur deux, sur
        // trois… mais toujours des puissances de dix.
        int pas = 1;
        while ((decades + pas - 1) / pas > cible + 2) ++pas;
        for (int k = premier; k <= dernier; k += pas) valeurs.push_back(std::pow(10.0, k));
        return valeurs;
    }
    // Moins d'une décade : les 1, 2 et 5 qui tombent dans l'intervalle.
    for (int k = premier - 2; k <= dernier + 1; ++k)
        for (double m : {1.0, 2.0, 5.0}) {
            double v = m * std::pow(10.0, k);
            if (v >= bas * (1 - 1e-9) && v <= haut * (1 + 1e-9)) valeurs.push_back(v);
        }
    std::sort(valeurs.begin(), valeurs.end());
    return valeurs;
}

bool bornesLog(double& bas, double& haut) {
    if (haut <= 0) return false;
    if (bas <= 0) bas = haut / 1000.0;
    if (!(haut > bas)) { bas = haut / 10.0; }
    return true;
}

namespace {
// viridis, 256 couleurs (S. van der Walt et N. Smith, CC0), telles que
// matplotlib les distribue.
const double VIRIDIS[256][3] = {
    {0.267004, 0.004874, 0.329415}, {0.268510, 0.009605, 0.335427},
    {0.269944, 0.014625, 0.341379}, {0.271305, 0.019942, 0.347269},
    {0.272594, 0.025563, 0.353093}, {0.273809, 0.031497, 0.358853},
    {0.274952, 0.037752, 0.364543}, {0.276022, 0.044167, 0.370164},
    {0.277018, 0.050344, 0.375715}, {0.277941, 0.056324, 0.381191},
    {0.278791, 0.062145, 0.386592}, {0.279566, 0.067836, 0.391917},
    {0.280267, 0.073417, 0.397163}, {0.280894, 0.078907, 0.402329},
    {0.281446, 0.084320, 0.407414}, {0.281924, 0.089666, 0.412415},
    {0.282327, 0.094955, 0.417331}, {0.282656, 0.100196, 0.422160},
    {0.282910, 0.105393, 0.426902}, {0.283091, 0.110553, 0.431554},
    {0.283197, 0.115680, 0.436115}, {0.283229, 0.120777, 0.440584},
    {0.283187, 0.125848, 0.444960}, {0.283072, 0.130895, 0.449241},
    {0.282884, 0.135920, 0.453427}, {0.282623, 0.140926, 0.457517},
    {0.282290, 0.145912, 0.461510}, {0.281887, 0.150881, 0.465405},
    {0.281412, 0.155834, 0.469201}, {0.280868, 0.160771, 0.472899},
    {0.280255, 0.165693, 0.476498}, {0.279574, 0.170599, 0.479997},
    {0.278826, 0.175490, 0.483397}, {0.278012, 0.180367, 0.486697},
    {0.277134, 0.185228, 0.489898}, {0.276194, 0.190074, 0.493001},
    {0.275191, 0.194905, 0.496005}, {0.274128, 0.199721, 0.498911},
    {0.273006, 0.204520, 0.501721}, {0.271828, 0.209303, 0.504434},
    {0.270595, 0.214069, 0.507052}, {0.269308, 0.218818, 0.509577},
    {0.267968, 0.223549, 0.512008}, {0.266580, 0.228262, 0.514349},
    {0.265145, 0.232956, 0.516599}, {0.263663, 0.237631, 0.518762},
    {0.262138, 0.242286, 0.520837}, {0.260571, 0.246922, 0.522828},
    {0.258965, 0.251537, 0.524736}, {0.257322, 0.256130, 0.526563},
    {0.255645, 0.260703, 0.528312}, {0.253935, 0.265254, 0.529983},
    {0.252194, 0.269783, 0.531579}, {0.250425, 0.274290, 0.533103},
    {0.248629, 0.278775, 0.534556}, {0.246811, 0.283237, 0.535941},
    {0.244972, 0.287675, 0.537260}, {0.243113, 0.292092, 0.538516},
    {0.241237, 0.296485, 0.539709}, {0.239346, 0.300855, 0.540844},
    {0.237441, 0.305202, 0.541921}, {0.235526, 0.309527, 0.542944},
    {0.233603, 0.313828, 0.543914}, {0.231674, 0.318106, 0.544834},
    {0.229739, 0.322361, 0.545706}, {0.227802, 0.326594, 0.546532},
    {0.225863, 0.330805, 0.547314}, {0.223925, 0.334994, 0.548053},
    {0.221989, 0.339161, 0.548752}, {0.220057, 0.343307, 0.549413},
    {0.218130, 0.347432, 0.550038}, {0.216210, 0.351535, 0.550627},
    {0.214298, 0.355619, 0.551184}, {0.212395, 0.359683, 0.551710},
    {0.210503, 0.363727, 0.552206}, {0.208623, 0.367752, 0.552675},
    {0.206756, 0.371758, 0.553117}, {0.204903, 0.375746, 0.553533},
    {0.203063, 0.379716, 0.553925}, {0.201239, 0.383670, 0.554294},
    {0.199430, 0.387607, 0.554642}, {0.197636, 0.391528, 0.554969},
    {0.195860, 0.395433, 0.555276}, {0.194100, 0.399323, 0.555565},
    {0.192357, 0.403199, 0.555836}, {0.190631, 0.407061, 0.556089},
    {0.188923, 0.410910, 0.556326}, {0.187231, 0.414746, 0.556547},
    {0.185556, 0.418570, 0.556753}, {0.183898, 0.422383, 0.556944},
    {0.182256, 0.426184, 0.557120}, {0.180629, 0.429975, 0.557282},
    {0.179019, 0.433756, 0.557430}, {0.177423, 0.437527, 0.557565},
    {0.175841, 0.441290, 0.557685}, {0.174274, 0.445044, 0.557792},
    {0.172719, 0.448791, 0.557885}, {0.171176, 0.452530, 0.557965},
    {0.169646, 0.456262, 0.558030}, {0.168126, 0.459988, 0.558082},
    {0.166617, 0.463708, 0.558119}, {0.165117, 0.467423, 0.558141},
    {0.163625, 0.471133, 0.558148}, {0.162142, 0.474838, 0.558140},
    {0.160665, 0.478540, 0.558115}, {0.159194, 0.482237, 0.558073},
    {0.157729, 0.485932, 0.558013}, {0.156270, 0.489624, 0.557936},
    {0.154815, 0.493313, 0.557840}, {0.153364, 0.497000, 0.557724},
    {0.151918, 0.500685, 0.557587}, {0.150476, 0.504369, 0.557430},
    {0.149039, 0.508051, 0.557250}, {0.147607, 0.511733, 0.557049},
    {0.146180, 0.515413, 0.556823}, {0.144759, 0.519093, 0.556572},
    {0.143343, 0.522773, 0.556295}, {0.141935, 0.526453, 0.555991},
    {0.140536, 0.530132, 0.555659}, {0.139147, 0.533812, 0.555298},
    {0.137770, 0.537492, 0.554906}, {0.136408, 0.541173, 0.554483},
    {0.135066, 0.544853, 0.554029}, {0.133743, 0.548535, 0.553541},
    {0.132444, 0.552216, 0.553018}, {0.131172, 0.555899, 0.552459},
    {0.129933, 0.559582, 0.551864}, {0.128729, 0.563265, 0.551229},
    {0.127568, 0.566949, 0.550556}, {0.126453, 0.570633, 0.549841},
    {0.125394, 0.574318, 0.549086}, {0.124395, 0.578002, 0.548287},
    {0.123463, 0.581687, 0.547445}, {0.122606, 0.585371, 0.546557},
    {0.121831, 0.589055, 0.545623}, {0.121148, 0.592739, 0.544641},
    {0.120565, 0.596422, 0.543611}, {0.120092, 0.600104, 0.542530},
    {0.119738, 0.603785, 0.541400}, {0.119512, 0.607464, 0.540218},
    {0.119423, 0.611141, 0.538982}, {0.119483, 0.614817, 0.537692},
    {0.119699, 0.618490, 0.536347}, {0.120081, 0.622161, 0.534946},
    {0.120638, 0.625828, 0.533488}, {0.121380, 0.629492, 0.531973},
    {0.122312, 0.633153, 0.530398}, {0.123444, 0.636809, 0.528763},
    {0.124780, 0.640461, 0.527068}, {0.126326, 0.644107, 0.525311},
    {0.128087, 0.647749, 0.523491}, {0.130067, 0.651384, 0.521608},
    {0.132268, 0.655014, 0.519661}, {0.134692, 0.658636, 0.517649},
    {0.137339, 0.662252, 0.515571}, {0.140210, 0.665859, 0.513427},
    {0.143303, 0.669459, 0.511215}, {0.146616, 0.673050, 0.508936},
    {0.150148, 0.676631, 0.506589}, {0.153894, 0.680203, 0.504172},
    {0.157851, 0.683765, 0.501686}, {0.162016, 0.687316, 0.499129},
    {0.166383, 0.690856, 0.496502}, {0.170948, 0.694384, 0.493803},
    {0.175707, 0.697900, 0.491033}, {0.180653, 0.701402, 0.488189},
    {0.185783, 0.704891, 0.485273}, {0.191090, 0.708366, 0.482284},
    {0.196571, 0.711827, 0.479221}, {0.202219, 0.715272, 0.476084},
    {0.208030, 0.718701, 0.472873}, {0.214000, 0.722114, 0.469588},
    {0.220124, 0.725509, 0.466226}, {0.226397, 0.728888, 0.462789},
    {0.232815, 0.732247, 0.459277}, {0.239374, 0.735588, 0.455688},
    {0.246070, 0.738910, 0.452024}, {0.252899, 0.742211, 0.448284},
    {0.259857, 0.745492, 0.444467}, {0.266941, 0.748751, 0.440573},
    {0.274149, 0.751988, 0.436601}, {0.281477, 0.755203, 0.432552},
    {0.288921, 0.758394, 0.428426}, {0.296479, 0.761561, 0.424223},
    {0.304148, 0.764704, 0.419943}, {0.311925, 0.767822, 0.415586},
    {0.319809, 0.770914, 0.411152}, {0.327796, 0.773980, 0.406640},
    {0.335885, 0.777018, 0.402049}, {0.344074, 0.780029, 0.397381},
    {0.352360, 0.783011, 0.392636}, {0.360741, 0.785964, 0.387814},
    {0.369214, 0.788888, 0.382914}, {0.377779, 0.791781, 0.377939},
    {0.386433, 0.794644, 0.372886}, {0.395174, 0.797475, 0.367757},
    {0.404001, 0.800275, 0.362552}, {0.412913, 0.803041, 0.357269},
    {0.421908, 0.805774, 0.351910}, {0.430983, 0.808473, 0.346476},
    {0.440137, 0.811138, 0.340967}, {0.449368, 0.813768, 0.335384},
    {0.458674, 0.816363, 0.329727}, {0.468053, 0.818921, 0.323998},
    {0.477504, 0.821444, 0.318195}, {0.487026, 0.823929, 0.312321},
    {0.496615, 0.826376, 0.306377}, {0.506271, 0.828786, 0.300362},
    {0.515992, 0.831158, 0.294279}, {0.525776, 0.833491, 0.288127},
    {0.535621, 0.835785, 0.281908}, {0.545524, 0.838039, 0.275626},
    {0.555484, 0.840254, 0.269281}, {0.565498, 0.842430, 0.262877},
    {0.575563, 0.844566, 0.256415}, {0.585678, 0.846661, 0.249897},
    {0.595839, 0.848717, 0.243329}, {0.606045, 0.850733, 0.236712},
    {0.616293, 0.852709, 0.230052}, {0.626579, 0.854645, 0.223353},
    {0.636902, 0.856542, 0.216620}, {0.647257, 0.858400, 0.209861},
    {0.657642, 0.860219, 0.203082}, {0.668054, 0.861999, 0.196293},
    {0.678489, 0.863742, 0.189503}, {0.688944, 0.865448, 0.182725},
    {0.699415, 0.867117, 0.175971}, {0.709898, 0.868751, 0.169257},
    {0.720391, 0.870350, 0.162603}, {0.730889, 0.871916, 0.156029},
    {0.741388, 0.873449, 0.149561}, {0.751884, 0.874951, 0.143228},
    {0.762373, 0.876424, 0.137064}, {0.772852, 0.877868, 0.131109},
    {0.783315, 0.879285, 0.125405}, {0.793760, 0.880678, 0.120005},
    {0.804182, 0.882046, 0.114965}, {0.814576, 0.883393, 0.110347},
    {0.824940, 0.884720, 0.106217}, {0.835270, 0.886029, 0.102646},
    {0.845561, 0.887322, 0.099702}, {0.855810, 0.888601, 0.097452},
    {0.866013, 0.889868, 0.095953}, {0.876168, 0.891125, 0.095250},
    {0.886271, 0.892374, 0.095374}, {0.896320, 0.893616, 0.096335},
    {0.906311, 0.894855, 0.098125}, {0.916242, 0.896091, 0.100717},
    {0.926106, 0.897330, 0.104071}, {0.935904, 0.898570, 0.108131},
    {0.945636, 0.899815, 0.112838}, {0.955300, 0.901065, 0.118128},
    {0.964894, 0.902323, 0.123941}, {0.974417, 0.903590, 0.130215},
    {0.983868, 0.904867, 0.136897}, {0.993248, 0.906157, 0.143936}
};

}  // namespace

const std::vector<double>& paletteParDefaut() {
    static const std::vector<double> palette = [] {
        std::vector<double> p;
        p.reserve(256 * 3);
        for (const auto& c : VIRIDIS) p.insert(p.end(), {c[0], c[1], c[2]});
        return p;
    }();
    return palette;
}

const std::vector<double>& paletteEnVigueur(const Figure& f, const Axes& a) {
    if (a.palette.size() >= 3) return a.palette;
    if (f.palette.size() >= 3) return f.palette;
    return paletteParDefaut();
}

void couleurCarte(double t, int& r, int& v, int& b) {
    couleurEchelle(paletteParDefaut(), t, 0.0, 1.0, r, v, b);
}

namespace {

void couleurDeRang(const std::vector<double>& palette, std::size_t rang, int& r, int& v,
                   int& b) {
    auto composante = [](double c) {
        if (!(c >= 0)) c = 0;
        if (c > 1) c = 1;
        return (int)std::lround(c * 255);
    };
    r = composante(palette[3 * rang]);
    v = composante(palette[3 * rang + 1]);
    b = composante(palette[3 * rang + 2]);
}

}  // namespace

void couleurEchelle(const std::vector<double>& palette, double valeur, double cmin,
                    double cmax, int& r, int& v, int& b) {
    const std::size_t m = palette.size() / 3;
    if (m == 0) {
        r = v = b = 0;
        return;
    }
    std::size_t rang = 0;
    if (std::isnan(valeur)) {
        rang = 0;
    } else if (!(cmax > cmin)) {
        rang = m / 2;
    } else {
        double t = std::floor((valeur - cmin) / (cmax - cmin) * (double)m);
        if (t < 0) t = 0;
        if (t > (double)(m - 1)) t = (double)(m - 1);
        rang = (std::size_t)t;
    }
    couleurDeRang(palette, rang, r, v, b);
}

void couleurPixelImage(const std::vector<double>& palette, const Serie& s, std::size_t k,
                       double cmin, double cmax, int& r, int& v, int& b) {
    const std::size_t n = (std::size_t)s.hauteurImage * (std::size_t)s.largeurImage;
    if (s.imageRvb && s.z.size() >= 3 * n) {
        auto composante = [](double c) {
            if (!(c >= 0)) c = 0;
            if (c > 1) c = 1;
            return (int)std::lround(c * 255);
        };
        r = composante(s.z[k]);
        v = composante(s.z[k + n]);
        b = composante(s.z[k + 2 * n]);
        return;
    }
    double valeur = k < s.z.size() ? s.z[k] : NAN;
    if (s.imageDirecte) {
        const std::size_t m = palette.size() / 3;
        if (m == 0) {
            r = v = b = 0;
            return;
        }
        double rang = std::isnan(valeur) ? 0 : std::floor(s.imageEntiere ? valeur : valeur - 1);
        if (rang < 0) rang = 0;
        if (rang > (double)(m - 1)) rang = (double)(m - 1);
        couleurDeRang(palette, (std::size_t)rang, r, v, b);
        return;
    }
    couleurEchelle(palette, valeur, cmin, cmax, r, v, b);
}

void limitesCouleur(const Axes& a, double& cmin, double& cmax) {
    if (a.climManuelle) {
        cmin = a.cmin;
        cmax = a.cmax;
        return;
    }
    cmin = INFINITY;
    cmax = -INFINITY;
    auto prendre = [&](double x) {
        if (!std::isfinite(x)) return;
        cmin = std::min(cmin, x);
        cmax = std::max(cmax, x);
    };
    for (const auto& s : a.series) {
        if (s.genre == GenreTrace::Image && !s.imageRvb && !s.imageDirecte)
            for (double x : s.z) prendre(x);
        if (s.couleurIndexee) {
            prendre(s.valeurCouleur);
            prendre(s.cBas);
            prendre(s.cHaut);
        }
    }
    if (!std::isfinite(cmin)) {
        cmin = 0;
        cmax = 1;
    } else if (!(cmax > cmin)) {
        cmin -= 0.5;
        cmax += 0.5;
    }
}

std::string couleurDeSerie(const Figure& f, const Axes& a, const Serie& s) {
    if (!s.couleurIndexee) return s.couleur;
    double cmin, cmax;
    limitesCouleur(a, cmin, cmax);
    int r, v, b;
    couleurEchelle(paletteEnVigueur(f, a), s.valeurCouleur, cmin, cmax, r, v, b);
    return formater("#%02X%02X%02X", r, v, b);
}

std::vector<EntreeLegende> entreesLegende(const Axes& a) {
    std::vector<std::size_t> candidates;
    if (!a.seriesLegende.empty()) {
        for (int identifiant : a.seriesLegende)
            for (std::size_t k = 0; k < a.series.size(); ++k)
                if (a.series[k].identifiant == identifiant) candidates.push_back(k);
    } else {
        for (std::size_t k = 0; k < a.series.size(); ++k) {
            const Serie& s = a.series[k];
            if (s.genre == GenreTrace::Texte || s.genre == GenreTrace::Image || s.horsLegende)
                continue;
            candidates.push_back(k);
        }
    }
    std::vector<EntreeLegende> entrees;
    if (!a.legende.empty()) {
        std::size_t n = std::min(a.legende.size(), candidates.size());
        for (std::size_t i = 0; i < n; ++i) entrees.push_back({candidates[i], a.legende[i]});
        return entrees;
    }
    for (std::size_t i = 0; i < candidates.size(); ++i) {
        const Serie& s = a.series[candidates[i]];
        entrees.push_back({candidates[i],
                           s.etiquette.empty() ? "data" + std::to_string(i + 1) : s.etiquette});
    }
    return entrees;
}

FormeMarqueur formeMarqueur(const std::string& marqueur, double taille) {
    FormeMarqueur f;
    // Une taille en points, rendue en pixels à 96 points par pouce : le
    // demi-côté d'un marqueur de taille 6 fait 4 pixels.
    const double h = std::max(1.0, taille) * (96.0 / 72.0) / 2.0;
    const double pi = 3.14159265358979323846;
    std::string m = marqueur;
    for (auto& c : m) c = (char)std::tolower((unsigned char)c);
    if (m.empty() || m == "none") return f;
    if (m == "o" || m == "circle") {
        f.genre = FormeMarqueur::Cercle;
        f.rayon = h;
    } else if (m == ".") {
        f.genre = FormeMarqueur::Cercle;
        f.rayon = std::max(1.0, h / 3.0);
        f.toujoursPlein = true;
    } else if (m == "+") {
        f.genre = FormeMarqueur::Traits;
        f.points = {{-h, 0}, {h, 0}, {0, -h}, {0, h}};
    } else if (m == "x") {
        double d = h * 0.75;
        f.genre = FormeMarqueur::Traits;
        f.points = {{-d, -d}, {d, d}, {-d, d}, {d, -d}};
    } else if (m == "*") {
        double d = h * 0.71;
        f.genre = FormeMarqueur::Traits;
        f.points = {{-h, 0}, {h, 0}, {0, -h}, {0, h}, {-d, -d}, {d, d}, {-d, d}, {d, -d}};
    } else if (m == "s" || m == "square") {
        double d = h * 0.9;
        f.genre = FormeMarqueur::Polygone;
        f.points = {{-d, -d}, {d, -d}, {d, d}, {-d, d}};
    } else if (m == "d" || m == "diamond") {
        double d = h * 1.1;
        f.genre = FormeMarqueur::Polygone;
        f.points = {{0, -d}, {d * 0.8, 0}, {0, d}, {-d * 0.8, 0}};
    } else if (m == "^" || m == "v" || m == ">" || m == "<") {
        // Le triangle pointe vers le haut, puis on le tourne. L'écran a
        // l'ordonnée vers le bas : « ^ » a sa pointe à y négatif.
        double d = h * 1.1;
        std::vector<std::pair<double, double>> pointe = {{0, -d}, {d * 0.87, d * 0.5},
                                                         {-d * 0.87, d * 0.5}};
        for (auto& p : pointe) {
            double x = p.first, y = p.second;
            if (m == "v") p = {x, -y};
            else if (m == ">") p = {-y, x};
            else if (m == "<") p = {y, x};
        }
        f.genre = FormeMarqueur::Polygone;
        f.points = pointe;
    } else if (m == "p" || m == "pentagram" || m == "h" || m == "hexagram") {
        int branches = (m == "p" || m == "pentagram") ? 5 : 6;
        double exterieur = h * 1.25, interieur = exterieur * (branches == 5 ? 0.4 : 0.55);
        f.genre = FormeMarqueur::Polygone;
        for (int k = 0; k < 2 * branches; ++k) {
            double rayon = k % 2 == 0 ? exterieur : interieur;
            double angle = -pi / 2 + k * pi / branches;
            f.points.push_back({rayon * std::cos(angle), rayon * std::sin(angle)});
        }
    } else {
        // Un marqueur que MATLAB ne connaît pas : un point plein, visible.
        f.genre = FormeMarqueur::Cercle;
        f.rayon = std::max(1.0, h / 2.0);
        f.toujoursPlein = true;
    }
    return f;
}

namespace {

// Les bornes automatiques de MATLAB tombent sur des graduations : les
// données de -3,2 à 3,8 donnent un axe de -4 à 4, et un marqueur posé au
// bord n'est pas coupé.
void arrondirAuxGraduations(double& bas, double& haut) {
    if (!std::isfinite(bas) || !std::isfinite(haut) || !(haut > bas)) return;
    // Le pas des graduations dépend de la plage, et la plage arrondie peut
    // en appeler un autre : de 0 à 17, un pas de 2 donne 18, sur lequel on
    // graduerait de 5 en 5 sans tomber sur la borne. On recommence avec le
    // pas de la plage arrondie jusqu'à ce qu'il ne change plus : 0 à 20.
    const double donneesBas = bas, donneesHaut = haut;
    double pas = 0;
    for (int essai = 0; essai < 4; ++essai) {
        std::vector<double> t = graduations(bas, haut, 6);
        if (t.size() < 2) return;
        double nouveau = t[1] - t[0];
        if (!(nouveau > 0)) return;
        if (nouveau == pas) break;
        pas = nouveau;
        double b = std::floor(donneesBas / pas + 1e-9) * pas;
        double h = std::ceil(donneesHaut / pas - 1e-9) * pas;
        bas = b == 0 ? 0.0 : b;
        haut = h == 0 ? 0.0 : h;
    }
}

void arrondirAuxDecades(double& bas, double& haut) {
    if (!(bas > 0) || !(haut > bas)) return;
    bas = std::pow(10.0, std::floor(std::log10(bas) + 1e-9));
    haut = std::pow(10.0, std::ceil(std::log10(haut) - 1e-9));
}

}  // namespace

void limitesAxe(const Axes& a, double& xmin, double& xmax, double& ymin, double& ymax) {
    etendueDonnees(a, xmin, xmax, ymin, ymax);
    // Une image serre l'axe sur son étendue, comme dans MATLAB ; sinon les
    // bornes tombent sur des graduations, ou des décades.
    bool image = false;
    for (const auto& s : a.series)
        if (s.genre == GenreTrace::Image) image = true;
    if (!image) {
        if (a.logX) arrondirAuxDecades(xmin, xmax);
        else arrondirAuxGraduations(xmin, xmax);
        if (a.logY) arrondirAuxDecades(ymin, ymax);
        else arrondirAuxGraduations(ymin, ymax);
    }
    if (a.limitesManuellesX) { xmin = a.xmin; xmax = a.xmax; }
    if (a.limitesManuellesY) { ymin = a.ymin; ymax = a.ymax; }
}
// L'écart des barres d'une série : le plus petit écart entre deux
// abscisses distinctes, ou 1 pour une barre seule — MATLAB fait de même.
double ecartBarres(const std::vector<double>& x) {
    std::vector<double> tri;
    for (double v : x)
        if (std::isfinite(v)) tri.push_back(v);
    std::sort(tri.begin(), tri.end());
    double ecart = INFINITY;
    for (std::size_t i = 1; i < tri.size(); ++i)
        if (tri[i] > tri[i - 1]) ecart = std::min(ecart, tri[i] - tri[i - 1]);
    return std::isfinite(ecart) ? ecart : 1.0;
}


void etendueDonnees(const Axes& a, double& xmin, double& xmax, double& ymin, double& ymax) {
    // Sur un axe logarithmique, seules les valeurs positives comptent.
    auto etendue = [&](bool enX, bool positives, double& bas, double& haut) {
        bas = INFINITY;
        haut = -INFINITY;
        for (const auto& s : a.series) {
            if (s.genre == GenreTrace::Constante || s.genre == GenreTrace::Texte) continue;
            const std::vector<double>& valeurs = enX ? s.x : s.y;
            double demi = 0;
            // Des barres débordent de leur abscisse d'une demi-largeur.
            if (enX && s.genre == GenreTrace::Barres)
                demi = s.largeurBarre / 2 * ecartBarres(s.x);
            // Des barres empilées partent de leur pied, non de zéro.
            if (!enX && s.genre == GenreTrace::Barres)
                for (double v : s.basesBarres) {
                    if (!std::isfinite(v) || (positives && v <= 0)) continue;
                    bas = std::min(bas, v);
                    haut = std::max(haut, v);
                }
            for (double v : valeurs) {
                if (!std::isfinite(v) || (positives && v <= 0)) continue;
                bas = std::min(bas, v - demi);
                haut = std::max(haut, v + demi);
            }
        }
    };
    etendue(true, a.logX, xmin, xmax);
    etendue(false, a.logY, ymin, ymax);
    if (!std::isfinite(xmin)) etendue(true, false, xmin, xmax);
    if (!std::isfinite(ymin)) etendue(false, false, ymin, ymax);
    if (!std::isfinite(xmin)) { xmin = 0; xmax = 1; }
    if (!std::isfinite(ymin)) { ymin = 0; ymax = 1; }
    if (!(xmax > xmin)) { xmin -= 0.5; xmax += 0.5; }
    if (!(ymax > ymin)) { ymin -= 0.5; ymax += 0.5; }
}

void cadreAxes(const Axes& a, double& x, double& y, double& largeur, double& hauteur) {
    if (a.positionManuelle) {
        x = a.posGauche;
        largeur = a.posLargeur;
        hauteur = a.posHauteur;
        // MATLAB compte la hauteur depuis le bas ; les deux rendus dessinent
        // depuis le haut.
        y = 1.0 - a.posBas - a.posHauteur;
        return;
    }
    int lignes = std::max(1, a.rangee), colonnes = std::max(1, a.colonne);
    int premiere = std::max(1, a.position);
    int derniere = a.positionFin > 0 ? std::max(premiere, a.positionFin) : premiere;
    int li0 = (premiere - 1) / colonnes, co0 = (premiere - 1) % colonnes;
    int li1 = (derniere - 1) / colonnes, co1 = (derniere - 1) % colonnes;
    if (co1 < co0 && li1 > li0) { co0 = 0; co1 = colonnes - 1; }
    x = (double)co0 / colonnes;
    largeur = (double)(co1 - co0 + 1) / colonnes;
    y = (double)li0 / lignes;
    hauteur = (double)(li1 - li0 + 1) / lignes;
}

bool axesSeRecouvrent(const Axes& a, const Axes& b) {
    double ax, ay, al, ah, bx, by, bl, bh;
    cadreAxes(a, ax, ay, al, ah);
    cadreAxes(b, bx, by, bl, bh);
    const double marge = 1e-6;
    return ax < bx + bl - marge && bx < ax + al - marge && ay < by + bh - marge &&
           by < ay + ah - marge;
}

void appliquerProportions(const Axes& a, int& gauche, int& droite, int& haut, int& bas,
                          double& xmin, double& xmax, double& ymin, double& ymax) {
    if (a.proportions == Axes::Proportions::Auto) return;
    if (a.proportions == Axes::Proportions::Carre) {
        int cote = std::min(droite - gauche, bas - haut);
        int centreX = (gauche + droite) / 2, centreY = (haut + bas) / 2;
        gauche = centreX - cote / 2;
        droite = gauche + cote;
        haut = centreY - cote / 2;
        bas = haut + cote;
        return;
    }
    double largeur = droite - gauche, hauteur = bas - haut;
    if (largeur <= 0 || hauteur <= 0) return;
    double echelle = std::max((xmax - xmin) / largeur, (ymax - ymin) / hauteur);
    if (!(echelle > 0)) return;
    double cx = (xmin + xmax) / 2, cy = (ymin + ymax) / 2;
    double demiX = echelle * largeur / 2, demiY = echelle * hauteur / 2;
    xmin = cx - demiX;
    xmax = cx + demiX;
    ymin = cy - demiY;
    ymax = cy + demiY;
}

std::string rendreSVG(const Figure& figure) {
    std::ostringstream out;
    int L = figure.largeur, H = figure.hauteur;
    out << "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"" << L << "\" height=\"" << H
        << "\" viewBox=\"0 0 " << L << " " << H << "\">\n";
    out << "<rect width=\"" << L << "\" height=\"" << H << "\" fill=\"white\"/>\n";
    out << "<style>text{font-family:Helvetica,Arial,sans-serif;font-size:12px;fill:#222}"
           ".titre{font-size:15px}.axe{stroke:#222;stroke-width:1;fill:none}"
           ".grille{stroke:#ccc;stroke-width:0.5}</style>\n";

    int indiceAxe = 0;
    for (const auto& axesPtr : figure.axes) {
        const Axes& a = *axesPtr;
        ++indiceAxe;
        double fx, fy, fl, fh;
        cadreAxes(a, fx, fy, fl, fh);
        // Les marges d'une case sont bornees par sa taille : une case
        // haute de cent cinquante pixels — la moitie d'un Bode dans un
        // quart de figure — ne peut pas en donner quatre-vingt-dix aux
        // etiquettes.
        double largeurCase = fl * L, hauteurCase = fh * H;
        int gauche = (int)(fx * L + std::min(70.0, 0.22 * largeurCase));
        int droite = (int)((fx + fl) * L - std::min(30.0, 0.10 * largeurCase));
        int haut = (int)(fy * H + std::min(40.0, 0.16 * hauteurCase));
        int bas = (int)((fy + fh) * H - std::min(50.0, 0.22 * hauteurCase));
        if (droite <= gauche + 10 || bas <= haut + 10) continue;
        int hautTitre = haut;

        // La légende se mesure avant les échelles : placée hors de l'axe,
        // elle lui prend de la place, comme dans MATLAB.
        std::vector<EntreeLegende> entrees;
        if (a.legendeVisible) entrees = entreesLegende(a);
        const double policeLegende = 12, ligneLegende = 18;
        double largeurLegende = 0, hauteurLegende = 0;
        std::vector<double> largeursEntrees;
        for (const auto& e : entrees) {
            double l = 36 + largeurTexte(e.texte, policeLegende) + 10;
            largeursEntrees.push_back(l);
            if (a.legendeHorizontale) largeurLegende += l;
            else largeurLegende = std::max(largeurLegende, l);
        }
        if (!entrees.empty())
            hauteurLegende = a.legendeHorizontale ? ligneLegende + 8
                                                  : ligneLegende * (double)entrees.size() + 8;
        const std::string& ou = a.positionLegende;
        auto finitPar = [&](const std::string& fin) {
            return ou.size() >= fin.size() &&
                   ou.compare(ou.size() - fin.size(), fin.size(), fin) == 0;
        };
        bool dehors = !entrees.empty() && finitPar("outside");
        double xLegende = 0, yLegende = 0;
        if (dehors) {
            if (ou == "northoutside") {
                yLegende = haut;
                haut += (int)std::ceil(hauteurLegende + 8);
                xLegende = (gauche + droite) / 2.0 - largeurLegende / 2;
            } else if (ou == "southoutside") {
                bas -= (int)std::ceil(hauteurLegende + 10);
                yLegende = bas + 46;
                xLegende = (gauche + droite) / 2.0 - largeurLegende / 2;
            } else if (ou == "westoutside" || ou == "northwestoutside" ||
                       ou == "southwestoutside") {
                xLegende = fx * L + 6;
                gauche += (int)std::ceil(largeurLegende + 12);
                yLegende = ou == "northwestoutside" ? haut
                           : ou == "southwestoutside" ? bas - hauteurLegende
                                                      : (haut + bas) / 2.0 - hauteurLegende / 2;
            } else {
                droite -= (int)std::ceil(largeurLegende + 12);
                xLegende = droite + 12;
                yLegende = ou == "northeastoutside" || ou == "bestoutside" ? haut
                           : ou == "southeastoutside" ? bas - hauteurLegende
                                                      : (haut + bas) / 2.0 - hauteurLegende / 2;
            }
            if (droite <= gauche + 10 || bas <= haut + 10) continue;
        }

        // Les bornes : celles qu'on a fixées, ou celles des données,
        // arrondies aux graduations comme le fait MATLAB.
        double xmin, xmax, ymin, ymax;
        limitesAxe(a, xmin, xmax, ymin, ymax);
        // Un axe logarithmique ne porte ni le zéro ni les négatifs : faute
        // de valeur positive, il redevient linéaire.
        bool logX = a.logX, logY = a.logY;
        if (logX && !(xmin > 0 && xmax > xmin) && !bornesLog(xmin, xmax)) logX = false;
        if (logY && !(ymin > 0 && ymax > ymin) && !bornesLog(ymin, ymax)) {
            logY = false;
            ymin = 0;
            ymax = 1;
        }
        appliquerProportions(a, gauche, droite, haut, bas, xmin, xmax, ymin, ymax);

        // Un axe inverse n'echange pas ses bornes mais les pixels ou
        // elles tombent : tout le reste du trace suit sans le savoir.
        Echelle ex{xmin, xmax, a.xInverse ? droite : gauche,
                   a.xInverse ? gauche : droite, logX};
        Echelle ey{ymin, ymax, a.yInverse ? haut : bas,
                   a.yInverse ? bas : haut, logY};

        // « axis off » : le cadre, les graduations et leurs nombres
        // disparaissent ; les courbes, elles, restent.
        if (a.axesVisibles)
            out << "<rect x=\"" << gauche << "\" y=\"" << haut << "\" width=\""
                << (droite - gauche) << "\" height=\"" << (bas - haut)
                << "\" fill=\"white\" stroke=\"#222\"/>\n";

        // Les graduations imposees par « ax.XTick = [...] » l'emportent sur
        // celles qu'on choisirait.
        auto tx = a.axesVisibles
                      ? (a.ticksX.empty() ? graduationsAxe(xmin, xmax, 6, logX) : a.ticksX)
                      : std::vector<double>{};
        auto ty = a.axesVisibles
                      ? (a.ticksY.empty() ? graduationsAxe(ymin, ymax, 6, logY) : a.ticksY)
                      : std::vector<double>{};
        std::size_t rangTick = 0;
        for (double v : tx) {
            double px = ex.versPixel(v);
            if (px < gauche - 1 || px > droite + 1) continue;
            if (a.grille)
                out << "<line class=\"grille\" x1=\"" << px << "\" y1=\"" << haut << "\" x2=\""
                    << px << "\" y2=\"" << bas << "\"/>\n";
            out << "<line class=\"axe\" x1=\"" << px << "\" y1=\"" << bas << "\" x2=\"" << px
                << "\" y2=\"" << (bas - 4) << "\"/>\n";
            // « xticklabels({'a','b'}) » l'emporte sur les nombres.
            std::string texte = rangTick < a.etiquettesTicksX.size()
                                    ? echapperXml(a.etiquettesTicksX[rangTick])
                                    : etiquetteGraduation(v, logX);
            ++rangTick;
            out << "<text x=\"" << px << "\" y=\"" << (bas + 16)
                << "\" text-anchor=\"middle\">" << texte << "</text>\n";
        }
        rangTick = 0;
        for (double v : ty) {
            double py = ey.versPixel(v);
            if (py < haut - 1 || py > bas + 1) continue;
            if (a.grille)
                out << "<line class=\"grille\" x1=\"" << gauche << "\" y1=\"" << py
                    << "\" x2=\"" << droite << "\" y2=\"" << py << "\"/>\n";
            out << "<line class=\"axe\" x1=\"" << gauche << "\" y1=\"" << py << "\" x2=\""
                << (gauche + 4) << "\" y2=\"" << py << "\"/>\n";
            std::string texteY = rangTick < a.etiquettesTicksY.size()
                                     ? echapperXml(a.etiquettesTicksY[rangTick])
                                     : etiquetteGraduation(v, logY);
            ++rangTick;
            out << "<text x=\"" << (gauche - 8) << "\" y=\"" << (py + 4)
                << "\" text-anchor=\"end\">" << texteY << "</text>\n";
        }

        out << "<clipPath id=\"c" << indiceAxe << "\"><rect x=\"" << gauche << "\" y=\"" << haut
            << "\" width=\"" << (droite - gauche) << "\" height=\"" << (bas - haut)
            << "\"/></clipPath>\n";
        out << "<g clip-path=\"url(#c" << indiceAxe << ")\">\n";

        const std::vector<double>& palette = paletteEnVigueur(figure, a);
        double cmin, cmax;
        limitesCouleur(a, cmin, cmax);
        for (const auto& serie : a.series) {
            // Une série indexée — un niveau de contour, un polygone de
            // couleur numérique — prend sa couleur dans la palette. Elle est
            // courte : on la copie pour lui poser cette couleur, et l'on ne
            // copie pas les autres, qui peuvent porter un million de points.
            Serie copieIndexee;
            const Serie* source = &serie;
            if (serie.couleurIndexee) {
                copieIndexee = serie;
                copieIndexee.couleur = couleurDeSerie(figure, a, serie);
                source = &copieIndexee;
            }
            const Serie& s = *source;
            std::size_t n = std::min(s.x.size(), s.y.size());
            if (s.genre == GenreTrace::Constante) {
                if (s.x.empty()) continue;
                double px = s.axeConstante == 'x' ? ex.versPixel(s.x[0]) : gauche;
                double py = s.axeConstante == 'y' ? ey.versPixel(s.x[0]) : haut;
                if (s.axeConstante == 'x')
                    out << "<line x1=\"" << px << "\" y1=\"" << haut << "\" x2=\"" << px
                        << "\" y2=\"" << bas << "\" stroke=\"" << s.couleur
                        << "\" stroke-width=\"" << s.epaisseur << "\""
                        << motifTrait(s.style) << "/>\n";
                else
                    out << "<line x1=\"" << gauche << "\" y1=\"" << py << "\" x2=\"" << droite
                        << "\" y2=\"" << py << "\" stroke=\"" << s.couleur
                        << "\" stroke-width=\"" << s.epaisseur << "\""
                        << motifTrait(s.style) << "/>\n";
                if (!s.legendeConstante.empty()) {
                    double tx = s.axeConstante == 'x' ? px + 4 : droite - 4;
                    double ty = s.axeConstante == 'x' ? haut + 14 : py - 4;
                    out << "<text x=\"" << tx << "\" y=\"" << ty << "\" text-anchor=\""
                        << (s.axeConstante == 'x' ? "start" : "end") << "\" fill=\""
                        << s.couleur << "\">" << echapperXml(s.legendeConstante)
                        << "</text>\n";
                }
                continue;
            }
            if (s.genre == GenreTrace::Texte) {
                if (s.x.empty() || s.y.empty()) continue;
                double taille = s.taillePoliceTexte > 0 ? s.taillePoliceTexte : 11.0;
                const char* ancre = s.alignement == 'c'   ? "middle"
                                    : s.alignement == 'r' ? "end"
                                                          : "start";
                out << "<text x=\"" << ex.versPixel(s.x[0]) << "\" y=\""
                    << ey.versPixel(s.y[0]) << "\" text-anchor=\"" << ancre
                    << "\" font-size=\"" << taille << "\" fill=\"" << s.couleur << "\">"
                    << echapperXml(s.legendeConstante) << "</text>\n";
                continue;
            }
            if (s.genre == GenreTrace::Aire || s.genre == GenreTrace::Polygone) {
                if (n < 2) continue;
                std::string chemin;
                for (std::size_t k = 0; k < n; ++k) {
                    chemin += (k ? " L " : "M ") + formater("%g", ex.versPixel(s.x[k])) + " " +
                              formater("%g", ey.versPixel(s.y[k]));
                }
                if (s.genre == GenreTrace::Aire) {
                    // On referme sur la ligne des zeros : c'est la surface
                    // sous la courbe.
                    double zero = ey.versPixel(std::max(ymin, std::min(ymax, 0.0)));
                    chemin += " L " + formater("%g", ex.versPixel(s.x[n - 1])) + " " +
                              formater("%g", zero);
                    chemin += " L " + formater("%g", ex.versPixel(s.x[0])) + " " +
                              formater("%g", zero);
                }
                chemin += " Z";
                // Comme dans MATLAB, le bord d'un « fill » ou d'une « area »
                // est noir tant qu'EdgeColor ne dit pas autre chose.
                out << "<path d=\"" << chemin << "\" fill=\"" << s.couleur
                    << "\" fill-opacity=\"" << s.opacite << "\" stroke=\""
                    << (s.couleurBord.empty() ? std::string("#000000") : s.couleurBord)
                    << "\" stroke-width=\"" << (s.epaisseur == 1.5 ? 0.5 : s.epaisseur) << "\"/>\n";
                continue;
            }
            if (s.genre == GenreTrace::Image) {
                int lImage = s.hauteurImage, cImage = s.largeurImage;
                if (lImage <= 0 || cImage <= 0) continue;
                // L'image occupe l'etendue que la serie declare, et non
                // toute la boite : « imagesc(x,y,Z) » se pose au bon
                // endroit, et un axe inverse la retourne comme le reste.
                double x0 = s.x.size() > 1 ? s.x[0] : 0.5;
                double x1 = s.x.size() > 1 ? s.x[1] : cImage + 0.5;
                double y0 = s.y.size() > 1 ? s.y[0] : 0.5;
                double y1 = s.y.size() > 1 ? s.y[1] : lImage + 0.5;
                // Les pixels voisins d'une même couleur, sur une ligne, ne
                // font qu'un rectangle : le fichier reste léger.
                for (int i = 0; i < lImage; ++i) {
                    int j = 0;
                    while (j < cImage) {
                        int r, vert, b;
                        couleurPixelImage(palette, s,
                                          (std::size_t)i + (std::size_t)j * (std::size_t)lImage,
                                          cmin, cmax, r, vert, b);
                        int jFin = j + 1;
                        while (jFin < cImage) {
                            int r2, v2, b2;
                            std::size_t suivant =
                                (std::size_t)i + (std::size_t)jFin * (std::size_t)lImage;
                            couleurPixelImage(palette, s, suivant, cmin, cmax, r2, v2, b2);
                            if (r2 != r || v2 != vert || b2 != b) break;
                            ++jFin;
                        }
                        double gx0 = ex.versPixel(x0 + (x1 - x0) * j / cImage);
                        double gx1 = ex.versPixel(x0 + (x1 - x0) * jFin / cImage);
                        double gy0 = ey.versPixel(y0 + (y1 - y0) * i / lImage);
                        double gy1 = ey.versPixel(y0 + (y1 - y0) * (i + 1) / lImage);
                        out << "<rect x=\"" << formater("%.2f", std::min(gx0, gx1)) << "\" y=\""
                            << formater("%.2f", std::min(gy0, gy1)) << "\" width=\""
                            << formater("%.2f", std::fabs(gx1 - gx0) + 0.5) << "\" height=\""
                            << formater("%.2f", std::fabs(gy1 - gy0) + 0.5)
                            << "\" fill=\"rgb(" << r << "," << vert << "," << b << ")\"/>\n";
                        j = jFin;
                    }
                }
                continue;
            }
            if (s.genre == GenreTrace::Barres) {
                // La largeur : BarWidth fois le plus petit écart entre deux
                // abscisses, en unités de données ; le pied : la base de
                // la barre empilée, sinon zéro, ramené dans le cadre.
                double demi = s.largeurBarre / 2 * ecartBarres(s.x);
                std::string bord = s.couleurBord.empty() ? std::string("#000000") : s.couleurBord;
                for (std::size_t k = 0; k < n; ++k) {
                    double pied = k < s.basesBarres.size() ? s.basesBarres[k] : 0.0;
                    pied = std::min(std::max(pied, ymin), ymax);
                    double gauche = ex.versPixel(s.x[k] - demi);
                    double droite = ex.versPixel(s.x[k] + demi);
                    double py = ey.versPixel(std::min(std::max(s.y[k], ymin), ymax));
                    double base = ey.versPixel(pied);
                    out << "<rect x=\"" << std::min(gauche, droite) << "\" y=\""
                        << std::min(py, base) << "\" width=\"" << std::fabs(droite - gauche)
                        << "\" height=\"" << std::fabs(base - py) << "\" fill=\"" << s.couleur
                        << "\" fill-opacity=\"" << s.opacite << "\" stroke=\"" << bord
                        << "\" stroke-width=\"" << s.epaisseur << "\"/>\n";
                }
                continue;
            }
            if (s.genre == GenreTrace::Points) {
                for (std::size_t k = 0; k < n; ++k)
                    out << "<circle cx=\"" << ex.versPixel(s.x[k]) << "\" cy=\""
                        << ey.versPixel(s.y[k]) << "\" r=\"3\" fill=\"" << s.couleur << "\"/>\n";
                continue;
            }
            if (s.genre == GenreTrace::Tige) {
                double base = ey.versPixel(0);
                for (std::size_t k = 0; k < n; ++k) {
                    double px = ex.versPixel(s.x[k]), py = ey.versPixel(s.y[k]);
                    out << "<line x1=\"" << px << "\" y1=\"" << base << "\" x2=\"" << px
                        << "\" y2=\"" << py << "\" stroke=\"" << s.couleur << "\"/>\n";
                    out << "<circle cx=\"" << px << "\" cy=\"" << py << "\" r=\"3\" fill=\"none\" "
                           "stroke=\""
                        << s.couleur << "\"/>\n";
                }
                continue;
            }
            // Les points qu'aucun pixel ne distingue sont retires : le
            // dessin est le meme, le fichier tient.
            std::vector<std::size_t> visibles =
                indicesVisibles(s.x, s.y, ex.min, ex.max, ex.pixelsMax - ex.pixelsMin, ex.log);
            std::string chemin;
            bool premier = true;
            std::size_t precedent = 0;
            for (std::size_t indice : visibles) {
                std::size_t k = indice;
                if (k >= n) continue;
                if (!std::isfinite(s.x[k]) || !std::isfinite(s.y[k])) {
                    premier = true;
                    continue;
                }
                double px = ex.versPixel(s.x[k]), py = ey.versPixel(s.y[k]);
                if (s.genre == GenreTrace::Escalier && !premier)
                    chemin += formater("L %.2f %.2f ", px, ey.versPixel(s.y[precedent]));
                chemin += formater("%s %.2f %.2f ", premier ? "M" : "L", px, py);
                premier = false;
                precedent = k;
            }
            std::string tirets;
            if (s.style == "--") tirets = " stroke-dasharray=\"8,4\"";
            else if (s.style == ":") tirets = " stroke-dasharray=\"2,3\"";
            else if (s.style == "-.") tirets = " stroke-dasharray=\"8,3,2,3\"";
            if (s.style != "none" && !chemin.empty())
                out << "<path d=\"" << chemin << "\" fill=\"none\" stroke=\"" << s.couleur
                    << "\" stroke-width=\"" << s.epaisseur << "\"" << tirets << "/>\n";
            if (!s.marqueur.empty() && s.marqueur != "none") {
                FormeMarqueur forme = formeMarqueur(s.marqueur, s.tailleMarqueur);
                std::string bord, face;
                couleursMarqueur(s, s.couleur, bord, face);
                for (std::size_t k = 0; k < n; ++k) {
                    if (!std::isfinite(s.x[k]) || !std::isfinite(s.y[k])) continue;
                    ecrireMarqueur(out, forme, ex.versPixel(s.x[k]), ey.versPixel(s.y[k]), bord,
                                   face);
                }
            }
        }
        out << "</g>\n";

        if (!a.titre.empty())
            out << "<text class=\"titre\" x=\"" << ((gauche + droite) / 2) << "\" y=\""
                << (hautTitre - 14) << "\" text-anchor=\"middle\""
                << (a.taillePoliceTitre > 0
                        ? " font-size=\"" + formater("%g", a.taillePoliceTitre) + "px\""
                        : std::string())
                << ">" << echapperXml(a.titre) << "</text>\n";
        // MATLAB garde le titre sous « axis off », mais pas les etiquettes
        // des axes : elles nomment ce qui n'est plus dessine.
        if (!a.etiquetteX.empty() && a.axesVisibles)
            out << "<text x=\"" << ((gauche + droite) / 2) << "\" y=\"" << (bas + 36)
                << "\" text-anchor=\"middle\">" << echapperXml(a.etiquetteX) << "</text>\n";
        if (!a.etiquetteY.empty() && a.axesVisibles)
            out << "<text x=\"" << (gauche - 46) << "\" y=\"" << ((haut + bas) / 2)
                << "\" text-anchor=\"middle\" transform=\"rotate(-90 " << (gauche - 46) << " "
                << ((haut + bas) / 2) << ")\">" << echapperXml(a.etiquetteY) << "</text>\n";

        if (!entrees.empty()) {
            // Les positions intérieures, à huit pixels du cadre ; « best »
            // prend celle qui couvre le moins de points.
            auto placer = [&](const std::string& p, double& x, double& y) {
                bool est = p.find("east") != std::string::npos;
                bool ouest = p.find("west") != std::string::npos;
                bool nord = p.find("north") != std::string::npos;
                bool sud = p.find("south") != std::string::npos;
                x = est ? droite - largeurLegende - 8
                        : ouest ? gauche + 8 : (gauche + droite) / 2.0 - largeurLegende / 2;
                y = nord ? haut + 8 : sud ? bas - hauteurLegende - 8
                                          : (haut + bas) / 2.0 - hauteurLegende / 2;
            };
            if (!dehors) {
                if (ou == "best") {
                    const char* choix[] = {"northeast", "northwest", "southeast", "southwest",
                                           "north", "south", "east", "west"};
                    std::size_t meilleur = (std::size_t)-1;
                    for (const char* c : choix) {
                        double x, y;
                        placer(c, x, y);
                        std::size_t dedans = 0;
                        for (const auto& serie : a.series) {
                            if (serie.genre == GenreTrace::Texte ||
                                serie.genre == GenreTrace::Image)
                                continue;
                            std::size_t m = std::min(serie.x.size(), serie.y.size());
                            std::size_t pas = std::max<std::size_t>(1, m / 400);
                            for (std::size_t k = 0; k < m; k += pas) {
                                double px = ex.versPixel(serie.x[k]), py = ey.versPixel(serie.y[k]);
                                if (px >= x && px <= x + largeurLegende && py >= y &&
                                    py <= y + hauteurLegende)
                                    ++dedans;
                            }
                        }
                        if (dedans < meilleur) {
                            meilleur = dedans;
                            xLegende = x;
                            yLegende = y;
                        }
                    }
                } else {
                    placer(ou, xLegende, yLegende);
                }
            }
            if (a.boiteLegende)
                out << "<rect x=\"" << formater("%.1f", xLegende) << "\" y=\""
                    << formater("%.1f", yLegende) << "\" width=\""
                    << formater("%.1f", largeurLegende)
                    << "\" height=\"" << formater("%.1f", hauteurLegende)
                    << "\" fill=\"white\" stroke=\"#999\"/>\n";
            double xe = xLegende, ye = yLegende + 4;
            for (std::size_t k = 0; k < entrees.size(); ++k) {
                const Serie& s = a.series[entrees[k].serie];
                std::string couleur = couleurDeSerie(figure, a, s);
                double milieu = ye + ligneLegende / 2;
                if (s.genre == GenreTrace::Barres || s.genre == GenreTrace::Aire ||
                    s.genre == GenreTrace::Polygone) {
                    out << "<rect x=\"" << formater("%.1f", xe + 8) << "\" y=\""
                        << formater("%.1f", milieu - 5) << "\" width=\"20\" height=\"10\" fill=\""
                        << couleur << "\" fill-opacity=\"" << s.opacite << "\" stroke=\""
                        << (s.couleurBord.empty() ? couleur : s.couleurBord) << "\"/>\n";
                } else if (s.genre == GenreTrace::Points) {
                    out << "<circle cx=\"" << formater("%.1f", xe + 18) << "\" cy=\""
                        << formater("%.1f", milieu) << "\" r=\"3\" fill=\"" << couleur << "\"/>\n";
                } else {
                    if (s.style != "none")
                        out << "<line x1=\"" << formater("%.1f", xe + 6) << "\" y1=\""
                            << formater("%.1f", milieu) << "\" x2=\"" << formater("%.1f", xe + 30)
                            << "\" y2=\"" << formater("%.1f", milieu) << "\" stroke=\"" << couleur
                            << "\" stroke-width=\"" << std::min(s.epaisseur, 3.0) << "\""
                            << motifTrait(s.style) << "/>\n";
                    std::string marqueur = s.genre == GenreTrace::Tige ? "o" : s.marqueur;
                    if (!marqueur.empty() && marqueur != "none") {
                        std::string bord, face;
                        couleursMarqueur(s, couleur, bord, face);
                        ecrireMarqueur(out, formeMarqueur(marqueur, s.tailleMarqueur), xe + 18,
                                       milieu, bord, face);
                    }
                }
                out << "<text x=\"" << formater("%.1f", xe + 36) << "\" y=\""
                    << formater("%.1f", milieu + 4) << "\">" << echapperXml(entrees[k].texte)
                    << "</text>\n";
                if (a.legendeHorizontale) xe += largeursEntrees[k];
                else ye += ligneLegende;
            }
        }
    }
    out << "</svg>\n";
    return out.str();
}

}  // namespace matlibre
