function p = nextpow2(n)
%NEXTPOW2 Exposant de la puissance de deux immédiatement supérieure.
%   P = NEXTPOW2(N) rend le plus petit entier P tel que 2^P >= abs(N).
%   Pour un tableau, le calcul se fait élément par élément.
%
%   Exemple :
%      nextpow2(1000)   % 10
    n = abs(double(n));
    p = zeros(size(n));
    for k = 1:numel(n)
        if n(k) == 0
            p(k) = 0;
        else
            e = ceil(log2(n(k)));
            if 2^e < n(k)
                e = e + 1;
            end
            p(k) = e;
        end
    end
end
