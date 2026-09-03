function [quotient, reste] = gfdeconv(a, b, p)
%GFDECONV Division de deux polynômes dans un corps de Galois.
%   [Q,R] = GFDECONV(A,B,P) divise le polynôme A par B dans GF(P), P
%   premier : A = GFADD(GFCONV(Q,B,P),R,P), le degré de R étant plus
%   petit que celui de B. Les coefficients vont par puissances
%   croissantes.
%   [Q,R] = GFDECONV(A,B) le fait dans GF(2).
%
%   La division est possible parce que tout coefficient non nul d'un
%   corps a un inverse : c'est lui qui sert de pivot à chaque étape.
%
%   Exemple :
%      [q, r] = gfdeconv([1 0 1], [1 1]);   % q = [1 1], r = 0
%      gfconv(q, [1 1])                     % [1 0 1] : on retombe sur A
%
%   Voir aussi GFCONV, GFDIV, GFADD, GFTRUNC.
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfdeconv');
    a = mod(double(gftrunc(a(:).')), p);
    b = mod(double(gftrunc(b(:).')), p);
    if all(b == 0)
        error('comm:gfdeconv:Nul', 'La division par le polynôme nul n''a pas de sens.');
    end
    degreB = numel(b) - 1;
    reste = a;
    if numel(a) - 1 < degreB
        quotient = 0;
        reste = gftrunc(reste);
        return
    end
    quotient = zeros(1, numel(a) - degreB);
    inversePivot = premierInverse(b(end), p);
    for k = (numel(a) - 1):-1:degreB
        indice = k + 1;
        if reste(indice) == 0
            continue
        end
        facteur = mod(reste(indice) * inversePivot, p);
        quotient(k - degreB + 1) = facteur;
        debut = indice - degreB;
        reste(debut:indice) = mod(reste(debut:indice) - facteur * b, p);
    end
    quotient = gftrunc(quotient);
    reste = gftrunc(reste);
end

function v = premierInverse(b, p)
    v = 1;
    base = mod(b, p);
    exposant = p - 2;
    while exposant > 0
        if mod(exposant, 2) == 1
            v = mod(v * base, p);
        end
        base = mod(base * base, p);
        exposant = floor(exposant / 2);
    end
end
