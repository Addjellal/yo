function [K, E] = ellipke(m, tol)
%ELLIPKE Intégrales elliptiques complètes de première et seconde espèce.
%   [K,E] = ELLIPKE(M) où M est le paramètre, M = k^2 avec k le module.
%   Le calcul suit la moyenne arithmético-géométrique de Gauss : la suite
%   converge quadratiquement, une dizaine de tours suffisent à la
%   précision machine.
%
%   Exemple :
%      [K, E] = ellipke(0.5)   % 1.854074677301372 et 1.350643881047676
    if nargin < 2 || isempty(tol), tol = eps; end
    m = double(m);
    K = zeros(size(m));
    E = zeros(size(m));
    for indice = 1:numel(m)
        [K(indice), E(indice)] = un(m(indice), tol);
    end
end

function [K, E] = un(m, tol)
    if m > 1 || m < 0 || isnan(m)
        K = NaN;
        E = NaN;
        return
    end
    if m == 1
        K = Inf;
        E = 1;
        return
    end
    a = 1;
    b = sqrt(1 - m);
    c = sqrt(m);
    somme = c ^ 2 / 2;
    puissance = 1;
    for tour = 1:100
        if abs(c) < tol
            break
        end
        aSuivant = (a + b) / 2;
        bSuivant = sqrt(a * b);
        c = (a - b) / 2;
        a = aSuivant;
        b = bSuivant;
        puissance = puissance * 2;
        somme = somme + puissance * c ^ 2 / 2;
    end
    K = pi / (2 * a);
    E = K * (1 - somme);
end
