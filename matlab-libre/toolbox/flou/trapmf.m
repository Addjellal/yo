function y = trapmf(x, p)
%TRAPMF Fonction d'appartenance trapézoïdale de paramètres [a b c d].
    a = p(1); b = p(2); c = p(3); d = p(4);
    y = zeros(size(x));
    for k = 1:numel(x)
        v = x(k);
        if v <= a || v >= d
            y(k) = 0;
        elseif v < b
            y(k) = (v - a) / max(b - a, eps);
        elseif v <= c
            y(k) = 1;
        else
            y(k) = (d - v) / max(d - c, eps);
        end
    end
end
