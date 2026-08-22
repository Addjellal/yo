function y = gaussmf(x, p)
%GAUSSMF Fonction d'appartenance gaussienne de paramètres [sigma centre].
    sigma = p(1);
    centre = p(2);
    y = exp(-((x - centre) .^ 2) / (2 * sigma ^ 2));
end
