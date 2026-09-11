function [p, q] = matlibre_sym_fraction(x, denominateurMaximal)
%MATLIBRE_SYM_FRACTION Écrit un nombre comme une fraction irréductible.
%   [P,Q] = MATLIBRE_SYM_FRACTION(X) rend P et Q entiers, premiers entre
%   eux, tels que P/Q vaut X. Q vaut un pour un entier.
%
%   La recherche est celle des fractions continues : on prend la partie
%   entière, on inverse ce qui reste, et l'on recommence. Les
%   approximations qu'elle produit sont les meilleures possibles à
%   dénominateur donné — aucune autre fraction de dénominateur plus petit
%   n'approche mieux —, ce qui est exactement ce qu'il faut pour
%   reconnaître une fraction que l'arithmétique flottante a un peu abîmée.
%
%   Un nombre qui n'est pas rationnel à la tolérance près est rendu avec
%   le dénominateur maximal atteint.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [p, q] = matlibre_sym_fraction(1/3);
%      p == 1 && q == 3
%      [p, q] = matlibre_sym_fraction(4);
%      p == 4 && q == 1
%
%   Voir aussi RAT, RATS, FACTOR.
    if nargin < 2, denominateurMaximal = 10000; end
    x = double(x);
    if x == round(x)
        p = x;
        q = 1;
        return
    end
    signe = sign(x);
    reste = abs(x);
    % Les deux dernieres reduites : (p0/q0) est celle d'avant, (p1/q1) la
    % courante. Chaque etape les combine avec le quotient partiel.
    p0 = 1; q0 = 0;
    p1 = floor(reste); q1 = 1;
    for essai = 1:40
        fraction = reste - floor(reste);
        if fraction < 1e-12
            break
        end
        reste = 1 / fraction;
        a = floor(reste);
        p2 = a * p1 + p0;
        q2 = a * q1 + q0;
        if q2 > denominateurMaximal
            break
        end
        p0 = p1; q0 = q1;
        p1 = p2; q1 = q2;
        if abs(p1 / q1 - abs(x)) < 1e-12
            break
        end
    end
    d = gcd(p1, q1);
    if d > 1
        p1 = p1 / d;
        q1 = q1 / d;
    end
    p = signe * p1;
    q = q1;
end
