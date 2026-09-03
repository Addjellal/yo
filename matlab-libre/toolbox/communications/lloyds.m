function [partition, codebook, distorsion, sortiesRelatives] = lloyds(donnees, depart, tolerance)
%LLOYDS Quantificateur optimal, par l'algorithme de Lloyd.
%   [PARTITION,CODEBOOK] = LLOYDS(X,N) cherche le quantificateur à N
%   niveaux qui minimise la distorsion sur le signal X. PARTITION porte
%   les N-1 seuils, CODEBOOK les N valeurs.
%
%   [PARTITION,CODEBOOK] = LLOYDS(X,CODEBOOK0) part d'un dictionnaire
%   donné plutôt que d'une partition régulière.
%   LLOYDS(X,N,TOL) fixe le seuil d'arrêt (1e-7 par défaut).
%   [P,C,D] = LLOYDS(...) rend la distorsion atteinte, et un quatrième
%   argument la distorsion relative au dernier tour.
%
%   L'algorithme alterne deux conditions d'optimalité : chaque valeur va
%   au niveau le plus proche, et chaque niveau se place au barycentre de
%   ce qu'il reçoit. La distorsion baisse à chaque tour et converge vers
%   un minimum local.
%
%   Exemple :
%      x = randn(1, 1000);
%      [p, c, d] = lloyds(x, 4);
%      numel(c)                       % 4
%
%   Voir aussi QUANTIZ, DPCMOPT, KMEANS.
    if nargin < 3 || isempty(tolerance), tolerance = 1e-7; end
    donnees = double(donnees(:)).';
    if isempty(donnees)
        error('comm:lloyds:Donnees', 'Il faut des données.');
    end
    if isscalar(depart)
        n = round(depart);
        if n < 1
            error('comm:lloyds:Niveaux', 'Il faut au moins un niveau.');
        end
        bas = min(donnees);
        haut = max(donnees);
        if haut == bas
            haut = bas + 1;
        end
        codebook = bas + (haut - bas) * ((1:n) - 0.5) / n;
    else
        codebook = double(depart(:)).';
        n = numel(codebook);
    end
    codebook = sort(codebook);
    distorsionPrecedente = Inf;
    for tour = 1:1000
        partition = (codebook(1:end-1) + codebook(2:end)) / 2;
        indices = zeros(size(donnees));
        for k = 1:numel(donnees)
            indices(k) = sum(donnees(k) > partition);
        end
        for j = 1:n
            dedans = indices == (j - 1);
            if any(dedans)
                codebook(j) = mean(donnees(dedans));
            end
        end
        codebook = sort(codebook);
        distorsion = mean((donnees - codebook(indices + 1)) .^ 2);
        if distorsionPrecedente < Inf
            relative = abs(distorsionPrecedente - distorsion) / max(distorsion, eps);
            if relative < tolerance
                break
            end
        end
        distorsionPrecedente = distorsion;
    end
    partition = (codebook(1:end-1) + codebook(2:end)) / 2;
    indices = zeros(size(donnees));
    for k = 1:numel(donnees)
        indices(k) = sum(donnees(k) > partition);
    end
    distorsion = mean((donnees - codebook(indices + 1)) .^ 2);
    if nargout > 3
        sortiesRelatives = distorsion / max(var(donnees), eps);
    end
end
