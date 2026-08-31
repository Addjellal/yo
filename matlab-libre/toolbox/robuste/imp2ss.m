function [sys, valeurs] = imp2ss(reponse, Ts, ordre, tolerance)
%IMP2SS Modèle d'état identifié sur une réponse impulsionnelle.
%   SYS = IMP2SS(Y,TS) construit un modèle d'état dont la réponse
%   impulsionnelle échantillonnée est Y, prise à la période TS. C'est
%   l'algorithme de Kung : on range les échantillons dans une matrice de
%   Hankel, on la décompose en valeurs singulières, et l'ordre du modèle
%   est le nombre de valeurs singulières qui comptent.
%
%   SYS = IMP2SS(Y,TS,N) impose l'ordre N.
%   SYS = IMP2SS(Y,TS,[],TOL) garde les valeurs singulières supérieures à
%   TOL fois la plus grande.
%
%   [SYS,SV] = IMP2SS(...) rend en outre les valeurs singulières de la
%   matrice de Hankel : leur décroissance dit quel ordre choisir. Un
%   décrochage net entre la k-ième et la suivante désigne l'ordre k.
%
%   C'est la réalisation d'une suite de Markov : le passage d'une mesure
%   brute à un modèle. Elle sert quand on ne dispose que d'un
%   enregistrement — une réponse à un choc, une réponse indicielle
%   dérivée — et non d'équations.
%
%   Exemples :
%      G = ss(tf(1, [1 1.4 1]));
%      Gd = c2d(G, 0.1);
%      y = impulse(Gd, 0:0.1:20) * 0.1;      % la suite de Markov
%      [H, sv] = imp2ss(y, 0.1);
%      sv(1:4)'                              % deux valeurs, puis du bruit
%
%   Voir aussi IMPULSE, C2D, D2C, BALREAL, HSVD, SS.
    y = double(reponse(:));
    n = numel(y);
    if n < 4
        error('robust:imp2ss:NotEnoughData', 'IMP2SS needs at least four samples.');
    end
    if nargin < 2 || isempty(Ts)
        Ts = 1;
    end
    if nargin < 4 || isempty(tolerance)
        tolerance = 1e-6;
    end
    % La matrice de Hankel des echantillons, sans le premier — qui est le
    % terme direct.
    D = y(1);
    marches = y(2:end);
    m = floor(numel(marches) / 2);
    H = zeros(m, m);
    for i = 1:m
        for j = 1:m
            H(i, j) = marches(i + j - 1);
        end
    end
    [U, S, V] = svd(H);
    valeurs = diag(S);
    if nargin >= 3 && ~isempty(ordre)
        r = max(1, min(round(ordre), numel(valeurs)));
    else
        r = sum(valeurs > tolerance * max([valeurs; realmin]));
        r = max(r, 1);
    end
    racine = sqrt(valeurs(1:r));
    O = U(:, 1:r) * diag(racine);          % observabilite
    C = diag(racine) * V(:, 1:r)';         % commandabilite
    % Le decalage de la matrice de Hankel donne A.
    A = (O(1:end - 1, :) \ O(2:end, :));
    B = C(:, 1);
    Cs = O(1, :);
    sys = ss(A, B, Cs, D, Ts);
end
