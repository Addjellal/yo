// VecteurPartage.h — un tableau que les copies partagent tant que personne
// ne l'écrit.
//
// MATLAB passe ses tableaux par valeur sans les recopier : « b = a », un
// argument, une valeur rendue partagent les mêmes données, et la copie n'a
// lieu qu'au moment où l'un des deux est modifié. C'est ce qui permet de
// passer un tableau de deux millions d'éléments à une fonction deux mille
// fois de suite, ou d'écrire un analyseur récursif qui passe tout son texte
// à chaque appel, sans que le temps devienne le carré de la taille.
//
// Ce type fait de même pour les tableaux d'une Valeur : ses nombres, ses
// cases de cellule, ses chaînes. Copier coûte un compteur à incrémenter.
// Tout accès qui peut écrire — l'opérateur [] non constant, begin(),
// data(), push_back, resize... — vérifie d'abord que le bloc n'a qu'un
// propriétaire, et s'en fait sinon une copie privée.
// Les accès constants ne copient jamais : quand on ne veut que lire, on
// lit par une référence constante — « const Valeur& x = args[0] ». Lire
// par un accès qui aurait pu écrire reste juste : on paie seulement une
// copie qu'on aurait pu éviter, celle qu'on payait toujours auparavant.
//
// Le piège est celui de toute copie à l'écriture. Un pointeur, un
// itérateur ou une référence obtenus par un accès qui écrit ne désignent
// des données à soi seul que jusqu'à la prochaine copie de la valeur qui
// les porte : on n'écrit plus par eux après l'avoir copiée.
//
// Le compteur est atomique : les travailleurs de parfor copient en même
// temps, chacun dans son fil, les mêmes valeurs diffusées.
#pragma once

#include <algorithm>
#include <atomic>
#include <cstddef>
#include <initializer_list>
#include <iterator>
#include <utility>
#include <vector>

namespace matlibre {

template <class T>
class VecteurPartage {
public:
    using value_type = T;
    using size_type = std::size_t;
    using difference_type = std::ptrdiff_t;
    using reference = T&;
    using const_reference = const T&;
    using pointer = T*;
    using const_pointer = const T*;
    using iterator = T*;
    using const_iterator = const T*;
    using reverse_iterator = std::reverse_iterator<iterator>;
    using const_reverse_iterator = std::reverse_iterator<const_iterator>;

    VecteurPartage() noexcept = default;
    VecteurPartage(const VecteurPartage& autre) noexcept : b_(autre.b_) { prendre(b_); }
    VecteurPartage(VecteurPartage&& autre) noexcept : b_(autre.b_) { autre.b_ = nullptr; }
    VecteurPartage(const std::vector<T>& v) : b_(v.empty() ? nullptr : new Bloc(v)) {}
    VecteurPartage(std::vector<T>&& v)
        : b_(v.empty() ? nullptr : new Bloc(std::move(v))) {}
    VecteurPartage(std::initializer_list<T> l) : VecteurPartage(std::vector<T>(l)) {}
    explicit VecteurPartage(size_type n, const T& x = T())
        : VecteurPartage(std::vector<T>(n, x)) {}
    template <class It, class = typename std::iterator_traits<It>::iterator_category>
    VecteurPartage(It debut, It fin) : VecteurPartage(std::vector<T>(debut, fin)) {}
    ~VecteurPartage() { lacher(b_); }

    VecteurPartage& operator=(const VecteurPartage& autre) noexcept {
        prendre(autre.b_);  // avant de lâcher : « a = a » ne libère rien
        lacher(b_);
        b_ = autre.b_;
        return *this;
    }
    VecteurPartage& operator=(VecteurPartage&& autre) noexcept {
        if (this != &autre) {
            lacher(b_);
            b_ = autre.b_;
            autre.b_ = nullptr;
        }
        return *this;
    }
    VecteurPartage& operator=(const std::vector<T>& v) {
        if (seul()) b_->v = v;  // garde la capacité déjà réservée
        else remplacer(std::vector<T>(v));
        return *this;
    }
    VecteurPartage& operator=(std::vector<T>&& v) {
        if (seul()) b_->v = std::move(v);
        else remplacer(std::move(v));
        return *this;
    }
    VecteurPartage& operator=(std::initializer_list<T> l) {
        if (seul()) b_->v = l;
        else remplacer(std::vector<T>(l));
        return *this;
    }

