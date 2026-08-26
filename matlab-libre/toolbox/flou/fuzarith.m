function y = fuzarith(x, A, B, operation)
%FUZARITH Arithmétique sur les nombres flous.
%   Y = FUZARITH(X,A,B,OPERATION) où A et B sont deux ensembles flous
%   échantillonnés sur la grille X, et OPERATION vaut 'sum', 'sub',
%   'prod' ou 'div'.
%
%   Le calcul suit le principe d'extension, appliqué par coupes de
%   niveau : à chaque niveau alpha, A et B se réduisent à deux
%   intervalles, sur lesquels l'opération est celle de l'arithmétique
%   d'intervalles. Le résultat est reconstitué en superposant les coupes.
%
%   Exemple :
%      x = linspace(-10, 30, 401);
%      a = trimf(x, [1 2 3]);
%      b = trimf(x, [4 6 8]);
%      y = fuzarith(x, a, b, 'sum');
%      x(find(y == max(y), 1))   % voisin de 8 : 2 + 6
%
%   Voir aussi TRIMF, EVALMF, DEFUZZ.
    x = double(x(:))';
    A = double(A(:))';
    B = double(B(:))';
    if numel(A) ~= numel(x) || numel(B) ~= numel(x)
        error('fuzzy:fuzarith:BadSize', ...
              'A et B doivent avoir la taille de X.');
    end
    operation = lower(char(operation));
    niveaux = linspace(0, 1, 101);
    niveaux = niveaux(2:end);
    y = zeros(size(x));
    for alpha = niveaux
        coupeA = x(A >= alpha);
        coupeB = x(B >= alpha);
        if isempty(coupeA) || isempty(coupeB)
            continue
        end
        [bas, haut] = combinerIntervalles(min(coupeA), max(coupeA), ...
                                          min(coupeB), max(coupeB), operation);
        dans = x >= bas & x <= haut;
        y(dans) = max(y(dans), alpha);
    end
end

function [bas, haut] = combinerIntervalles(a1, a2, b1, b2, operation)
%COMBINERINTERVALLES Arithmétique d'intervalles.
%   Pour le produit et le quotient, les quatre produits des bornes sont
%   calculés : le signe des opérandes décide lequel est le plus petit.
    switch operation
        case 'sum'
            bas = a1 + b1;
            haut = a2 + b2;
        case 'sub'
            bas = a1 - b2;
            haut = a2 - b1;
        case 'prod'
            produits = [a1 * b1, a1 * b2, a2 * b1, a2 * b2];
            bas = min(produits);
            haut = max(produits);
        case 'div'
            if b1 <= 0 && b2 >= 0
                error('fuzzy:fuzarith:DivisionParZero', ...
                      'Le diviseur ne doit pas contenir zéro.');
            end
            quotients = [a1 / b1, a1 / b2, a2 / b1, a2 / b2];
            bas = min(quotients);
            haut = max(quotients);
        otherwise
            error('fuzzy:fuzarith:BadOperation', ...
                  'L''opération doit être ''sum'', ''sub'', ''prod'' ou ''div''.');
    end
end
