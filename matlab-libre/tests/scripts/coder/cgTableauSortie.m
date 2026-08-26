function y = cgTableauSortie(x)
%CGTABLEAUSORTIE Rend un vecteur construit element par element.
    y = zeros(1, 4);
    for k = 1:4
        y(k) = x * k;
    end
end
