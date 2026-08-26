function [parmat, genmat, k] = cyclgen(n, polynome)
%CYCLGEN Matrices d'un code cyclique.
%   [PARMAT,GENMAT,K] = CYCLGEN(N,POL) rend la matrice de contrôle et la
%   matrice génératrice, sous forme systématique, du code cyclique de
%   longueur N engendré par POL, donné par puissances croissantes.
%
%   La construction est directe : la ligne i de la génératrice code le
%   mot x^(N-i), corrigé de son reste modulo POL pour que le résultat soit
%   divisible. Les K premières colonnes forment donc l'identité, et le
%   message se lit tel quel dans le mot de code.
%
%   Exemple :
%      [h, g, k] = cyclgen(7, cyclpoly(7, 4));
%      k                                  % 4
%      max(max(mod(g * h', 2)))           % nul
%
%   Voir aussi CYCLPOLY, HAMMGEN, GEN2PAR.
    n = round(double(n));
    polynome = mod(double(polynome(:))', 2);
    degre = find(polynome ~= 0, 1, 'last') - 1;
    if isempty(degre) || degre < 1
        error('comm:cyclgen:BadPolynomial', 'Le polynôme doit être de degré au moins un.');
    end
    k = n - degre;
    if k < 1
        error('comm:cyclgen:BadSize', 'Le degré du polynôme doit rester sous N.');
    end
    genmat = zeros(k, n);
    for i = 1:k
        % Mot x^(n-i), écrit par puissances croissantes sur n coefficients.
        mot = zeros(1, n);
        mot(n - i + 1) = 1;
        reste = restePolynomeBinaire(mot, polynome);
        ligne = mod(mot + reste, 2);
        % Passage aux puissances décroissantes, colonne 1 = x^(n-1).
        genmat(i, :) = ligne(end:-1:1);
    end
    P = genmat(:, k + 1:end);
    parmat = [P', eye(n - k)];
end

function reste = restePolynomeBinaire(dividende, diviseur)
%RESTEPOLYNOMEBINAIRE Reste de la division sur GF(2), puissances croissantes.
    reste = mod(dividende, 2);
    degreDiviseur = find(diviseur ~= 0, 1, 'last') - 1;
    for position = (numel(reste) - 1):-1:degreDiviseur
        if reste(position + 1) == 1
            decalage = position - degreDiviseur;
            for j = 0:degreDiviseur
                reste(decalage + j + 1) = mod(reste(decalage + j + 1) + diviseur(j + 1), 2);
            end
        end
    end
end
