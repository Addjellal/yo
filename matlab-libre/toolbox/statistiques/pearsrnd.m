function [r, type, coefficients] = pearsrnd(mu, sigma, asymetrie, aplatissement, varargin)
%PEARSRND Tirages d'une loi du système de Pearson.
%   R = PEARSRND(MU,SIGMA,SKEW,KURT,M,N) tire dans la loi du système de
%   Pearson dont les quatre premiers moments sont ceux demandés :
%   moyenne, écart type, coefficient d'asymétrie et coefficient
%   d'aplatissement.
%
%   Le système de Pearson est l'ensemble des lois dont la densité vérifie
%
%      p'(x)/p(x) = -(a + x) / (c0 + c1 x + c2 x^2),
%
%   les quatre coefficients se lisant sur les quatre premiers moments.
%   Suivant les racines du dénominateur, on retrouve la normale, la
%   bêta, la gamma, la Student, la bêta de seconde espèce : sept familles
%   qui couvrent tout couple (asymétrie, aplatissement) admissible.
%
%   MatLibre intègre l'équation sur une grille et tire par inversion de
%   la répartition, ce qui traite les sept familles d'une seule façon ;
%   MATLAB choisit la famille et emploie un tirage propre à chacune. Les
%   moments obtenus sont les mêmes.
%
%   [R,TYPE] = PEARSRND(...) rend le numéro de la famille,
%   [R,TYPE,COEF] = PEARSRND(...) les coefficients de l'équation.
%
%   Exemple :
%      r = pearsrnd(0, 1, 0.75, 4, 20000, 1);
%      skewness(r)      % proche de 0,75
%
%   Voir aussi RANDOM, SKEWNESS, KURTOSIS, MLE, FITDIST.
    if nargin < 4
        error('stats:pearsrnd:Arguments', 'pearsrnd attend quatre moments.');
    end
    dimensions = varargin;
    if isempty(dimensions)
        dimensions = {1, 1};
    elseif numel(dimensions) == 1
        dimensions = {dimensions{1}, dimensions{1}};
    end
    n = prod(cell2mat(dimensions));
    beta1 = asymetrie ^ 2;
    beta2 = aplatissement;
    if beta2 <= beta1 + 1
        error('stats:pearsrnd:Moments', ...
              'L''aplatissement doit dépasser le carré de l''asymétrie plus un.');
    end
    if abs(beta1) < 1e-12 && abs(beta2 - 3) < 1e-12
        type = 0;
        r = randn(n, 1);
        coefficients = [0 1 0 0];
        r = reshape(mu + sigma * r, dimensions{:});
        return;
    end
    % Coefficients de l'équation de Pearson pour la variable centrée
    % réduite, dans la paramétrisation d'Elderton et Johnson.
    denominateur = 10 * beta2 - 12 * beta1 - 18;
    if abs(denominateur) < 1e-10
        denominateur = sign(denominateur + eps) * 1e-10;
    end
    a = asymetrie * (beta2 + 3) / denominateur;
    c0 = (4 * beta2 - 3 * beta1) / denominateur;
    c1 = a;
    c2 = (2 * beta2 - 3 * beta1 - 6) / denominateur;
    coefficients = [a, c0, c1, c2];
    type = familleDePearson(beta1, beta2, c0, c1, c2);
    [grille, densite] = densiteDePearson(a, c0, c1, c2);
    % Tirage par inversion de la répartition, interpolée linéairement.
    repartition = cumsum(densite);
    repartition = repartition / repartition(end);
    [repartition, garde] = unique(repartition);
    r = interp1(repartition, grille(garde), rand(n, 1), 'linear', 'extrap');
    % Les moments d'ordre un et deux sont imposés exactement ; les deux
    % suivants viennent de la forme de la densité.
    r = (r - mean(r)) / max(std(r), eps);
    r = reshape(mu + sigma * r, dimensions{:});
end

function type = familleDePearson(beta1, beta2, c0, c1, c2)
% Le critère kappa départage les familles ; les cas dégénérés — c2 nul,
% discriminant nul — donnent les familles à support semi-infini.
    if abs(c2) < 1e-10
        if abs(c1) < 1e-10
            type = 0;          % normale
        else
            type = 3;          % gamma
        end
        return;
    end
    discriminant = c1 ^ 2 - 4 * c0 * c2;
    if abs(discriminant) < 1e-10
        type = 5;
    elseif discriminant > 0
        racines = roots([c2, c1, c0]);
        if prod(racines) < 0
            type = 1;          % bêta, support borné
        else
            type = 6;          % bêta de seconde espèce
        end
    else
        if abs(beta1) < 1e-10
            type = 7;          % Student
        else
            type = 4;
        end
    end
end

function [grille, densite] = densiteDePearson(a, c0, c1, c2)
% Intégration de p'/p sur une grille, entre les bornes du support.
%   Le support s'arrête aux racines réelles du dénominateur : c'est là
%   que la densité s'annule.
    [bas, haut] = supportDePearson(c0, c1, c2);
    m = 20001;
    grille = linspace(bas, haut, m);
    pas = grille(2) - grille(1);
    % On intègre le logarithme, ce qui évite les débordements, en
    % partant du milieu de la grille.
    logDensite = zeros(1, m);
    milieu = round(m / 2);
    for k = milieu:-1:2
        x = (grille(k) + grille(k - 1)) / 2;
        logDensite(k - 1) = logDensite(k) + pas * pente(x, a, c0, c1, c2);
    end
    for k = milieu:(m - 1)
        x = (grille(k) + grille(k + 1)) / 2;
        logDensite(k + 1) = logDensite(k) - pas * pente(x, a, c0, c1, c2);
    end
    logDensite = logDensite - max(logDensite);
    densite = exp(logDensite);
    densite(~isfinite(densite)) = 0;
end

function d = pente(x, a, c0, c1, c2)
% -(a+x)/(c0+c1 x+c2 x^2), bornée pour rester intégrable près des bords.
    denominateur = c0 + c1 * x + c2 * x ^ 2;
    if abs(denominateur) < 1e-12
        denominateur = sign(denominateur + eps) * 1e-12;
    end
    d = (a + x) / denominateur;
    d = max(min(d, 1e6), -1e6);
end

function [bas, haut] = supportDePearson(c0, c1, c2)
    limite = 60;
    bas = -limite;
    haut = limite;
    if abs(c2) > 1e-12
        discriminant = c1 ^ 2 - 4 * c0 * c2;
        if discriminant > 0
            racines = sort(roots([c2, c1, c0]));
            if c2 > 0
                % Le dénominateur est positif hors des racines : le
                % support est l'intervalle qui contient l'origine.
                if racines(1) < 0 && racines(2) > 0
                    bas = racines(1) * (1 - 1e-9);
                    haut = racines(2) * (1 - 1e-9);
                elseif racines(2) < 0
                    bas = racines(2) * (1 - 1e-9);
                else
                    haut = racines(1) * (1 - 1e-9);
                end
            else
                bas = max(racines(1) * (1 - 1e-9), -limite);
                haut = min(racines(2) * (1 - 1e-9), limite);
            end
        end
    elseif abs(c1) > 1e-12
        racine = -c0 / c1;
        if c1 > 0
            bas = max(racine * (1 + 1e-9), -limite);
        else
            haut = min(racine * (1 - 1e-9), limite);
        end
    end
    if ~(haut > bas)
        bas = -limite;
        haut = limite;
    end
end
