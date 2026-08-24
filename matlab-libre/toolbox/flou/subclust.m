function [centres, sigmas] = subclust(X, rayons, bornes, options)
%SUBCLUST Classification par soustraction, méthode de Chiu.
%   C = SUBCLUST(X,RA) cherche les centres de classes sans qu'on ait à
%   dire combien. Chaque point reçoit un potentiel, somme des influences
%   de tous les autres :
%
%      P(i) = somme_j exp(-4 ||x_i - x_j||^2 / RA^2)
%
%   Le point de potentiel maximal devient un centre ; on retranche alors
%   son influence à tous les autres, et on recommence. Un point entouré
%   de voisins gagne, un point isolé perd : le nombre de classes sort du
%   calcul au lieu d'y entrer.
%
%   [C,S] = SUBCLUST(...) rend aussi les écarts types à donner aux
%   fonctions d'appartenance gaussiennes construites autour des centres.
%
%   SUBCLUST(X,RA,BORNES,OPTIONS) où OPTIONS vaut
%     [ECRASEMENT ACCEPTATION REJET AFFICHAGE]
%   valant par défaut [1.25 0.5 0.15 0]. L'écrasement fixe le rayon de
%   soustraction, plus large que le rayon d'influence pour que deux
%   centres ne se collent pas.
%
%   Exemple :
%      c = subclust([randn(50,2); randn(50,2) + 8], 0.5);
%
%   Voir aussi FCM, GENFIS2.
    if nargin < 2 || isempty(rayons), rayons = 0.5; end
    if nargin < 3, bornes = []; end
    if nargin < 4 || isempty(options), options = []; end
    reglages = [1.25, 0.5, 0.15, 0];
    for k = 1:min(numel(options), 4)
        if ~isnan(options(k)), reglages(k) = options(k); end
    end
    ecrasement = reglages(1);
    acceptation = reglages(2);
    rejet = reglages(3);
    affichage = reglages(4);
    X = double(X);
    [n, d] = size(X);
    if numel(rayons) == 1
        rayons = repmat(rayons, 1, d);
    end
    if isempty(bornes)
        bornes = [min(X, [], 1); max(X, [], 1)];
    end
    etendue = bornes(2, :) - bornes(1, :);
    etendue(etendue == 0) = 1;
    % Normalisation dans le cube unité : les rayons y ont un sens commun.
    Xn = (X - repmat(bornes(1, :), n, 1)) ./ repmat(etendue, n, 1);
    alpha = 4 ./ (rayons .^ 2);
    beta = 4 ./ ((ecrasement * rayons) .^ 2);
    potentiels = zeros(n, 1);
    for i = 1:n
        ecarts = Xn - repmat(Xn(i, :), n, 1);
        potentiels(i) = sum(exp(-sum((ecarts .^ 2) .* repmat(alpha, n, 1), 2)));
    end
    [potentielMax, indice] = max(potentiels);
    premierPotentiel = potentielMax;
    centresNormalises = [];
    while potentielMax > 0
        rapport = potentielMax / premierPotentiel;
        if rapport > acceptation
            accepter = true;
        elseif rapport < rejet
            break
        else
            % Zone grise : on garde le centre s'il est assez loin des
            % précédents, faute de quoi on l'écarte définitivement.
            if isempty(centresNormalises)
                accepter = true;
            else
                ecarts = centresNormalises - repmat(Xn(indice, :), size(centresNormalises, 1), 1);
                distanceMin = sqrt(min(sum(ecarts .^ 2, 2)));
                accepter = (distanceMin / mean(rayons) + rapport) >= 1;
            end
            if ~accepter
                potentiels(indice) = 0;
                [potentielMax, indice] = max(potentiels);
                continue
            end
        end
        centresNormalises = [centresNormalises; Xn(indice, :)];   %#ok<AGROW>
        if affichage
            fprintf('subclust : centre %d, potentiel %.4f\n', size(centresNormalises, 1), potentielMax);
        end
        ecarts = Xn - repmat(Xn(indice, :), n, 1);
        potentiels = potentiels - potentielMax * ...
            exp(-sum((ecarts .^ 2) .* repmat(beta, n, 1), 2));
        potentiels = max(potentiels, 0);
        [potentielMax, indice] = max(potentiels);
    end
    centres = centresNormalises .* repmat(etendue, size(centresNormalises, 1), 1) + ...
              repmat(bornes(1, :), size(centresNormalises, 1), 1);
    sigmas = rayons .* etendue / sqrt(8);
end
