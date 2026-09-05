function [A, C] = matlibre_id_sous_espaces(y, u, ordre, horizon)
%MATLIBRE_ID_SOUS_ESPACES Matrices A et C par projection de sous-espaces.
%   [A,C] = MATLIBRE_ID_SOUS_ESPACES(Y,U,ORDRE,HORIZON) construit les
%   matrices de Hankel du passé et de l'avenir, projette l'avenir des
%   sorties sur le passé le long de l'avenir des entrées, et lit A et C
%   dans la décomposition en valeurs singulières du résultat.
%
%   La projection le long des entrées futures est ce qui isole la part de
%   l'avenir qui vient de l'état — c'est-à-dire du passé — de celle qui
%   vient de l'entrée à venir. Sans elle, les deux se confondraient.
%
%   C se lit dans le premier bloc de la matrice d'observabilité, et A dans
%   le fait que cette matrice se répète décalée d'un bloc : c'est
%   l'invariance par décalage.
%
%   Exemple :
%      [A, C] = matlibre_id_sous_espaces(y, u, 2, 6);
%
%   Voir aussi N4SID, SSEST.
    y = y(:, :);
    u = u(:, :);
    N = size(y, 1);
    sorties = size(y, 2);
    entrees = size(u, 2);
    i = max(horizon, ordre + 1);
    j = N - 2 * i + 1;
    if j < 2 * i * (entrees + sorties)
        i = max(ordre + 1, floor((N - 1) / (2 + 2 * (entrees + sorties))));
        j = N - 2 * i + 1;
    end
    if j < ordre + 1
        error('ident:n4sid:Donnees', 'Trop peu de données pour cet ordre.');
    end
    Up = matlibre_id_hankel(u, 1, i, j);
    Uf = matlibre_id_hankel(u, i + 1, i, j);
    Yp = matlibre_id_hankel(y, 1, i, j);
    Yf = matlibre_id_hankel(y, i + 1, i, j);
    Wp = [Up; Yp];
    % Projection sur le complément orthogonal des entrées futures.
    orthogonal = @(M) M - (M * Uf.') * pinv(Uf * Uf.') * Uf;
    YfPerp = orthogonal(Yf);
    WpPerp = orthogonal(Wp);
    projection = (YfPerp * WpPerp.') * pinv(WpPerp * WpPerp.') * Wp;
    [U, S, ~] = svd(projection, 0);
    valeurs = diag(S);
    ordre = min(ordre, numel(valeurs));
    Gamma = U(:, 1:ordre) * diag(sqrt(valeurs(1:ordre)));
    C = Gamma(1:sorties, :);
    A = pinv(Gamma(1:(end - sorties), :)) * Gamma((sorties + 1):end, :);
end
