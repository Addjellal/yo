// Tampon.h — les doubles d'une valeur, partagés entre copies jusqu'à la
// première écriture.
//
// MATLAB ne recopie pas un tableau qu'on passe à une fonction, ni celui
// qu'on affecte à une autre variable : la copie n'a lieu que si l'un des
// deux est modifié. Sans cela, appeler deux cents fois une fonction sur un
// tableau de seize mégaoctets coûtait trois secondes de recopies, et une
// fonction récursive sur un grand tableau devenait quadratique.
//
// TamponDouble a l'interface de std::vector<double> dont le reste du code
// se sert. Les accès en lecture (const) partagent ; tout accès qui peut
// écrire — l'opérateur [] non const, data(), begin() non const, resize… —
// détache d'abord le tampon s'il est partagé. Une valeur vide ne porte
// aucun tampon.
#pragma once

#include <algorithm>
#include <atomic>
#include <cstddef>
#include <initializer_list>
#include <memory>
#include <vector>

namespace matlibre {

class TamponDouble {
public:
    using value_type = double;
    using size_type = std::size_t;
    using iterator = std::vector<double>::iterator;
    using const_iterator = std::vector<double>::const_iterator;
    using reverse_iterator = std::vector<double>::reverse_iterator;
    using const_reverse_iterator = std::vector<double>::const_reverse_iterator;

    TamponDouble() = default;
    // Copier partage le tampon : ni l'original ni la copie n'en sont plus
    // seuls propriétaires, et la prochaine écriture de l'un le détachera.
    TamponDouble(const TamponDouble& o) : d_(o.d_) {
        o.seul_.store(false, std::memory_order_relaxed);
    }
    TamponDouble(TamponDouble&& o) noexcept
        : d_(std::move(o.d_)), seul_(o.seul_.load(std::memory_order_relaxed)) {
        o.seul_.store(false, std::memory_order_relaxed);
    }
    TamponDouble& operator=(const TamponDouble& o) {
        if (this != &o) {
            d_ = o.d_;
            o.seul_.store(false, std::memory_order_relaxed);
            seul_.store(false, std::memory_order_relaxed);
        }
        return *this;
    }
    TamponDouble& operator=(TamponDouble&& o) noexcept {
        if (this != &o) {
            d_ = std::move(o.d_);
            seul_.store(o.seul_.load(std::memory_order_relaxed), std::memory_order_relaxed);
            o.seul_.store(false, std::memory_order_relaxed);
        }
        return *this;
    }

    explicit TamponDouble(size_type n, double v = 0.0)
        : d_(n ? std::make_shared<std::vector<double>>(n, v) : nullptr) {}
    TamponDouble(std::initializer_list<double> l)
        : d_(l.size() ? std::make_shared<std::vector<double>>(l) : nullptr) {}
    TamponDouble(const std::vector<double>& v)  // NOLINT : conversion voulue
        : d_(v.empty() ? nullptr : std::make_shared<std::vector<double>>(v)) {}
    TamponDouble(std::vector<double>&& v)  // NOLINT : conversion voulue
        : d_(v.empty() ? nullptr : std::make_shared<std::vector<double>>(std::move(v))) {}
    template <class It, class = typename std::iterator_traits<It>::iterator_category>
    TamponDouble(It a, It b) : d_(std::make_shared<std::vector<double>>(a, b)) {
        if (d_->empty()) d_.reset();
    }

    TamponDouble& operator=(const std::vector<double>& v) {
        d_ = v.empty() ? nullptr : std::make_shared<std::vector<double>>(v);
        seul_.store(false, std::memory_order_relaxed);
        return *this;
    }
    TamponDouble& operator=(std::vector<double>&& v) {
        d_ = v.empty() ? nullptr : std::make_shared<std::vector<double>>(std::move(v));
        seul_.store(false, std::memory_order_relaxed);
        return *this;
    }
    TamponDouble& operator=(std::initializer_list<double> l) {
        d_ = l.size() ? std::make_shared<std::vector<double>>(l) : nullptr;
        seul_.store(false, std::memory_order_relaxed);
        return *this;
    }

    // --- lecture : rien n'est copié ---
    size_type size() const { return d_ ? d_->size() : 0; }
    bool empty() const { return !d_ || d_->empty(); }
    const double& operator[](size_type k) const { return (*d_)[k]; }
    const double* data() const { return d_ ? d_->data() : nullptr; }
    const_iterator begin() const { return lire().begin(); }
    const_iterator end() const { return lire().end(); }
    const_iterator cbegin() const { return lire().cbegin(); }
    const_iterator cend() const { return lire().cend(); }
    const_reverse_iterator rbegin() const { return lire().rbegin(); }
    const_reverse_iterator rend() const { return lire().rend(); }
    const double& front() const { return d_->front(); }
    const double& back() const { return d_->back(); }
    size_type capacity() const { return d_ ? d_->capacity() : 0; }
    const std::vector<double>& lire() const {
        static const std::vector<double> vide;
        return d_ ? *d_ : vide;
    }
    operator const std::vector<double>&() const { return lire(); }  // NOLINT

