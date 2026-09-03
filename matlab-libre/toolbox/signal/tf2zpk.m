function [z, p, k] = tf2zpk(b, a)
%TF2ZPK Transfert numérique -> zéros, pôles et gain.
%   [Z,P,K] = TF2ZPK(B,A) rend les zéros, les pôles et le gain du filtre
%   numérique de fonction de transfert B(z)/A(z), les polynômes étant
%   écrits en puissances décroissantes de z.
%
%   C'est le pendant de TF2ZP pour les filtres numériques : les zéros de
%   tête de B, qui ne sont que des retards, sont écartés au lieu de
%   devenir des zéros à l'infini.
%
%   Exemple :
%      [b, a] = butter(3, 0.4);
%      [z, p, k] = tf2zpk(b, a);
%      all(abs(p) < 1)        % le filtre est stable
%
%   Voir aussi TF2ZP, ZP2TF, ZPLANE, TF2SOS.
    if nargin < 2 || isempty(a)
        a = 1;
    end
    b = double(b(:)).';
    a = double(a(:)).';
    if isempty(b), b = 0; end
    if isempty(a), a = 1; end
    % Le premier coefficient non nul de A donne le gain ; les zéros de
    % tête de B sont des retards purs, non des zéros du filtre.
    premierA = find(a ~= 0, 1);
    if isempty(premierA)
        error('signal:tf2zpk:NullDenominator', 'Le dénominateur est nul.');
    end
    a = a(premierA:end);
    premierB = find(b ~= 0, 1);
    if isempty(premierB)
        z = zeros(0, 1);
        p = roots(a);
        k = 0;
        return;
    end
    b = b(premierB:end);
    k = b(1) / a(1);
    z = roots(b / b(1));
    p = roots(a / a(1));
end