    // ---- lecture : ne copie jamais ----
    size_type size() const noexcept { return b_ ? b_->v.size() : 0; }
    bool empty() const noexcept { return !b_ || b_->v.empty(); }
    size_type capacity() const noexcept { return b_ ? b_->v.capacity() : 0; }
    const T* data() const noexcept { return b_ ? b_->v.data() : nullptr; }
    const T& operator[](size_type k) const noexcept { return b_->v[k]; }
    const T& at(size_type k) const { return lire().at(k); }
    const T& front() const { return b_->v.front(); }
    const T& back() const { return b_->v.back(); }
    const_iterator begin() const noexcept { return data(); }
    const_iterator end() const noexcept { return data() + size(); }
    const_iterator cbegin() const noexcept { return begin(); }
    const_iterator cend() const noexcept { return end(); }
    const_reverse_iterator rbegin() const noexcept { return const_reverse_iterator(end()); }
    const_reverse_iterator rend() const noexcept { return const_reverse_iterator(begin()); }
    const_reverse_iterator crbegin() const noexcept { return rbegin(); }
    const_reverse_iterator crend() const noexcept { return rend(); }

    // Le vecteur lui-même, en lecture : pour ce qui attend un std::vector.
    const std::vector<T>& lire() const noexcept { return b_ ? b_->v : vide(); }
    operator const std::vector<T>&() const noexcept { return lire(); }

    // Vrai quand une autre copie tient le même bloc : une écriture le
    // recopierait d'abord. Pour les tests et les mesures.
    bool partage() const noexcept { return b_ && !seul(); }
    bool memeBloc(const VecteurPartage& autre) const noexcept {
        return b_ != nullptr && b_ == autre.b_;
    }

    // ---- écriture : se rend d'abord seul propriétaire ----
    // Le vecteur lui-même, en écriture : pour ce qui attend un std::vector&.
    std::vector<T>& modifier() { return propre(); }

    T* data() { return b_ ? propre().data() : nullptr; }
    T& operator[](size_type k) { return propre()[k]; }
    T& at(size_type k) { return propre().at(k); }
    T& front() { return propre().front(); }
    T& back() { return propre().back(); }
    iterator begin() { return b_ ? propre().data() : nullptr; }
    iterator end() {
        if (!b_) return nullptr;
        std::vector<T>& v = propre();
        return v.data() + v.size();
    }
    reverse_iterator rbegin() { return reverse_iterator(end()); }
    reverse_iterator rend() { return reverse_iterator(begin()); }

    void push_back(const T& x) { propre().push_back(x); }
    void push_back(T&& x) { propre().push_back(std::move(x)); }
    template <class... A>
    T& emplace_back(A&&... a) {
        return propre().emplace_back(std::forward<A>(a)...);
    }
    void pop_back() { propre().pop_back(); }

    void clear() noexcept {
        if (seul()) {
            b_->v.clear();
        } else {
            lacher(b_);
            b_ = nullptr;
        }
    }
    void reserve(size_type n) {
        if (seul()) {
            b_->v.reserve(n);
            return;
        }
        if (n <= size()) return;  // rien à réserver : inutile de copier
        std::vector<T> v;
        v.reserve(n);
        v.insert(v.end(), cbegin(), cend());
        remplacer(std::move(v));
    }
    // Les deux « resize » ne copient rien quand la taille ne change pas ;
    // sur un bloc partagé, ils ne recopient que ce qui reste.
    void resize(size_type n) {
        if (n == size()) return;
        if (seul()) {
            b_->v.resize(n);
            return;
        }
        std::vector<T> v;
        v.reserve(n);
        v.insert(v.end(), cbegin(), cbegin() + std::min(n, size()));
        v.resize(n);
        remplacer(std::move(v));
    }
    void resize(size_type n, const T& x) {
        if (n == size()) return;
        if (seul()) {
            b_->v.resize(n, x);
            return;
        }
        std::vector<T> v;
        v.reserve(n);
        v.insert(v.end(), cbegin(), cbegin() + std::min(n, size()));
        v.resize(n, x);
        remplacer(std::move(v));
    }
    void assign(size_type n, const T& x) {
        if (seul()) b_->v.assign(n, x);
        else remplacer(std::vector<T>(n, x));
    }
    template <class It, class = typename std::iterator_traits<It>::iterator_category>
    void assign(It debut, It fin) {
        if (seul()) b_->v.assign(debut, fin);
        else remplacer(std::vector<T>(debut, fin));
    }
    void assign(std::initializer_list<T> l) { assign(l.begin(), l.end()); }