    // --- écriture : le tampon partagé est d'abord détaché ---
    double& operator[](size_type k) { return ecrire()[k]; }
    double* data() { return empty() ? nullptr : ecrire().data(); }
    iterator begin() { return ecrire().begin(); }
    iterator end() { return ecrire().end(); }
    reverse_iterator rbegin() { return ecrire().rbegin(); }
    reverse_iterator rend() { return ecrire().rend(); }
    double& front() { return ecrire().front(); }
    double& back() { return ecrire().back(); }
    void resize(size_type n) { if (n != size()) ecrire().resize(n); }
    void resize(size_type n, double v) { if (n != size()) ecrire().resize(n, v); }
    void assign(size_type n, double v) { *this = TamponDouble(n, v); }
    template <class It, class = typename std::iterator_traits<It>::iterator_category>
    void assign(It a, It b) { *this = TamponDouble(a, b); }
    void assign(std::initializer_list<double> l) { *this = TamponDouble(l); }
    void push_back(double v) { ecrire().push_back(v); }
    template <class... A>
    double& emplace_back(A&&... a) { return ecrire().emplace_back(std::forward<A>(a)...); }
    void pop_back() { ecrire().pop_back(); }
    void reserve(size_type n) { if (n > capacity()) ecrire().reserve(n); }
    void shrink_to_fit() { if (d_) ecrire().shrink_to_fit(); }
    void clear() {
        d_.reset();
        seul_.store(false, std::memory_order_relaxed);
    }
    template <class... A>
    iterator insert(const_iterator ou, A&&... a) {
        std::size_t rang = (std::size_t)(ou - lire().cbegin());
        std::vector<double>& v = ecrire();
        return v.insert(v.cbegin() + (std::ptrdiff_t)rang, std::forward<A>(a)...);
    }
    iterator erase(const_iterator a, const_iterator b) {
        std::size_t debut = (std::size_t)(a - lire().cbegin());
        std::size_t fin = (std::size_t)(b - lire().cbegin());
        std::vector<double>& v = ecrire();
        return v.erase(v.cbegin() + (std::ptrdiff_t)debut, v.cbegin() + (std::ptrdiff_t)fin);
    }
    iterator erase(const_iterator a) { return erase(a, a + 1); }
    void swap(TamponDouble& autre) noexcept {
        d_.swap(autre.d_);
        bool a = seul_.load(std::memory_order_relaxed);
        seul_.store(autre.seul_.load(std::memory_order_relaxed), std::memory_order_relaxed);
        autre.seul_.store(a, std::memory_order_relaxed);
    }
    void swap(std::vector<double>& autre) {
        ecrire().swap(autre);
        if (d_->empty()) clear();
    }
    operator std::vector<double>&() { return ecrire(); }  // NOLINT

    // Le vecteur, seul propriétaire : le copier s'il est partagé. Le
    // drapeau évite de relire le compteur atomique à chaque écriture d'une
    // boucle, une fois le tampon à soi.
    // Le chemin rapide tient en deux instructions, pour que les boucles qui
    // lisent par une valeur non const — un comparateur de tri — restent
    // en ligne ; la copie est à part.
    std::vector<double>& ecrire() {
#if defined(__GNUC__)
        if (__builtin_expect(seul_.load(std::memory_order_relaxed), 1)) return *d_;
#else
        if (seul_.load(std::memory_order_relaxed)) return *d_;
#endif
        return detacher();
    }
    // Vrai si une autre valeur partage ce tampon : ce que les tests vérifient.
    bool partage() const { return d_ && d_.use_count() > 1; }

    friend bool operator==(const TamponDouble& a, const TamponDouble& b) {
        return a.d_ == b.d_ || a.lire() == b.lire();
    }
    friend bool operator!=(const TamponDouble& a, const TamponDouble& b) { return !(a == b); }
    friend bool operator==(const TamponDouble& a, const std::vector<double>& b) {
        return a.lire() == b;
    }

private:
#if defined(__GNUC__)
    __attribute__((noinline, cold))
#endif
    std::vector<double>& detacher() {
        if (!d_) d_ = std::make_shared<std::vector<double>>();
        else if (d_.use_count() > 1) d_ = std::make_shared<std::vector<double>>(*d_);
        seul_.store(true, std::memory_order_relaxed);
        return *d_;
    }

    std::shared_ptr<std::vector<double>> d_;
    // Vrai quand ce tampon est sûrement seul à tenir son vecteur.
    mutable std::atomic<bool> seul_{false};
};

inline void swap(TamponDouble& a, TamponDouble& b) noexcept { a.swap(b); }

}  // namespace matlibre
