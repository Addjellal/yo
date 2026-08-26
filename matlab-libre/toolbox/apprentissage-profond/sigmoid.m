function y = sigmoid(x)
%SIGMOID Sigmoïde logistique 1/(1+exp(-x)).
    y = 1 ./ (1 + exp(-x));
end