    // Les positions sont converties en rangs AVANT de se détacher : elles
    // peuvent désigner le bloc partagé, que la copie privée remplace.
    iterator insert(const_iterator pos, const T& x) {
        const size_type k = rang(pos);
        std::vector<T>& v = propre();
        v.insert(v.begin() + (difference_type)k, x);
        return v.data() + k;
    }
    iterator insert(const_iterator pos, T&& x) {
        const size_type k = rang(pos);
        std::vector<T>& v = propre();
        v.insert(v.begin() + (difference_type)k, std::move(x));
        return v.data() + k;
    }
    iterator insert(const_iterator pos, size_type n, const T& x) {
        const size_type k = rang(pos);
        std::vector<T>& v = propre();
        v.insert(v.begin() + (difference_type)k, n, x);
        return v.data() + k;
    }
    template <class It, class = typename std::iterator_traits<It>::iterator_category>
    iterator insert(const_iterator pos, It debut, It fin) {
        const size_type k = rang(pos);
        std::vector<T>& v = propre();
        v.insert(v.begin() + (difference_type)k, debut, fin);
        return v.data() + k;
    }
    iterator insert(const_iterator pos, std::initializer_list<T> l) {
        return insert(pos, l.begin(), l.end());
    }
    iterator erase(const_iterator pos) {
        const size_type k = rang(pos);
        std::vector<T>& v = propre();
        v.erase(v.begin() + (difference_type)k);
        return v.data() + k;
    }
    iterator erase(const_iterator debut, const_iterator fin) {
        const size_type a = rang(debut), b = rang(fin);
        std::vector<T>& v = propre();
        v.erase(v.begin() + (difference_type)a, v.begin() + (difference_type)b);
        return v.data() + a;
    }
    void shrink_to_fit() {
        if (seul()) b_->v.shrink_to_fit();
    }

    void swap(VecteurPartage& autre) noexcept { std::swap(b_, autre.b_); }
    void swap(std::vector<T>& v) { propre().swap(v); }
    friend void swap(VecteurPartage& a, VecteurPartage& b) noexcept { a.swap(b); }

    // Pas de raccourci « même bloc, donc égaux » : NaN n'est pas égal à
    // lui-même, et deux copies d'un NaN ne le sont pas davantage.
    friend bool operator==(const VecteurPartage& a, const VecteurPartage& b) {
        return a.lire() == b.lire();
    }
    friend bool operator!=(const VecteurPartage& a, const VecteurPartage& b) {
        return !(a == b);
    }
    friend bool operator==(const VecteurPartage& a, const std::vector<T>& b) {
        return a.lire() == b;
    }
    friend bool operator==(const std::vector<T>& a, const VecteurPartage& b) {
        return a == b.lire();
    }
    friend bool operator!=(const VecteurPartage& a, const std::vector<T>& b) {
        return !(a == b);
    }
    friend bool operator!=(const std::vector<T>& a, const VecteurPartage& b) {
        return !(a == b);
    }

private:
    struct Bloc {
        std::atomic<long> proprietaires{1};
        std::vector<T> v;
        Bloc() = default;
        explicit Bloc(const std::vector<T>& x) : v(x) {}
        explicit Bloc(std::vector<T>&& x) noexcept : v(std::move(x)) {}
    };

    static const std::vector<T>& vide() noexcept {
        static const std::vector<T> rien;
        return rien;
    }
    static void prendre(Bloc* b) noexcept {
        if (b) b->proprietaires.fetch_add(1, std::memory_order_relaxed);
    }
    static void lacher(Bloc* b) noexcept {
        if (b && b->proprietaires.fetch_sub(1, std::memory_order_acq_rel) == 1) delete b;
    }
    // Seul propriétaire d'un bloc existant. La lecture « acquire » répond
    // au « release » de celui qui vient de lâcher le bloc : ce qu'il y
    // lisait est terminé avant qu'on y écrive.
    bool seul() const noexcept {
        return b_ && b_->proprietaires.load(std::memory_order_acquire) == 1;
    }
    size_type rang(const_iterator pos) const noexcept {
        return b_ ? (size_type)(pos - b_->v.data()) : 0;
    }
    // Le vecteur, à soi seul : copié s'il est partagé, créé s'il n'existe pas.
    std::vector<T>& propre() {
        if (!seul()) detacher();
        return b_->v;
    }
    void detacher() {
        Bloc* nouveau = b_ ? new Bloc(b_->v) : new Bloc();
        lacher(b_);
        b_ = nouveau;
    }
    // Remplace le contenu sans recopier l'ancien ; un tableau vide ne
    // garde pas de bloc.
    void remplacer(std::vector<T>&& v) {
        Bloc* nouveau = v.empty() ? nullptr : new Bloc(std::move(v));
        lacher(b_);
        b_ = nouveau;
    }

    Bloc* b_ = nullptr;
};

}  // namespace matlibre
