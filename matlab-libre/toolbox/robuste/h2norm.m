function n = h2norm(sys)
%H2NORM Norme H2 d'un modèle stable.
%   N = H2NORM(SYS) rend la racine de l'intégrale du carré du module de
%   la réponse fréquentielle, divisée par pi : c'est l'énergie de la
%   réponse impulsionnelle, et l'écart-type de la sortie quand l'entrée
%   est un bruit blanc de variance unité.
%
%   Un modèle instable, ou dont la transmittance ne tend pas vers zéro,
%   n'a pas de norme H2 finie.
%
%   Exemples :
%      abs(h2norm(tf(1, [1 1])) - sqrt(0.5)) < 1e-3    % la valeur exacte
%      h2norm(tf(1, [1 0.1 1])) > h2norm(tf(1, [1 2 1]))   % le peu amorti en a plus
%
%   Voir aussi HINFNORM, SIGMA, COVAR, GRAM.
    w = logspace(-4, 4, 20000).';
    m = bode(sys, w);
    n = sqrt(trapz(w, m .^ 2) / pi);
end
