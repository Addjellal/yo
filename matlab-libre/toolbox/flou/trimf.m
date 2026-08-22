function y = trimf(x, p)
%TRIMF Fonction d'appartenance triangulaire de paramètres [a b c].
    a = p(1); b = p(2); c = p(3);
    y = zeros(size(x));
    for k = 1:numel(x)
        v = x(k);
        if v <= a || v >= c
            y(k) = 0;
        elseif v <= b
            if b == a
                y(k) = 1;
            else
                y(k) = (v - a) / (b - a);
            end
        else
            if c == b
                y(k) = 1;
            else
                y(k) = (c - v) / (c - b);
            end
        end
    end
end
