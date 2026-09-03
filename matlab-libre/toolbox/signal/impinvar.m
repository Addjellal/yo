function [bz, az] = impinvar(b, a, fs, tol)
%IMPINVAR Transformation par invariance impulsionnelle.
%   [BZ,AZ] = IMPINVAR(B,A,FS) rend le filtre numérique dont la réponse
%   impulsionnelle est celle du filtre analogique B(s)/A(s) échantillonnée
%   à FS hertz : hz(n) = h(n/FS)/FS.
%
%   Contrairement à la transformation bilinéaire, elle ne déforme pas
%   l'axe des fréquences — mais elle replie tout ce que le filtre
%   analogique laisse passer au-delà de FS/2. Elle demande donc un filtre
%   analogique déjà bien atténué à la moitié de la fréquence
%   d'échantillonnage, et refuse un filtre qui n'est pas strictement
%   propre.
%
%   FS vaut 1 par défaut.
%
%   Exemple :
%      [b, a] = butter(4, 0.3, 's');
%      [bz, az] = impinvar(b, a, 10);
%
%   Voir aussi BILINEAR, RESIDUE, IMPZ.
    if nargin < 3 || isempty(fs)
        fs = 1;
    end
    if nargin < 4
        tol = 1e-6;
    end
    b = double(b(:)).';
    a = double(a(:)).';
    if numel(b) >= numel(a)
        error('signal:impinvar:NotProper', ...
              'Le filtre analogique doit être strictement propre.');
    end
    % La décomposition en éléments simples donne un pôle par terme ; un
    % terme d'ordre m devient un pôle numérique d'ordre m.
    [r, p, k] = residue(b, a);
    if ~isempty(k) && any(abs(k) > tol)
        error('signal:impinvar:NotProper', ...
              'Le filtre analogique doit être strictement propre.');
    end
    % La somme part du premier terme, non d'un zéro : mettre 0/1 au
    % départ ajoutait un coefficient de tête au numérateur, et toute la
    % réponse impulsionnelle avançait d'un échantillon.
    bz = [];
    az = [];
    dejaVus = zeros(0, 1);
    for j = 1:numel(p)
        multiplicite = sum(abs(dejaVus - p(j)) < tol) + 1;
        dejaVus(end + 1) = p(j);   %#ok<AGROW>
        [numTerme, denTerme] = termeNumerique(r(j), p(j), multiplicite, fs);
        if isempty(az)
            bz = numTerme;
            az = denTerme;
        else
            [bz, az] = additionner(bz, az, numTerme, denTerme);
        end
    end
    if isempty(az)
        bz = 0;
        az = 1;
    end
    bz = real(bz);
    az = real(az);
    bz = bz / az(1);
    az = az / az(1);
    % Un filtre strictement propre a un coefficient de moins au
    % numérateur qu'au dénominateur.
    if numel(bz) > numel(az) - 1
        bz = bz(1:numel(az) - 1);
    end
end

function [num, den] = termeNumerique(residu, pole, multiplicite, fs)
%TERMENUMERIQUE Le terme numérique d'un pôle analogique.
%   Le terme analogique RESIDU/(s-POLE)^m a pour réponse impulsionnelle
%   residu*t^(m-1)*exp(pole*t)/(m-1)!. Échantillonnée au pas T et
%   multipliée par T, elle se somme en
%
%      residu*T^m/(m-1)! * N_(m-1)(x) / (1-x)^m,   x = exp(pole*T) z^-1,
%
%   où N_k est le polynôme eulérien, bâti par la récurrence
%   N_(k+1) = x[(1-x) N_k' + (k+1) N_k]. C'est exact pour toute
%   multiplicité, là où la forme au carré ne l'est que pour un pôle
%   simple.
    T = 1 / fs;
    a = exp(pole * T);
    % Numérateur eulérien, en puissances croissantes de x.
    N = 1;
    for k = 0:(multiplicite - 2)
        derivee = derivePolynome(N);
        N = multiplierParX(polyAjouter(derivee, ...
                                       polyAjouter(multiplierParMoinsX(derivee), ...
                                                   (k + 1) * N)));
    end
    % x = a z^-1 : le coefficient de x^j devient celui de z^-j, multiplié
    % par a^j.
    num = N .* (a .^ (0:(numel(N) - 1)));
    num = residu * T ^ multiplicite / factorial(multiplicite - 1) * num;
    den = 1;
    for k = 1:multiplicite
        den = conv(den, [1, -a]);
    end
end

function d = derivePolynome(N)
% Dérivée d'un polynôme écrit en puissances croissantes.
    if numel(N) <= 1
        d = 0;
        return;
    end
    d = N(2:end) .* (1:(numel(N) - 1));
end

function r = multiplierParX(N)
    r = [0, N];
end

function r = multiplierParMoinsX(N)
    r = [0, -N];
end

function s = polyAjouter(p, q)
% Somme de deux polynômes en puissances croissantes.
    n = max(numel(p), numel(q));
    s = [p, zeros(1, n - numel(p))] + [q, zeros(1, n - numel(q))];
end

function [b, a] = additionner(b1, a1, b2, a2)
% Somme de deux fractions rationnelles.
    b = polyAdditionner(conv(b1, a2), conv(b2, a1));
    a = conv(a1, a2);
end

function s = polyAdditionner(p, q)
    n = max(numel(p), numel(q));
    s = [zeros(1, n - numel(p)), p] + [zeros(1, n - numel(q)), q];
end
