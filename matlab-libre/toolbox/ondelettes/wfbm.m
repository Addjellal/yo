function [fBm, bruit] = wfbm(H, L, varargin)
%WFBM Mouvement brownien fractionnaire.
%   FBM = WFBM(H,L) tire un mouvement brownien fractionnaire de L points,
%   de paramètre de Hurst H compris strictement entre zéro et un.
%
%   H = 0,5 donne le mouvement brownien ordinaire, à accroissements
%   indépendants. Au-dessus, les accroissements sont corrélés
%   positivement : la trajectoire persiste dans sa direction. En dessous,
%   ils s'opposent : elle revient sans cesse sur ses pas.
%
%   [FBM,BRUIT] = WFBM(H,L) rend en outre le bruit gaussien
%   fractionnaire, dont FBM est la somme cumulée.
%
%   La synthèse est celle de Davies et Harte : le bruit fractionnaire est
%   engendré par plongement circulant de sa matrice de covariance, ce qui
%   donne des échantillons de covariance exacte — et non approchée.
%   MATLAB emploie une synthèse par ondelettes ; les deux tirent la même
%   loi.
%
%   Exemple :
%      x = wfbm(0.7, 1024);
%      wfbmesti(x)                    % trois estimations, voisines de 0,7
%
%   Voir aussi WFBMESTI, WNOISE, RANDN, CUMSUM.
    if nargin < 2 || isempty(L), L = 1024; end
    L = round(L);
    if H <= 0 || H >= 1
        error('wavelet:wfbm:Hurst', ...
              'Le paramètre de Hurst doit être strictement entre zéro et un.');
    end
    if L < 2
        error('wavelet:wfbm:Longueur', 'Il faut au moins deux points.');
    end
    bruit = bruitFractionnaire(H, L);
    fBm = cumsum(bruit);
end

function g = bruitFractionnaire(H, n)
%BRUITFRACTIONNAIRE Bruit gaussien fractionnaire, par plongement circulant.
%   La covariance du bruit fractionnaire vaut
%
%      r(k) = ( |k+1|^2H - 2|k|^2H + |k-1|^2H ) / 2.
%
%   On la plonge dans une matrice circulante de taille 2m, dont les
%   valeurs propres sont la transformée de Fourier de la première ligne.
%   Si elles sont toutes positives — c'est le cas pour ce noyau —, une
%   racine carrée s'en déduit, et le tirage est exact.
    m = 2 ^ ceil(log2(n));
    k = 0:m;
    r = 0.5 * (abs(k + 1) .^ (2 * H) - 2 * abs(k) .^ (2 * H) + abs(k - 1) .^ (2 * H));
    ligne = [r, r(m:-1:2)];
    valeursPropres = real(fft(ligne));
    if any(valeursPropres < 0)
        % Le plongement a échoué : on retombe sur la racine carrée de la
        % partie positive, ce qui reste une bonne approximation.
        valeursPropres = max(valeursPropres, 0);
    end
    taille = numel(ligne);
    bruitComplexe = (randn(1, taille) + 1i * randn(1, taille)) / sqrt(2);
    tirage = real(ifft(sqrt(valeursPropres) .* bruitComplexe)) * sqrt(taille);
    g = tirage(1:n);
end
