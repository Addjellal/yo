function p = fcdf(x, d1, d2)
%FCDF Répartition de la loi de Fisher.
%   F(x) = I_{d1 x / (d1 x + d2)}(d1/2, d2/2).
%
%   Exemple :
%      fcdf(1, 10, 10)             % 0.5 : a degres egaux, la mediane est en un
%
%   Voir aussi FPDF, FINV, FRND, FSTAT, PDF, CDF.
    p = zeros(size(x));
    for k = 1:numel(x)
        v = x(k);
        if v <= 0
            p(k) = 0;
        else
            p(k) = betainc(d1 * v / (d1 * v + d2), d1 / 2, d2 / 2);
        end
    end
end
