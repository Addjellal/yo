function r = corr2(a, b)
%CORR2 Coefficient de corrélation entre deux matrices de même taille.
%   Exemple :  corr2(magic(4), magic(4))   % 1
    a = double(a(:)) - mean2(a);
    b = double(b(:)) - mean2(b);
    denominateur = sqrt(sum(a.^2) * sum(b.^2));
    if denominateur == 0
        r = 0;
    else
        r = sum(a .* b) / denominateur;
    end
end
