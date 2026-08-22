function [A, B, C, D] = tf2ss(num, den)
%TF2SS Forme compagne de commande d'une fonction de transfert.
%   [A,B,C,D] = TF2SS(NUM,DEN) rend la réalisation d'état canonique.
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
