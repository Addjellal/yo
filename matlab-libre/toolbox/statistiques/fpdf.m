function y = fpdf(x, d1, d2)
%FPDF Densité de la loi de Fisher.
    y = zeros(size(x));
    for k = 1:numel(x)
        v = x(k);
        if v <= 0
            y(k) = 0;
        else
            logNum = (d1/2) * log(d1/d2) + (d1/2 - 1) * log(v);
            logDen = ((d1 + d2)/2) * log(1 + d1 * v / d2) + ...
                     gammaln(d1/2) + gammaln(d2/2) - gammaln((d1 + d2)/2);
            y(k) = exp(logNum - logDen);
        end
    end
end
