function taux = berfading(EbNodB, methode, M, diversite)
%BERFADING Taux d'erreur binaire théorique sur canal de Rayleigh.
%   BER = BERFADING(EBNO,'psk',M,L) rend le taux d'erreur binaire d'une
%   modulation de phase à M états sur un canal à évanouissements de
%   Rayleigh, avec une diversité d'ordre L combinée à gain maximal. EBNO
%   est le rapport moyen par branche, en décibels.
%
%   Pour la modulation à deux états, la formule est close :
%
%      p  = (1 - sqrt(g/(1+g))) / 2,   g = 10^(EBNO/10)
%      Pb = p^L * somme_{k=0}^{L-1} C(L-1+k,k) (1-p)^k
%
%   Pour les autres ordres, le taux gaussien est moyenné sur la loi du
%   rapport signal sur bruit combiné, qui suit une loi gamma de forme L
%   et d'échelle g.
%
%   La différence avec le canal gaussien est spectaculaire : là où
%   BERAWGN décroît exponentiellement, BERFADING décroît en 1/EbNo à la
%   puissance L. C'est tout l'intérêt de la diversité.
%
%   Exemple :
%      berfading(10, 'psk', 2, 1)   % 0.0233
%      berfading(10, 'psk', 2, 2)   % 0.0016
%
%   Voir aussi BERAWGN, AWGN.
    if nargin < 2 || isempty(methode), methode = 'psk'; end
    if nargin < 3 || isempty(M), M = 2; end
    if nargin < 4 || isempty(diversite), diversite = 1; end
    L = round(double(diversite));
    if L < 1
        error('comm:berfading:BadOrder', 'L''ordre de diversité doit valoir au moins un.');
    end
    EbNodB = double(EbNodB);
    taux = zeros(size(EbNodB));
    for indice = 1:numel(EbNodB)
        g = 10 ^ (EbNodB(indice) / 10);
        if strcmpi(char(methode), 'psk') && (M == 2 || M == 4)
            % Deux et quatre états ont le même taux binaire : le codage de
            % Gray fait de la MDP-4 deux MDP-2 en quadrature.
            p = (1 - sqrt(g / (1 + g))) / 2;
            somme = 0;
            coefficient = 1;
            for k = 0:L-1
                somme = somme + coefficient * (1 - p) ^ k;
                coefficient = coefficient * (L - 1 + k + 1) / (k + 1);
            end
            taux(indice) = p ^ L * somme;
        else
            taux(indice) = moyennerSurGamma(g, L, methode, M);
        end
    end
end

function valeur = moyennerSurGamma(gammaMoyen, L, methode, M)
%MOYENNERSURGAMMA Espérance du taux gaussien sous une loi gamma(L, g).
%   La substitution u = gamma / g ramène l'intégrale à une forme de
%   Laguerre, dont l'intégrande décroît en exp(-u) : une grille fine sur
%   [0, 60 + 8L] suffit largement.
    borne = 60 + 8 * L;
    points = 20000;
    u = linspace(1e-9, borne, points);
    logDensite = (L - 1) * log(u) - u - gammaln(L);
    densite = exp(logDensite);
    snrdB = 10 * log10(gammaMoyen * u);
    taux = berawgn(snrdB, methode, M);
    valeur = trapz(u, taux .* densite);
end
