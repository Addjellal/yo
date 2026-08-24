function [phi, psi, xval] = wavefun(nom, iterations)
%WAVEFUN Fonctions d'échelle et d'ondelette, par l'algorithme en cascade.
%   [PHI,PSI,XVAL] = WAVEFUN(NOM,ITER) approche la fonction d'échelle et
%   la fonction d'ondelette de l'ondelette orthogonale NOM. On part d'une
%   impulsion et on applique ITER fois l'équation à deux échelles
%
%      phi(x) = sqrt(2) * somme_n Lo_R(n) phi(2x - n)
%      psi(x) = sqrt(2) * somme_n Hi_R(n) phi(2x - n)
%
%   chaque tour doublant la résolution. Les deux fonctions sont rendues
%   sur la même grille XVAL, de pas 2^-ITER, qui couvre le support
%   commun [0, L-1] où L est la longueur du filtre. Le vecteur compte
%   donc 2^ITER*(L-1)+1 points et l'échelonnement est celui de MATLAB :
%   l'intégrale de PHI vaut 1 et celle de PSI vaut 0.
%
%   Exemple :
%      [phi, psi, x] = wavefun('db2', 8);
%      numel(x)                % 769
%      sum(phi) * (x(2)-x(1))  % 1
%      sum(psi) * (x(2)-x(1))  % 0
%
%   Pour une ondelette continue — 'mexh', 'morl', 'gausP' — il n'y a pas
%   de fonction d'échelle : l'appel prend alors la forme de MATLAB
%
%      [PSI,XVAL] = WAVEFUN('mexh',ITER)
%
%   et l'ondelette est échantillonnée sur 2^ITER points de son support
%   effectif.
%
%   Voir aussi WFILTERS, CENTFRQ, UPCOEF, MEXIHAT, MORLET, GAUSWAVF.
    if nargin < 2 || isempty(iterations), iterations = 8; end
    iterations = max(1, round(double(iterations)));
    [bas, haut, famille, ordre] = supportOndeletteContinue(nom);
    if ~isempty(famille)
        points = 2 ^ iterations;
        switch famille
            case 'mexh'
                [phi, psi] = mexihat(bas, haut, points);
            case 'morl'
                [phi, psi] = morlet(bas, haut, points);
            otherwise
                [phi, psi] = gauswavf(bas, haut, points, ordre);
        end
        xval = psi;
        return
    end
    [~, ~, Lo_R, Hi_R] = wfilters(nom);
    Lo_R = Lo_R(:)';
    Hi_R = Hi_R(:)';
    longueur = numel(Lo_R);
    pas = 2 ^ (-iterations);
    % Cascade : ITER-1 raffinements de la seule fonction d'échelle. À chaque
    % tour, phi est suréchantillonné d'un facteur deux puis filtré, ce qui
    % divise le pas de la grille par deux.
    grossier = 1;
    for k = 1:(iterations - 1)
        grossier = sqrt(2) * conv(dyadup(grossier), Lo_R);
    end
    % Dernier tour. Les deux équations à deux échelles s'écrivent, sur la
    % grille de pas 2^-ITER,
    %    phi(m 2^-ITER) = sqrt(2) somme_n Lo_R(n) grossier(m - n 2^(ITER-1))
    %    psi(m 2^-ITER) = sqrt(2) somme_n Hi_R(n) grossier(m - n 2^(ITER-1))
    % soit une convolution de l'approximation grossière par le filtre
    % dilaté de 2^(ITER-1) — et non par le filtre à pas unité, qui
    % ferait osciller psi à la fréquence d'échantillonnage.
    facteur = 2 ^ (iterations - 1);
    basDilate = zeros(1, (longueur - 1) * facteur + 1);
    hautDilate = basDilate;
    basDilate(1:facteur:end) = Lo_R;
    hautDilate(1:facteur:end) = Hi_R;
    phi = sqrt(2) * conv(basDilate, grossier);
    psi = sqrt(2) * conv(hautDilate, grossier);
    % La cascade s'arrête (L-2) échantillons avant le bord droit du support
    % (elle couvre [0, (L-1)(1-2^-ITER)]) : on complète par des zéros pour
    % obtenir exactement le support [0, L-1].
    n = round((longueur - 1) / pas) + 1;
    phi(end+1:n) = 0;
    psi(end+1:n) = 0;
    phi = phi(1:n);
    psi = psi(1:n);
    xval = (0:n-1) * pas;
end
