function [b, a] = besself(n, Wo)
%BESSELF Filtre analogique de Bessel.
%   [B,A] = BESSELF(N,WO) rend les coefficients du filtre passe-bas
%   analogique d'ordre N dont le temps de propagation de groupe reste
%   plat jusqu'à WO radians par seconde. Contrairement aux autres
%   familles, BESSELF ne conçoit pas de filtre numérique : la
%   transformation bilinéaire détruirait la platitude du retard.
%
%   Le dénominateur est le polynôme de Bessel inverse
%
%      theta_n(s) = somme des a_k s^k,  a_k = (2n-k)! / (2^(n-k) k! (n-k)!)
%
%   dont le retard de groupe vaut exactement 1 en zéro.
%
%   Exemple :
%      [b, a] = besself(2, 1);   % a = [1 3 3], b = 3
%
%   Voir aussi BUTTER, CHEBY1, ELLIP.
    if nargin < 2 || isempty(Wo), Wo = 1; end
    n = round(n);
    if n < 1
        error('signal:besself:BadOrder', 'L''ordre doit être au moins 1.');
    end
    % La récurrence theta_n = (2n-1) theta_(n-1) + s^2 theta_(n-2) garde
    % des entiers exacts, là où la formule factorielle passe par des
    % logarithmes et rend 839,999999 au lieu de 840.
    precedent = 1;                       % theta_0 = 1
    courant = [1 1];                     % theta_1 = s + 1, puissances décroissantes
    if n == 1
        polynome = courant;
    else
        for ordre = 2:n
            decale = [precedent 0 0];    % s^2 theta_(ordre-2)
            etendu = [0 (2 * ordre - 1) * courant];
            polynome = decale + etendu;
            precedent = courant;
            courant = polynome;
        end
    end
    % Mise à l'échelle s -> s/Wo, puis multiplication par Wo^n.
    a = zeros(1, n + 1);
    for k = 0:n
        a(k + 1) = polynome(k + 1) * Wo ^ k;
    end
    b = a(end);
end
