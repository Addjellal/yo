function h = impulseest(donnees, n)
%IMPULSEEST Réponse impulsionnelle estimée par moindres carrés.
%   H = IMPULSEEST(DONNEES) estime les 20 premiers points de la réponse
%   impulsionnelle du système dont DONNEES porte l'entrée U et la sortie Y.
%   H = IMPULSEEST(DONNEES,N) en estime N.
%
%   La sortie est écrite comme la convolution de l'entrée par la réponse
%   cherchée, ce qui donne un système linéaire en les coefficients de
%   celle-ci, résolu au sens des moindres carrés. Aucune structure n'est
%   supposée : ni ordre, ni pôles, ni retard — c'est un modèle non
%   paramétrique, et il sert surtout à découvrir ces éléments avant de
%   choisir une structure paramétrique.
%
%   Le retard pur se lit directement : les premiers coefficients sont
%   nuls, et leur nombre donne le retard en périodes d'échantillonnage.
%
%   L'entrée doit être suffisamment riche. Une entrée en échelon, ou une
%   sinusoïde unique, rend la matrice de régression mal conditionnée et
%   l'estimation instable : il faut une séquence binaire pseudo-aléatoire
%   ou du bruit blanc, qui excitent toutes les fréquences.
%
%   Exemple :
%      rng(1);
%      u = randn(300, 1);
%      z = iddata(filter([0 1 0.5], 1, u), u);
%      h = impulseest(z, 5);      % 0, 1, 0.5, 0, 0
%
%   Voir aussi ARX, PREDICTARX, IMPULSE, IDDATA.
    if nargin < 2
        n = 20;
    end
    y = donnees.y;
    u = donnees.u;
    N = numel(y);
    Phi = zeros(N - n, n);
    for t = n+1:N
        for k = 1:n
            Phi(t - n, k) = u(t - k + 1);
        end
    end
    h = Phi \ y(n+1:N);
end
