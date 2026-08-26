function polynomes = cyclpoly(n, k, option)
%CYCLPOLY Polynômes générateurs des codes cycliques.
%   POL = CYCLPOLY(N,K) rend un polynôme générateur d'un code cyclique
%   [N,K] : un diviseur de x^N - 1 sur GF(2), de degré N-K, écrit par
%   puissances croissantes. Par défaut c'est celui qui a le moins de
%   termes non nuls, donc le codeur le plus simple.
%
%   CYCLPOLY(N,K,'max') rend celui qui en a le plus, CYCLPOLY(N,K,'all')
%   les rend tous, une ligne par polynôme, et CYCLPOLY(N,K,W) ceux qui
%   ont exactement W termes non nuls.
%
%   Exemple :
%      cyclpoly(7, 4)   % [1 1 0 1] : 1 + x + x^3
%
%   Voir aussi CYCLGEN, HAMMGEN, GEN2PAR.
    if nargin < 3 || isempty(option), option = 'min'; end
    n = round(double(n));
    k = round(double(k));
    degre = n - k;
    if degre < 1 || k < 1
        error('comm:cyclpoly:BadSize', 'Il faut 1 <= K < N.');
    end
    % x^n - 1 vaut x^n + 1 sur GF(2), par puissances croissantes.
    cible = zeros(1, n + 1);
    cible(1) = 1;
    cible(n + 1) = 1;
    candidats = [];
    for motif = 0:(2 ^ max(degre - 1, 0) - 1)
        coefficients = zeros(1, degre + 1);
        coefficients(1) = 1;
        coefficients(degre + 1) = 1;
        reste = motif;
        for position = 2:degre
            coefficients(position) = mod(reste, 2);
            reste = floor(reste / 2);
        end
        if divisePolynomeBinaire(cible, coefficients)
            candidats(end+1, :) = coefficients;      %#ok<AGROW>
        end
    end
    if isempty(candidats)
        error('comm:cyclpoly:NoCode', ...
              'Aucun code cyclique [%d,%d] n''existe.', n, k);
    end
    poids = sum(candidats, 2)';
    if isnumeric(option)
        polynomes = candidats(poids == option, :);
        if isempty(polynomes)
            error('comm:cyclpoly:NoWeight', ...
                  'Aucun générateur n''a %d termes.', option);
        end
        return
    end
    switch lower(char(option))
        case 'all'
            polynomes = candidats;
        case 'max'
            [~, indice] = max(poids);
            polynomes = candidats(indice, :);
        otherwise
            [~, indice] = min(poids);
            polynomes = candidats(indice, :);
    end
end

function oui = divisePolynomeBinaire(dividende, diviseur)
%DIVISEPOLYNOMEBINAIRE Le reste de la division sur GF(2) est-il nul ?
%   Les deux polynômes sont donnés par puissances croissantes.
    reste = mod(dividende, 2);
    degreDiviseur = trouverDegre(diviseur);
    for position = trouverDegre(reste):-1:degreDiviseur
        if reste(position + 1) == 1
            decalage = position - degreDiviseur;
            for j = 0:degreDiviseur
                reste(decalage + j + 1) = mod(reste(decalage + j + 1) + diviseur(j + 1), 2);
            end
        end
    end
    oui = ~any(reste);
end

function d = trouverDegre(p)
    d = find(p ~= 0, 1, 'last') - 1;
    if isempty(d), d = 0; end
end
