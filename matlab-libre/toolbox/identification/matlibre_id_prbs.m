function u = matlibre_id_prbs(N)
%MATLIBRE_ID_PRBS Suite binaire pseudo-aléatoire de longueur maximale.
%   U = MATLIBRE_ID_PRBS(N) rend N valeurs valant moins un ou un,
%   engendrées par un registre à décalage bouclé sur lui-même.
%
%   Une telle suite parcourt tous les états non nuls du registre avant de
%   se répéter : son autocorrélation vaut un au décalage nul et presque
%   zéro partout ailleurs, ce qui en fait un bruit blanc reproductible.
%
%   Exemple :
%      u = matlibre_id_prbs(31);
%      all(abs(u) == 1)      % vrai
%
%   Voir aussi IDINPUT.
    ordre = 9;
    while (2 ^ ordre - 1) < N && ordre < 20
        ordre = ordre + 1;
    end
    prises = matlibre_id_prises_registre(ordre);
    registre = ones(1, ordre);
    u = zeros(N, 1);
    for k = 1:N
        u(k) = registre(end);
        neuf = mod(sum(registre(prises)), 2);
        registre = [neuf, registre(1:(end - 1))];
    end
    u = 2 * u - 1;
end
