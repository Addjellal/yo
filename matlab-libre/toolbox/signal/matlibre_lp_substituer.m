function [num, den] = matlibre_lp_substituer(num, den, P, Q)
%MATLIBRE_LP_SUBSTITUER Remplace s par P(s)/Q(s) dans une fonction de transfert.
%   [N,D] = MATLIBRE_LP_SUBSTITUER(NUM,DEN,P,Q) rend la fonction de
%   transfert obtenue en substituant la fraction rationnelle P/Q à la
%   variable s dans NUM(s)/DEN(s).
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Le calcul suit la définition. Un polynôme A de degré n s'écrit
%   somme a_i s^(n-i) ; y substituer P/Q donne
%
%      A(P/Q) = (1/Q^n) * somme a_i P^(n-i) Q^i
%
%   Numérateur et dénominateur sont d'abord complétés à la même longueur,
%   si bien que le facteur 1/Q^n est le même pour les deux et disparaît du
%   quotient. C'est ce qui rend la substitution exacte : aucune division
%   de polynômes, seulement des produits.
    num = num(:).';
    den = den(:).';
    n = max(numel(num), numel(den));
    num = [zeros(1, n - numel(num)), num];
    den = [zeros(1, n - numel(den)), den];
    num = combiner(num, P, Q);
    den = combiner(den, P, Q);
    % Les zéros de tête ne décrivent pas un degré, seulement une écriture.
    while numel(num) > 1 && num(1) == 0, num(1) = []; end
    while numel(den) > 1 && den(1) == 0, den(1) = []; end
end

function r = combiner(a, P, Q)
    n = numel(a) - 1;
    r = 0;
    for i = 0:n
        terme = a(i + 1) * conv(puissance(P, n - i), puissance(Q, i));
        r = ajouter(r, terme);
    end
end

function p = puissance(base, k)
    p = 1;
    for j = 1:k
        p = conv(p, base);
    end
end

function s = ajouter(a, b)
    a = a(:).';
    b = b(:).';
    n = max(numel(a), numel(b));
    s = [zeros(1, n - numel(a)), a] + [zeros(1, n - numel(b)), b];
end
