function Lo_R = daubechiesFiltre(N, phase)
%DAUBECHIESFILTRE Filtre d'échelle de Daubechies à N moments nuls.
%   LO = DAUBECHIESFILTRE(N) construit le filtre de longueur 2N par
%   factorisation spectrale, sans recopier aucune table.
%
%   La méthode est celle de Daubechies : le module carré du filtre vaut
%
%      |H(w)|^2 = 2 cos(w/2)^(2N) P(sin(w/2)^2),
%      P(y) = somme des C(N-1+k, k) y^k,
%
%   et l'on en prend une racine carrée en factorisant P. Chaque racine de
%   P donne une paire de racines réciproques en z : garder celle de
%   l'intérieur donne le filtre à phase minimale, c'est-à-dire dbN ;
%   choisir la combinaison la moins asymétrique donne le symlet symN.
%
%   PHASE vaut 'minimale' (par défaut) ou 'symetrique'.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 2 || isempty(phase), phase = 'minimale'; end
    N = round(N);
    if N < 1
        error('wavelet:daubechiesFiltre:BadOrder', 'N doit valoir au moins 1.');
    end
    if N == 1
        Lo_R = [1 1] / sqrt(2);
        return
    end
    % Polynôme P(y) = somme C(N-1+k, k) y^k, puissances décroissantes.
    coefficients = zeros(1, N);
    for k = 0:N-1
        coefficients(N - k) = nchoosek(N - 1 + k, k);
    end
    racinesY = roots(coefficients);
    % y = -(z - 2 + 1/z)/4  =>  z^2 - (2 - 4y) z + 1 = 0.
    paires = cell(1, numel(racinesY));
    for k = 1:numel(racinesY)
        y = racinesY(k);
        b = 2 - 4 * y;
        discriminant = sqrt(b ^ 2 - 4);
        z1 = (b + discriminant) / 2;
        z2 = (b - discriminant) / 2;
        if abs(z1) > abs(z2)
            paires{k} = [z2 z1];      % d'abord l'intérieur du cercle
        else
            paires{k} = [z1 z2];
        end
    end
    if strncmpi(char(phase), 'sym', 3)
        choix = choisirMoinsAsymetrique(paires, N);
    else
        choix = ones(1, numel(paires));   % toujours la racine intérieure
    end
    racines = zeros(1, numel(paires));
    for k = 1:numel(paires)
        racines(k) = paires{k}(choix(k));
    end
    Lo_R = poly([-ones(1, N), racines]);
    Lo_R = real(Lo_R);
    Lo_R = Lo_R / sum(Lo_R) * sqrt(2);
end

function choix = choisirMoinsAsymetrique(paires, N)
%CHOISIRMOINSASYMETRIQUE Combinaison de racines la plus proche de la symétrie.
%   On mesure l'écart du retard de groupe à sa moyenne : le symlet est
%   la factorisation qui minimise cet écart.
    m = numel(paires);
    meilleur = Inf;
    choix = ones(1, m);
    for masque = 0:(2 ^ m - 1)
        essai = ones(1, m);
        for k = 1:m
            if bitand(masque, 2 ^ (k - 1)) ~= 0
                essai(k) = 2;
            end
        end
        racines = zeros(1, m);
        for k = 1:m
            racines(k) = paires{k}(essai(k));
        end
        % Une combinaison n'est admissible que si le filtre est réel :
        % les racines complexes doivent aller par paires conjuguées.
        candidat = poly([-ones(1, N), racines]);
        if max(abs(imag(candidat))) > 1e-8 * max(abs(candidat))
            continue
        end
        candidat = real(candidat) / sum(real(candidat)) * sqrt(2);
        ecart = asymetrie(candidat);
        if ecart < meilleur - 1e-12
            meilleur = ecart;
            choix = essai;
        end
    end
end

function e = asymetrie(h)
%ASYMETRIE Écart quadratique entre le filtre et son renversé.
    e = sum((h - fliplr(h)) .^ 2);
end
