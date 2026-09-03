function [fonctions, xval] = wpfun(nom, numero, iterations)
%WPFUN Fonctions de paquets d'ondelettes.
%   [WPWS,X] = WPFUN(NOM,NUM,ITER) rend les fonctions W0 à WNUM de la
%   famille de paquets de l'ondelette NOM, une par ligne, échantillonnées
%   sur la grille X.
%
%   Les fonctions se construisent par récurrence, en descendant l'arbre
%   avec les deux filtres :
%
%      W(2n)(x)   = sqrt(2) somme_k Lo_R(k) W(n)(2x - k)
%      W(2n+1)(x) = sqrt(2) somme_k Hi_R(k) W(n)(2x - k)
%
%   W0 est la fonction d'échelle, W1 l'ondelette ; les suivantes
%   oscillent de plus en plus, chacune occupant sa propre bande.
%
%   Exemple :
%      [w, x] = wpfun('db2', 3, 7);
%      size(w, 1)                     % 4 : W0 à W3
%      trapz(x, w(1, :))              % 1 : W0 est la fonction d'échelle
%      abs(trapz(x, w(2, :)))         % nul : W1 est l'ondelette
%
%   Voir aussi WAVEFUN, WPDEC, WPCOEF, WFILTERS.
    if nargin < 2 || isempty(numero), numero = 1; end
    if nargin < 3 || isempty(iterations), iterations = 7; end
    numero = round(numero);
    if numero < 0
        error('wavelet:wpfun:Numero', 'Le numéro doit être positif.');
    end
    [~, ~, Lo_R, Hi_R] = wfilters(nom);
    longueur = numel(Lo_R);
    support = longueur - 1;
    pas = 2 ^ (-iterations);
    xval = 0:pas:(support - pas);
    n = numel(xval);
    fonctions = zeros(numero + 1, n);
    % W0 vient de la cascade : c'est la fonction d'échelle.
    [phi, ~, xPhi] = wavefun(nom, iterations);
    fonctions(1, :) = interp1(xPhi, phi, xval, 'linear', 0);
    for k = 1:numero
        parent = floor(k / 2);
        if mod(k, 2) == 0
            filtre = Lo_R;
        else
            filtre = Hi_R;
        end
        fonctions(k + 1, :) = deuxEchelles(fonctions(parent + 1, :), filtre, xval, pas);
    end
end

function y = deuxEchelles(parent, filtre, xval, pas)
%DEUXECHELLES Applique l'équation à deux échelles à une fonction.
%   y(x) = sqrt(2) somme_k filtre(k) parent(2x - k), la fonction parent
%   étant lue par interpolation sur la même grille.
    n = numel(xval);
    y = zeros(1, n);
    for k = 1:numel(filtre)
        if filtre(k) == 0, continue; end
        cible = 2 * xval - (k - 1);
        indices = round(cible / pas) + 1;
        valide = indices >= 1 & indices <= n;
        y(valide) = y(valide) + filtre(k) * parent(indices(valide));
    end
    y = sqrt(2) * y;
end
