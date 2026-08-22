function [meilleur, valeur] = multistart(fonction, bas, haut, nDeparts)
%MULTISTART Minimisation locale répétée depuis des points tirés au hasard.
    if nargin < 4
        nDeparts = 20;
    end
    bas = bas(:).';
    haut = haut(:).';
    valeur = inf;
    meilleur = bas;
    for k = 1:nDeparts
        depart = bas + rand(size(bas)) .* (haut - bas);
        x = fminsearch(fonction, depart);
        v = fonction(x);
        if v < valeur
            valeur = v;
            meilleur = x;
        end
    end
end
