function [A, B, C, D] = tf2ss(num, den)
%TF2SS Fonction de transfert vers modèle d'état.
%   [A,B,C,D] = TF2SS(NUM,DEN) rend la forme compagne de commande : la
%   réalisation dont la matrice A porte les coefficients du dénominateur
%   sur sa première ligne. Le modèle obtenu est commandable par
%   construction ; il n'est observable que si la transmittance n'a pas de
%   simplification pôle-zéro.
%
%   Exemples :
%      [A, B, C, D] = tf2ss(1, [1 3 2]);
%      sort(eig(A))                         % -2  -1, les poles
%      D                                    % 0 : la transmittance est stricte
%      rank(ctrb(A, B))                     % 2 : commandable par construction
%
%   Voir aussi SS2TF, SS, TF, SSDATA, CANON.
    num = num(:).';
    den = den(:).';
    if den(1) == 0
        error('control:tf2ss:LeadingZero', 'The denominator must not start with zero.');
    end
    num = num / den(1);
    den = den / den(1);
    n = numel(den) - 1;
    if numel(num) < n + 1
        num = [zeros(1, n + 1 - numel(num)), num];
    end
    D = num(1);
    reste = num(2:end) - num(1) * den(2:end);
    A = zeros(n, n);
    if n > 0
        A(1, :) = -den(2:end);
        for k = 2:n
            A(k, k-1) = 1;
        end
    end
    B = zeros(n, 1);
    if n > 0
        B(1) = 1;
    end
    C = reste;
end
