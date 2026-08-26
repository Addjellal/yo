function [courte, longue] = movavg(cours, n1, n2)
%MOVAVG Moyennes mobiles courte et longue.
    cours = cours(:).';
    courte = moyenneMobile(cours, n1);
    if nargin > 2
        longue = moyenneMobile(cours, n2);
    else
        longue = courte;
    end
end

function m = moyenneMobile(x, n)
    m = zeros(size(x));
    for k = 1:numel(x)
        a = max(1, k - n + 1);
        m(k) = mean(x(a:k));
    end
end
