function trellis = poly2trellis(contrainte, generateurs, retour)
%POLY2TRELLIS Treillis d'un codeur convolutif.
%   TRELLIS = POLY2TRELLIS(CONTRAINTE,GENERATEURS) décrit le codeur de
%   longueur de contrainte CONTRAINTE et de polynômes GENERATEURS, écrits
%   en octal. Pour un rendement k/n, CONTRAINTE est un vecteur de k
%   longueurs et GENERATEURS une matrice k x n.
%
%   La structure rendue porte les champs de MATLAB :
%     numInputSymbols   2^k
%     numOutputSymbols  2^n
%     numStates         2^(somme des CONTRAINTE - k)
%     nextStates        état suivant, indexé (état+1, symbole d'entrée+1)
%     outputs           symbole de sortie, en octal, même indexation
%
%   L'état numérote le contenu des registres : le registre de la première
%   entrée est le plus significatif, et dans chaque registre le bit entré
%   le plus récemment est le plus significatif.
%
%   TRELLIS = POLY2TRELLIS(CONTRAINTE,GENERATEURS,RETOUR) décrit un codeur
%   récursif, RETOUR donnant les polynômes de rebouclage en octal.
%
%   Exemple :
%      t = poly2trellis(3, [7 5]);
%      t.nextStates   % [0 2; 0 2; 1 3; 1 3]
%      t.outputs      % [0 3; 3 0; 2 1; 1 2]
%
%   Voir aussi ISTRELLIS, CONVENC, VITDEC.
    contrainte = double(contrainte(:))';
    k = numel(contrainte);
    if size(generateurs, 1) ~= k
        if k == 1
            generateurs = generateurs(:)';
        else
            error('comm:poly2trellis:BadSize', ...
                  'GENERATEURS doit avoir autant de lignes que CONTRAINTE d''éléments.');
        end
    end
    n = size(generateurs, 2);
    if nargin < 3 || isempty(retour)
        retour = zeros(k, 1);
        for i = 1:k
            retour(i) = dec2oct(2 ^ (contrainte(i) - 1));
        end
    end
    retour = double(retour(:));
    memoires = contrainte - 1;
    totalMemoire = sum(memoires);
    nEtats = 2 ^ totalMemoire;
    nEntrees = 2 ^ k;
    % Coefficients binaires, le plus significatif portant l'entrée courante.
    coefficients = cell(k, n);
    for i = 1:k
        for j = 1:n
            coefficients{i, j} = bitsDepuisOctal(generateurs(i, j), contrainte(i));
        end
    end
    coefficientsRetour = cell(k, 1);
    for i = 1:k
        coefficientsRetour{i} = bitsDepuisOctal(retour(i), contrainte(i));
    end
    nextStates = zeros(nEtats, nEntrees);
    outputs = zeros(nEtats, nEntrees);
    for etat = 0:nEtats-1
        registres = decouperEtat(etat, memoires);
        for symbole = 0:nEntrees-1
            entrees = bitsSymbole(symbole, k);
            sorties = zeros(1, n);
            nouveauxRegistres = registres;
            for i = 1:k
                if memoires(i) == 0
                    avance = entrees(i);
                    contenu = zeros(1, 0);
                else
                    contenu = registres{i};
                    % Rebouclage : le bit qui entre dans le registre est
                    % l'entrée corrigée par les prises de retour.
                    prises = coefficientsRetour{i};
                    avance = entrees(i);
                    if numel(prises) > 1
                        avance = mod(avance + sum(prises(2:end) .* contenu), 2);
                    end
                    nouveauxRegistres{i} = [avance, contenu(1:end-1)];
                end
                etatComplet = [avance, contenu];
                for j = 1:n
                    sorties(j) = mod(sorties(j) + sum(coefficients{i, j} .* etatComplet), 2);
                end
            end
            nextStates(etat + 1, symbole + 1) = recomposerEtat(nouveauxRegistres, memoires);
            outputs(etat + 1, symbole + 1) = dec2oct(sum(sorties .* 2 .^ (n-1:-1:0)));
        end
    end
    trellis = struct('numInputSymbols', nEntrees, ...
                     'numOutputSymbols', 2 ^ n, ...
                     'numStates', nEtats, ...
                     'nextStates', nextStates, ...
                     'outputs', outputs);
end

function bits = bitsDepuisOctal(valeur, longueur)
%BITSDEPUISOCTAL Coefficients binaires, du plus significatif au moindre.
    d = oct2dec(valeur);
    bits = zeros(1, longueur);
    for position = longueur:-1:1
        bits(position) = mod(d, 2);
        d = floor(d / 2);
    end
end

function registres = decouperEtat(etat, memoires)
%DECOUPERETAT Contenu de chaque registre, le premier étant le plus fort.
    registres = cell(1, numel(memoires));
    reste = etat;
    for i = numel(memoires):-1:1
        m = memoires(i);
        if m == 0
            registres{i} = zeros(1, 0);
            continue
        end
        valeur = mod(reste, 2 ^ m);
        reste = floor(reste / 2 ^ m);
        bits = zeros(1, m);
        for position = m:-1:1
            bits(position) = mod(valeur, 2);
            valeur = floor(valeur / 2);
        end
        registres{i} = bits;
    end
end

function etat = recomposerEtat(registres, memoires)
    etat = 0;
    for i = 1:numel(memoires)
        m = memoires(i);
        if m == 0, continue, end
        bits = registres{i};
        etat = etat * 2 ^ m + sum(bits .* 2 .^ (m-1:-1:0));
    end
end

function bits = bitsSymbole(symbole, k)
    bits = zeros(1, k);
    for position = k:-1:1
        bits(position) = mod(symbole, 2);
        symbole = floor(symbole / 2);
    end
end
