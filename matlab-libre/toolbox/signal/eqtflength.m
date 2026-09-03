function [b, a, nb, na] = eqtflength(num, den)
%EQTFLENGTH Met deux polynômes de transfert à la même longueur.
%   [B,A] = EQTFLENGTH(NUM,DEN) complète le plus court par des zéros en
%   queue, de sorte que B et A aient le même nombre de coefficients :
%   c'est ce qu'attendent les fonctions qui travaillent sur B et A pris
%   ensemble. Les zéros de queue en trop, communs aux deux, sont retirés.
%
%   [B,A,NB,NA] = EQTFLENGTH(...) rend en outre les degrés effectifs.
%
%   Exemple :
%      [b, a] = eqtflength([1 2], [1 2 3 0]);
%      % b = [1 2 0], a = [1 2 3]
%
%   Voir aussi TF2ZP, FILTER, IMPZ.
    b = double(num(:)).';
    a = double(den(:)).';
    if isempty(b), b = 0; end
    if isempty(a), a = 1; end
    longueur = max(numel(b), numel(a));
    b = [b, zeros(1, longueur - numel(b))];
    a = [a, zeros(1, longueur - numel(a))];
    % Une fois les deux à la même longueur, les zéros de queue communs ne
    % portent plus aucune information : ils gonflent l'ordre apparent du
    % filtre sans rien y changer.
    while numel(b) > 1 && numel(a) > 1 && b(end) == 0 && a(end) == 0
        b(end) = [];
        a(end) = [];
    end
    nb = derniereNonNulle(b);
    na = derniereNonNulle(a);
end

function n = derniereNonNulle(v)
    n = find(v ~= 0, 1, 'last');
    if isempty(n)
        n = 1;
    end
    n = n - 1;
end
