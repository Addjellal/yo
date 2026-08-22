function e = mse(predit, cible)
%MSE Erreur quadratique moyenne.
    d = predit - cible;
    e = sum(sum(d .^ 2)) / numel(d);
end
