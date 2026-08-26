function y = sigmf(x, p)
%SIGMF Fonction d'appartenance sigmoïde de paramètres [pente centre].
    y = 1 ./ (1 + exp(-p(1) * (x - p(2))));
end
