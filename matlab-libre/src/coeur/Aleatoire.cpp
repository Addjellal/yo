// Aleatoire.cpp — le générateur de MATLAB (voir Aleatoire.h).
#include "matlibre/Aleatoire.h"

#include <cmath>

namespace matlibre {

namespace {

// Les bords des 256 bandes du ziggurat de Marsaglia et Tsang (2000) :
// X[0] la plus étroite, en haut de la cloche, X[254] = r, et X[255] la
// largeur de la bande de base, v / f(r), qui porte la queue.
struct TableZiggurat {
    std::array<double, 256> x{};
    std::array<double, 256> f{};
    TableZiggurat() {
        const double r = 3.6541528853610088;
        const double v = 4.92867323399e-3;
        auto densite = [](double t) { return std::exp(-0.5 * t * t); };
        x[254] = r;
        for (int i = 253; i >= 0; --i)
            x[i] = std::sqrt(-2.0 * std::log(v / x[i + 1] + densite(x[i + 1])));
        x[255] = v / densite(r);
        for (int i = 0; i < 256; ++i) f[i] = densite(x[i]);
    }
};

const TableZiggurat& table() {
    static const TableZiggurat t;
    return t;
}

}  // namespace

void GenerateurMatlab::initialiser(std::uint32_t graine) {
    mt_[0] = graine == 0 ? 5489u : graine;
    for (int i = 1; i < 624; ++i)
        mt_[i] = 1812433253u * (mt_[i - 1] ^ (mt_[i - 1] >> 30)) + (std::uint32_t)i;
    indice_ = 624;
}

GenerateurMatlab::result_type GenerateurMatlab::operator()() {
    if (indice_ >= 624) {
        for (int k = 0; k < 624; ++k) {
            std::uint32_t y = (mt_[k] & 0x80000000u) | (mt_[(k + 1) % 624] & 0x7FFFFFFFu);
            mt_[k] = mt_[(k + 397) % 624] ^ (y >> 1) ^ ((y & 1u) ? 0x9908B0DFu : 0u);
        }
        indice_ = 0;
    }
    std::uint32_t y = mt_[indice_++];
    y ^= y >> 11;
    y ^= (y << 7) & 0x9D2C5680u;
    y ^= (y << 15) & 0xEFC60000u;
    y ^= y >> 18;
    return y;
}

double GenerateurMatlab::uniforme() {
    for (;;) {
        std::uint32_t a = (*this)() >> 5, b = (*this)() >> 6;
        double u = (a * 67108864.0 + b) / 9007199254740992.0;
        if (u > 0.0) return u;   // rand rend un nombre de l'intervalle ouvert
    }
}

double GenerateurMatlab::normale() {
    const TableZiggurat& t = table();
    for (;;) {
        std::uint32_t a = (*this)(), b = (*this)();
        double u = ((a >> 5) * 67108864.0 + (b >> 6)) / 9007199254740992.0;
        int i = (int)(b >> 24);
        double s = 2.0 * u - 1.0;
        double x = s * t.x[(std::size_t)i];
        double interieur = i > 0 ? t.x[(std::size_t)i - 1] / t.x[(std::size_t)i] : 0.0;
        if (std::fabs(s) < interieur) return x;     // le rectangle : 99 % des tirages
        if (i == 255) {
            // La queue, au-delà de r (Marsaglia, 1964).
            const double r = t.x[254];
            double xq, yq;
            do {
                xq = -std::log(uniforme()) / r;
                yq = -std::log(uniforme());
            } while (2.0 * yq < xq * xq);
            return s > 0 ? r + xq : -(r + xq);
        }
        // Le coin de la bande, entre la courbe et le rectangle.
        double haut = i > 0 ? t.f[(std::size_t)i - 1] : 1.0;
        if (t.f[(std::size_t)i] + uniforme() * (haut - t.f[(std::size_t)i]) <
            std::exp(-0.5 * x * x))
            return x;
    }
}

std::array<std::uint32_t, 625> GenerateurMatlab::etat() const {
    std::array<std::uint32_t, 625> e{};
    for (int i = 0; i < 624; ++i) e[(std::size_t)i] = mt_[(std::size_t)i];
    e[624] = (std::uint32_t)indice_;
    return e;
}

void GenerateurMatlab::restaurer(const std::array<std::uint32_t, 625>& e) {
    for (int i = 0; i < 624; ++i) mt_[(std::size_t)i] = e[(std::size_t)i];
    indice_ = (int)(e[624] > 624 ? 624 : e[624]);
}

}  // namespace matlibre
