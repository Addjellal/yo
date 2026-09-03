function [W, H, D] = nnmf(A, k, varargin)
%NNMF Factorisation en matrices non négatives.
%   [W,H] = NNMF(A,K) cherche deux matrices non négatives W (n×K) et H
%   (K×p) dont le produit approche A au sens de la norme de Frobenius.
%   À la différence de la décomposition en valeurs singulières, aucun
%   terme n'est négatif : les parties s'additionnent au lieu de se
%   compenser, ce qui rend la décomposition lisible.
%
%   [W,H,D] = NNMF(...) rend en outre la racine de l'erreur quadratique
%   moyenne résiduelle.
%
%   NNMF(...,'Algorithm','mult') emploie les mises à jour
%   multiplicatives de Lee et Seung (défaut), 'als' les moindres carrés
%   alternés.
%   NNMF(...,'W0',W0,'H0',H0) impose le point de départ,
%   'Replicates',R relance R fois et garde le meilleur,
%   'MaxIter',N et 'TolFun',T règlent l'arrêt.
%
%   Exemple :
%      A = rand(20, 3) * rand(3, 10);      % de rang 3, non négative
%      [W, H, D] = nnmf(A, 3);
%      D < 1e-3
%
%   Voir aussi PCA, SVD, KMEANS, FACTORAN.
    A = double(A);
    if any(A(:) < 0)
        error('stats:nnmf:Negatif', 'A ne doit porter aucune valeur négative.');
    end
    [n, p] = size(A);
    k = round(k);
    algorithme = 'mult';
    W0 = [];
    H0 = [];
    repliques = 1;
    maxIter = 200;
    tolFun = 1e-8;
    j = 1;
    while j + 1 <= numel(varargin)
        switch lower(char(varargin{j}))
            case 'algorithm', algorithme = lower(char(varargin{j+1}));
            case 'w0',        W0 = double(varargin{j+1});
            case 'h0',        H0 = double(varargin{j+1});
            case 'replicates', repliques = round(varargin{j+1});
            case 'maxiter',   maxIter = round(varargin{j+1});
            case 'tolfun',    tolFun = double(varargin{j+1});
            case {'options', 'display'}
                % Acceptées et sans effet.
            otherwise
                error('stats:nnmf:Option', 'Option inconnue : %s.', char(varargin{j}));
        end
        j = j + 2;
    end
    meilleurD = inf;
    W = [];
    H = [];
    for essai = 1:max(1, repliques)
        if isempty(W0)
            Wc = rand(n, k) + 0.1;
        else
            Wc = W0;
        end
        if isempty(H0)
            Hc = rand(k, p) + 0.1;
        else
            Hc = H0;
        end
        precedent = inf;
        for iteration = 1:maxIter
            if strncmp(algorithme, 'a', 1)
                % Moindres carrés alternés, ramenés dans le positif.
                Hc = max(Wc \ A, 0);
                Wc = max((Hc.' \ A.').', 0);
            else
                % Mises à jour multiplicatives : elles gardent la
                % positivité sans projection, et font décroître l'erreur.
                Hc = Hc .* (Wc.' * A) ./ max(Wc.' * Wc * Hc, eps);
                Wc = Wc .* (A * Hc.') ./ max(Wc * (Hc * Hc.'), eps);
            end
            residu = A - Wc * Hc;
            d = sqrt(sum(residu(:) .^ 2) / (n * p));
            if abs(precedent - d) < tolFun * max(1, d)
                break;
            end
            precedent = d;
        end
        if d < meilleurD
            meilleurD = d;
            W = Wc;
            H = Hc;
        end
    end
    % Normalisation à la façon de MATLAB : les colonnes de W sont de
    % norme 1, l'échelle passe dans H, et les composantes sont rangées
    % par poids décroissant.
    normes = sqrt(sum(W .^ 2, 1));
    normes(normes == 0) = 1;
    W = W ./ repmat(normes, n, 1);
    H = H .* repmat(normes.', 1, p);
    poids = sum(H, 2);
    [~, ordre] = sort(poids, 'descend');
    W = W(:, ordre);
    H = H(ordre, :);
    D = meilleurD;
end
